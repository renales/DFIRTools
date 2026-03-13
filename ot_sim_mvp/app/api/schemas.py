from pydantic import BaseModel


class ModeRequest(BaseModel):
    mode: str


class CommandRequest(BaseModel):
    target: str
    value: bool
