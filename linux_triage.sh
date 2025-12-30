#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =========================
# Linux Forensic Triage
# Live Response Collection
# 2025 Raul Renales
# =========================

VERSION="1.2"
UMASK_ORIG="$(umask)"
umask 077

# ---- Defaults ----
OUT_BASE="${OUT_BASE:-/tmp}"
CASE_ID="${CASE_ID:-CASE_$(date -u +%Y%m%dT%H%M%SZ)}"
HOST="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${OUTDIR:-${OUT_BASE}/triage_${HOST}_${CASE_ID}_${TS}}"
TAR_OUT="${TAR_OUT:-${OUTDIR}.tar.gz}"

# Optional: enable more expensive checks/finds
DEEP="${DEEP:-0}"          # 0/1
MAX_FIND_MINUTES="${MAX_FIND_MINUTES:-1440}"  # files modified within X minutes (default 24h)

# ---- Tools preference ----
CMD_DATE="$(command -v date || true)"
CMD_UNAME="$(command -v uname || true)"
CMD_SHA256="$(command -v sha256sum || true)"
CMD_TAR="$(command -v tar || true)"
CMD_FIND="$(command -v find || true)"
CMD_STAT="$(command -v stat || true)"
CMD_PS="$(command -v ps || true)"
CMD_SS="$(command -v ss || true)"
CMD_NETSTAT="$(command -v netstat || true)"
CMD_IP="$(command -v ip || true)"
CMD_IFCONFIG="$(command -v ifconfig || true)"
CMD_LSOF="$(command -v lsof || true)"
CMD_SYSTEMCTL="$(command -v systemctl || true)"
CMD_JOURNALCTL="$(command -v journalctl || true)"
CMD_DMIDECODE="$(command -v dmidecode || true)"
CMD_LSBLK="$(command -v lsblk || true)"
CMD_BLKID="$(command -v blkid || true)"
CMD_DF="$(command -v df || true)"
CMD_MOUNT="$(command -v mount || true)"
CMD_FREE="$(command -v free || true)"
CMD_UPTIME="$(command -v uptime || true)"
CMD_WHO="$(command -v who || true)"
CMD_LAST="$(command -v last || true)"
CMD_CRONTAB="$(command -v crontab || true)"
CMD_GETENT="$(command -v getent || true)"
CMD_SUDO="$(command -v sudo || true)"
CMD_AA_STATUS="$(command -v aa-status || true)"
CMD_SESTATUS="$(command -v sestatus || true)"
CMD_AUDITCTL="$(command -v auditctl || true)"

LOGFILE=""
ERRFILE=""

# ---- Helpers ----
usage() {
  cat <<EOF
Usage: sudo bash $0 [options]

Options:
  -o, --outdir DIR      Output directory (default: ${OUTDIR})
  -c, --case-id ID      Case identifier (default: ${CASE_ID})
  -d, --deep            Enable deeper/expensive checks (default: ${DEEP})
  --minutes N           "Recent changes" window in minutes (default: ${MAX_FIND_MINUTES})
  -h, --help            Show help

Environment variables:
  OUT_BASE, OUTDIR, CASE_ID, DEEP, MAX_FIND_MINUTES, TAR_OUT
EOF
}

log()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOGFILE" >/dev/null; }
warn()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARNING: $*" | tee -a "$LOGFILE" >/dev/null; }
err()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" | tee -a "$LOGFILE" >/dev/null; }

run_cmd() {
  # run_cmd "label" "command..."
  local label="$1"; shift
  local out="$1"; shift
  {
    echo "### ${label}"
    echo "### CMD: $*"
    echo "### UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    "$@"
    echo
  } >"$out" 2>>"$ERRFILE" || {
    warn "Command failed for: ${label} -> $*"
    return 0
  }
}

safe_copy() {
  # safe_copy SRC DSTDIR
  local src="$1"
  local dstdir="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$dstdir"
    cp -a --preserve=all "$src" "$dstdir"/ 2>>"$ERRFILE" || warn "Failed to copy $src"
  fi
}

