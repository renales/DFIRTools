from __future__ import annotations

from fastapi import FastAPI

from .api.routes import build_router
from .simulation import SimulationEngine

app = FastAPI(title="OT/Industrial Simulation MVP", version="0.1.0")
engine = SimulationEngine()
app.include_router(build_router(engine), prefix="/api")


@app.on_event("startup")
async def startup_event() -> None:
    await engine.start()


@app.on_event("shutdown")
async def shutdown_event() -> None:
    await engine.stop()
