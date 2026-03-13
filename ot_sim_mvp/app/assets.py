from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Tank:
    name: str
    level: float
    capacity: float
    leak_rate: float = 0.0

    def apply_flow(self, inflow: float, outflow: float, dt: float) -> None:
        delta = (inflow - outflow - self.leak_rate) * dt
        self.level = max(0.0, min(self.capacity, self.level + delta))


@dataclass
class Pump:
    name: str
    running: bool = False
    flow_rate: float = 10.0
    stuck_off: bool = False

    def effective_running(self) -> bool:
        return self.running and not self.stuck_off


@dataclass
class Valve:
    name: str
    open: bool = True
    blocked: bool = False

    def effective_open(self) -> bool:
        return self.open and not self.blocked


@dataclass
class LevelSensor:
    name: str
    tank_name: str
    failed: bool = False

    def read(self, level: float) -> float:
        if self.failed:
            return -1.0
        return level
