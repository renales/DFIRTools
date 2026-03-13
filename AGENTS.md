# AGENTS.md

Reglas de trabajo para futuras iteraciones en este repositorio.

## Principios generales
- Priorizar soluciones funcionales end-to-end antes de optimizaciones.
- Mantener arquitectura modular con separación clara entre dominio, infraestructura e interfaces.
- Evitar sobreingeniería y dependencias innecesarias.
- Escribir código legible, con nombres explícitos y tipado cuando aporte valor.

## Convenciones técnicas
- Python como lenguaje principal para servicios de simulación.
- API HTTP con FastAPI y telemetría en tiempo real con WebSocket cuando aplique.
- Persistencia ligera con SQLite para MVPs y pruebas locales.
- Tests con pytest para lógica de negocio crítica y endpoints básicos.

## Estructura y diseño
- Separar explícitamente:
  1. modelo de proceso
  2. activos industriales
  3. lógica de control
  4. motor de simulación
  5. API
  6. HMI
  7. alarmas y eventos
- Añadir nuevas funcionalidades mediante módulos pequeños y cohesionados.
- Preparar extensibilidad para escenarios de fallo (sensor, actuadores, comunicaciones).

## Calidad y validación
- Ejecutar tests antes de cerrar una iteración.
- Incluir comprobación rápida de arranque de la app cuando se modifique backend/API.
- Registrar en README cómo ejecutar, probar y extender el sistema.

## Documentación
- Mantener README actualizado con alcance, arquitectura y endpoints.
- Documentar decisiones de diseño importantes en términos de simplicidad y mantenibilidad.
