from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any


class SQLiteEventStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.path)

    def _init_db(self) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    type TEXT NOT NULL,
                    payload TEXT NOT NULL
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS alarms (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    alarm_id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    severity TEXT NOT NULL,
                    message TEXT NOT NULL,
                    value REAL NOT NULL
                )
                """
            )

    def insert_event(self, timestamp: str, event_type: str, payload: str) -> None:
        with self._connect() as conn:
            conn.execute(
                "INSERT INTO events(timestamp, type, payload) VALUES (?, ?, ?)",
                (timestamp, event_type, payload),
            )

    def insert_alarm(
        self,
        timestamp: str,
        alarm_id: str,
        event_type: str,
        severity: str,
        message: str,
        value: float,
    ) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO alarms(timestamp, alarm_id, event_type, severity, message, value)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (timestamp, alarm_id, event_type, severity, message, value),
            )

    def recent_alarms(self, limit: int = 20) -> list[dict[str, Any]]:
        with self._connect() as conn:
            rows = conn.execute(
                """
                SELECT timestamp, alarm_id, event_type, severity, message, value
                FROM alarms ORDER BY id DESC LIMIT ?
                """,
                (limit,),
            ).fetchall()
        return [
            {
                "timestamp": r[0],
                "alarm_id": r[1],
                "event_type": r[2],
                "severity": r[3],
                "message": r[4],
                "value": r[5],
            }
            for r in rows
        ]

    def recent_events(self, limit: int = 20) -> list[dict[str, Any]]:
        with self._connect() as conn:
            rows = conn.execute(
                "SELECT timestamp, type, payload FROM events ORDER BY id DESC LIMIT ?",
                (limit,),
            ).fetchall()
        return [{"timestamp": r[0], "type": r[1], "payload": r[2]} for r in rows]
