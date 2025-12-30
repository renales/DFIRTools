DFIR Linux Toolkit

Digital Forensics & Incident Response – Live Triage Tools

Descripción

Este repositorio contiene un conjunto de herramientas DFIR para Linux, centradas en triaje forense, live response y respuesta inicial a incidentes.
El objetivo es recoger evidencia relevante de forma rápida, estructurada y con garantías de integridad, minimizando el impacto sobre el sistema analizado.

Las herramientas están diseñadas para:

Analistas DFIR

Equipos SOC / CSIRT

Respuesta a incidentes en producción

Formación avanzada en ciberseguridad y forense digital

Principios de diseño

Las herramientas de este repositorio siguen los siguientes principios:

Live Response consciente
Se asume ejecución en sistemas en funcionamiento (no dead-box).

Minimización de huella
Uso de comandos estándar del sistema, sin dependencias externas innecesarias.

Trazabilidad y custodia

Timestamps en UTC

Logs de ejecución

Hashes criptográficos (SHA-256)

Manifiestos de integridad

Compatibilidad amplia
Funciona en la mayoría de distribuciones Linux modernas (Debian, Ubuntu, RHEL, Rocky, Alma, SUSE).

Orientación operativa
Pensado para escenarios reales de intrusión, malware, insider threat y hardening post-incidente.

Contenido del repositorio
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
│   ├── chain_of_custody.md      # Custodia y evidencias
│   └── legal_notes.md           # Consideraciones legales
│
├── LICENSE
└── README.md


El núcleo del repositorio es el script de triaje forense en Linux, pensado como primera acción tras la detección de un incidente.

Herramienta principal: Linux Forensic Triage
¿Qué recoge?

Información del sistema y kernel

Usuarios, sesiones, sudoers

Procesos, árbol de procesos y ficheros abiertos

Red: interfaces, rutas, conexiones, firewall

Persistencia: systemd, cron, init, módulos

Logs críticos (auth, syslog, journal)

Snapshots de configuración (/etc, SSH)

Búsquedas rápidas de IOCs:

SUID/SGID

Ficheros recientes

Ejecutables world-writable

Ficheros ocultos sospechosos

Salida

Directorio estructurado por categorías

Logs de ejecución

Manifiesto SHA-256 de todos los artefactos

Archivo final .tar.gz + hash

Uso básico
chmod +x linux_triage.sh
sudo CASE_ID="INC-2025-001" ./linux_triage.sh


Opciones avanzadas:

sudo DEEP=1 MAX_FIND_MINUTES=720 ./linux_triage.sh


Se recomienda ejecutar como root y, siempre que sea posible, escribir la salida en un medio externo montado con noexec,nosuid,nodev.

Metodología DFIR aplicada

Este toolkit sigue una aproximación alineada con:

Identification
Confirmación del incidente y alcance inicial.

Collection (Live)
Recogida de evidencia volátil y semivolátil.

Preservation
Hashes, logs y empaquetado para custodia.

Triage & Scoping
Identificación rápida de indicadores de compromiso.

No sustituye un análisis forense completo, pero optimiza las primeras horas críticas de un incidente.

Limitaciones conocidas

Ejecutar cualquier herramienta en vivo modifica el sistema (inevitable).

No incluye volcado de memoria por defecto.

El triaje no reemplaza:

Análisis de imagen forense

Reverse engineering de malware

Threat hunting profundo

Buenas prácticas recomendadas

Documentar quién, cuándo y por qué se ejecuta la herramienta.

Registrar hashes del script antes de su uso.

Usar relojes sincronizados (NTP).

Preservar la salida original sin modificaciones.

Licencia

Este proyecto se distribuye bajo licencia MIT (o la que definas).
Consulta el archivo LICENSE para más detalles.

Aviso legal

Estas herramientas se proporcionan tal cual, sin garantía.
El autor no se hace responsable del uso indebido o ilegal del software.
Úsese únicamente en sistemas sobre los que se tenga autorización expresa.

Contribuciones

Las contribuciones son bienvenidas:

Mejoras técnicas

Nuevos módulos DFIR

Compatibilidad con más distribuciones

Documentación y casos de uso
