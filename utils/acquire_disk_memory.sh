#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  cat <<'USAGE'
Uso:
  sudo ./acquire_disk_memory.sh --disk /dev/sdX --out /ruta/salida [--memory] [--lime-module /ruta/lime.ko]

Descripción:
  - Crea una copia bit a bit de un disco usando dd.
  - Opcionalmente intenta capturar memoria RAM usando LiME si se proporciona el módulo.

Parámetros:
  --disk         Dispositivo de bloque origen (ej: /dev/sda, /dev/nvme0n1)
  --out          Directorio de salida para almacenar la evidencia
  --memory       Habilita captura de memoria (requiere LiME)
  --lime-module  Ruta al módulo LiME (lime.ko) compatible con el kernel actual
  --help         Muestra esta ayuda

Ejemplo:
  sudo ./acquire_disk_memory.sh --disk /dev/sda --out /evidencias/caso123 --memory --lime-module /opt/lime/lime.ko
USAGE
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "[!] Este script debe ejecutarse como root." >&2
    exit 1
  fi
}

check_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[!] Falta el comando requerido: $1" >&2
    exit 1
  fi
}

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

DISK=""
OUT_DIR=""
CAPTURE_MEMORY="no"
LIME_MODULE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)
      DISK="$2"
      shift 2
      ;;
    --out)
      OUT_DIR="$2"
      shift 2
      ;;
    --memory)
      CAPTURE_MEMORY="yes"
      shift 1
      ;;
    --lime-module)
      LIME_MODULE="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "[!] Opción desconocida: $1" >&2
      usage
      exit 1
      ;;
  esac
 done

if [[ -z "$DISK" || -z "$OUT_DIR" ]]; then
  echo "[!] Debe indicar --disk y --out" >&2
  usage
  exit 1
fi

require_root
check_command dd
check_command sha256sum
check_command lsblk
check_command blockdev

if [[ ! -b "$DISK" ]]; then
  echo "[!] El dispositivo $DISK no existe o no es un bloque válido." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

TIMESTAMP="$(date -u +'%Y%m%dT%H%M%SZ')"
DISK_BASENAME="$(basename "$DISK")"
DISK_IMAGE="$OUT_DIR/${DISK_BASENAME}_${TIMESTAMP}.img"
DISK_LOG="$OUT_DIR/${DISK_BASENAME}_${TIMESTAMP}.log"
DISK_HASH="$OUT_DIR/${DISK_BASENAME}_${TIMESTAMP}.sha256"

log "Iniciando adquisición bit a bit del disco $DISK" | tee -a "$DISK_LOG"
log "Modelo/serial:" | tee -a "$DISK_LOG"
lsblk -o NAME,MODEL,SERIAL,SIZE,TYPE "$DISK" | tee -a "$DISK_LOG"
log "Tamaño en bytes:" | tee -a "$DISK_LOG"
blockdev --getsize64 "$DISK" | tee -a "$DISK_LOG"

log "Copiando con dd (esto puede tardar)..." | tee -a "$DISK_LOG"
if dd if="$DISK" of="$DISK_IMAGE" bs=4M conv=noerror,sync status=progress; then
  log "Copia completada." | tee -a "$DISK_LOG"
else
  log "[!] dd reportó un error." | tee -a "$DISK_LOG"
  exit 1
fi

log "Calculando hash SHA-256..." | tee -a "$DISK_LOG"
sha256sum "$DISK_IMAGE" | tee "$DISK_HASH" >> "$DISK_LOG"

if [[ "$CAPTURE_MEMORY" == "yes" ]]; then
  log "Captura de memoria habilitada." | tee -a "$DISK_LOG"

  if [[ -z "$LIME_MODULE" ]]; then
    log "[!] Debe proporcionar --lime-module para capturar memoria." | tee -a "$DISK_LOG"
    exit 1
  fi

  if [[ ! -f "$LIME_MODULE" ]]; then
    log "[!] No se encontró el módulo LiME en $LIME_MODULE." | tee -a "$DISK_LOG"
    exit 1
  fi

  check_command insmod
  check_command lsmod

  MEM_IMAGE="$OUT_DIR/mem_${TIMESTAMP}.lime"
  MEM_LOG="$OUT_DIR/mem_${TIMESTAMP}.log"
  MEM_HASH="$OUT_DIR/mem_${TIMESTAMP}.sha256"

  log "Cargando LiME y capturando memoria en $MEM_IMAGE" | tee -a "$MEM_LOG"
  insmod "$LIME_MODULE" "path=$MEM_IMAGE" "format=lime"

  sleep 2

  if lsmod | grep -q "^lime"; then
    log "Esperando a que finalice la captura de memoria..." | tee -a "$MEM_LOG"
  else
    log "[!] No se pudo cargar LiME." | tee -a "$MEM_LOG"
    exit 1
  fi

  while lsmod | grep -q "^lime"; do
    sleep 2
  done

  log "Captura de memoria completada." | tee -a "$MEM_LOG"
  log "Calculando hash SHA-256 de memoria..." | tee -a "$MEM_LOG"
  sha256sum "$MEM_IMAGE" | tee "$MEM_HASH" >> "$MEM_LOG"
fi

log "Proceso finalizado. Evidencias en: $OUT_DIR" | tee -a "$DISK_LOG"
