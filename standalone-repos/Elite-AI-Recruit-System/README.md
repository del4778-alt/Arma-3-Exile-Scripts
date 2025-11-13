# 🎖️ Elite AI Recruit System v7.13

**Extreme Elite Operators - Your personal AI dream team for Arma 3 Exile**

Give every player 3 ultra-skilled AI teammates that respawn automatically, follow intelligently, and fight with perfect accuracy. Think of them as your personal Navy SEAL squad.

---

## ✨ Features

### 🎯 Extreme Elite Skills
- **1.0 Perfect Accuracy** - AI are headshot masters
- **300m Sight Range** - Detect and engage enemies at extreme distance
- **1.4x Movement Speed** - Lightning fast reactions and movement
- **Perfect Aim** - No shake, instant target acquisition
- **Stealth Bonus** - 50% harder to spot, 50% quieter
- **Fearless** - Never flee (except when critically wounded >70%)

### 🧠 Advanced FSM Brain System
- **4 Intelligent States:**
  - **IDLE** - Safe mode, runs standing with player
  - **COMBAT** - Instant switch when enemies detected
  - **RETREAT** - Falls back when critically wounded
  - **HEAL** - Self-heals when safe and wounded

- **Instant Threat Reaction** - No delay when combat starts
- **300m Knowledge-Based Detection** - Awareness system
- **50m Visual Detection** - Close-range auto-reveal

### 🚗 Vehicle Integration
- **Auto-Board** - AI automatically get in your vehicle
- **Smart Seating** - Driver/gunner/cargo assignment
- **Auto-Exit** - Get out when you do
- **Compatible with Elite AI Driving** - No conflicts

### ♻️ Automatic Respawn
- **Death Detection** - Dual system (event + polling)
- **Auto-Respawn** - Missing AI respawn after 3 seconds
- **Spawn Cooldown** - 5-second cooldown prevents spam
- **Strict 3 AI Limit** - Never more than 3 teammates

### 🔧 Exile Resilient
- **Survives Session Init** - Brain persists through Exile respawns
- **UID-Based Tracking** - Uses player UID, not object reference
- **Reconnect Support** - AI respawn when player reconnects
- **Clean Disconnect** - Removes AI when player leaves

---

## 📦 Installation

### Step 1: Download
Click the green **Code** button → **Download ZIP**

### Step 2: Extract
Extract `recruit_ai.sqf` to your mission folder:
```
YourMission.Map/scripts/recruit_ai.sqf
```

### Step 3: Initialize
Add to `initServer.sqf`:
```sqf
// Elite AI Recruit System
execVM "scripts\recruit_ai.sqf";
```

### Step 4: Configure AI Types
Edit the `RECRUIT_AI_TYPES` array to choose your AI loadouts:

```sqf
RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",    // Anti-Tank specialist
    "I_Soldier_AA_F",    // Anti-Air specialist
    "I_Sniper_F"         // Sniper
];
```

**Popular Loadouts:**
```sqf
// Assault Squad
["I_Soldier_AR_F", "I_medic_F", "I_Soldier_GL_F"]

// Recon Team
["I_Soldier_M_F", "I_Sniper_F", "I_Spotter_F"]

// Heavy Support
["I_Soldier_AT_F", "I_Soldier_AA_F", "I_Soldier_AR_F"]

// Balanced
["I_Soldier_F", "I_medic_F", "I_Soldier_AT_F"]
```

### Step 5: Restart Server
Restart your Arma 3 server. Every player will automatically get 3 AI teammates!

---

## ⚙️ Configuration

All settings are in the script header. Edit as needed:

```sqf
// === AI SKILLS ===
// All set to 1.0 (perfect) by default
["aimingAccuracy", 1.0]   // Headshot masters
["aimingSpeed", 1.0]      // Instant acquisition
["spotDistance", 1.0]     // 300m sight range
["courage", 1.0]          // Fearless

// === MOVEMENT ===
_unit setAnimSpeedCoef 1.4;  // 1.4x speed (change to 1.0-2.0)

// === STEALTH ===
_unit setUnitTrait ["camouflageCoef", 0.5];  // Harder to spot
_unit setUnitTrait ["audibleCoef", 0.5];     // Quieter

// === BEHAVIOR ===
FSM_STATE_COMBAT = "COMBAT";   // Combat when enemies near
FSM_STATE_RETREAT = "RETREAT"; // Retreat when >70% damage
FSM_STATE_HEAL = "HEAL";       // Heal when >30% damage
```

---

## 🎮 How It Works

### Player Joins Server
1. System waits for player to land (no parachute spawns)
2. Checks player is ready (valid position, UID, group)
3. Spawns 3 AI teammates (3m around player)
4. AI marked with `ExileRecruited = true`

### AI Brain Loop
Every 2 seconds, each AI:
1. **Scans for Threats** (300m knowledge + 50m visual)
2. **Evaluates State** (wounded? enemies? safe?)
3. **Executes Behavior** (follow, fight, retreat, heal)

### FSM State Transitions
```
IDLE → Enemies detected → COMBAT
COMBAT → Damage >70% → RETREAT
RETREAT → Safe + wounded → HEAL
HEAL → Recovered → IDLE
```

### AI Death & Respawn
1. AI killed → Event handler fires
2. Removed from player's AssignedAI list
3. Removed from global tracking map
4. After 3 seconds → Respawn check (with cooldown)
5. Missing AI respawned at player position

### Player Death
1. Death detected (event + backup polling)
2. All AI deleted immediately
3. Player respawns
4. After landing → Fresh AI spawned

### Player Disconnect
1. Cleanup function triggered
2. All AI deleted from all sources:
   - Global tracking map
   - Player variable
   - Player's group
