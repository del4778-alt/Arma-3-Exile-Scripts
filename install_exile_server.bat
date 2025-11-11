@echo off
REM ========================================
REM ARMA 3 EXILE SERVER INSTALLER
REM Complete setup for Arma 3 Exile Server
REM ========================================

COLOR 0A
title Arma 3 Exile Server Installer

echo ========================================
echo    ARMA 3 EXILE SERVER INSTALLER
echo ========================================
echo.
echo This script will install:
echo  - SteamCMD
echo  - Arma 3 Dedicated Server
echo  - MySQL/MariaDB Database
echo  - Exile Mod
echo  - Basic Configuration
echo.
echo Installation Path: C:\ExileServer
echo.
pause

REM ========================================
REM CONFIGURATION
REM ========================================

set SERVER_DIR=C:\ExileServer
set STEAMCMD_DIR=%SERVER_DIR%\steamcmd
set ARMA_DIR=%SERVER_DIR%\arma3
set MODS_DIR=%ARMA_DIR%\mods
set MYSQL_DIR=%SERVER_DIR%\MySQL
set BACKUP_DIR=%SERVER_DIR%\backups

REM Your Steam credentials (OPTIONAL - leave blank for anonymous)
set STEAM_USER=
set STEAM_PASS=

REM Server settings
set SERVER_NAME=My Exile Server
set SERVER_PASSWORD=
set ADMIN_PASSWORD=changeme123
set MAX_PLAYERS=60
set SERVER_PORT=2302

echo.
echo ========================================
echo STEP 1: Creating Directory Structure
echo ========================================
echo.

if not exist "%SERVER_DIR%" mkdir "%SERVER_DIR%"
if not exist "%STEAMCMD_DIR%" mkdir "%STEAMCMD_DIR%"
if not exist "%ARMA_DIR%" mkdir "%ARMA_DIR%"
if not exist "%MODS_DIR%" mkdir "%MODS_DIR%"
if not exist "%MYSQL_DIR%" mkdir "%MYSQL_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo [OK] Directories created
echo.

REM ========================================
REM STEP 2: Download and Install SteamCMD
REM ========================================

echo ========================================
echo STEP 2: Installing SteamCMD
echo ========================================
echo.

if not exist "%STEAMCMD_DIR%\steamcmd.exe" (
    echo Downloading SteamCMD...
    powershell -Command "Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile '%STEAMCMD_DIR%\steamcmd.zip'"

    echo Extracting SteamCMD...
    powershell -Command "Expand-Archive -Path '%STEAMCMD_DIR%\steamcmd.zip' -DestinationPath '%STEAMCMD_DIR%' -Force"

    del "%STEAMCMD_DIR%\steamcmd.zip"
    echo [OK] SteamCMD installed
) else (
    echo [OK] SteamCMD already installed
)

echo.

REM ========================================
REM STEP 3: Install Arma 3 Dedicated Server
REM ========================================

echo ========================================
echo STEP 3: Installing Arma 3 Server
echo ========================================
echo This may take 30-60 minutes...
echo.

if "%STEAM_USER%"=="" (
    echo Installing as anonymous...
    "%STEAMCMD_DIR%\steamcmd.exe" +force_install_dir "%ARMA_DIR%" +login anonymous +app_update 233780 validate +quit
) else (
    echo Installing with credentials...
    "%STEAMCMD_DIR%\steamcmd.exe" +force_install_dir "%ARMA_DIR%" +login "%STEAM_USER%" "%STEAM_PASS%" +app_update 233780 validate +quit
)

echo [OK] Arma 3 Server installed
echo.

REM ========================================
REM STEP 4: Download MariaDB (MySQL)
REM ========================================

echo ========================================
echo STEP 4: Installing MariaDB (MySQL)
echo ========================================
echo.

