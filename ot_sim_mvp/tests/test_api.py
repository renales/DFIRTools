import pytest

fastapi = pytest.importorskip("fastapi")
from fastapi.testclient import TestClient

from ot_sim_mvp.app.main import app


def test_health_and_state_endpoints() -> None:
    with TestClient(app) as client:
        h = client.get("/api/health")
        assert h.status_code == 200
        assert h.json()["status"] == "ok"

        s = client.get("/api/state")
        assert s.status_code == 200
        body = s.json()
        assert "tags" in body
        assert "mode" in body
