# Ravage Exile Integration - Installation Guide

Complete integration of the Ravage mod with Exile mod for Arma 3.

## Features

- **Zombie Resurrection System**: AI deaths spawn zombies (90% single, 10% horde)
- **Ambient Bandits**: Light patrol groups spawn around players
- **Trader Zone Protection**: No zombie/bandit spawns in safe zones
- **Faction Hostility**: All AI factions (EAST, RESISTANCE, WEST) attack zombies
- **Zombie Kill Rewards**: 100 poptabs + 250 respect per zombie kill
- **Performance Optimized**: AI cap culling system prevents server lag

---

## Requirements

### Mods Required
- **Exile Mod** (installed and configured)
- **Ravage Mod** (Steam Workshop or manual install)
- **CBA_A3** (Community Base Addons - required by Ravage)

### Server Files Access
You need access to your mission file (e.g., `Exile.Altis.pbo` or unpacked mission folder)

---

## Installation Steps

### Step 1: Mission File Structure

In your mission root folder (e.g., `mpmissions/Exile.Altis/`), create this folder:
```
scripts/
```

Your mission structure should look like:
```
Exile.Altis/
├── init.sqf
├── initServer.sqf
├── description.ext
├── mission.sqm
├── scripts/
│   └── rmg_ravage_exile_config.sqf  ← Place the script here
└── ... (other files)
```

### Step 2: Copy Script File

1. Copy `scripts/rmg_ravage_exile_config.sqf` to your mission's `scripts/` folder
2. Ensure the file path is: `mpmissions/Exile.Altis/scripts/rmg_ravage_exile_config.sqf`

### Step 3: Update initServer.sqf

Open your mission's `initServer.sqf` file and add this line at the end:

```sqf
// Ravage Exile Integration
[] execVM "scripts\rmg_ravage_exile_config.sqf";
```

**Full example initServer.sqf:**
```sqf
if (!isServer) exitWith {};

// Your existing Exile server initialization code
// ...

// Ravage Exile Integration
[] execVM "scripts\rmg_ravage_exile_config.sqf";
```

### Step 4: Description.ext Configuration

Open your mission's `description.ext` file.

#### A. Add Ravage Sounds (if not already present)

Add this section to enable Ravage zombie sounds:

```cpp
class CfgSounds
{
    // Ravage mod sounds (if not already included)
    // These are typically handled by the Ravage mod itself
    // No manual additions needed unless you have custom sounds
};
```

#### B. Verify CfgRemoteExec

**Important**: Exile already whitelists `ExileServer_system_network_send_to` by default.

Verify your `description.ext` has this section:

```cpp
class CfgRemoteExec
{
    class Functions
    {
        mode = 1; // 0=anybody, 1=whitelist, 2=blacklist
        jip = 0;

        // Exile functions (should already exist)
        class ExileServer_system_network_send_to { allowedTargets = 2; };

        // Add other Exile functions as needed
    };

    class Commands
    {
        mode = 1;
        jip = 0;
    };
};
```

**Note**: If you're using the default Exile `description.ext`, this should already be configured correctly. The script uses only Exile's built-in network functions.

---

## Configuration

### Trader Zone Configuration

Open `scripts/rmg_ravage_exile_config.sqf` and update these values:

```sqf
// Line 22-23: Update your trader zone marker names
["safeZoneMarkers", ["MafiaTraderCity","TraderZoneSilderas","TraderZoneFolia"]],
["safeZoneRadius", 175],  // Must match your trader zone radius
```

**How to find your trader zone markers:**
1. Open your `mission.sqm` file
2. Search for `type="ExileTraderZone"`
3. Look for the `name=` field (e.g., `name="MafiaTraderCity"`)
4. Add all trader zone names to the `safeZoneMarkers` array

### Zombie Classes

Verify zombie class names match your Ravage installation:

```sqf
// Line 26: Zombie class names
["zedClasses", ["zombie_runner","zombie_bolter","zombie_walker"]],
```

**Standard Ravage classes:**
- `zombie_runner` - Fast zombies
- `zombie_bolter` - Very fast zombies
- `zombie_walker` - Slow zombies

### Rewards Configuration

Adjust zombie kill rewards:

```sqf
// Lines 59-60: Zombie kill rewards
["zombieKillRewardPoptabs", 100],   // Change this value
["zombieKillRewardRespect", 250]    // Change this value
```

### Ambient Bandits

Configure bandit patrols:

```sqf
// Lines 33-49: Ambient bandit configuration
["ambientEnabled", true],           // Set to false to disable bandits
["ambientMaxGroups", 6],            // Max concurrent groups
["ambientGroupSize", [2,4]],        // Group size range
["ambientSpawnRadius", [800, 1600]], // Distance from players
```

**Change bandit classes** (for RHS, CUP, or other mods):

```sqf
["ambientClasses", [
    // Replace these with your mod's class names
    "rhsusf_army_ocp_rifleman",
    "rhsusf_army_ocp_grenadier",
    // ... etc
]],
```

### Performance Tuning

