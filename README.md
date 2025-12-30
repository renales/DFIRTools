# DFIR Linux Toolkit
**Digital Forensics & Incident Response – Live Triage Tools**



## Descripción

Este repositorio contiene un **conjunto de herramientas DFIR para Linux**, centradas en **triaje forense, live response y respuesta inicial a incidentes**.  
El objetivo es **recoger evidencia relevante de forma rápida, estructurada y con garantías de integridad**, minimizando el impacto sobre el sistema analizado.

Está orientado a:
- Analistas DFIR
- Equipos SOC / CSIRT
- Respuesta a incidentes en entornos productivos
- Formación avanzada en forense digital y ciberseguridad


## Principios de diseño

Las herramientas de este repositorio siguen estos principios:

- **Live Response consciente**  
  Pensado para ejecución en sistemas en funcionamiento (no dead-box).

- **Minimización de huella**  
  Uso de utilidades estándar del sistema, sin dependencias externas innecesarias.

- **Trazabilidad y custodia**  
  - Timestamps en UTC  
  - Logs de ejecución  
  - Hashes criptográficos (SHA-256)  
  - Manifiestos de integridad  

- **Compatibilidad amplia**  
  Funciona en la mayoría de distribuciones Linux modernas:
  Debian, Ubuntu, RHEL, Rocky, Alma, SUSE.

- **Orientación operativa**  
  Diseñado para escenarios reales: intrusión, malware, insider threat y hardening post-incidente.



## Estructura del repositorio

```text
.
├── triage/
│   ├── linux_triage.sh          # Script principal de triaje forense
│   └── README_triage.md         # Detalle técnico del triaje
│
├── ioc/
│   ├── yara/                    # Reglas YARA (opcional)
│   ├── hashes/                  # Hashes conocidos (malware / tools)
│   └── patterns/                # Patrones de búsqueda
│
├── utils/
│   ├── timeline.sh              # Generación de timelines básicos
│   ├── hash_verify.sh           # Verificación de integridad
│   └── mount_safe.sh            # Montajes forenses seguros
│
├── docs/
│   ├── methodology.md           # Metodología DFIR aplicada
│   ├── chain_of_custody.md      # Custodia de evidencias
│   └── legal_notes.md           # Consideraciones legales
│
├── LICENSE
└── README.md
