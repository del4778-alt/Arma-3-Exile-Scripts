# Dynamic Mission System v2.0 - ENHANCED EDITION

**AI-driven missions with comprehensive performance optimizations, advanced AI, enhanced loot, and dynamic gameplay features inspired by DMS Exile & A3 Exile Occupation.**

---

## 🚀 What's New in v2.0?

### **Performance Optimizations** ⚡
- **AI Freezing System** - Units freeze when 3500m+ from players, unfreezing on proximity (massive FPS gains)
- **FPS-Based Spawn Control** - Automatically halts spawning below 15 FPS threshold
- **Player-Scaled AI** - Dynamically reduces max AI count as more players join
- **Terrain Validation** - Prevents spawns on steep slopes (surface normal checking)
- **Spawn Throttling** - Adaptive position finding that relaxes constraints after failed attempts

### **Advanced AI System** 🎯
- **5-Tier Difficulty** - Static (0.20), Easy (0.30), Moderate (0.60), Difficult (0.70), Hardcore (1.00)
- **AI Class Types** - Assault (rifles), Machine Gunner (LMGs), Sniper (precision rifles)
- **Random Skill Distribution** - 10% hardcore, 30% difficult, 40% moderate, 20% easy
- **Class-Specific Loadouts**:
  - Assault: 75% optics, 25% bipods, GPS
  - Machine Gunner: 50% optics, 90% bipods, binoculars, backpack
  - Sniper: 100% optics, 90% bipods, rangefinder, GPS

### **Enhanced Loot System** 💰
- **60+ Weapon Variants** (up from 5):
  - 30+ vanilla weapons
  - 22 Marksman DLC weapons (optional)
  - 8 Apex DLC weapons (optional)
- **20+ Consumables** - 14 food types, 6 beverages
- **Medical Supplies** - InstaDoc, Bandages, Vishpirin, FirstAidKits
- **Building Materials** - Wood planks, metal boards, cement, wiring
- **Rare Items** - 10% spawn chance for safes, code locks, laptops
- **7+ Backpack Types** - Varying capacities and models

### **Reward System** 🏆
- **Distance Bonuses** - +0.05 respect per meter beyond 100m kills
- **Unit-Type Rewards**:
  - Soldiers: 50 poptabs, 10 respect
  - Gunners: 100 poptabs, 20 respect
  - Snipers: 150 poptabs, 30 respect
  - Crew: 200 poptabs, 40 respect
- **Skill Tier Multipliers** - Hardcore kills worth 2.5x rewards

### **Mission Features** 🎮
- **Reinforcement Waves** - 30% chance for helicopter insertions (2-5min delay, 4-6 troops)
- **Mine Fields** - 25% of missions spawn 5-25 mines based on difficulty
- **Variable Spawn Timing** - Random intervals (8-12min) instead of fixed
- **Timeout Reset** - Missions extend timer by 5min when players within 1500m
- **4 Difficulty Tiers** - Easy, Moderate, Difficult, Hardcore

### **Cleanup System** 🧹
- **Timed Removal** - Objects removed after 1 hour, vehicles after 5 minutes
- **Player Proximity Protection** - No cleanup within 20m of players
- **Automatic Rescheduling** - Delays cleanup if players approach

### **Map-Specific Configs** 🗺️
- Altis: 120 max AI, 10min spawn intervals
- Tanoa: 80 max AI, 8min spawn intervals
- Malden: 70 max AI, 7min spawn intervals

---

## 📋 Mission Types

### **1. Crash Site**
- Wrecked helicopter with loot crates
- Mixed AI: 70% assault, 30% snipers
- AI Count: 3-16 (scales with difficulty)
- **Difficulty**: Easy/Moderate/Difficult/Hardcore
- **Features**: Mines, Reinforcements

