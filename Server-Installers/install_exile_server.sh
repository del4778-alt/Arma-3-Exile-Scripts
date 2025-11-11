#!/bin/bash

# ========================================
# ARMA 3 EXILE SERVER INSTALLER (LINUX)
# Complete setup for Arma 3 Exile Server
# ========================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   ARMA 3 EXILE SERVER INSTALLER${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will install:"
echo " - SteamCMD"
echo " - Arma 3 Dedicated Server"
echo " - MariaDB Database"
echo " - Exile Mod"
echo " - Basic Configuration"
echo ""
echo "Installation Path: /opt/exileserver"
echo ""
read -p "Press Enter to continue..."

# ========================================
# CONFIGURATION
# ========================================

SERVER_DIR="/opt/exileserver"
STEAMCMD_DIR="$SERVER_DIR/steamcmd"
ARMA_DIR="$SERVER_DIR/arma3"
MODS_DIR="$ARMA_DIR/mods"
BACKUP_DIR="$SERVER_DIR/backups"

# Your Steam credentials (OPTIONAL - leave blank for anonymous)
STEAM_USER=""
STEAM_PASS=""

# Server settings
SERVER_NAME="My Exile Server"
SERVER_PASSWORD=""
ADMIN_PASSWORD="changeme123"
MAX_PLAYERS="60"
SERVER_PORT="2302"

