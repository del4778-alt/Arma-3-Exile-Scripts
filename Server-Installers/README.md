# Arma 3 Exile Server Installer

Complete automated installation script for setting up a local Arma 3 Exile server with MySQL database.

## 📋 **What This Installer Does**

1. ✅ Downloads and installs **SteamCMD**
2. ✅ Installs **Arma 3 Dedicated Server** (via Steam)
3. ✅ Installs **MariaDB (MySQL)** portable version
4. ✅ Creates **Exile database** with user
5. ✅ Generates **server configuration files**
6. ✅ Creates **startup/stop/restart scripts**
7. ✅ Configures **Windows firewall rules**
8. ✅ Sets up **database backup script**

---

## 🖥️ **System Requirements**

### Minimum:
- **OS:** Windows 10/11 or Windows Server 2016+
- **RAM:** 8 GB minimum (16 GB recommended)
- **Storage:** 50 GB free space (SSD recommended)
- **CPU:** Quad-core processor (Intel i5/AMD Ryzen 5 or better)
- **Network:** Stable internet connection (for downloads)

### Software Requirements:
- **Administrator privileges** (required for service installation)
- **PowerShell** (included in Windows)
- **.NET Framework 4.8+** (usually pre-installed)

---

## 🚀 **Quick Start**

### **Option 1: Simple Installation (Recommended)**

1. **Download** `install_exile_server.bat`
2. **Right-click** → **Run as Administrator**
3. Follow the on-screen prompts
4. Wait for installation (30-60 minutes)

### **Option 2: Manual Configuration**

Edit the batch file before running to customize:

```batch
REM Your Steam credentials (OPTIONAL)
set STEAM_USER=your_steam_username
set STEAM_PASS=your_steam_password

REM Server settings
set SERVER_NAME=My Awesome Exile Server
set SERVER_PASSWORD=player_password
set ADMIN_PASSWORD=admin_password_here
set MAX_PLAYERS=60
set SERVER_PORT=2302
```

---

## 📁 **Installation Directories**

After installation, your server structure will be:

```
C:\ExileServer\
├── steamcmd\              # SteamCMD installation
├── arma3\                 # Arma 3 Dedicated Server
│   ├── @ExileServer\      # Server-side mod
│   ├── mods\
│   │   └── @Exile\        # Client mod
│   ├── mpmissions\        # Your mission files
│   ├── server.cfg         # Server configuration
│   └── basic.cfg          # Network configuration
├── MySQL\                 # MariaDB database
│   ├── bin\
│   ├── data\
│   └── my.ini
├── backups\               # Database backups
├── start_server.bat       # START SERVER
├── stop_server.bat        # STOP SERVER
├── restart_server.bat     # RESTART SERVER
├── backup_database.bat    # BACKUP DATABASE
└── install.log            # Installation info
```

---

## 🔧 **Post-Installation Steps**

### **Step 1: Download Exile Mod**

The installer **cannot automatically download** Exile mod. You must:

1. Go to: https://www.exilemod.com/downloads/
2. Download the latest Exile version
3. Extract the contents:
   - Place `@Exile` folder in `C:\ExileServer\arma3\mods\@Exile`
   - Place `@ExileServer` folder in `C:\ExileServer\arma3\mods\@ExileServer`

### **Step 2: Import Exile Database**

```batch
cd C:\ExileServer\MySQL\bin
mysql.exe -u root exile < C:\path\to\exile.sql
```

The `exile.sql` file is included in the Exile download.

### **Step 3: Configure Database Connection**

Edit: `C:\ExileServer\arma3\mods\@ExileServer\extDB3\sql_custom_v2\exile.ini`

```ini
[Database]
IP = 127.0.0.1
Port = 3306
Username = exile
Password = exile123
Database = exile
```

### **Step 4: Install Your Mission**

1. Create or download an Exile mission (e.g., `Exile.Altis`)
2. Place mission folder in: `C:\ExileServer\arma3\mpmissions\`
3. Copy your AI recruit script to: `mpmissions\YourMission.MapName\scripts\`

#### **Example Mission Structure:**
```
C:\ExileServer\arma3\mpmissions\Exile.Altis\
├── mission.sqm
├── description.ext
├── initServer.sqf
├── config.cpp
└── scripts\
    └── recruit_ai.sqf
