# Linux Forensic Triage
**DFIR Live Response Script – Usage Guide**



## Descripción

`linux_triage.sh` es un **script de triaje forense para sistemas Linux** diseñado para **respuestas rápidas ante incidentes de seguridad**.  
Permite recoger evidencia relevante en sistemas en funcionamiento (*live response*), de forma **estructurada, trazable y con control de integridad**.

Este script está pensado como **primera acción DFIR**, no como sustituto de un análisis forense completo.



## Objetivos del triaje

- Obtener una **visión rápida del estado del sistema**
- Identificar **indicadores tempranos de compromiso (IOCs)**
- Preservar evidencia para análisis posterior
- Facilitar decisiones rápidas en fases iniciales del incidente



## Requisitos

- Sistema Linux (probado en Debian/Ubuntu/RHEL/Rocky/Alma)
- Shell: `bash`
- Ejecución recomendada como **root**
- Utilidades estándar del sistema (`ps`, `ip`, `ss`, `find`, `tar`, etc.)

> No requiere instalación de dependencias externas.



## Advertencia importante

**La ejecución en vivo modifica el sistema** (lecturas, procesos, accesos a disco).  
Esto es inherente al *live response* y debe documentarse correctamente.



## Instalación

Clona el repositorio o copia el script:

```bash
git clone https://github.com/<usuario>/dfir-linux-toolkit.git
cd dfir-linux-toolkit/triage
chmod +x linux_triage.sh
