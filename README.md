# Elite AI Systems for Arma 3 Exile

A collection of advanced AI enhancement scripts for Arma 3 Exile servers, providing intelligent driving, patrol systems, and player AI recruits.

## 📦 Contents

- **[AI Elite Driving](#ai-elite-driving)** - Enhanced AI vehicle handling and combat driving
- **[AI Patrol System](#ai-patrol-system)** - Dynamic patrol routes with squad leader coordination
- **[Elite AI Recruit System](#elite-ai-recruit-system)** - Player AI teammates with full lifecycle management

---

## 🚗 AI Elite Driving

### Description
Enhances AI driving behavior with realistic speeds, combat awareness, and side-specific configuration. AI will adjust speed based on threat level and vehicle type.

### Features
- ✅ Side-specific configuration (BLUFOR, OPFOR, Independent, Civilian)
- ✅ Dynamic speed adjustment based on threat level
- ✅ Vehicle-type awareness (light/heavy/armored)
- ✅ Combat vs. safe driving modes
- ✅ Automatic headlight control
- ✅ Damage-based speed reduction

### Installation

#### Step 1: Add Script to Mission
Place `AI_EliteDriving.sqf` in your mission folder:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    └── AI_EliteDriving.sqf
```

#### Step 2: Initialize from initServer.sqf
Add to your `initServer.sqf`:
```sqf
// Load Elite AI Driving
if (isServer) then {
    [] execVM "scripts\AI_EliteDriving.sqf";
};
```

### Configuration

Edit the script to choose which sides use enhanced driving:

```sqf
// Line ~15: Configure which sides use Elite Driving
ELITE_DRIVING_SIDES = [
    independent,  // AI missions (DMS, VEMF, etc.)
    east,         // OPFOR AI
    west          // BLUFOR AI
    // civilian   // Uncomment to include civilians
];
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ELITE_DRIVING_SIDES` | Array of sides that use enhanced driving | `[independent]` |
| Combat Speed | Speed when enemies nearby | 40 km/h |
| Safe Speed | Speed when no threats | 80 km/h |
| Update Interval | How often to check vehicles | 5 seconds |

---

## 🎯 AI Patrol System

### Description
Creates dynamic patrol routes for AI squads with intelligent waypoint placement and squad leader coordination.

### Features
- ✅ Dynamic waypoint generation
- ✅ Squad leader coordination
- ✅ Automatic patrol route creation
- ✅ Building and cover awareness
- ✅ Looping patrol routes
- ✅ Configurable patrol radius and waypoints

### Installation

#### Step 1: Add Script to Mission
Place `fn_aiPatrolSystem.sqf` in your mission folder:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    └── fn_aiPatrolSystem.sqf
```

#### Step 2: Compile Function
Add to your `initServer.sqf`:
```sqf
// Compile AI Patrol Function
if (isServer) then {
    fnc_aiPatrolSystem = compile preprocessFileLineNumbers "scripts\fn_aiPatrolSystem.sqf";
};
```

### Usage

#### Basic Patrol
```sqf
// Create patrol for a group around a position
[_aiGroup, _centerPosition, 200] call fnc_aiPatrolSystem;
```

#### Advanced Patrol
```sqf
// Full parameters
[
    _aiGroup,           // Group to patrol
    _centerPosition,    // Center of patrol area [x,y,z]
    _radius,           // Patrol radius in meters
    _waypointCount     // Number of waypoints (optional, default: 4)
] call fnc_aiPatrolSystem;
```

#### Example with DMS Mission
```sqf
// In your DMS mission file
_aiGroup = createGroup independent;
// ... spawn AI units ...

// Set up patrol
[_aiGroup, _missionCenter, 150, 6] call fnc_aiPatrolSystem;
```

### Configuration

```sqf
// Edit in script to customize behavior
_radius = _this select 2;              // Patrol radius
_waypointCount = _this param [3, 4];   // Number of waypoints (default: 4)
_waypointTimeout = [10, 20, 30];       // Time at each waypoint [min, mid, max]
```

### Features Explained

**Squad Leader:**
- First unit in group becomes squad leader
- Other units follow leader's commands
- Leader controls patrol route

**Dynamic Waypoints:**
- Placed around perimeter of patrol radius
- Avoid water and extreme terrain
- Return to start point on completion

---

## 👥 Elite AI Recruit System

### Description
**Version 7.6** - Comprehensive AI recruit system that gives each player 3 AI teammates with full lifecycle management, death cleanup, and respawn handling.

### Features
- ✅ **3 AI teammates per player** (AT, AA, Sniper)
- ✅ **Server-side death monitoring** - AI cleaned up instantly on death
- ✅ **Proven cleanup system** - Uses same reliable code as disconnect
- ✅ **Respawn handling** - Fresh AI spawn after respawn
- ✅ **Vehicle seat assignment** - AI automatically board vehicles
- ✅ **Strict 3 AI maximum** - Prevents duplicates
- ✅ **VCOMAI integration** - Auto-detects and configures
- ✅ **A3XAI blacklist** - Prevents AI mission conflicts
- ✅ **Extensive logging** - Easy troubleshooting

### Installation

#### Step 1: Add Script to Mission
Place `init_recruit.sqf` in your mission folder in a folder named addons:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    init_recruit.sqf
```

#### Step 2: Initialize from initServer.sqf
Add to your `initServer.sqf`:
```sqf
// Load Elite AI Recruit System
if (isServer) then {
    execVM "addons\init_recruit.sqf";
};
```

#### Step 3: Restart Server
Restart your server and check RPT logs for:
```
========================================
[AI RECRUIT] Elite AI Recruit System v7.6
  • Death cleanup = Disconnect cleanup
  • Server-side death monitoring
  • STRICT 3 AI maximum
  • Proven cleanup method
========================================
```

### Configuration

#### Change AI Types
Edit lines 34-38 in the script:
```sqf
RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",      // Anti-Tank (Titan Launcher)
    "I_Soldier_AA_F",      // Anti-Air (Titan AA)
    "I_Sniper_F"           // Sniper (Mk-I EMR)
];
```

**Popular AI Types:**
```sqf
// Medic Support
"I_medic_F"

// Machine Gunner
"I_Soldier_AR_F"

// Grenadier
"I_Soldier_GL_F"

// Marksman
"I_Soldier_M_F"

// Engineer
"I_engineer_F"

// Heavy Gunner
"I_HeavyGunner_F"
```

#### Adjust Death Check Interval
Edit line 605:
```sqf
sleep 5; // Check every 5 seconds for player deaths
```

- **3 seconds** = Very responsive (more CPU usage)
- **5 seconds** = Good balance (recommended)
- **10 seconds** = Less responsive (lighter CPU)

#### AI Skill Levels
Edit lines 132-138 for standard AI (non-VCOMAI):
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

### How It Works

#### 1. Player Joins Server
```
Player connects → Wait 10 seconds → Setup event handlers → Spawn 3 AI
```

#### 2. During Gameplay
```
Every 30 seconds → Check if player has 3 AI → Spawn missing AI if needed
AI dies → Wait 3 seconds → Respawn replacement AI
```

#### 3. Player Dies
```
Death detected (within 5 seconds) → Kill all AI → Delete AI → Clear tracking
```

#### 4. Player Respawns
```
Respawn → Clear old AI → Wait 5 seconds → Spawn 3 fresh AI
```

#### 5. Player Disconnects
```
Disconnect → Kill all AI → Delete AI → Clear tracking
```

### Troubleshooting

#### AI Not Spawning on Join
**Check:**
- Server RPT shows `[AI RECRUIT] System initialized`
- Player is fully spawned (not at spawn selection)
- No script errors in RPT

**Solution:**
```sqf
// Increase initial spawn delay (line 580)
sleep 10; // Change to sleep 15;
```

#### AI Not Cleaned Up on Death
**Check:**
- RPT shows `[AI RECRUIT] !!!!! DEATH DETECTED`
- Death monitoring loop is running

**Solution:**
Death cleanup happens within 5 seconds. If not working, check RPT logs for errors.

#### Group Ownership Warnings
**Issue:**
```
Warning: Adding units to a remote group is not safe
```

**Solution:**
Update to latest version - this is fixed in v7.6 with proper group ownership transfer.

#### Too Many AI After Multiple Deaths
**Check:**
- RPT logs show cleanup completing
- Global map is being cleared

**Solution:**
Script enforces strict 3 AI maximum. Extra AI are automatically deleted. Check RPT for:
```
[AI RECRUIT] WARNING: Player has 5 AI! Removing extras...
```

#### AI Not Following Player
**Check:**
- VCOMAI compatibility (auto-detected)
- A3XAI not interfering (auto-blacklisted)
- AI behavior settings

**Solution:**
```sqf
// Check RPT for:
[AI RECRUIT] VCOMAI Integration: ENABLED
```

### Performance Impact

| Aspect | Impact | Notes |
|--------|--------|-------|
| CPU Usage | Minimal | Checks every 5 seconds per player |
| Memory | Low | Uses efficient hashmap tracking |
| Network | Low | Only group synchronization |
| AI Count | 3 per player | 10 players = 30 AI maximum |

### Compatibility

#### ✅ Compatible With:
- Exile Mod (required)
- VCOMAI (auto-detected)
- A3XAI (auto-blacklisted)
- DMS Missions
- VEMF Reloaded
- Occupation
- Ryan's Zombies
- Ravage Zombies

#### ⚠️ May Conflict With:
- Other AI recruit scripts (remove them)
- Custom group management mods
- Scripts that modify player respawn

### Logs Reference

#### Successful Startup
```
[AI RECRUIT] Starting initialization v7.6...
[AI RECRUIT] VCOMAI Integration: ENABLED
[AI RECRUIT] System initialized
[AI RECRUIT] Setting up handlers for PlayerName
[AI RECRUIT] Player PlayerName needs 3 AI
[AI RECRUIT] Spawned I_Soldier_AT_F - Global map now has 1 AI
[AI RECRUIT] Spawned I_Soldier_AA_F - Global map now has 2 AI
[AI RECRUIT] Spawned I_Sniper_F - Global map now has 3 AI
```

#### Player Death
```
[AI RECRUIT] !!!!! DEATH DETECTED: PlayerName !!!!!
[AI RECRUIT] CLEANUP START: PlayerName (UID: xxxxx)
[AI RECRUIT] CLEANUP: Deleting 3 AI for PlayerName
[AI RECRUIT]   From map: 3, From var: 3, From group: 3
[AI RECRUIT]   Deleted: I_Soldier_AT_F
[AI RECRUIT]   Deleted: I_Soldier_AA_F
[AI RECRUIT]   Deleted: I_Sniper_F
[AI RECRUIT] Cleanup complete - 3 AI removed
```

#### Player Respawn
```
[AI RECRUIT] Player PlayerName RESPAWNED
[AI RECRUIT] Starting fresh AI spawn for PlayerName
[AI RECRUIT] Player PlayerName needs 3 AI
(spawning messages...)
```

---

## 🔧 Complete Installation Example

Here's a complete `initServer.sqf` with all three scripts:

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
execVM "addons\ai_recruit\init.sqf";

diag_log "[SERVER] All Elite AI systems loaded!";

// ===================================================================
// CONTINUE WITH OTHER INITIALIZATION
// ===================================================================
```

### Complete Folder Structure
```
Exile.Altis/
├── mission.sqm
├── description.ext
├── initServer.sqf
├── scripts/
│   ├── AI_EliteDriving.sqf
│   └── fn_aiPatrolSystem.sqf
    └── init_recruit.sqf

```

---

## 📊 Version History

### Elite AI Driving
- **Latest:** Side-specific configuration
- **Previous:** Applied to all AI vehicles

### AI Patrol System
- **Latest:** Added squad leader coordination
- **Previous:** Basic waypoint system

### Elite AI Recruit System
- **v7.6:** Server-side death monitoring, proven cleanup
- **v7.5:** Enhanced logging, 4-source tracking
- **v7.4:** Simplified cleanup
- **v7.0-7.3:** Initial versions

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Test thoroughly on your server
2. Document any changes
3. Submit pull requests with clear descriptions
4. Include RPT logs for bug reports

---

## 📝 License

Free to use and modify for your Arma 3 Exile server.  
Please give credit if you redistribute or modify.

---

## 🐛 Reporting Issues

When reporting issues, please include:
- **Server RPT logs** (relevant sections)
- **Script version** you're using
- **Mods installed** (DMS, A3XAI, VCOMAI, etc.)
- **Steps to reproduce** the issue
- **Expected vs actual behavior**

---

## 📞 Support

For support and updates:
- Check RPT logs first
- Review troubleshooting sections
- Ensure you're using latest versions
- Test scripts individually before combining

---

## 🎯 Credits

- **Elite AI Driving:** Enhanced vehicle AI behavior
- **AI Patrol System:** Dynamic patrol route generation
- **Elite AI Recruit System:** Complete player AI teammate solution
- **Exile Mod:** Community and server framework
- **VCOMAI/A3XAI:** AI enhancement integration

---

## ⚡ Quick Start Checklist

- [ ] Download all three scripts
- [ ] Place in correct folders
- [ ] Add initialization to initServer.sqf
- [ ] Configure side settings (Elite Driving)
- [ ] Configure AI types (Recruit System)
- [ ] Restart server
- [ ] Check RPT logs for successful initialization
- [ ] Test in-game functionality
- [ ] Monitor performance

---

**Enjoy your enhanced AI systems!** 🚀
