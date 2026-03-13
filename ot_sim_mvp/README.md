# OT/Industrial Simulation MVP

MVP de una estación de bombeo orientado a formación y ciberseguridad OT.

## Alcance actual
- 2 tanques, 1 bomba, 2 válvulas, 2 sensores de nivel
- Modo automático y manual
- Alarmas de nivel (H, HH, L, LL) por tanque
- Simulación discreta cada 500 ms
- API FastAPI + WebSocket para telemetría en tiempo real
- HMI web mínima
- Registro de eventos y alarmas en SQLite

## Arquitectura
- `app/assets.py`: activos industriales (Tank, Pump, Valve, LevelSensor)
- `app/process.py`: modelo de proceso y balances simples de flujo
- `app/control.py`: lógica de control automática
- `app/simulation.py`: motor de simulación, ticks, snapshot de estado
- `app/alarm_event.py`: reglas y evaluación de alarmas/eventos
- `app/storage.py`: persistencia SQLite
- `app/api/*`: endpoints y esquemas
- `app/hmi/index.html`: interfaz mínima de operación/monitorización

## Estructura
```
ot_sim_mvp/
  app/
    api/
    hmi/
    alarm_event.py
    assets.py
    config.py
    control.py
    main.py
    models.py
    process.py
    simulation.py
    storage.py
  tests/
  requirements.txt
  pytest.ini
```

## Ejecución
```bash
cd ot_sim_mvp
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Abrir HMI en: `http://127.0.0.1:8000/api/`

## Endpoints
- `GET /api/health`
- `GET /api/state`
- `GET /api/events`
- `GET /api/alarms`
- `POST /api/mode` body `{ "mode": "auto" | "manual" }`
- `POST /api/command` body `{ "target": "pump_ab.running|valve_inlet.open|valve_outlet.open", "value": true|false }`
- `WS /api/ws`

## Plan de implementación por fases
1. **Fase 1 (actual)**: simulación funcional base + HMI + API + persistencia + tests básicos.
2. **Fase 2**: escenarios de fallo (sensor fail, bomba atascada, válvula bloqueada, pérdida de comms) y API de inyección de fallos.
3. **Fase 3**: trazas de escenarios formativos, replay, exportación de eventos, mejoras UX HMI.