```

#### **Example initServer.sqf:**
```sqf
if (!isServer) exitWith {};

diag_log "[SERVER] Loading Exile server scripts...";

// Load AI Recruit System
execVM "scripts\recruit_ai.sqf";

diag_log "[SERVER] Server initialization complete";
```

### **Step 5: Update server.cfg**

Edit `C:\ExileServer\arma3\server.cfg`:

```cpp
class Missions
{
    class Exile
    {
        template = Exile.Altis;  // Your mission name
        difficulty = "ExileRegular";
    };
};
```

---

## 🎮 **Starting Your Server**

### **Start Server**
Double-click: `C:\ExileServer\start_server.bat`

Or run from command line:
```batch
cd C:\ExileServer
start_server.bat
```

### **Server Logs**
Monitor server activity:
```
C:\ExileServer\arma3\SC\server_console.log
```

### **Stop Server**
```batch
cd C:\ExileServer
stop_server.bat
```

### **Restart Server**
```batch
cd C:\ExileServer
restart_server.bat
```

---

## 🔒 **Security Checklist**

Before making your server public:

### ✅ **Change Default Passwords**

1. **Admin Password** (in `server.cfg`):
   ```cpp
   passwordAdmin = "ChooseAStrongPassword123!";
   ```

2. **MySQL Root Password**:
   ```batch
   cd C:\ExileServer\MySQL\bin
   mysql.exe -u root
   ```
   ```sql
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_root_password';
   ALTER USER 'exile'@'localhost' IDENTIFIED BY 'new_exile_password';
   FLUSH PRIVILEGES;
   ```

3. **Update Database Config** (after changing MySQL password):
   Edit: `@ExileServer\extDB3\sql_custom_v2\exile.ini`

### ✅ **Firewall Configuration**

The installer automatically opens these ports:
- **2302 UDP** - Game port
- **2304 UDP** - Steam port
- **2305 UDP** - Steam query port
- **3306 TCP** - MySQL (only if needed externally)

For router/external firewall, forward ports **2302-2305 UDP**.

### ✅ **BattlEye Configuration**

1. Copy BattlEye files from `C:\ExileServer\arma3\battleye\` to server root
2. Configure `beserver_x64.cfg` with your RCON password

---

## 💾 **Database Backups**

### **Automatic Backup**
Run the backup script:
```batch
C:\ExileServer\backup_database.bat
```

Creates timestamped backup in: `C:\ExileServer\backups\`

### **Schedule Automatic Backups**

Use Windows Task Scheduler:

1. Open **Task Scheduler**
2. **Create Basic Task**
3. **Name:** "Exile Database Backup"
4. **Trigger:** Daily at 3 AM (or your preference)
5. **Action:** Start a program
6. **Program:** `C:\ExileServer\backup_database.bat`

### **Restore from Backup**
```batch
cd C:\ExileServer\MySQL\bin
mysql.exe -u root exile < C:\ExileServer\backups\exile_20250101_120000.sql
```

---

## 🛠️ **Troubleshooting**

### **Server Won't Start**

**Check if MySQL is running:**
```batch
sc query ExileMySQL
```

**Manually start MySQL:**
```batch
net start ExileMySQL
```

**Check Arma 3 logs:**
```
C:\ExileServer\arma3\SC\server_console.log
```

### **Database Connection Errors**

**Test MySQL connection:**
```batch
cd C:\ExileServer\MySQL\bin
mysql.exe -u exile -p
```
Enter password: `exile123` (or your custom password)

**Common issues:**
- Wrong password in `exile.ini`
- MySQL service not running
- Database not imported

### **Players Can't Connect**

**Verify firewall rules:**
```batch
netsh advfirewall firewall show rule name="Arma3 Server - Game Port"
```

**Check server.cfg:**
- Correct port number (default: 2302)
- No conflicting services on same port

**Port forwarding:**
- Forward UDP ports 2302-2305 on your router
- Set static IP for server machine

### **Low Performance**

**Optimize server.cfg:**
```cpp
MaxMsgSend = 512;
MaxSizeGuaranteed = 1024;
MinBandwidth = 107374182;
MaxBandwidth = 2147483647;
```

**Reduce AI count:**
Edit mission parameters to lower AI spawns

**Enable headless client:**
Configure HC in Exile mission files

---

## 🔄 **Updating Arma 3 Server**

### **Manual Update**
```batch
cd C:\ExileServer\steamcmd
steamcmd.exe +force_install_dir C:\ExileServer\arma3 +login anonymous +app_update 233780 validate +quit
```

### **Update Script**

Create `C:\ExileServer\update_server.bat`:
```batch
@echo off
echo Stopping server...
call C:\ExileServer\stop_server.bat
timeout /t 5

