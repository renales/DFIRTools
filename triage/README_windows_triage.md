# Windows Forensic Triage
**DFIR Live Response Script – Usage & Coverage**



## Descripción

`windows_triage.ps1` es un **script de triaje forense para sistemas Windows** diseñado para **respuestas rápidas ante incidentes de seguridad** en entornos corporativos y profesionales.

El script permite realizar **live response** sobre sistemas Windows en funcionamiento, recogiendo evidencia relevante de forma **estructurada, trazable y con control de integridad**, sin depender de herramientas externas.

Está pensado como **primera acción DFIR**, no como sustituto de un análisis forense completo.



## Objetivos del triaje

- Obtener una **visión rápida y fiable del sistema**
- Identificar **indicadores tempranos de compromiso (IOCs)**
- Preservar evidencia para análisis posterior
- Apoyar decisiones rápidas en fases iniciales del incidente



## Requisitos

- Windows 10 / 11 / Windows Server 2016 o superior
- PowerShell 5.1 o superior
- Ejecución como **Administrador**
- Espacio suficiente en disco (o medio externo)

> No requiere instalación de dependencias externas.



## Advertencia importante

⚠️ **La ejecución en vivo modifica el sistema** (lecturas, procesos, accesos a disco).  
Esto es inherente al *live response* y debe documentarse adecuadamente en la cadena de custodia.



## Instalación

Clona el repositorio o copia el script en el sistema objetivo:

```powershell
git clone https://github.com/<usuario>/dfir-linux-toolkit.git
cd dfir-linux-toolkit\triage
