from ot_sim_mvp.app.alarm_event import AlarmEngine, DEFAULT_ALARM_RULES
from ot_sim_mvp.app.assets import Pump, Tank, Valve
from ot_sim_mvp.app.process import ProcessModel


def test_process_levels_change_with_pump_and_valves() -> None:
    tank_a = Tank("a", level=50.0, capacity=100.0)
    tank_b = Tank("b", level=10.0, capacity=100.0)
    process = ProcessModel(
        tank_a=tank_a,
        tank_b=tank_b,
        pump_ab=Pump("p", running=True, flow_rate=10.0),
        inlet_valve=Valve("in", open=True),
        outlet_valve=Valve("out", open=True),
        inlet_rate=8.0,
        outlet_rate=6.0,
    )

    process.step(dt=0.5)

    assert tank_a.level < 50.0
    assert tank_b.level > 10.0


def test_alarm_engine_raises_and_clears() -> None:
    engine = AlarmEngine(DEFAULT_ALARM_RULES)

    raised = engine.evaluate({"tank_a.level": 95.0, "tank_b.level": 50.0})
    assert any(e["alarm_id"] == "A_HH" and e["type"] == "alarm_raised" for e in raised)

    cleared = engine.evaluate({"tank_a.level": 50.0, "tank_b.level": 50.0})
    assert any(e["alarm_id"] == "A_HH" and e["type"] == "alarm_cleared" for e in cleared)
