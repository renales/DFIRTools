#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =========================
# DFIR Timeline Generator
# Raul Renales Agüero
# =========================

VERSION="1.0"

# ---- Configuración ----
BASE_PATH="${1:-/}"
OUTDIR="${OUTDIR:-./timeline_output}"
CASE_ID="${CASE_ID:-CASE_$(date -u +%Y%m%dT%H%M%SZ)}"
UTC_NOW="$(date -u +%Y%m%dT%H%M%SZ)"

MAX_DAYS="${MAX_DAYS:-7}"     # ficheros modificados en los últimos X días
MAX_DEPTH="${MAX_DEPTH:-6}"  # profundidad máxima en búsquedas

# ---- Preparación ----
mkdir -p "$OUTDIR"
OUTFILE="$OUTDIR/timeline_${CASE_ID}_${UTC_NOW}.csv"
LOGFILE="$OUTDIR/timeline.log"

echo "timestamp_utc,type,source,details" > "$OUTFILE"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOGFILE" >/dev/null
}

log "Starting timeline generation"
log "Base path: $BASE_PATH"
log "Days window: $MAX_DAYS"

# =========================
# Helper functions
# =========================

file_timeline() {
  local path="$1"
  log "File timeline: $path"

  find "$path" -xdev -maxdepth "$MAX_DEPTH" -type f \
    -mtime "-$MAX_DAYS" 2>/dev/null |
  while read -r f; do
    stat --printf '%y,FILE,%n,modified\n' "$f" 2>/dev/null || true
    stat --printf '%x,FILE,%n,accessed\n' "$f" 2>/dev/null || true
    stat --printf '%z,FILE,%n,changed\n'  "$f" 2>/dev/null || true
  done >> "$OUTFILE"
}

log_timeline() {
  local file="$1"
  local label="$2"

  [[ -f "$file" ]] || return 0
  log "Log timeline: $file"

  awk -v SRC="$label" '
  {
    if ($0 ~ /^[A-Z][a-z]{2} [ 0-9][0-9] [0-9:]{8}/) {
      cmd="date -u -d \""$1" "$2" "$3"\" +%Y-%m-%dT%H:%M:%SZ"
      cmd | getline ts
      close(cmd)
      printf "%s,LOG,%s,%s\n", ts, SRC, $0
    }
  }' "$file" >> "$OUTFILE" 2>/dev/null || true
}

journal_timeline() {
  if command -v journalctl >/dev/null; then
    log "Journalctl timeline"
    journalctl --since "$MAX_DAYS days ago" --utc --no-pager |
    while read -r line; do
      ts=$(echo "$line" | awk '{print $1}')
      echo "$ts,LOG,journalctl,$line"
    done >> "$OUTFILE" || true
  fi
}

process_timeline() {
  log "Process timeline"

  ps -eo lstart,pid,ppid,user,cmd --no-headers |
  while read -r lstart pid ppid user rest; do
    ts=$(date -u -d "$lstart" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
    [[ -n "$ts" ]] && echo "$ts,PROCESS,PID=$pid,$user $rest"
  done >> "$OUTFILE"
}

login_timeline() {
  log "Login timeline"

  last -Faiw 2>/dev/null |
  while read -r line; do
    ts=$(echo "$line" | awk '{print $(NF-6),$(NF-5),$(NF-4)}')
    tsu=$(date -u -d "$ts" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
    [[ -n "$tsu" ]] && echo "$tsu,AUTH,last,$line"
  done >> "$OUTFILE"
}

# =========================
# Timeline sources
# =========================

# File system (zonas críticas)
for p in /etc /var/log /home /root /tmp /dev/shm; do
  [[ -d "$p" ]] && file_timeline "$p"
done

# Logs clásicos
log_timeline /var/log/auth.log auth.log
log_timeline /var/log/secure secure
log_timeline /var/log/syslog syslog
log_timeline /var/log/messages messages

# Journald
journal_timeline

# Procesos
process_timeline

# Logins
login_timeline

# =========================
# Normalización
# =========================
log "Sorting timeline"
sort -u "$OUTFILE" -o "$OUTFILE"

log "Timeline completed"
log "Output: $OUTFILE"

exit 0
