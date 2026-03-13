from __future__ import annotations

import asyncio
from pathlib import Path

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse

from .schemas import CommandRequest, ModeRequest


def build_router(sim_engine) -> APIRouter:
    router = APIRouter()

    @router.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @router.get("/state")
    async def state() -> dict:
        return await sim_engine.snapshot()

    @router.get("/events")
    async def events(limit: int = 20) -> dict:
        return {"events": sim_engine.store.recent_events(limit)}

    @router.get("/alarms")
    async def alarms(limit: int = 20) -> dict:
        return {"alarms": sim_engine.store.recent_alarms(limit)}

    @router.post("/mode")
    async def set_mode(payload: ModeRequest) -> dict[str, str]:
        try:
            await sim_engine.set_mode(payload.mode)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        return {"result": "ok", "mode": payload.mode}

    @router.post("/command")
    async def command(payload: CommandRequest) -> dict[str, str]:
        if (await sim_engine.snapshot())["mode"] != "manual":
            raise HTTPException(status_code=409, detail="Commands allowed only in manual mode")
        try:
            await sim_engine.command(payload.target, payload.value)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        return {"result": "ok"}

    @router.get("/")
    async def hmi() -> FileResponse:
        return FileResponse(Path(__file__).resolve().parent.parent / "hmi" / "index.html")

    @router.websocket("/ws")
    async def ws_state(websocket: WebSocket) -> None:
        await websocket.accept()
        try:
            while True:
                await websocket.send_json(await sim_engine.snapshot())
                await asyncio.sleep(0.5)
        except WebSocketDisconnect:
            return

    return router
