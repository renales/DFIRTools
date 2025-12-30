<#
 Windows Forensic Triage Script
 DFIR Live Response
 Author: Raul Renales
#>

# =========================
# Configuration
# =========================
$Version = "1.0"
$CaseID  = $env:CASE_ID
if (-not $CaseID) {
    $CaseID = "CASE_" + (Get-Date -Format "yyyyMMddTHHmmssZ")
}

$UTC     = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$HostN   = $env:COMPUTERNAME
$BaseOut = $env:OUT_BASE
if (-not $BaseOut) { $BaseOut = "C:\Windows\Temp" }

$OutDir  = "$BaseOut\triage_${HostN}_${CaseID}_${UTC}"

# =========================
# Helpers
# =========================
function New-Section($Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Write-Log($Msg) {
    $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    "$ts $Msg" | Tee-Object -FilePath "$OutDir\meta\triage.log" -Append
}

function Run-Cmd($Label, $Cmd, $OutFile) {
    Write-Log "Running: $Label"
    "### $Label" | Out-File $OutFile
    "### CMD: $Cmd" | Out-File $OutFile -Append
    "### UTC: $(Get-Date -AsUTC)" | Out-File $OutFile -Append
    Invoke-Expression $Cmd | Out-File $OutFile -Append 2>>"$OutDir\meta\stderr.log"
}

# =========================
# Directory layout
# =========================
New-Section $OutDir
"meta","system","users","process","network","persistence","logs","files","search","hashes" |
    ForEach-Object { New-Section "$OutDir\$_" }

# =========================
# Metadata
# =========================
@"
Windows Forensic Triage
Version: $Version
Case ID: $CaseID
Host: $HostN
UTC Start: $UTC
User: $env:USERNAME
Elevation: $(whoami /groups | Select-String "S-1-16-12288")
"@ | Out-File "$OutDir\meta\metadata.txt"

Write-Log "Starting Windows triage"

# =========================
# System information
# =========================
Run-Cmd "System info" "systeminfo" "$OutDir\system\systeminfo.txt"
Run-Cmd "OS version" "Get-ComputerInfo" "$OutDir\system\computerinfo.txt"
Run-Cmd "Installed hotfixes" "Get-HotFix" "$OutDir\system\hotfixes.txt"
Run-Cmd "Logical disks" "Get-Volume" "$OutDir\system\disks.txt"

# =========================
# Users and logons
# =========================
Run-Cmd "Local users" "Get-LocalUser" "$OutDir\users\local_users.txt"
Run-Cmd "Local groups" "Get-LocalGroup" "$OutDir\users\local_groups.txt"
Run-Cmd "Logged users" "quser" "$OutDir\users\logged_users.txt"
Run-Cmd "Last logons" "Get-WinEvent -LogName Security -MaxEvents 200" "$OutDir\users\security_logons.txt"

# =========================
# Processes
# =========================
Run-Cmd "Process list" "Get-Process | Sort CPU -Descending" "$OutDir\process\processes.txt"
Run-Cmd "Process with paths" "Get-CimInstance Win32_Process | Select Name,ProcessId,ParentProcessId,ExecutablePath,CommandLine" "$OutDir\process\process_paths.txt"
Run-Cmd "Services" "Get-Service" "$OutDir\process\services.txt"

# =========================
# Network
# =========================
Run-Cmd "IP config" "ipconfig /all" "$OutDir\network\ipconfig.txt"
Run-Cmd "Routes" "route print" "$OutDir\network\routes.txt"
Run-Cmd "Connections" "netstat -ano" "$OutDir\network\netstat.txt"
Run-Cmd "DNS cache" "ipconfig /displaydns" "$OutDir\network\dns_cache.txt"
Run-Cmd "Firewall rules" "netsh advfirewall firewall show rule name=all" "$OutDir\network\firewall_rules.txt"

# =========================
# Persistence
# =========================
Run-Cmd "Autoruns (registry)" "Get-CimInstance Win32_StartupCommand" "$OutDir\persistence\startup_registry.txt"
Run-Cmd "Scheduled tasks" "schtasks /query /fo LIST /v" "$OutDir\persistence\scheduled_tasks.txt"
Run-Cmd "Services auto-start" "Get-Service | Where StartType -eq 'Automatic'" "$OutDir\persistence\services_autostart.txt"

# =========================
# Registry snapshots
# =========================
reg save HKLM\Software "$OutDir\files\HKLM_Software.hiv" /y | Out-Null
reg save HKLM\System   "$OutDir\files\HKLM_System.hiv"   /y | Out-Null
reg save HKCU          "$OutDir\files\HKCU.hiv"          /y | Out-Null

# =========================
# Logs
# =========================
wevtutil epl System   "$OutDir\logs\System.evtx"
wevtutil epl Security "$OutDir\logs\Security.evtx"
wevtutil epl Application "$OutDir\logs\Application.evtx"

# =========================
# IOC hunting (basic)
# =========================
Run-Cmd "Recently modified files" `
"Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue |
 Where-Object { \$_.LastWriteTime -gt (Get-Date).AddDays(-1) } |
 Select FullName,LastWriteTime" `
"$OutDir\search\recent_files.txt"

Run-Cmd "Hidden executables" `
"Get-ChildItem C:\ -Recurse -Force -ErrorAction SilentlyContinue |
 Where-Object { \$_.Attributes -match 'Hidden' -and \$_.Extension -match 'exe|dll' } |
 Select FullName" `
"$OutDir\search\hidden_exec.txt"

# =========================
# Hashing
# =========================
Write-Log "Hashing collected artifacts"

Get-ChildItem $OutDir -Recurse -File | ForEach-Object {
    Get-FileHash $_.FullName -Algorithm SHA256 |
    Select Hash,Path
} | Out-File "$OutDir\hashes\sha256_manifest.txt"

# =========================
# Packaging
# =========================
$ZipFile = "$OutDir.zip"
Compress-Archive -Path $OutDir -DestinationPath $ZipFile -Force
Get-FileHash $ZipFile -Algorithm SHA256 |
    Out-File "$ZipFile.sha256"

Write-Log "Triage completed"
Write-Log "Output: $OutDir"
Write-Log "Archive: $ZipFile"