if not exist "%MYSQL_DIR%\bin\mysqld.exe" (
    echo Downloading MariaDB 10.11 (Portable)...
    powershell -Command "Invoke-WebRequest -Uri 'https://downloads.mariadb.org/rest-api/mariadb/10.11.8/mariadb-10.11.8-winx64.zip' -OutFile '%SERVER_DIR%\mariadb.zip'"

    echo Extracting MariaDB...
    powershell -Command "Expand-Archive -Path '%SERVER_DIR%\mariadb.zip' -DestinationPath '%SERVER_DIR%' -Force"

    REM Move to MySQL_DIR
    move "%SERVER_DIR%\mariadb-10.11.8-winx64" "%MYSQL_DIR%"
    del "%SERVER_DIR%\mariadb.zip"

    echo [OK] MariaDB installed
) else (
    echo [OK] MariaDB already installed
)

echo.

REM ========================================
REM STEP 5: Initialize MySQL Database
REM ========================================

echo ========================================
echo STEP 5: Setting up MySQL Database
echo ========================================
echo.

if not exist "%MYSQL_DIR%\data" (
    echo Initializing MySQL data directory...
    "%MYSQL_DIR%\bin\mysql_install_db.exe" --datadir="%MYSQL_DIR%\data" --service=ExileMySQL

    echo [OK] MySQL initialized
) else (
    echo [OK] MySQL data directory exists
)

echo.

REM ========================================
REM STEP 6: Create MySQL Configuration
REM ========================================

echo ========================================
echo STEP 6: Creating MySQL Configuration
echo ========================================
echo.

(
echo [mysqld]
echo port=3306
echo datadir=%MYSQL_DIR%\data
echo character-set-server=utf8mb4
echo max_connections=100
echo bind-address=127.0.0.1
echo.
echo [client]
echo port=3306
echo default-character-set=utf8mb4
) > "%MYSQL_DIR%\my.ini"

echo [OK] MySQL configuration created
echo.

REM ========================================
REM STEP 7: Start MySQL and Create Database
REM ========================================

echo ========================================
echo STEP 7: Starting MySQL Service
echo ========================================
echo.

echo Installing MySQL as Windows service...
"%MYSQL_DIR%\bin\mysqld.exe" --install ExileMySQL --defaults-file="%MYSQL_DIR%\my.ini"

echo Starting MySQL service...
net start ExileMySQL

timeout /t 5

echo Creating Exile database...
"%MYSQL_DIR%\bin\mysql.exe" -u root -e "CREATE DATABASE IF NOT EXISTS exile;"
"%MYSQL_DIR%\bin\mysql.exe" -u root -e "CREATE USER IF NOT EXISTS 'exile'@'localhost' IDENTIFIED BY 'exile123';"
"%MYSQL_DIR%\bin\mysql.exe" -u root -e "GRANT ALL PRIVILEGES ON exile.* TO 'exile'@'localhost';"
"%MYSQL_DIR%\bin\mysql.exe" -u root -e "FLUSH PRIVILEGES;"

echo [OK] Database created
echo.

REM ========================================
REM STEP 8: Download Exile Mod
REM ========================================

echo ========================================
echo STEP 8: Exile Mod Installation
echo ========================================
echo.
echo IMPORTANT: You need to manually download Exile mod
echo.
echo Steps:
echo 1. Download Exile mod from http://www.exilemod.com/downloads/
echo 2. Extract @Exile and @ExileServer to: %MODS_DIR%
echo 3. Import exile.sql to database using:
echo    %MYSQL_DIR%\bin\mysql.exe -u root exile ^< exile.sql
echo.
echo Press any key when Exile mod is installed...
pause > nul

if exist "%MODS_DIR%\@ExileServer" (
    echo [OK] Exile mod detected
) else (
    echo [WARNING] Exile mod not found - please install manually
)

echo.

REM ========================================
REM STEP 9: Create Server Configuration
REM ========================================

echo ========================================
echo STEP 9: Creating Server Configuration
echo ========================================
echo.