hash_file() {
  local f="$1"
  if [[ -n "$CMD_SHA256" && -f "$f" ]]; then
    sha256sum "$f"
  fi
}

hash_tree() {
  local base="$1"
  local manifest="$2"
  if [[ -z "$CMD_SHA256" ]]; then
    warn "sha256sum not found; skipping hashes"
    return 0
  fi
  ( cd "$base" && find . -type f -print0 | sort -z | xargs -0 sha256sum ) >"$manifest" 2>>"$ERRFILE" || warn "Hashing failed"
}

require_root_or_warn() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    warn "Not running as root. Some artifacts may be inaccessible."
  fi
}

mkdir_layout() {
  mkdir -p "$OUTDIR"/{meta,system,network,process,users,persistence,logs,files,search,ioc,hashes}
  LOGFILE="$OUTDIR/meta/triage.log"
  ERRFILE="$OUTDIR/meta/stderr.log"
  : >"$LOGFILE"
  : >"$ERRFILE"
}

write_metadata() {
  {
    echo "Linux Forensic Triage - Live Response"
    echo "Version: $VERSION"
    echo "Case ID: $CASE_ID"
    echo "Host: $HOST"
    echo "UTC Start: $TS"
    echo "EUID: ${EUID:-$(id -u)}"
    echo "User: $(id 2>/dev/null || true)"
    echo "Kernel: $(uname -a 2>/dev/null || true)"
    echo "OUTDIR: $OUTDIR"
    echo "DEEP: $DEEP"
    echo "Recent changes window (minutes): $MAX_FIND_MINUTES"
  } >"$OUTDIR/meta/metadata.txt"
}

# ---- Argument parsing ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--outdir) OUTDIR="$2"; shift 2 ;;
    -c|--case-id) CASE_ID="$2"; shift 2 ;;
    -d|--deep) DEEP=1; shift ;;
    --minutes) MAX_FIND_MINUTES="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

mkdir_layout
write_metadata
require_root_or_warn

log "Starting triage. OUTDIR=$OUTDIR"

# =========================
# 1) System information
# =========================
run_cmd "Time / Uptime"            "$OUTDIR/system/time_uptime.txt"        bash -lc '
  date -u; echo; uptime 2>/dev/null || true; echo; who -a 2>/dev/null || true
'
run_cmd "Kernel / OS Release"      "$OUTDIR/system/os_kernel.txt"          bash -lc '
  uname -a 2>/dev/null || true
  echo
  cat /etc/os-release 2>/dev/null || true
  echo
  cat /etc/issue 2>/dev/null || true
'
run_cmd "Hardware / CPU / Memory"  "$OUTDIR/system/hw_cpu_mem.txt"         bash -lc '
  lscpu 2>/dev/null || true
  echo
  cat /proc/cpuinfo 2>/dev/null | head -n 200 || true
  echo
  free -h 2>/dev/null || true
  echo
  cat /proc/meminfo 2>/dev/null | head -n 200 || true
'
run_cmd "Disks / Mounts / FS"      "$OUTDIR/system/storage_mounts.txt"     bash -lc '
  lsblk -a 2>/dev/null || true
  echo
  blkid 2>/dev/null || true
  echo
  df -hT 2>/dev/null || true
  echo
  mount 2>/dev/null || true
  echo
  cat /etc/fstab 2>/dev/null || true
'
run_cmd "Loaded modules"           "$OUTDIR/system/modules.txt"            bash -lc '
  lsmod 2>/dev/null || true
  echo
  cat /proc/modules 2>/dev/null || true
'
run_cmd "Kernel cmdline"           "$OUTDIR/system/cmdline.txt"            bash -lc '
  cat /proc/cmdline 2>/dev/null || true
  echo
  sysctl -a 2>/dev/null | head -n 500 || true
'

# Security posture
run_cmd "Security controls (SELinux/AppArmor/audit)" "$OUTDIR/system/security_controls.txt" bash -lc '
  sestatus 2>/dev/null || true
  echo
  aa-status 2>/dev/null || true
  echo
  auditctl -s 2>/dev/null || true
  echo
  auditctl -l 2>/dev/null || true
'

