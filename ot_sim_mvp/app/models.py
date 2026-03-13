from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict


class Mode(str, Enum):
    AUTO = "auto"
    MANUAL = "manual"


@dataclass
class ProcessState:
    tick: int = 0
    mode: Mode = Mode.AUTO
    tags: Dict[str, float | int | bool | str] = field(default_factory=dict)
