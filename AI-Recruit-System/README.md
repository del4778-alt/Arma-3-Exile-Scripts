# Elite AI Recruit System v7.14

**Comprehensive AI recruit system that gives each player 3 AI teammates with full lifecycle management, death cleanup, respawn handling, and vehicle compatibility.**

![Version](https://img.shields.io/badge/version-7.14-blue.svg)
![Arma 3](https://img.shields.io/badge/Arma%203-v2.18+-green.svg)
![Exile](https://img.shields.io/badge/Exile-1.0.4+-orange.svg)

---

## 🎯 Features

### Core Features
- ✅ **3 AI teammates per player** (Anti-Tank, Anti-Air, Sniper)
- ✅ **EVENT-BASED death detection** - Instant cleanup (Killed + MPKilled events)
- ✅ **BACKUP POLLING** - 5-second fallback if events fail
- ✅ **Parachute/altitude checks** - AI won't spawn mid-air and die
- ✅ **Fixed group cleanup** - Prevents memory leaks
- ✅ **Spawn cooldown system** - Prevents cascading respawns (5 seconds)
- ✅ **Enhanced spawn lock** - Auto-recovery from stuck locks (30 second timeout)

### Advanced Features
- ✅ **Respawn handling** - Fresh AI spawn after player respawn
- ✅ **Vehicle seat assignment** - AI automatically board vehicles
- ✅ **Vehicle compatibility** - Works perfectly with Elite Driving System
- ✅ **Passenger retention** - AI stay in vehicles unless player exits
- ✅ **Driver AI isolation** - FSM doesn't interfere with AI drivers
- ✅ **Strict 3 AI maximum** - Prevents duplicates
- ✅ **VCOMAI integration** - Auto-detects and configures
- ✅ **A3XAI blacklist** - Prevents AI mission conflicts
- ✅ **AI type validation** - Catches config errors early
- ✅ **EXTENSIVE LOGGING** - See exactly what's happening

---

## 📥 Quick Download

**Download just this script:**
- [recruit_ai.sqf](recruit_ai.sqf) - Right-click → Save As

**Or clone the repository:**
```bash
git clone https://github.com/del4778-alt/Arma-3-Exile-Scripts.git
cd Arma-3-Exile-Scripts/AI-Recruit-System
```

---

## 🚀 Installation

### Step 1: Add Script to Mission

Place `recruit_ai.sqf` in your mission folder:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    └── recruit_ai.sqf
```

### Step 2: Initialize from initServer.sqf

Add to your `initServer.sqf`:
```sqf
// Load Elite AI Recruit System
if (isServer) then {
    execVM "scripts\recruit_ai.sqf";
};
```

### Step 3: Restart Server

Restart your server and check RPT logs for:
```
========================================
[AI RECRUIT] Elite AI Recruit System v7.7.1
  • EVENT-BASED death detection (Killed + MPKilled)
  • BACKUP POLLING death detection (fallback)
  • Parachute/altitude checks (no mid-air spawns)
  • Fixed group cleanup logic
  • Spawn cooldown (5s) prevents cascading
  • Enhanced spawn lock with timeout
  • EXTENSIVE LOGGING for debugging
  • AI type validation
  • STRICT 3 AI maximum
========================================
```

---

## ⚙️ Configuration

### Change AI Types

Edit lines 40-44 in `recruit_ai.sqf`:
```sqf
RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",      // Anti-Tank (Titan Launcher)
    "I_Soldier_AA_F",      // Anti-Air (Titan AA)
    "I_Sniper_F"           // Sniper (Mk-I EMR)
];
```

**Popular AI Types:**
```sqf
"I_medic_F"           // Medic Support
"I_Soldier_AR_F"      // Machine Gunner
"I_Soldier_GL_F"      // Grenadier
"I_Soldier_M_F"       // Marksman
"I_engineer_F"        // Engineer
"I_HeavyGunner_F"     // Heavy Gunner
```

### Adjust AI Skills

Edit lines 196-202 for standard AI (non-VCOMAI):
```sqf
{
    _unit setSkill [_x, 1.0];  // Change 1.0 to 0.1-1.0
} forEach [
    "aimingAccuracy",  // 0.1 = poor aim, 1.0 = perfect aim
    "aimingShake",     // 0.1 = shaky, 1.0 = steady
    "spotDistance",    // 0.1 = blind, 1.0 = eagle eyes
    "courage"          // 0.1 = coward, 1.0 = fearless
];
```

### Adjust Maintenance Loop

Edit line 757 to change check frequency:
```sqf
sleep 5;  // Check every 5 seconds (recommended)
```

- **3 seconds** = Very responsive (more CPU usage)
- **5 seconds** = Good balance (recommended)
- **10 seconds** = Less responsive (lighter CPU)

---

## 📊 How It Works

### Player Joins Server
```
Player connects → Wait 10s → Setup event handlers → Spawn 3 AI
```

### During Gameplay
```
Every 30 seconds → Check if player has 3 AI → Spawn missing if needed
AI dies → Wait 3s (cooldown) → Respawn replacement AI
```

### Player Dies
```
Death event fires → INSTANT cleanup of all AI → Delete from tracking
Backup polling (5s) → Also detects death if event fails
```

### Player Respawns
```
Respawn event → Clear old AI → Wait for landing → Spawn 3 fresh AI
```

### Player Disconnects
```
Disconnect event → Kill all AI → Delete AI → Clear tracking
```

---

## 🐛 Troubleshooting

### AI Not Spawning on Join

**Check RPT logs for:**
```
[AI RECRUIT] System initialized
[AI RECRUIT] Setting up handlers for PlayerName
```

**Solutions:**
- Ensure player is fully spawned (not at spawn selection)
- Check for script errors in RPT
- Verify script is in correct folder

### AI Not Cleaned Up on Death

**Check RPT logs for:**
```
[AI RECRUIT] !!!!! DEATH DETECTED (Killed Event): PlayerName !!!!!
```
OR
```
[AI RECRUIT] !!!!! DEATH DETECTED (BACKUP POLLING): PlayerName !!!!!
```

**If no death detection logs:**
- Event handlers may not be registered
- Check for script errors during initialization

### AI Spawning in Air and Dying

**Check RPT logs for:**
```
[AI RECRUIT] Player Admin is in air (altitude: 125m) - waiting for landing
[AI RECRUIT] Player Admin landed - spawning fresh AI
```

**v7.7.1 includes:**
- Altitude checks (>3m = wait)
- Parachute detection
- Respawn waits up to 60 seconds for landing

### Group Ownership Warnings

**You may see:**
```
[AI RECRUIT] WARNING: Failed to transfer group ownership for Admin - continuing anyway
[AI RECRUIT] Units will be created in client-owned group (this is usually fine)
```

**This is normal** - AI will still work correctly. Group ownership transfer often fails on Exile servers but doesn't affect functionality.

### Too Many AI

**Check RPT logs for:**
```
[AI RECRUIT] WARNING: Player Admin has 5 AI! Removing extras...
```

Script automatically enforces 3 AI maximum. Extras are deleted.

---

## 📝 Expected RPT Log Output

### Successful Startup
```
[AI RECRUIT] ========================================
[AI RECRUIT] Starting initialization v7.7.1...
[AI RECRUIT] ========================================
[AI RECRUIT] VCOMAI not detected - Using standard AI
[AI RECRUIT] Validating AI types...
[AI RECRUIT] Validated AI type: I_Soldier_AT_F
[AI RECRUIT] Validated AI type: I_Soldier_AA_F
[AI RECRUIT] Validated AI type: I_Sniper_F
[AI RECRUIT] System initialized
[AI RECRUIT] Death detection: EVENT-BASED + BACKUP POLLING
```

### Player Death
```
[AI RECRUIT] !!!!! DEATH DETECTED (Killed Event): PlayerName !!!!!
========================================
[AI RECRUIT] *** CLEANUP START: PlayerName (UID: xxxxx) ***
========================================
[AI RECRUIT] Player object lookup: FOUND
[AI RECRUIT] Source 1 (Global Map): 3 AI found
[AI RECRUIT] Source 2 (Player Variable): 3 AI found
[AI RECRUIT] Source 3 (Player Group): 3 AI found
[AI RECRUIT] Total unique AI to delete: 3
[AI RECRUIT]   Deleted: I_Soldier_AT_F
[AI RECRUIT]   Deleted: I_Soldier_AA_F
[AI RECRUIT]   Deleted: I_Sniper_F
[AI RECRUIT]   Deleted empty group: B Alpha 1-1
========================================
[AI RECRUIT] *** CLEANUP COMPLETE for PlayerName ***
[AI RECRUIT] Results: 3 AI deleted, 1 groups cleaned
========================================
```

### Player Respawn
```
========================================
[AI RECRUIT] *** PLAYER RESPAWNED: PlayerName (UID: xxxxx) ***
========================================
[AI RECRUIT] Good: No orphaned AI found (cleanup worked correctly)
[AI RECRUIT] Player PlayerName landed - spawning fresh AI
[AI RECRUIT] Player PlayerName needs 3 AI (has 0)
[AI RECRUIT] Spawned I_Soldier_AT_F for PlayerName - Global map now has 1 AI
[AI RECRUIT] Spawned I_Soldier_AA_F for PlayerName - Global map now has 2 AI
[AI RECRUIT] Spawned I_Sniper_F for PlayerName - Global map now has 3 AI
[AI RECRUIT] Team spawn complete for PlayerName - now has 3 AI
```

---

## 🔄 Version History

### v7.7.1 (Current) - Critical Bug Fixes
- ✅ DUAL death detection (Killed + MPKilled events + backup polling)
- ✅ Parachute/altitude checks (no mid-air spawns)
- ✅ EXTENSIVE logging for debugging
- ✅ Enhanced respawn handling (waits for landing)
- ✅ Fixed group cleanup logic
- ✅ Spawn cooldown (5s) prevents cascading respawns

### v7.7 - Comprehensive Improvements
- ✅ EVENT-BASED death detection
- ✅ Fixed group cleanup
- ✅ Spawn cooldown system
- ✅ Enhanced spawn lock
- ✅ Optimized array operations
- ✅ AI type validation

### v7.6 - Server-Side Monitoring
- Server-side death monitoring
- Proven cleanup system

See [CHANGELOG_v7.7.md](CHANGELOG_v7.7.md) for detailed changes.

---

## 🎮 Compatibility

### ✅ Compatible With:
- **Exile Mod** (required)
- **VCOMAI** (auto-detected)
- **A3XAI** (auto-blacklisted)
- **DMS Missions**
- **VEMF Reloaded**
- **Occupation**
- **Ryan's Zombies**
- **Ravage Zombies**

### ⚠️ May Conflict With:
- Other AI recruit scripts (remove them)
- Custom group management mods
- Scripts that modify player respawn

---

## 📈 Performance

| Aspect | Impact | Notes |
|--------|--------|-------|
| CPU Usage | Minimal | Checks every 5 seconds per player |
| Memory | Low | Efficient hashmap tracking |
| Network | Low | Only group synchronization |
| AI Count | 3 per player | 10 players = 30 AI maximum |

---

## 🆘 Support

### Reporting Issues
Include:
- Server RPT logs (relevant sections)
- Script version (v7.7.1)
- Mods installed (DMS, A3XAI, VCOMAI, etc.)
- Steps to reproduce
- Expected vs actual behavior

### Resources
- **GitHub Issues:** [Report a bug](https://github.com/del4778-alt/Arma-3-Exile-Scripts/issues)
- **Exile Forums:** https://www.exilemod.com/forums/
- **Exile Discord:** https://discord.gg/exile

---

## 📄 License

Free to use and modify for your Arma 3 Exile server.
Please give credit if you redistribute.

---

## 🙏 Credits

- **Script Author:** del4778-alt
- **Exile Mod:** Community and framework
- **VCOMAI/A3XAI:** AI enhancement integration

---

**Last Updated:** 2025
**Version:** 7.7.1
**Tested On:** Arma 3 v2.18+, Exile 1.0.4+