REM Create server.cfg
(
echo // Server.cfg for Exile
echo.
echo hostname = "%SERVER_NAME%";
echo password = "%SERVER_PASSWORD%";
echo passwordAdmin = "%ADMIN_PASSWORD%";
echo maxPlayers = %MAX_PLAYERS%;
echo.
echo motd[] = {
echo     "Welcome to %SERVER_NAME%",
echo     "Enjoy your stay!"
echo };
echo.
echo motdInterval = 5;
echo.
echo // Logging
echo logFile = "server_console.log";
echo timeStampFormat = "short";
echo.
echo // Voting
echo voteThreshold = 0.33;
echo voteMissionPlayers = 3;
echo.
echo // Missions
echo class Missions
echo {
echo     class Exile
echo     {
echo         template = Exile.Altis;
echo         difficulty = "ExileRegular";
echo     };
echo };
echo.
echo // BattlEye
echo BattlEye = 1;
echo.
echo // Persistence
echo persistent = 1;
echo.
echo // Voice
echo disableVoN = 0;
echo vonCodecQuality = 10;
echo.
echo // Performance
echo MaxMsgSend = 256;
echo MaxSizeGuaranteed = 512;
echo MaxSizeNonguaranteed = 256;
echo MinBandwidth = 107374182;
echo MaxBandwidth = 1073741824;
echo.
echo // Network
echo steamPort = 2304;
echo steamQueryPort = 2305;
) > "%ARMA_DIR%\server.cfg"

echo [OK] server.cfg created
echo.

REM Create basic.cfg
(
echo // Basic.cfg for Arma 3
echo.
echo MaxMsgSend = 256;
echo MaxSizeGuaranteed = 512;
echo MaxSizeNonguaranteed = 256;
echo MinBandwidth = 107374182;
echo MaxBandwidth = 1073741824;
echo MinErrorToSend = 0.001;
echo MinErrorToSendNear = 0.01;
echo MaxCustomFileSize = 160000;
) > "%ARMA_DIR%\basic.cfg"

echo [OK] basic.cfg created
echo.

REM ========================================
REM STEP 10: Create Server Startup Script
REM ========================================

echo ========================================
echo STEP 10: Creating Startup Scripts
echo ========================================
echo.

REM Main startup script
(
echo @echo off
echo title Exile Server - Starting...
echo.
echo echo ========================================
echo echo    ARMA 3 EXILE SERVER STARTUP
echo echo ========================================
echo echo.
echo.
echo REM Check if MySQL is running
echo sc query ExileMySQL ^| find "RUNNING" ^>nul
echo if errorlevel 1 ^(
echo     echo Starting MySQL service...
echo     net start ExileMySQL
echo     timeout /t 5
echo ^)
echo.
echo echo Starting Arma 3 Exile Server...
echo echo Server Name: %SERVER_NAME%
echo echo Port: %SERVER_PORT%
echo echo.
echo.
echo cd /d "%ARMA_DIR%"
echo.
echo start "Exile Server" /min arma3server_x64.exe ^
echo     -port=%SERVER_PORT% ^
echo     -config=server.cfg ^
echo     -cfg=basic.cfg ^
echo     -profiles=SC ^
echo     -name=SC ^
echo     "-mod=@Exile" ^
echo     "-servermod=@ExileServer" ^
echo     -world=empty ^
echo     -autoinit ^
echo     -enableHT
echo.
echo echo.
echo echo Server started!
echo echo Check logs in: %ARMA_DIR%\SC\server_console.log
echo echo.
echo pause
) > "%SERVER_DIR%\start_server.bat"

echo [OK] Startup script created
echo.

REM Stop server script
(
echo @echo off
echo title Exile Server - Stopping...
echo.
echo echo Stopping Arma 3 Server...
echo taskkill /F /IM arma3server_x64.exe
echo.
echo echo Server stopped
echo pause
) > "%SERVER_DIR%\stop_server.bat"

echo [OK] Stop script created
echo.

REM Restart server script
(
echo @echo off
echo title Exile Server - Restarting...
echo.
echo call "%SERVER_DIR%\stop_server.bat"
echo timeout /t 5
echo call "%SERVER_DIR%\start_server.bat"
) > "%SERVER_DIR%\restart_server.bat"

echo [OK] Restart script created
echo.

