# DFIR Timeline Generator (Linux)
**timeline.sh – Forensic Timeline Creation**



## Descripción

`timeline.sh` es un **script de generación de timelines forenses para sistemas Linux**, diseñado para **análisis post-triaje** dentro de procesos de **Digital Forensics & Incident Response (DFIR)**.

Su objetivo es **correlacionar eventos en el tiempo** (filesystem, logs, procesos y autenticación) para facilitar la **reconstrucción de la actividad del sistema** durante un incidente de seguridad.

El script genera un **timeline unificado en formato CSV**, fácil de analizar con herramientas estándar (Excel, Timesketch, Splunk, Elastic, etc.).



## Objetivos del timeline

- Reconstruir cronológicamente la actividad del sistema
- Correlacionar artefactos procedentes del triaje forense
- Identificar **patrones de ataque**, persistencia y movimientos laterales
- Apoyar la toma de decisiones durante la investigación



## Requisitos

- Sistema Linux
- `bash`
- Utilidades estándar:
  - `find`
  - `stat`
  - `date`
  - `awk`
  - `ps`
  - `last`
  - `journalctl` (si systemd)
- Ejecución recomendada como **root**

> No requiere dependencias externas.



## Advertencia importante

**El timeline no indicated causalidad ni culpabilidad**, únicamente correlación temporal.  
Debe interpretarse siempre junto con otras evidencias DFIR.



## Instalación

Ubicar el script dentro del repositorio DFIR:

```bash
chmod +x timeline.sh
