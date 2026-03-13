from __future__ import annotations

from dataclasses import dataclass

from .assets import Pump, Valve
from .models import Mode


@dataclass
class Controller:
    pump_start_level: float = 40.0
    pump_stop_level: float = 20.0

    def apply_auto(
        self,
        mode: Mode,
        tank_a_level: float,
        tank_b_level: float,
        pump: Pump,
        inlet_valve: Valve,
        outlet_valve: Valve,
    ) -> None:
        if mode != Mode.AUTO:
            return

        inlet_valve.open = True
        outlet_valve.open = True

        if tank_a_level >= self.pump_start_level and tank_b_level < 90.0:
            pump.running = True
        elif tank_a_level <= self.pump_stop_level or tank_b_level >= 95.0:
            pump.running = False
