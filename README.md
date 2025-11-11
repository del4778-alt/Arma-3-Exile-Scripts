# Elite AI Systems for Arma 3 Exile

A collection of advanced AI enhancement scripts for Arma 3 Exile servers, providing intelligent driving, patrol systems, and player AI recruits.

---

## 📦 **Quick Downloads**

Click on any system to view details and download individually:

| System | Version | Description | Download |
|--------|---------|-------------|----------|
| **[AI Recruit System](AI-Recruit-System/)** | v7.7.1 | 3 AI teammates per player with full lifecycle management | [📥 Download](AI-Recruit-System/recruit_ai.sqf) |
| **[AI Elite Driving](AI-Elite-Driving/)** | v1.0 | Enhanced AI vehicle handling and combat driving | [📥 Download](AI-Elite-Driving/AI_EliteDriving.sqf) |
| **[AI Patrol System](AI-Patrol-System/)** | v1.0 | Dynamic patrol routes with squad leader coordination | [📥 Download](AI-Patrol-System/fn_aiPatrolSystem.sqf) |
| **[Server Installers](Server-Installers/)** | v1.0 | Automated Exile server setup scripts (Windows/Linux) | [📁 View](Server-Installers/) |

---

## 🎯 **Featured: AI Recruit System v7.7.1**

### Latest Updates - Critical Bug Fixes

**[View Full Documentation →](AI-Recruit-System/)**

✅ **DUAL death detection** - Event handlers + backup polling
✅ **Parachute checks** - AI won't spawn mid-air and die
✅ **EXTENSIVE logging** - See exactly what's happening
✅ **Enhanced respawn** - Waits for player to land
✅ **Fixed group cleanup** - No memory leaks
✅ **Spawn cooldown** - Prevents cascading respawns

**Quick Install:**
```sqf
// initServer.sqf
if (isServer) then {
    execVM "scripts\recruit_ai.sqf";
};
```

---

## 📋 **All Systems Overview**

### 🤖 **[AI Recruit System](AI-Recruit-System/)**

**What it does:** Gives each player 3 AI teammates (Anti-Tank, Anti-Air, Sniper) with automatic spawning, death cleanup, and respawn handling.

**Features:**
- Dual death detection (instant + polling)
- Parachute/altitude awareness
- Vehicle seat assignment
- VCOMAI/A3XAI integration
- Extensive logging
- Strict 3 AI limit

**Perfect for:** Exile servers wanting to give players AI support without overpowering gameplay

**[📖 Read Full Documentation →](AI-Recruit-System/README.md)**

---

### 🚗 **[AI Elite Driving](AI-Elite-Driving/)**

**What it does:** Makes AI drivers act intelligently - slowing down in combat, adjusting for vehicle damage, and maintaining realistic speeds.

**Features:**
- Dynamic speed adjustment
- Threat-based behavior
- Vehicle-type awareness
- Combat vs safe modes
- Automatic headlights
- Damage-based reduction

**Perfect for:** Servers with AI missions (DMS, VEMF) wanting realistic vehicle behavior

**[📖 Read Full Documentation →](AI-Elite-Driving/README.md)**

---

### 🎯 **[AI Patrol System](AI-Patrol-System/)**

**What it does:** Creates dynamic patrol routes for AI squads with intelligent waypoint placement.

**Features:**
- Dynamic waypoint generation
- Squad leader coordination
- Looping patrol routes
- Configurable radius/waypoints
- Terrain awareness
- Building avoidance

**Perfect for:** Mission creators wanting AI to patrol areas naturally

**[📖 Read Full Documentation →](AI-Patrol-System/README.md)**

---

### 🖥️ **[Server Installers](Server-Installers/)**

**What it does:** Automated installation scripts for setting up a complete Arma 3 Exile server from scratch.

**Includes:**
- Windows installer (.bat)
- Linux installer (.sh)
- SteamCMD setup
- Arma 3 Dedicated Server
- MySQL/MariaDB database
- Configuration generation
- Startup/stop scripts

**Perfect for:** Backup solution if your rented server expires, or setting up a local test server

**[📖 Read Full Documentation →](Server-Installers/README.md)**

---

## 🚀 **Quick Start**

### **Option 1: Download Individual Scripts**

Navigate to the system you want:
- [AI-Recruit-System/](AI-Recruit-System/) → Download `recruit_ai.sqf`
- [AI-Elite-Driving/](AI-Elite-Driving/) → Download `AI_EliteDriving.sqf`
- [AI-Patrol-System/](AI-Patrol-System/) → Download `fn_aiPatrolSystem.sqf`

### **Option 2: Clone Entire Repository**

```bash
git clone https://github.com/del4778-alt/Arma-3-Exile-Scripts.git
```

### **Option 3: Download Specific Folder**

Use GitHub's interface:
1. Click on the folder you want
2. Click "Code" → "Download ZIP"
3. Extract only that folder

---

## 📁 **Repository Structure**