echo Updating Arma 3...
cd C:\ExileServer\steamcmd
steamcmd.exe +force_install_dir C:\ExileServer\arma3 +login anonymous +app_update 233780 validate +quit

echo Starting server...
call C:\ExileServer\start_server.bat
```

---

## 📊 **Performance Monitoring**

### **View Server Status**
```batch
tasklist | find "arma3server"
```

### **Monitor Resources**
Use **Task Manager** → **Performance** tab

### **Check Player Count**
```batch
netstat -an | find "2302"
```

---

## 🌐 **Making Server Public**

### **1. Port Forwarding (Router)**
Forward these ports to your server's local IP:
- **2302-2305 UDP**

### **2. Dynamic DNS (Optional)**
If you don't have a static IP:
- Use services like **No-IP** or **DuckDNS**
- Install DDNS client on server

### **3. Register with Server Browsers**
Your server will appear in:
- Arma 3 in-game browser (if properly configured)
- Third-party tools like **A3Launcher**

### **4. Server.cfg Settings**
```cpp
// Make server public
password = "";  // No password = public

// Show in browser
steamPort = 2304;
steamQueryPort = 2305;
```

---

## 📞 **Support & Resources**

### **Official Resources:**
- **Exile Website:** https://www.exilemod.com/
- **Exile Forums:** https://www.exilemod.com/forums/
- **Exile Discord:** https://discord.gg/exile

### **Arma 3 Server Resources:**
- **Bohemia Wiki:** https://community.bistudio.com/wiki/Arma_3:_Dedicated_Server
- **Server Setup Guide:** https://community.bistudio.com/wiki/Arma_3:_Server_Config_File

### **Database Management:**
- **HeidiSQL:** https://www.heidisql.com/ (MySQL GUI)
- **MySQL Workbench:** https://www.mysql.com/products/workbench/

---

## 📝 **Default Credentials**

**MySQL Database:**
- Host: `127.0.0.1` (localhost)
- Port: `3306`
- Database: `exile`
- Username: `exile`
- Password: `exile123`

**Server Admin:**
- Password: Set in `server.cfg` (`passwordAdmin`)
- Default: `changeme123` (⚠️ **CHANGE THIS!**)

---

## ⚙️ **Advanced Configuration**

### **Add Additional Mods**

Edit `start_server.bat`:
```batch
"-mod=@Exile;@CBA_A3;@Ryanzombies" ^
"-servermod=@ExileServer;@infiSTAR" ^
```

### **Multiple Server Instances**

Create separate directories and change ports:
```batch
set SERVER_PORT=2402  # Server 2
```

### **RAM Allocation**

Edit `start_server.bat` to add:
```batch
-maxMem=8192 ^  # 8GB RAM
```

---

## 🎯 **Quick Reference**

| Task | Command |
|------|---------|
| Start Server | `start_server.bat` |
| Stop Server | `stop_server.bat` |
| Restart Server | `restart_server.bat` |
| Backup Database | `backup_database.bat` |
| Update Arma 3 | `update_server.bat` |
| MySQL Console | `MySQL\bin\mysql.exe -u root` |
| View Logs | `arma3\SC\server_console.log` |

---

## ❓ **FAQ**

**Q: Do I need to buy Arma 3?**
A: No, the dedicated server is free via SteamCMD.

**Q: Can I run this on Linux?**
A: Yes! Use `install_exile_server.sh` (Linux version)

**Q: How many players can I host?**
A: Depends on your hardware. 60 players = good CPU + 16GB RAM recommended

**Q: Can I use a different map?**
A: Yes, install map mod and change mission file

**Q: Is port 3306 required to be open?**
A: No, only if you need external database access (not recommended)

---

## 📄 **License**

This installer script is provided as-is for educational and personal use.
Arma 3 and Exile are property of their respective owners.

---

**Installer Version:** 1.0
**Last Updated:** 2025
**Compatible With:** Arma 3 v2.18+, Exile 1.0.4+
