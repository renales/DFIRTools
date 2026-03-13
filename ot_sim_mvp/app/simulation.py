from __future__ import annotations

import asyncio
import json
from dataclasses import asdict

from .alarm_event import AlarmEngine, DEFAULT_ALARM_RULES, now_iso
from .assets import LevelSensor, Pump, Tank, Valve
from .config import DB_PATH, TICK_SECONDS
from .control import Controller
from .models import Mode, ProcessState
from .process import ProcessModel
from .storage import SQLiteEventStore


class SimulationEngine:
    def __init__(self) -> None:
        self.tank_a = Tank(name="tank_a", level=35.0, capacity=100.0)
        self.tank_b = Tank(name="tank_b", level=45.0, capacity=100.0)
        self.pump = Pump(name="pump_ab", running=False, flow_rate=12.0)
        self.inlet = Valve(name="valve_inlet", open=True)
        self.outlet = Valve(name="valve_outlet", open=True)
        self.sensor_a = LevelSensor(name="ls_tank_a", tank_name="tank_a")
        self.sensor_b = LevelSensor(name="ls_tank_b", tank_name="tank_b")

        self.process = ProcessModel(self.tank_a, self.tank_b, self.pump, self.inlet, self.outlet)
        self.controller = Controller()
        self.alarm_engine = AlarmEngine(DEFAULT_ALARM_RULES)
        self.state = ProcessState(mode=Mode.AUTO)
        self.store = SQLiteEventStore(DB_PATH)

        self._task: asyncio.Task | None = None
        self._lock = asyncio.Lock()
        self.last_alarm_events: list[dict[str, str | float]] = []

    async def start(self) -> None:
        if self._task is None:
            self._task = asyncio.create_task(self._run_loop())

    async def stop(self) -> None:
        if self._task is not None:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
            self._task = None

    async def _run_loop(self) -> None:
        while True:
            async with self._lock:
                self._tick()
            await asyncio.sleep(TICK_SECONDS)

    def _collect_tags(self) -> dict[str, float | int | bool | str]:
        return {
            "tank_a.level": round(self.sensor_a.read(self.tank_a.level), 2),
            "tank_b.level": round(self.sensor_b.read(self.tank_b.level), 2),
            "pump_ab.running": self.pump.effective_running(),
            "valve_inlet.open": self.inlet.effective_open(),
            "valve_outlet.open": self.outlet.effective_open(),
            "mode": self.state.mode.value,
        }

    def _tick(self) -> None:
        self.controller.apply_auto(
            mode=self.state.mode,
            tank_a_level=self.tank_a.level,
            tank_b_level=self.tank_b.level,
            pump=self.pump,
            inlet_valve=self.inlet,
            outlet_valve=self.outlet,
        )
        self.process.step(TICK_SECONDS)
        self.state.tick += 1
        self.state.tags = self._collect_tags()

        numeric_tags = {k: float(v) for k, v in self.state.tags.items() if isinstance(v, (int, float))}
        alarm_events = self.alarm_engine.evaluate(numeric_tags)
        self.last_alarm_events = alarm_events

        self.store.insert_event(
            timestamp=now_iso(),
            event_type="tick",
            payload=json.dumps({"tick": self.state.tick, "tags": self.state.tags}),
        )
        for event in alarm_events:
            self.store.insert_alarm(
                timestamp=str(event["timestamp"]),
                alarm_id=str(event["alarm_id"]),
                event_type=str(event["type"]),
                severity=str(event["severity"]),
                message=str(event["message"]),
                value=float(event["value"]),
            )

    async def snapshot(self) -> dict:
        async with self._lock:
            return {
                "tick": self.state.tick,
                "mode": self.state.mode.value,
                "assets": {
                    "tank_a": asdict(self.tank_a),
                    "tank_b": asdict(self.tank_b),
                    "pump": asdict(self.pump),
                    "inlet_valve": asdict(self.inlet),
                    "outlet_valve": asdict(self.outlet),
                },
                "tags": self.state.tags,
                "active_alarms": [k for k, v in self.alarm_engine.active.items() if v],
            }

    async def set_mode(self, mode: str) -> None:
        async with self._lock:
            self.state.mode = Mode(mode)
            self.store.insert_event(now_iso(), "mode_change", json.dumps({"mode": mode}))

    async def command(self, target: str, value: bool) -> None:
        async with self._lock:
            if target == "pump_ab.running":
                self.pump.running = value
            elif target == "valve_inlet.open":
                self.inlet.open = value
            elif target == "valve_outlet.open":
                self.outlet.open = value
            else:
                raise ValueError(f"Unknown target {target}")
            self.store.insert_event(
                now_iso(),
                "command",
                json.dumps({"target": target, "value": value, "mode": self.state.mode.value}),
            )