### **2. Supply Cache**
- 2-5 loot crates (scales with difficulty)
- Mixed AI: 50% assault, 30% MG, 20% snipers
- AI Count: 4-16
- **Difficulty**: Easy/Moderate/Difficult/Hardcore
- **Features**: Mines, Reinforcements

### **3. Convoy Intercept**
- 2-4 armed vehicles traveling across map
- Moving markers that update in real-time
- Vehicle crew + cargo troops
- Loot stored in last vehicle
- **Difficulty**: Moderate/Difficult/Hardcore only
- **Features**: Reinforcements

### **4. Rescue Hostages**
- 2-5 hostages in holding area
- Mixed AI: 60% assault, 30% MG, 10% snipers
- Must eliminate AI and approach hostages
- AI Count: 4-15
- **Difficulty**: Easy/Moderate/Difficult/Hardcore
- **Features**: Mines, Reinforcements

### **5. AI Camp**
- Fortified position with barriers
- 3-5 loot crates
- Armed vehicle
- Heavy resistance: 50% assault, 30% MG, 20% snipers
- AI Count: 10-24
- **Difficulty**: Moderate/Difficult/Hardcore only
- **Features**: Mines, Reinforcements

---

## ⚙️ Configuration

Edit `MISSION_CONFIG` in `fn_dynamicMissions.sqf`:

### Core Settings
```sqf
["enabled", true],                    // Enable/disable system
["debug", true],                      // Show debug messages
["minPlayers", 1],                    // Min players for spawning
["maxActiveMissions", 3],             // Max concurrent missions
```

### Spawn Timing (Variable)
```sqf
["spawnIntervalMin", 480],            // 8 minutes min
["spawnIntervalMax", 720],            // 12 minutes max
["missionTimeoutMin", 1800],          // 30 min timeout min
["missionTimeoutMax", 2700],          // 45 min timeout max
["timeoutResetDistance", 1500],       // Extend timer if player within this
["timeoutResetAmount", 300],          // Add 5 min when players nearby
```

### Spawn Validation (Enhanced)
```sqf
["safeZoneDistance", 2500],           // Distance from safe zones
["minPlayerDistance", 2000],          // Distance from players
["waterDistance", 500],               // Distance from water
["mapBorderDistance", 250],           // Distance from map edge
["maxSpawnAttempts", 5000],           // Max position attempts
["throttleInterval", 15],             // Relax constraints every X attempts
["minSurfaceNormal", 0.9],            // Max terrain slope (0.9 = ~25°)
```

### Performance
```sqf
["enableAIFreezing", true],           // Freeze distant AI
["aiFreezeDistance", 3500],           // Freeze distance
["aiFreezeCheckInterval", 15],        // Check every 15s
["enableFPSControl", true],           // Block spawns on low FPS
["minFPS", 15],                       // Minimum FPS threshold
["enablePlayerScaling", true],        // Scale AI with player count
["playerScaleThreshold", 10],         // Start scaling above 10 players
["playerScaleReduction", 10],         // Reduce max AI by 10 per player
```

### Rewards
```sqf
["enableDistanceBonus", true],        // Distance-based bonuses
["distanceBonusStart", 100],          // Start bonus after 100m
["distanceBonusPerMeter", 0.05],      // +0.05 respect per meter

// Unit Type Rewards [poptabs, respect]
["rewardSoldier", [50, 10]],
["rewardGunner", [100, 20]],
["rewardSniper", [150, 30]],
["rewardCrew", [200, 40]],
```

### AI System
```sqf
// 5-Tier Skill Levels
["skillStatic", 0.20],
["skillEasy", 0.30],
["skillModerate", 0.60],
["skillDifficult", 0.70],
["skillHardcore", 1.00],

// Random Distribution [tier, weight]
["aiDistribution", [
    ["hardcore", 10],                 // 10%
    ["difficult", 30],                // 30%
    ["moderate", 40],                 // 40%
    ["easy", 20]                      // 20%
]],
```

