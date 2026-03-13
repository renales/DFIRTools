from __future__ import annotations

from dataclasses import dataclass

from .assets import Pump, Tank, Valve


@dataclass
class ProcessModel:
    tank_a: Tank
    tank_b: Tank
    pump_ab: Pump
    inlet_valve: Valve
    outlet_valve: Valve
    inlet_rate: float = 8.0
    outlet_rate: float = 6.0

    def step(self, dt: float) -> None:
        inlet_flow = self.inlet_rate if self.inlet_valve.effective_open() else 0.0
        transfer_flow = self.pump_ab.flow_rate if self.pump_ab.effective_running() else 0.0
        outlet_flow = self.outlet_rate if self.outlet_valve.effective_open() else 0.0

        self.tank_a.apply_flow(inflow=inlet_flow, outflow=transfer_flow, dt=dt)
        self.tank_b.apply_flow(inflow=transfer_flow, outflow=outlet_flow, dt=dt)
