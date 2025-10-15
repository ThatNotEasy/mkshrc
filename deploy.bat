@echo off
cls
setlocal EnableExtensions EnableDelayedExpansion

:: Check device connectivity
adb get-state 1>nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] No device detected. Please connect your device and enable USB debugging.
    exit /b 1
)

:: Get current ABI
for /f "usebackq delims=" %%A in (`adb shell getprop ro.product.cpu.abi`) do (
    set "ABI=%%A"
)

:: Check if ABI was retrieved
if not defined ABI (
    echo [ERROR] Failed to retrieve ABI from device.
    exit /b 1
)

echo [OK] Device ABI: %ABI%
echo.

dos2unix install.sh
dos2unix package/mkshrc.sh
echo.
echo [OK] Success converting
echo.

adb shell rm -rf /data/local/tmp/bin /data/local/tmp/mkshrc /data/local/tmp/package /data/local/tmp/mkshrc
adb shell mkdir -p /data/local/tmp/package

adb push package/%ABI%/ /data/local/tmp/package/
adb push package/mkshrc.sh /data/local/tmp/package/
adb push package/update-ca-certificate.sh /data/local/tmp/package/
adb push package/WifiConfigStore.xml /data/local/tmp/
adb push package/wpa_supplicant.conf /data/local/tmp/

adb push install.sh /data/local/tmp/mkshrc

echo.
echo [OK] Deployment completed successfully
echo [OK] Now you're in adb shell. Please run and execute the following commands:
echo      $ source /data/local/tmp/mkshrc
echo.

adb shell