### Reinforcements
```sqf
["enableReinforcements", true],
["reinforcementChance", 30],          // 30% chance per mission
["reinforcementDelay", [120, 300]],   // 2-5 minutes delay
["reinforcementCount", [4, 6]],       // 4-6 troops
["reinforcementHeight", 500],         // Helicopter altitude
["reinforcementRadius", [500, 5000]], // Drop radius
```

### Mine Fields
```sqf
["enableMineFields", true],
["mineFieldChance", 25],              // 25% of missions
["minesEasy", [5, 50]],               // [count, radius in meters]
["minesMedium", [10, 60]],
["minesHard", [15, 80]],
["minesHardcore", [25, 100]],
```

### DLC Support
```sqf
["enableMarksman", true],             // +22 weapons
["enableApex", true],                 // +8 weapons
```

### Cleanup
```sqf
["cleanupObjectTime", 3600],          // 1 hour for objects
["cleanupVehicleTime", 300],          // 5 min for vehicles
["cleanupPlayerDistance", 20],        // Don't cleanup near players
["cleanupCheckInterval", 60],         // Check every 60s
```

---

## 📦 Installation

1. **Place Files**
   ```
   YourMission/
   └── Dynamic-Mission-System/
       ├── fn_dynamicMissions.sqf
       └── README.md
   ```

2. **Add to init.sqf**
   ```sqf
   [] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
   ```

3. **Configure** (optional)
   - Edit `MISSION_CONFIG` in `fn_dynamicMissions.sqf`
   - Adjust difficulty, rewards, spawn rates, etc.

4. **Test**
   - Join server as player
   - Missions spawn after 8-12 minutes
   - Check map for mission markers

---

## 🎮 Gameplay

### For Players

**Finding Missions:**
- Red markers appear on map
- Text format: `Mission Type [DIFFICULTY]`
- Examples: "Crash Site [HARDCORE]", "Convoy [DIFFICULT]"

**Completing Missions:**
1. Travel to mission location
2. Eliminate all AI (watch for reinforcements!)
3. Avoid mines (use MineDetector)
4. Collect loot from crates/vehicles
5. Mission completes when all AI dead

**Rewards:**
- Base rewards: Poptabs + Respect
- Difficulty multiplier: Hardcore = 2.5x
- Distance bonus: +0.05 respect per meter beyond 100m
- Example: 300m hardcore sniper kill = 150 poptabs, 30 respect, +10 distance bonus = **40 total respect**

**Tips:**
- Long-range kills = better rewards
- Hardcore missions = highest loot quality
- Watch for reinforcement helicopters (announced in chat)
- Mines spawn in 25% of missions
- Convoys move - intercept early!

### For Server Admins

**Performance Monitoring:**
- Check server FPS (missions pause below threshold)
- AI freeze at 3500m (logged in debug mode)
- Max AI scales with player count

**Troubleshooting:**

Mission not spawning?
- Check `minPlayers` requirement
- Verify `enabled` = true
- Check max AI limit (player scaling)
- Review spawn position logs (throttling attempts)

AI frozen?
- Normal if >3500m from players
- Unfreeze when players approach

Low FPS?
- System auto-pauses spawning
- Reduce `maxActiveMissions`
- Lower difficulty (less AI)
- Enable `enablePlayerScaling`

---

## 🔧 Advanced Features

### AI Freezing
Automatically freezes AI groups >3500m from players:
- Saves server FPS
- Unfreezes when players approach
- Logged in debug mode

### Spawn Throttling
Adaptive position finding:
- Starts with strict constraints
- Relaxes every 15 attempts
- Player distance: 2000m → 100m (min)
- Safe zone distance: 2500m → 100m (min)
- Surface normal: 0.9 → 0.75 (min)

### Cleanup Queue
Timed removal system:
- Objects queued after mission ends
- Checks player proximity before deletion
- Reschedules if players nearby
- Separate timers for objects/vehicles

