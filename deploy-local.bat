@echo off
REM Quick L1 deployment script (Windows batch file)
echo.
echo ========================================
echo   UNYKORN L1 LOCAL DEPLOYMENT
echo ========================================
echo.

REM Check if node is running
echo Checking for existing Hardhat node...
curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}" http://127.0.0.1:8545 >nul 2>&1

if %errorlevel% neq 0 (
    echo [!] No node detected. Starting Hardhat node in background...
    start "Hardhat Node" /MIN cmd /c "npx hardhat node --hostname 127.0.0.1 --port 8545 > hardhat-node.log 2>&1"
    timeout /t 5 /nobreak >nul
    echo [+] Node started
) else (
    echo [+] Node already running
)

echo.
echo Deploying contracts to localhost...
echo.

npx hardhat run scripts\deploy-energy-system.js --network localhost

echo.
echo ========================================
echo   DEPLOYMENT COMPLETE
echo ========================================
echo.
echo View node logs: type hardhat-node.log
echo Stop node: taskkill /FI "WindowTitle eq Hardhat Node*" /F
echo.

pause