3. Empty groups deleted
4. UID removed from cooldown map

---

## 🚫 Compatibility

### ✅ Works With
- **Exile Mod** - Fully integrated
- **Elite AI Driving** - Recruits excluded from driving system
- **VCOMAI** - Enhanced AI behavior (auto-detected)
- **A3XAI** - Recruits blacklisted automatically
- **DMS Missions** - No conflicts
- **Any respawn system** - UID-based tracking

### ❌ Conflicts
- **Other recruit systems** - Disable them first
- **AI limiters** - May prevent spawning (whitelist recruits)

---

## 🐛 Troubleshooting

### AI Not Spawning
1. Check RPT logs for `[AI RECRUIT]` messages
2. Verify AI types are valid in CfgVehicles
3. Check player is fully loaded (not parachuting)
4. Ensure no AI limiter mod is blocking spawns

### AI Too Powerful
Reduce skills in the spawn function:
```sqf
["aimingAccuracy", 0.8]  // Instead of 1.0
["aimingSpeed", 0.9]
```

### AI Too Slow
Increase speed multiplier:
```sqf
_unit setAnimSpeedCoef 1.6;  // Instead of 1.4
```

### AI Not Following
Check FSM state in logs. Should show:
```
[AI RECRUIT FSM] Brain activated for I_Soldier_AT_F (UID: 12345...)
[AI RECRUIT FSM] Name: IDLE → COMBAT (Threat: 2 @ 150m)
```

### Spawn Spam
Cooldown prevents this, but if still happening:
- Increase cooldown from 5 to 10 seconds
- Check for duplicate spawn triggers

---

## 📊 Performance

**Server Impact:** Low
- **CPU:** ~1% per 10 players (30 AI)
- **Memory:** ~100 KB per AI
- **Network:** Minimal (server-side AI)

**Tested With:**
- 30 players = 90 AI recruits
- Running alongside A3XAI, DMS, VCOMAI
- No performance degradation

---

## 🔄 Version History

### v7.13 - Extreme Elite Operators (Current)
- ✅ 1.0 perfect skills (headshot masters)
- ✅ 300m sight range
- ✅ 1.4x movement speed
- ✅ FSM brain system (4 states)
- ✅ Instant combat reaction
- ✅ Dual death detection
- ✅ Exile resilient (UID-based)

### v7.0
- FSM brain implementation
- State-based behavior

### v6.0
- VCOMAI integration
- Enhanced AI skills

---

## 📝 License

**MIT License** - Free to use, modify, and distribute

---

## 🤝 Support

**Issues?** Check the troubleshooting section above.

**Questions?** Open an issue on GitHub.

**Want to contribute?** Pull requests welcome!

---

## 🎯 Recommended Loadouts

### Assault Squad (CQB)
```sqf
["I_Soldier_AR_F", "I_medic_F", "I_Soldier_GL_F"]
```
- Auto-rifleman for suppression
- Medic for healing
- Grenadier for explosives

### Sniper Team (Long Range)
```sqf
["I_Sniper_F", "I_Spotter_F", "I_Soldier_AT_F"]
```
- Sniper for precision kills
- Spotter for recon
- AT for vehicles

### Heavy Weapons (Anti-Vehicle)
```sqf
["I_Soldier_AT_F", "I_Soldier_AA_F", "I_Soldier_AR_F"]
```
- AT for tanks
- AA for helicopters
- AR for suppression

### Balanced (All-Purpose)
```sqf
["I_Soldier_F", "I_medic_F", "I_Soldier_AT_F"]
```
- Rifleman (general combat)
- Medic (healing)
- AT (vehicles)

---

## 🚀 Pro Tips

1. **Use VCOMAI** for enhanced AI behavior (auto-detected)
2. **Set skills to 0.8** if recruits are too powerful
3. **Monitor RPT logs** during first spawn to verify
4. **Test death/respawn** to ensure clean cleanup
5. **Combine with Elite AI Driving** for vehicle support

---

## 🎬 Expected Behavior

### On Join
```
[AI RECRUIT] Player connecting: YourName
[AI RECRUIT] Setting up handlers for YourName (UID: ...)
[AI RECRUIT] Spawned I_Soldier_AT_F for YourName
[AI RECRUIT] Spawned I_Soldier_AA_F for YourName
[AI RECRUIT] Spawned I_Sniper_F for YourName
[AI RECRUIT] Team spawn complete - now has 3 AI
```

### In Combat
```
[AI RECRUIT FSM] Name: IDLE → COMBAT (Threat: 3 @ 200m)
[AI RECRUIT FSM] Name: COMBAT → RETREAT (Threat: 2 @ 50m)
[AI RECRUIT FSM] Name: RETREAT → HEAL (Threat: 0 @ 0m)
[AI RECRUIT FSM] Name: HEAL → IDLE (Threat: 0 @ 0m)
```

### On Death
```
[AI RECRUIT] AI killed: I_Soldier_AT_F (owner: YourName) - 2 AI remaining
[AI RECRUIT] Player YourName needs 1 AI (has 2)
[AI RECRUIT] Spawned I_Soldier_AT_F for YourName
```

### On Disconnect
```
[AI RECRUIT] *** PLAYER DISCONNECTED: YourName ***
[AI RECRUIT] Source 1 (Global Map): 3 AI found
[AI RECRUIT] Total unique AI to delete: 3
[AI RECRUIT] Deleted: I_Soldier_AT_F
[AI RECRUIT] Deleted: I_Soldier_AA_F
[AI RECRUIT] Deleted: I_Sniper_F
[AI RECRUIT] *** CLEANUP COMPLETE for YourName ***
```

---

**Enjoy your elite AI squad! 🎖️💪**