# Database settings
DB_NAME="exile"
DB_USER="exile"
DB_PASS="exile123"
DB_ROOT_PASS="root123"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 1: Checking Requirements${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Please run as root (use sudo)${NC}"
   exit 1
fi

echo -e "${GREEN}[OK]${NC} Running as root"

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect Linux distribution${NC}"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Detected $OS $VER"

# ========================================
# STEP 2: Install Dependencies
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 2: Installing Dependencies${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo "Installing packages for Debian/Ubuntu..."

    # Add 32-bit architecture (required for SteamCMD)
    dpkg --add-architecture i386
    apt-get update

    # Install dependencies
    apt-get install -y \
        lib32gcc-s1 \
        lib32stdc++6 \
        wget \
        curl \
        tar \
        bzip2 \
        gzip \
        unzip \
        screen \
        mariadb-server \
        mariadb-client

elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    echo "Installing packages for CentOS/RHEL..."

    yum install -y \
        glibc.i686 \
        libstdc++.i686 \
        wget \
        curl \
        tar \
        bzip2 \
        gzip \
        unzip \
        screen \
        mariadb-server \
        mariadb
else
    echo -e "${YELLOW}Unsupported distribution. Please install dependencies manually.${NC}"
fi

echo -e "${GREEN}[OK]${NC} Dependencies installed"

# ========================================
# STEP 3: Create Directory Structure
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 3: Creating Directory Structure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

mkdir -p "$SERVER_DIR"
mkdir -p "$STEAMCMD_DIR"
mkdir -p "$ARMA_DIR"
mkdir -p "$MODS_DIR"
mkdir -p "$BACKUP_DIR"

# Create steam user
if ! id "steam" &>/dev/null; then
    useradd -m -d "$SERVER_DIR" -s /bin/bash steam
    echo -e "${GREEN}[OK]${NC} Steam user created"
else
    echo -e "${GREEN}[OK]${NC} Steam user already exists"
fi

echo -e "${GREEN}[OK]${NC} Directories created"

# ========================================
# STEP 4: Install SteamCMD
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 4: Installing SteamCMD${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
    cd "$STEAMCMD_DIR"
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xvzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz

    # Initial run to update
    ./steamcmd.sh +quit

    echo -e "${GREEN}[OK]${NC} SteamCMD installed"
else
    echo -e "${GREEN}[OK]${NC} SteamCMD already installed"
fi

# ========================================
# STEP 5: Install Arma 3 Server
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 5: Installing Arma 3 Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This may take 30-60 minutes..."
echo ""

cd "$STEAMCMD_DIR"

if [ -z "$STEAM_USER" ]; then
    ./steamcmd.sh \
        +force_install_dir "$ARMA_DIR" \
        +login anonymous \
        +app_update 233780 validate \
        +quit
else
    ./steamcmd.sh \
        +force_install_dir "$ARMA_DIR" \
        +login "$STEAM_USER" "$STEAM_PASS" \
        +app_update 233780 validate \
        +quit
fi

echo -e "${GREEN}[OK]${NC} Arma 3 Server installed"

# ========================================
# STEP 6: Setup MariaDB
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 6: Setting up MariaDB${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Start MariaDB service
systemctl start mariadb
systemctl enable mariadb

echo -e "${GREEN}[OK]${NC} MariaDB service started"

# Secure installation
echo "Securing MariaDB installation..."

mysql -e "UPDATE mysql.user SET Password=PASSWORD('$DB_ROOT_PASS') WHERE User='root';" 2>/dev/null || \
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS';"

mysql -u root -p"$DB_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p"$DB_ROOT_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -p"$DB_ROOT_PASS" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"$DB_ROOT_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -p"$DB_ROOT_PASS" -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}[OK]${NC} MariaDB secured"

# Create Exile database and user
echo "Creating Exile database..."

mysql -u root -p"$DB_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}[OK]${NC} Exile database created"

# ========================================
# STEP 7: Download Exile Mod
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 7: Exile Mod Installation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: You need to manually download Exile mod${NC}"
echo ""
echo "Steps:"
echo "1. Download Exile mod from http://www.exilemod.com/downloads/"
echo "2. Extract @Exile and @ExileServer to: $MODS_DIR"
echo "3. Import exile.sql using:"
echo "   mysql -u root -p$DB_ROOT_PASS $DB_NAME < exile.sql"
echo ""
read -p "Press Enter when Exile mod is installed..."

if [ -d "$MODS_DIR/@ExileServer" ]; then
    echo -e "${GREEN}[OK]${NC} Exile mod detected"
else
    echo -e "${YELLOW}[WARNING]${NC} Exile mod not found - please install manually"
fi

# ========================================
# STEP 8: Create Server Configuration
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 8: Creating Server Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create server.cfg
cat > "$ARMA_DIR/server.cfg" <<EOF
// Server.cfg for Exile

hostname = "$SERVER_NAME";
password = "$SERVER_PASSWORD";
passwordAdmin = "$ADMIN_PASSWORD";
maxPlayers = $MAX_PLAYERS;

motd[] = {
    "Welcome to $SERVER_NAME",
    "Enjoy your stay!"
};

motdInterval = 5;

// Logging
logFile = "server_console.log";
timeStampFormat = "short";

// Voting
voteThreshold = 0.33;
voteMissionPlayers = 3;

// Missions
class Missions
{
    class Exile
    {
        template = Exile.Altis;
        difficulty = "ExileRegular";
    };
};

// BattlEye
BattlEye = 1;

// Persistence
persistent = 1;

// Voice
disableVoN = 0;
vonCodecQuality = 10;

// Performance
MaxMsgSend = 256;
MaxSizeGuaranteed = 512;
MaxSizeNonguaranteed = 256;
MinBandwidth = 107374182;
MaxBandwidth = 1073741824;

// Network
steamPort = 2304;
steamQueryPort = 2305;
EOF

echo -e "${GREEN}[OK]${NC} server.cfg created"

# Create basic.cfg
cat > "$ARMA_DIR/basic.cfg" <<EOF
// Basic.cfg for Arma 3

MaxMsgSend = 256;
MaxSizeGuaranteed = 512;
MaxSizeNonguaranteed = 256;
MinBandwidth = 107374182;
MaxBandwidth = 1073741824;
MinErrorToSend = 0.001;
MinErrorToSendNear = 0.01;
MaxCustomFileSize = 160000;
EOF

echo -e "${GREEN}[OK]${NC} basic.cfg created"

# ========================================
# STEP 9: Create Startup Scripts
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 9: Creating Startup Scripts${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Start server script
cat > "$SERVER_DIR/start_server.sh" <<'STARTSCRIPT'
#!/bin/bash

echo "========================================="
echo "    ARMA 3 EXILE SERVER STARTUP"
echo "========================================="
echo ""

# Check if MariaDB is running
if ! systemctl is-active --quiet mariadb; then
    echo "Starting MariaDB service..."
    sudo systemctl start mariadb
    sleep 3
fi

echo "Starting Arma 3 Exile Server..."
echo "Server will run in screen session: exile-server"
echo ""

cd /opt/exileserver/arma3

screen -dmS exile-server ./arma3server \
    -port=2302 \
    -config=server.cfg \
    -cfg=basic.cfg \
    -profiles=SC \
    -name=SC \
    "-mod=@Exile" \
    "-servermod=@ExileServer" \
    -world=empty \
    -autoinit

sleep 2

if screen -list | grep -q "exile-server"; then
    echo "Server started successfully!"
    echo ""
    echo "Commands:"
    echo "  Attach to server:  screen -r exile-server"
    echo "  Detach from screen: Ctrl+A, then D"
    echo "  View logs:         tail -f SC/server_console.log"
else
    echo "Failed to start server. Check logs."
fi
STARTSCRIPT

chmod +x "$SERVER_DIR/start_server.sh"
echo -e "${GREEN}[OK]${NC} Start script created"

# Stop server script
cat > "$SERVER_DIR/stop_server.sh" <<'STOPSCRIPT'
#!/bin/bash

echo "Stopping Arma 3 Server..."

if screen -list | grep -q "exile-server"; then
    screen -S exile-server -X quit
    echo "Server stopped"
else
    echo "Server is not running"
fi

# Also kill any remaining processes
pkill -f arma3server
STOPSCRIPT

chmod +x "$SERVER_DIR/stop_server.sh"
echo -e "${GREEN}[OK]${NC} Stop script created"

# Restart server script
cat > "$SERVER_DIR/restart_server.sh" <<EOF
#!/bin/bash

echo "Restarting Arma 3 Server..."

$SERVER_DIR/stop_server.sh
sleep 5
$SERVER_DIR/start_server.sh
EOF

chmod +x "$SERVER_DIR/restart_server.sh"
echo -e "${GREEN}[OK]${NC} Restart script created"

# Backup database script
cat > "$SERVER_DIR/backup_database.sh" <<EOF
#!/bin/bash

TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/exile_\${TIMESTAMP}.sql"

echo "Backing up Exile database..."
mysqldump -u root -p$DB_ROOT_PASS $DB_NAME > "\$BACKUP_FILE"

echo "Backup saved to: \$BACKUP_FILE"

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t exile_*.sql | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
EOF

chmod +x "$SERVER_DIR/backup_database.sh"
echo -e "${GREEN}[OK]${NC} Backup script created"

# ========================================
# STEP 10: Configure Firewall
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 10: Configuring Firewall${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if command -v ufw &> /dev/null; then
    ufw allow 2302/udp comment "Arma3 Game Port"
    ufw allow 2304/udp comment "Arma3 Steam Port"
    ufw allow 2305/udp comment "Arma3 Query Port"
    ufw allow 3306/tcp comment "MySQL"
    echo -e "${GREEN}[OK]${NC} UFW rules added"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=2302/udp
    firewall-cmd --permanent --add-port=2304/udp
    firewall-cmd --permanent --add-port=2305/udp
    firewall-cmd --permanent --add-port=3306/tcp
    firewall-cmd --reload
    echo -e "${GREEN}[OK]${NC} Firewalld rules added"
else
    echo -e "${YELLOW}[WARNING]${NC} No firewall detected - configure manually"
fi

# ========================================
# STEP 11: Set Permissions
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 11: Setting Permissions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

chown -R steam:steam "$SERVER_DIR"
chmod +x "$ARMA_DIR/arma3server"

echo -e "${GREEN}[OK]${NC} Permissions set"

# ========================================
# STEP 12: Create systemd service
# ========================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 12: Creating systemd Service${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cat > /etc/systemd/system/exile-server.service <<EOF
[Unit]
Description=Arma 3 Exile Server
After=network.target mariadb.service

[Service]
Type=forking
User=steam
Group=steam
WorkingDirectory=$ARMA_DIR
ExecStart=$SERVER_DIR/start_server.sh
ExecStop=$SERVER_DIR/stop_server.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable exile-server

echo -e "${GREEN}[OK]${NC} Systemd service created"

# ========================================
# Installation Complete
# ========================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installation Summary:"
echo " Server Directory: $SERVER_DIR"
echo " Arma 3 Directory: $ARMA_DIR"
echo " Mods Directory:   $MODS_DIR"
echo ""
echo "Database Info:"
echo " Database: $DB_NAME"
echo " User:     $DB_USER"
echo " Password: $DB_PASS"
echo " Root PW:  $DB_ROOT_PASS"
echo ""
echo "Server Scripts:"
echo " Start Server:    $SERVER_DIR/start_server.sh"
echo " Stop Server:     $SERVER_DIR/stop_server.sh"
echo " Restart Server:  $SERVER_DIR/restart_server.sh"
echo " Backup Database: $SERVER_DIR/backup_database.sh"
echo ""
echo "Systemd Commands:"
echo " Start:   systemctl start exile-server"
echo " Stop:    systemctl stop exile-server"
echo " Restart: systemctl restart exile-server"
echo " Status:  systemctl status exile-server"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "========================================="
echo ""
echo "1. Install Exile Mod Files"
echo "2. Import exile.sql to database"
echo "3. Configure @ExileServer/extDB3/sql_custom_v2/exile.ini"
echo "4. Create/configure mission in mpmissions/"
echo "5. Start server: $SERVER_DIR/start_server.sh"
echo ""
echo "See SERVER_INSTALL_README.md for detailed instructions"
echo ""

# Save installation info
cat > "$SERVER_DIR/install.log" <<EOF
Arma 3 Exile Server Installation
Date: $(date)

Server Directory: $SERVER_DIR
Arma 3 Directory: $ARMA_DIR

Database: $DB_NAME
User: $DB_USER
Password: $DB_PASS
Root Password: $DB_ROOT_PASS

Admin Password: $ADMIN_PASSWORD
Server Port: $SERVER_PORT
EOF

chmod 600 "$SERVER_DIR/install.log"

echo "Installation log saved to: $SERVER_DIR/install.log"
echo ""
