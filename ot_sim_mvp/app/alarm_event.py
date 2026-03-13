from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from enum import Enum


class Severity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class AlarmRule:
    tag: str
    alarm_id: str
    threshold: float
    direction: str
    severity: Severity
    message: str


DEFAULT_ALARM_RULES = [
    AlarmRule("tank_a.level", "A_H", 75.0, "high", Severity.MEDIUM, "Tank A high level"),
    AlarmRule("tank_a.level", "A_HH", 90.0, "high", Severity.HIGH, "Tank A high-high level"),
    AlarmRule("tank_a.level", "A_L", 25.0, "low", Severity.MEDIUM, "Tank A low level"),
    AlarmRule("tank_a.level", "A_LL", 10.0, "low", Severity.CRITICAL, "Tank A low-low level"),
    AlarmRule("tank_b.level", "B_H", 75.0, "high", Severity.MEDIUM, "Tank B high level"),
    AlarmRule("tank_b.level", "B_HH", 90.0, "high", Severity.HIGH, "Tank B high-high level"),
    AlarmRule("tank_b.level", "B_L", 25.0, "low", Severity.MEDIUM, "Tank B low level"),
    AlarmRule("tank_b.level", "B_LL", 10.0, "low", Severity.CRITICAL, "Tank B low-low level"),
]


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class AlarmEngine:
    def __init__(self, rules: list[AlarmRule]) -> None:
        self.rules = rules
        self.active: dict[str, bool] = {}

    def evaluate(self, tags: dict[str, float]) -> list[dict[str, str | float]]:
        events: list[dict[str, str | float]] = []
        for rule in self.rules:
            value = float(tags.get(rule.tag, 0.0))
            triggered = value >= rule.threshold if rule.direction == "high" else value <= rule.threshold
            was_active = self.active.get(rule.alarm_id, False)

            if triggered and not was_active:
                self.active[rule.alarm_id] = True
                events.append(
                    {
                        "type": "alarm_raised",
                        "alarm_id": rule.alarm_id,
                        "tag": rule.tag,
                        "severity": rule.severity.value,
                        "message": rule.message,
                        "value": value,
                        "timestamp": now_iso(),
                    }
                )
            elif not triggered and was_active:
                self.active[rule.alarm_id] = False
                events.append(
                    {
                        "type": "alarm_cleared",
                        "alarm_id": rule.alarm_id,
                        "tag": rule.tag,
                        "severity": rule.severity.value,
                        "message": f"Cleared: {rule.message}",
                        "value": value,
                        "timestamp": now_iso(),
                    }
                )

        return events