```
Arma-3-Exile-Scripts/
├── README.md (this file)
│
├── AI-Recruit-System/
│   ├── README.md
│   ├── recruit_ai.sqf
│   └── CHANGELOG_v7.7.md
│
├── AI-Elite-Driving/
│   ├── README.md
│   └── AI_EliteDriving.sqf
│
├── AI-Patrol-System/
│   ├── README.md
│   └── fn_aiPatrolSystem.sqf
│
└── Server-Installers/
    ├── README.md
    ├── install_exile_server.bat
    └── install_exile_server.sh
```

---

## ⚙️ **Installation Example**

Complete `initServer.sqf` with all three AI systems:

```sqf
// ===================================================================
// EXILE SERVER INITIALIZATION
// ===================================================================

if (!isServer) exitWith {};

diag_log "[SERVER] Starting Exile server initialization...";

// Wait for server to be ready
waitUntil {time > 0};
sleep 5;

// ===================================================================
// ELITE AI SYSTEMS
// ===================================================================

// Load Elite AI Driving
diag_log "[SERVER] Loading Elite AI Driving...";
[] execVM "scripts\AI_EliteDriving.sqf";

// Compile AI Patrol System Function
diag_log "[SERVER] Compiling AI Patrol System...";
fnc_aiPatrolSystem = compile preprocessFileLineNumbers "scripts\fn_aiPatrolSystem.sqf";

// Load Elite AI Recruit System
diag_log "[SERVER] Loading Elite AI Recruit System...";
execVM "scripts\recruit_ai.sqf";

diag_log "[SERVER] All Elite AI systems loaded!";
```

---

## 🎮 **Compatibility**

### ✅ **All Systems Compatible With:**
- Arma 3 v2.18+
- Exile Mod 1.0.4+
- DMS (Defent's Mission System)
- VEMF Reloaded
- A3XAI
- VCOMAI
- Ryan's Zombies
- Ravage Zombies

### ⚠️ **Potential Conflicts:**
- Other AI recruit scripts (remove before installing)
- Custom AI behavior overrides
- Scripts that modify player respawn

---

## 📊 **Performance Impact**

| System | CPU Usage | Memory | Network | Notes |
|--------|-----------|--------|---------|-------|
| **AI Recruit** | Minimal | Low | Low | 3 AI per player |
| **Elite Driving** | Very Low | Minimal | None | Server-side only |
| **Patrol System** | Low | Minimal | None | Calculated once |

**Combined Impact:** Suitable for servers with 60+ players

---

## 🆘 **Support**

### **Getting Help**

1. **Check the specific system's README** - Most issues are covered in detailed docs
2. **Review RPT logs** - Extensive logging helps identify issues
3. **GitHub Issues** - [Report bugs here](https://github.com/del4778-alt/Arma-3-Exile-Scripts/issues)

### **When Reporting Issues**

Include:
- Which system (Recruit/Driving/Patrol)
- Version number
- Server RPT logs (relevant sections)
- Mods installed
- Steps to reproduce

### **Resources**

- **Exile Forums:** https://www.exilemod.com/forums/
- **Exile Discord:** https://discord.gg/exile
- **Arma 3 Wiki:** https://community.bistudio.com/wiki/Arma_3

---

## 🔄 **Version History**

### **AI Recruit System**
- **v7.7.1** (Current) - Critical bug fixes, parachute checks, dual death detection
- **v7.7** - Event-based death detection, group cleanup fixes
- **v7.6** - Server-side monitoring
- **v7.0-7.5** - Initial releases

**[See Full Changelog →](AI-Recruit-System/CHANGELOG_v7.7.md)**

### **AI Elite Driving**
- **v1.0** - Side-specific configuration, dynamic speed adjustment

### **AI Patrol System**
- **v1.0** - Squad leader coordination, dynamic waypoints

### **Server Installers**
- **v1.0** - Windows and Linux automated installers

---

## 🤝 **Contributing**

Contributions are welcome! Please:

1. Test thoroughly on your server
2. Document any changes
3. Submit pull requests with clear descriptions
4. Include RPT logs for bug reports

---

## 📝 **License**

All scripts are provided free to use and modify for your Arma 3 Exile server.
Please give credit if you redistribute or modify.

---

## 🙏 **Credits**

- **Script Author:** del4778-alt
- **Exile Mod Team:** Framework and community
- **Arma 3 Community:** Support and inspiration
- **VCOMAI/A3XAI:** AI enhancement integration

---

## ⭐ **Show Your Support**

If these scripts helped your server:
- ⭐ Star this repository
- 🐛 Report bugs to help improve
- 💬 Share feedback in issues
- 🔗 Link to this repo in your server

---

## 📞 **Quick Links**

| Link | Description |
|------|-------------|
| [AI Recruit System](AI-Recruit-System/) | Player AI teammates |
| [AI Elite Driving](AI-Elite-Driving/) | Enhanced AI vehicle behavior |
| [AI Patrol System](AI-Patrol-System/) | Dynamic AI patrols |
| [Server Installers](Server-Installers/) | Automated server setup |
| [Report Bug](https://github.com/del4778-alt/Arma-3-Exile-Scripts/issues) | GitHub Issues |

---

**Repository Version:** 1.0
**Last Updated:** 2025
**Tested On:** Arma 3 v2.18+, Exile 1.0.4+

**Enjoy your enhanced AI systems!** 🚀