# =========================
# 2) Users / auth / sessions
# =========================
run_cmd "Users and groups"         "$OUTDIR/users/users_groups.txt"        bash -lc '
  getent passwd 2>/dev/null || true
  echo
  getent group 2>/dev/null || true
  echo
  cat /etc/sudoers 2>/dev/null || true
  echo
  ls -la /etc/sudoers.d 2>/dev/null || true
  echo
  for f in /etc/sudoers.d/*; do [ -f "$f" ] && { echo "--- $f"; cat "$f"; echo; }; done 2>/dev/null || true
'
run_cmd "Login history (last)"     "$OUTDIR/users/login_history.txt"       bash -lc '
  last -Faiw 2>/dev/null | head -n 2000 || true
  echo
  lastb -Faiw 2>/dev/null | head -n 500 || true
'

# =========================
# 3) Processes / runtime
# =========================
run_cmd "Process list"             "$OUTDIR/process/ps_full.txt"           bash -lc '
  ps auxww 2>/dev/null || true
  echo
  ps -eo pid,ppid,user,group,lstart,etime,stat,pcpu,pmem,cmd --sort=-pcpu 2>/dev/null | head -n 300 || true
'
run_cmd "Process tree"             "$OUTDIR/process/pstree.txt"            bash -lc '
  pstree -a 2>/dev/null || true
'
run_cmd "Open files (lsof)"        "$OUTDIR/process/lsof.txt"              bash -lc '
  lsof -nP 2>/dev/null || true
'
run_cmd "/proc quick triage"       "$OUTDIR/process/proc_overview.txt"     bash -lc '
  echo "cmdline for top 50 pids by cpu:"
  ps -eo pid --sort=-pcpu | head -n 51 | tail -n 50 | while read -r p; do
    [ -r "/proc/$p/cmdline" ] && { echo "PID $p: $(tr "\0" " " </proc/$p/cmdline)"; }
  done 2>/dev/null || true
'

# =========================
# 4) Network
# =========================
run_cmd "Network interfaces / routes" "$OUTDIR/network/interfaces_routes.txt" bash -lc '
  ip addr 2>/dev/null || ifconfig -a 2>/dev/null || true
  echo
  ip route 2>/dev/null || route -n 2>/dev/null || true
  echo
  ip neigh 2>/dev/null || arp -an 2>/dev/null || true
'
run_cmd "DNS / resolv / hosts"     "$OUTDIR/network/dns_hosts.txt"         bash -lc '
  cat /etc/resolv.conf 2>/dev/null || true
  echo
  cat /etc/hosts 2>/dev/null || true
  echo
  cat /etc/nsswitch.conf 2>/dev/null || true
'
run_cmd "Listening and connections" "$OUTDIR/network/connections.txt"      bash -lc '
  ss -aonp 2>/dev/null || netstat -anp 2>/dev/null || true
'
run_cmd "Firewall"                "$OUTDIR/network/firewall.txt"           bash -lc '
  iptables -S 2>/dev/null || true
  echo
  iptables -L -n -v 2>/dev/null || true
  echo
  nft list ruleset 2>/dev/null || true
  echo
  ufw status verbose 2>/dev/null || true
  echo
  firewall-cmd --list-all 2>/dev/null || true
'

# =========================
# 5) Persistence
# =========================
run_cmd "Systemd units / timers"   "$OUTDIR/persistence/systemd.txt"       bash -lc '
  systemctl list-unit-files --no-pager 2>/dev/null || true
  echo
  systemctl list-units --all --no-pager 2>/dev/null || true
  echo
  systemctl list-timers --all --no-pager 2>/dev/null || true
'
run_cmd "Cron and at"              "$OUTDIR/persistence/cron_at.txt"       bash -lc '
  ls -la /etc/cron* 2>/dev/null || true
  echo
  for f in /etc/crontab /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.weekly/* /etc/cron.monthly/*; do
    [ -f "$f" ] && { echo "--- $f"; sed -n "1,200p" "$f"; echo; }
  done 2>/dev/null || true
  echo
  atq 2>/dev/null || true
'
run_cmd "Init scripts / rc"        "$OUTDIR/persistence/init_rc.txt"       bash -lc '
  ls -la /etc/init.d 2>/dev/null || true
  echo
  ls -la /etc/rc*.d 2>/dev/null || true
'
run_cmd "Kernel module persistence" "$OUTDIR/persistence/modules_conf.txt" bash -lc '
  cat /etc/modules 2>/dev/null || true
  echo
  ls -la /etc/modules-load.d 2>/dev/null || true
  echo
  for f in /etc/modules-load.d/*; do [ -f "$f" ] && { echo "--- $f"; cat "$f"; echo; }; done 2>/dev/null || true
'
run_cmd "SSH config"               "$OUTDIR/persistence/ssh.txt"           bash -lc '
  ls -la /etc/ssh 2>/dev/null || true
  echo
  sed -n "1,240p" /etc/ssh/sshd_config 2>/dev/null || true
  echo
  sed -n "1,240p" /etc/ssh/ssh_config 2>/dev/null || true
'

# =========================
# 6) Logs
# =========================
# Copy key logs (best-effort)
safe_copy "/var/log/auth.log"         "$OUTDIR/logs"
safe_copy "/var/log/secure"           "$OUTDIR/logs"
safe_copy "/var/log/syslog"           "$OUTDIR/logs"
safe_copy "/var/log/messages"         "$OUTDIR/logs"
safe_copy "/var/log/kern.log"         "$OUTDIR/logs"
safe_copy "/var/log/audit"            "$OUTDIR/logs"
safe_copy "/var/log/wtmp"             "$OUTDIR/logs"
safe_copy "/var/log/btmp"             "$OUTDIR/logs"
safe_copy "/var/log/lastlog"          "$OUTDIR/logs"

run_cmd "Journald (last 24h)"      "$OUTDIR/logs/journal_last24h.txt"    bash -lc '
  journalctl --utc --since "24 hours ago" --no-pager 2>/dev/null || true
'

# =========================
# 7) Critical files snapshots
# =========================
# /etc (config baseline)
mkdir -p "$OUTDIR/files/etc"
cp -a --preserve=all /etc/* "$OUTDIR/files/etc/" 2>>"$ERRFILE" || warn "Copy /etc partial"

# User SSH keys
mkdir -p "$OUTDIR/files/user_ssh"
for d in /home/* /root; do
  [[ -d "$d/.ssh" ]] && cp -a --preserve=all "$d/.ssh" "$OUTDIR/files/user_ssh/$(basename "$d")_ssh" 2>>"$ERRFILE" || true
done

# Temp areas (metadata only unless DEEP=1)
run_cmd "Tmp listings" "$OUTDIR/files/tmp_listings.txt" bash -lc '
  ls -la /tmp 2>/dev/null || true
  echo
  ls -la /var/tmp 2>/dev/null || true
  echo
  ls -la /dev/shm 2>/dev/null || true
'
if [[ "$DEEP" -eq 1 ]]; then
  mkdir -p "$OUTDIR/files/tmp_snapshots"
  cp -a --preserve=all /tmp "$OUTDIR/files/tmp_snapshots/" 2>>"$ERRFILE" || warn "Copy /tmp partial"
  cp -a --preserve=all /var/tmp "$OUTDIR/files/tmp_snapshots/" 2>>"$ERRFILE" || warn "Copy /var/tmp partial"
  cp -a --preserve=all /dev/shm "$OUTDIR/files/tmp_snapshots/" 2>>"$ERRFILE" || warn "Copy /dev/shm partial"
fi

# =========================
# 8) Searches / quick IOC hunting
# =========================
# Recent file changes window
run_cmd "Recently modified files (time window)" "$OUTDIR/search/recent_changes.txt" bash -lc "
  echo \"Window: last ${MAX_FIND_MINUTES} minutes\"
  for p in /etc /usr/bin /usr/sbin /bin /sbin /var /home; do
    [ -d \"\$p\" ] || continue
    echo
    echo \"## \$p\"
    find \"\$p\" -xdev -type f -mmin -${MAX_FIND_MINUTES} -printf '%TY-%Tm-%Td %TT %u:%g %m %s %p\n' 2>/dev/null | head -n 2000
  done
"

# SUID/SGID binaries
run_cmd "SUID/SGID binaries" "$OUTDIR/search/suid_sgid.txt" bash -lc '
  for p in / /usr /bin /sbin /usr/bin /usr/sbin; do
    [ -d "$p" ] || continue
    echo "## $p"
    find "$p" -xdev -type f \( -perm -4000 -o -perm -2000 \) -printf "%m %u:%g %s %p\n" 2>/dev/null
    echo
  done
'

# World-writable executable files (common red flag)
run_cmd "World-writable executables" "$OUTDIR/search/world_writable_exec.txt" bash -lc '
  for p in / /usr /bin /sbin /usr/bin /usr/sbin /var /tmp /dev/shm; do
    [ -d "$p" ] || continue
    echo "## $p"
    find "$p" -xdev -type f -perm -0002 -executable -printf "%m %u:%g %s %p\n" 2>/dev/null | head -n 2000
    echo
  done
'

# Hidden files in key dirs (limited)
run_cmd "Hidden files in key dirs" "$OUTDIR/search/hidden_files.txt" bash -lc '
  for p in /etc /var /home /root /tmp; do
    [ -d "$p" ] || continue
    echo "## $p"
    find "$p" -xdev -maxdepth 3 -name ".*" -printf "%TY-%Tm-%Td %TT %u:%g %m %s %p\n" 2>/dev/null | head -n 2000
    echo
  done
'

# Suspicious names (basic)
run_cmd "Basic suspicious filename patterns" "$OUTDIR/search/suspicious_names.txt" bash -lc '
  patterns="(\\.so\\.|\\.tmp$|\\.dat$|/\\.[^/]+/|/\\.cache/|/\\.config/|\\.service$|\\.timer$)"
  find / -xdev -type f 2>/dev/null | grep -E "$patterns" | head -n 3000 || true
'

# Optional deeper: hash common binary dirs to help detect tampering (heavy)
if [[ "$DEEP" -eq 1 ]]; then
  if [[ -n "$CMD_SHA256" ]]; then
    run_cmd "Hash core binaries (can be slow)" "$OUTDIR/ioc/core_binaries_hashes.txt" bash -lc '
      for p in /bin /sbin /usr/bin /usr/sbin; do
        [ -d "$p" ] || continue
        echo "## $p"
        find "$p" -xdev -type f -maxdepth 1 -print0 2>/dev/null | sort -z | xargs -0 sha256sum 2>/dev/null || true
        echo
      done
    '
  fi
fi

# =========================
# 9) Manifests and hashing
# =========================
log "Hashing collected artifacts"
hash_tree "$OUTDIR" "$OUTDIR/hashes/sha256_manifest.txt" || true

# Top-level metadata hashes
{
  echo "### Top-level file hashes (sha256)"
  [[ -n "$CMD_SHA256" ]] && sha256sum "$OUTDIR/meta/metadata.txt" "$OUTDIR/meta/triage.log" "$OUTDIR/meta/stderr.log" 2>/dev/null || true
} >"$OUTDIR/hashes/top_level_hashes.txt" 2>>"$ERRFILE" || true

# =========================
# 10) Package results
# =========================
log "Packaging results to $TAR_OUT"
if [[ -n "$CMD_TAR" ]]; then
  ( cd "$(dirname "$OUTDIR")" && tar -czf "$TAR_OUT" "$(basename "$OUTDIR")" ) 2>>"$ERRFILE" || warn "tar packaging failed"
  if [[ -n "$CMD_SHA256" && -f "$TAR_OUT" ]]; then
    sha256sum "$TAR_OUT" > "${TAR_OUT}.sha256" 2>>"$ERRFILE" || true
  fi
else
  warn "tar not found; skipping archive"
fi

log "Completed triage."
log "Output directory: $OUTDIR"
[[ -f "$TAR_OUT" ]] && log "Archive: $TAR_OUT"
[[ -f "${TAR_OUT}.sha256" ]] && log "Archive hash: ${TAR_OUT}.sha256"

umask "$UMASK_ORIG"
exit 0
