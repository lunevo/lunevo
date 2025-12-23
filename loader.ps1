# Lunevo Fileless Loader
# Lädt und startet das Bypass-Menü vollständig fileless (keine Dateien auf Festplatte)

# Anti-Detection: Random Delay
$delay = Get-Random -Minimum 1 -Maximum 3
Start-Sleep -Seconds $delay

# Prüfe ob AnyDesk läuft (Blockade - kein Start wenn AnyDesk aktiv)
$anydeskRunning = Get-Process -Name "anydesk" -ErrorAction SilentlyContinue
if ($anydeskRunning) {
    exit
}

# Prüfe ob Bypass bereits läuft (verhindert mehrfaches Starten) - MEHRFACHE PRÜFUNG
$bypassRunning = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
if ($bypassRunning) {
    # Warte kurz und prüfe erneut (falls Prozess gerade startet)
    Start-Sleep -Milliseconds 500
    $bypassRunning2 = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
    if ($bypassRunning2) {
        exit
    }
}

# Lock-Datei prüfen (zusätzliche Sicherheit)
$lockFile = "$env:TEMP\Lunevo\bypass_lock.tmp"
if (Test-Path $lockFile) {
    $lockTime = (Get-Item $lockFile).LastWriteTime
    $lockAge = (Get-Date) - $lockTime
    if ($lockAge.TotalSeconds -lt 10) {
        # Lock ist sehr neu - warte kurz
        Start-Sleep -Seconds 2
        $bypassCheck = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
        if ($bypassCheck) {
            exit
        }
    }
}

# Download Bypass EXE von GitHub direkt in Memory (fileless)
$exeUrl = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.exe"

try {
    # Lade EXE direkt in Memory (keine Festplatte)
    $exeBytes = (Invoke-WebRequest -Uri $exeUrl -UseBasicParsing -ErrorAction Stop).Content
    
    # Konvertiere zu Byte-Array falls nötig
    if ($exeBytes -is [string]) {
        $exeBytes = [System.Text.Encoding]::Default.GetBytes($exeBytes)
    }
    
    # Fileless Execution: Schreibe in sehr versteckten temporären Ort und lösche sofort
    $tempDir = "$env:TEMP\Lunevo"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    # Zufälliger Dateiname (schwer zu finden)
    $randomName = [System.Guid]::NewGuid().ToString() + ".exe"
    $tempPath = Join-Path $tempDir $randomName
    
    try {
        # Konvertiere zu Byte-Array falls nötig
        if ($exeBytes -is [string]) {
            $exeBytes = [System.Text.Encoding]::Default.GetBytes($exeBytes)
        }
        
        # Schreibe EXE in temporären Speicher
        [System.IO.File]::WriteAllBytes($tempPath, $exeBytes)
        
        # Erneute Prüfung vor Start (verhindert doppeltes Starten)
        $bypassFinalCheck = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
        if ($bypassFinalCheck) {
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            exit
        }
        
        # Starte Prozess (GUI sichtbar)
        $proc = Start-Process -FilePath $tempPath -PassThru
        
        # Warte kurz und prüfe ob Prozess wirklich gestartet wurde
        if ($proc) {
            Start-Sleep -Milliseconds 500
            $bypassVerify = Get-Process -Name "bypass" -ErrorAction SilentlyContinue
            if ($bypassVerify) {
                # Prozess läuft - lösche temporäre Datei
                Start-Sleep -Milliseconds 100
                try {
                    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                } catch {
                    # Falls gelockt: Lösche später im Cleanup
                }
            } else {
                # Prozess startete nicht - lösche Datei
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        # Silent fail
    }
    
} catch {
    # Fallback: Base64 Payload (falls EXE als Base64 verfügbar)
    try {
        $base64Url = "https://raw.githubusercontent.com/lunevo/lunevo/main/bypass.b64"
        $base64 = (Invoke-WebRequest -Uri $base64Url -UseBasicParsing -ErrorAction Stop).Content.Trim()
        $bytes = [Convert]::FromBase64String($base64)
        
        # Versuche als .NET Assembly (falls es eine .NET EXE ist)
        try {
            $assembly = [System.Reflection.Assembly]::Load($bytes)
            $entryPoint = $assembly.EntryPoint
            if ($entryPoint) {
                $entryPoint.Invoke($null, @())
            }
        } catch {
            # Nicht .NET - verwende temporäre Datei-Methode
            $tempDir = "$env:TEMP\Lunevo"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            }
            $randomName = [System.Guid]::NewGuid().ToString() + ".exe"
            $tempPath = Join-Path $tempDir $randomName
            try {
                [System.IO.File]::WriteAllBytes($tempPath, $bytes)
                $proc = Start-Process -FilePath $tempPath -PassThru
                if ($proc) {
                    Start-Sleep -Milliseconds 150
                    Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                }
            } catch {}
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
    Get-ChildItem -Path "$env:TEMP" -Filter "*.ps1" -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } | 
        Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
    
    # Lösche temporäre EXE-Dateien (falls welche erstellt wurden)
    Get-ChildItem -Path "$env:TEMP\Lunevo" -Filter "*.exe" -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-1) } | 
        Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
} catch {
    # Silent
}