Adjust AI cap:

```sqf
// Line 53: Global AI limit
["globalAICap", 220],  // Lower = better performance, higher = more AI
```

---

## Verification & Testing

### 1. Check Server Logs

After server restart, check your server's RPT log file for these messages:

```
[RMG:Ravage] Zombie faction relations configured: CIVILIAN hostile to [EAST,GUER,WEST]
[RMG:Ravage] Zombie kill reward system initialized
[RMG:Ravage] Exile integration complete - all systems active
```

### 2. In-Game Testing

1. **Spawn Test**: Kill an AI unit → should spawn a zombie at the death location
2. **Reward Test**: Kill a zombie → should receive poptabs and respect
3. **Faction Test**: EAST/RESISTANCE/WEST AI should attack zombies on sight
4. **Safe Zone Test**: No zombies/bandits should spawn in trader zones

### 3. Debug Commands (Admin only)

Use these commands in the debug console to test:

```sqf
// Check if script is running
diag_log "Testing Ravage Integration";

// Spawn a test zombie at your position
_grp = createGroup [civilian, true];
_zed = _grp createUnit ["zombie_runner", getPos player, [], 0, "NONE"];
```

---

## Troubleshooting

### Zombies Not Spawning

**Issue**: AI deaths don't spawn zombies

**Solutions**:
1. Check RPT log for initialization messages
2. Verify `initServer.sqf` has the execVM line
3. Ensure zombie class names match your Ravage version
4. Check if deaths happen in trader zones (protected areas)

### Rewards Not Working

**Issue**: No poptabs/respect after zombie kills

**Solutions**:
1. Verify `ExileServer_system_network_send_to` is in CfgRemoteExec
2. Check RPT log for reward initialization message
3. Ensure zombie class names in config match actual spawned zombies
4. Test with `typeOf _zombie` to verify class name

### AI Not Attacking Zombies

**Issue**: AI ignore zombies

**Solutions**:
1. Check faction setup in RPT log
2. Verify `zombieHostileSides` includes correct sides: `[east, resistance, west]`
3. Ensure zombies spawn on CIVILIAN side (script default)
4. Check if Ravage mod is properly loaded

### Performance Issues

**Issue**: Server lag or low FPS

**Solutions**:
1. Lower `globalAICap` (try 150 instead of 220)
2. Reduce `ambientMaxGroups` (try 3-4 instead of 6)
3. Increase `ambientRespawnDelay` (try [120, 180] instead of [60, 120])
4. Disable ambient bandits: `["ambientEnabled", false]`

### Script Errors

**Issue**: Script errors in RPT log

**Solutions**:
1. Verify file path is correct: `scripts\rmg_ravage_exile_config.sqf`
2. Check for syntax errors if you edited the config
3. Ensure backslash `\` is used in Windows paths, forward slash `/` in Linux
4. Verify all array brackets `[]` and parentheses `()` are balanced

---

## Advanced Configuration

### Custom Horde Sizes

```sqf
// Line 27: Horde size range
["hordeSizeRange", [6, 12]],  // Min 6, max 12 zombies

// Line 30: Horde chance
["chanceHorde", 0.10],  // 10% = horde, 90% = single zombie
```

### Zombie Spawn Behavior

```sqf
// Line 28-29: Spawn timing and positioning
["spawnDelay", 0.75],      // Delay after AI death (seconds)
["spawnOffset", 1.0],      // Height above ground (meters)

// Line 32: Minimum player distance
["minPlayerDist", 40],     // Don't spawn if player within 40m
```

### Multi-Faction Setup

If you have multiple AI factions:

```sqf
// Line 31: Sides that resurrect as zombies
["spawnFromSides", [east, resistance, west]],

// Line 56: Sides hostile to zombies
["zombieHostileSides", [east, resistance, west]],
```

---

## Compatibility

### Compatible With:
- ✅ Exile Mod (all versions)
- ✅ Ravage Mod (latest version)
- ✅ A3XAI
- ✅ DMS (Dynamic Mission System)
- ✅ VEMF Reloaded
- ✅ Occupation scripts
- ✅ CUP, RHS, and other weapon/unit mods

### Known Issues:
- ⚠️ If using other zombie mods simultaneously, adjust zombie class names
- ⚠️ High AI counts (>300 total) may cause performance issues
- ⚠️ Ravage's own spawn system should be disabled (this script replaces it)

---

## Support & Credits

**Author**: RMG
**Version**: 2.0
**License**: Free to use and modify

### Credits:
- Ravage Mod by Haleks
- Exile Mod team
- Community feedback and testing

### Getting Help:
1. Check this installation guide thoroughly
2. Review troubleshooting section
3. Check server RPT logs for error messages
4. Test with minimal configuration first

---

## Changelog

### Version 2.0
- Added zombie kill reward system (poptabs + respect)
- Added WEST faction hostility
- Performance optimizations (cap culling)
- Custom trader zone support
- Improved documentation

### Version 1.0
- Initial release
- Basic zombie resurrection
- Ambient bandit patrols
- Safe zone protection