### Map-Specific Configs
Override settings per map:
```sqf
["mapConfigs", createHashMapFromArray [
    ["YourMap", createHashMapFromArray [
        ["maxAI", 100],
        ["spawnIntervalMin", 500]
    ]]
]]
```

---

## 📊 Statistics

**AI System:**
- 5 difficulty tiers
- 3 class types (Assault/MG/Sniper)
- Random skill distribution
- Class-specific loadouts

**Loot System:**
- 60+ weapons (with DLC)
- 20+ consumables
- 10% rare item chance
- 7+ backpack types

**Missions:**
- 5 mission types
- 3-4 difficulty levels per type
- 30% reinforcement chance
- 25% mine field chance

**Performance:**
- AI freezing at 3500m
- FPS-based spawn control
- Player-scaled AI limits
- Map-specific optimizations

---

## 🐛 Known Issues

1. **Reinforcement helicopters may not land** - Waypoint issue, troops will paradrop
2. **Convoy vehicles may get stuck** - Arma pathfinding limitation
3. **Exile reward integration** - Commented out, needs server-side implementation

---

## 📝 Changelog

### v2.0.0 (2025-01-18) - MAJOR UPDATE
**Added:**
- AI freezing system (3500m distance)
- FPS-based spawn control (15 FPS min)
- Player-scaled AI (dynamic max AI)
- Terrain validation (slope checking)
- Spawn throttling (adaptive constraints)
- 5-tier AI difficulty system
- AI class types (Assault/MG/Sniper)
- 60+ weapons (with DLC support)
- 20+ consumables
- Rare items system (10% chance)
- Distance-based rewards (+0.05 respect/m)
- Unit-type rewards (soldier/gunner/sniper/crew)
- Reinforcement waves (helicopter insertions)
- Mine fields (5-25 mines)
- Variable spawn timing (8-12min)
- Timeout reset (extend on player proximity)
- Comprehensive cleanup system
- Map-specific configs (Altis/Tanoa/Malden)
- Convoy mission type (enhanced)
- Rescue mission type (enhanced)
- Camp mission type (enhanced)

**Changed:**
- Spawn validation (multi-layer blacklist)
- Safe zone distance: 1000m → 2500m
- Player distance: 500m → 2000m
- AI skills now randomized per unit
- Loot tables massively expanded
- Missions now have 4 difficulty tiers

**Performance:**
- Massive FPS gains from AI freezing
- Dynamic AI limits prevent overload
- Adaptive spawn finding reduces lag spikes

### v1.1 (2025-01-15)
- Fixed convoy AI frozen/unresponsive issue
- Added delayed activation for convoy vehicles

### v1.0 (2025-01-10)
- Initial release
- 5 mission types
- Basic AI system
- Simple loot tables

---

## 🙏 Credits

**Inspired by:**
- [DMS Exile](https://github.com/Defent/DMS_Exile) - Advanced mission framework
- [A3 Exile Occupation](https://github.com/secondcoming/a3_exile_occupation) - Performance optimizations

**Features adapted from DMS Exile:**
- AI freezing system
- 5-tier difficulty
- Enhanced loot tables
- Reinforcement mechanics
- Mine fields
- Cleanup system

**Features adapted from A3 Exile Occupation:**
- FPS-based spawn control
- Player-scaled AI
- Terrain validation

**Original work:**
- Mission integration
- Convoy system
- Exile compatibility
- Configuration structure

---

## 📜 License

Free to use and modify. Credit appreciated but not required.

---

## 💬 Support

**Issues?**
- Enable debug mode: `["debug", true]`
- Check server logs: `diag_log` entries
- Review configuration settings
- Test with `minPlayers = 1` for solo testing

**Questions?**
- Check configuration comments
- Review mission type descriptions
- Consult troubleshooting section

---

**Enjoy the enhanced mission system! Good hunting! 🎯**