REM Database backup script
(
echo @echo off
echo title MySQL Backup
echo.
echo set TIMESTAMP=%%date:~10,4%%%%date:~4,2%%%%date:~7,2%%_%%time:~0,2%%%%time:~3,2%%%%time:~6,2%%
echo set TIMESTAMP=%%TIMESTAMP: =0%%
echo.
echo echo Backing up Exile database...
echo "%MYSQL_DIR%\bin\mysqldump.exe" -u root exile ^> "%BACKUP_DIR%\exile_%%TIMESTAMP%%.sql"
echo.
echo echo Backup saved to: %BACKUP_DIR%\exile_%%TIMESTAMP%%.sql
echo echo.
echo pause
) > "%SERVER_DIR%\backup_database.bat"

echo [OK] Backup script created
echo.

REM ========================================
REM STEP 11: Create Firewall Rules
REM ========================================

echo ========================================
echo STEP 11: Creating Firewall Rules
echo ========================================
echo.

echo Adding firewall rules for Arma 3 server...

netsh advfirewall firewall add rule name="Arma3 Server - Game Port" dir=in action=allow protocol=UDP localport=%SERVER_PORT% > nul
netsh advfirewall firewall add rule name="Arma3 Server - Steam Port" dir=in action=allow protocol=UDP localport=2304 > nul
netsh advfirewall firewall add rule name="Arma3 Server - Steam Query" dir=in action=allow protocol=UDP localport=2305 > nul
netsh advfirewall firewall add rule name="MySQL Server" dir=in action=allow protocol=TCP localport=3306 > nul

echo [OK] Firewall rules created
echo.

REM ========================================
REM INSTALLATION COMPLETE
REM ========================================

echo.
echo ========================================
echo    INSTALLATION COMPLETE!
echo ========================================
echo.
echo Installation Summary:
echo  Server Directory: %SERVER_DIR%
echo  Arma 3 Directory: %ARMA_DIR%
echo  MySQL Directory:  %MYSQL_DIR%
echo  Mods Directory:   %MODS_DIR%
echo.
echo Database Info:
echo  Database: exile
echo  User:     exile
echo  Password: exile123
echo  Port:     3306
echo.
echo Server Scripts:
echo  Start Server:    %SERVER_DIR%\start_server.bat
echo  Stop Server:     %SERVER_DIR%\stop_server.bat
echo  Restart Server:  %SERVER_DIR%\restart_server.bat
echo  Backup Database: %SERVER_DIR%\backup_database.bat
echo.
echo NEXT STEPS:
echo ========================================
echo.
echo 1. Install Exile Mod Files:
echo    - Download Exile from: http://www.exilemod.com/downloads/
echo    - Extract @Exile and @ExileServer to: %MODS_DIR%
echo.
echo 2. Import Exile Database:
echo    - Run: %MYSQL_DIR%\bin\mysql.exe -u root exile ^< exile.sql
echo.
echo 3. Configure Your Mission:
echo    - Create/edit mission file in: %ARMA_DIR%\mpmissions\
echo    - Copy this AI recruit script to mission folder
echo.
echo 4. Configure @ExileServer:
echo    - Edit: %MODS_DIR%\@ExileServer\extDB\sql_custom_v2\exile.ini
echo    - Set database credentials: exile / exile123
echo.
echo 5. Start Your Server:
echo    - Run: %SERVER_DIR%\start_server.bat
echo.
echo 6. IMPORTANT Security Settings:
echo    - Change admin password in server.cfg
echo    - Change MySQL password:
echo      mysql -u root
echo      ALTER USER 'exile'@'localhost' IDENTIFIED BY 'new_password';
echo.
echo ========================================
echo.
echo Installation log saved to: %SERVER_DIR%\install.log
echo.

REM Save installation info
(
echo Arma 3 Exile Server Installation
echo Date: %date% %time%
echo.
echo Server Directory: %SERVER_DIR%
echo Arma 3 Directory: %ARMA_DIR%
echo MySQL Directory:  %MYSQL_DIR%
echo.
echo Database: exile
echo User: exile
echo Password: exile123
echo.
echo Admin Password: %ADMIN_PASSWORD%
echo Server Port: %SERVER_PORT%
) > "%SERVER_DIR%\install.log"

echo Press any key to exit...
pause > nul
