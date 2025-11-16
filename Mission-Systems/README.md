# Mission Systems - Convoy Spawn Fix

## Overview

This folder contains fixes for dynamic mission systems where convoy AI and vehicles die/explode instantly on spawn.

## Problem

When dynamic missions (especially convoys) spawn, you find:
- All AI units dead on the ground
- Vehicles destroyed or heavily damaged
- Mission fails before players can reach it

## ⚠️ #1 CAUSE: RemoteExec Blocking

**Before anything else**, check if remoteExec is blocking mission spawn commands!

**Symptoms:**
- ALL missions fail (not random)
- No mission markers appear
- RPT shows: `"not allowed to be remotely executed"`

**Quick Fix:**
Create `@ExileServer\addons\exile_server_config\remoteExec.txt` with mission system commands whitelisted.

**📖 See**: `MISSION_REMOTEEXEC_FIX.md` for complete remoteExec configuration.

**This alone fixes 80%+ of convoy spawn failures!**

## Files

### `convoy_spawn_fix.sqf`
Universal patch script that fixes convoy spawn issues across multiple mission systems:
- **A3XAI** - Auto-detects and patches
- **DMS** (Defent's Mission System) - Manual integration
- **VEMF Reloaded** - Manual integration
- **Custom mission systems** - Provides safe spawn function

**Features:**
- Prevents vehicle collision on spawn
- Eliminates fall damage
- Fixes simulation race conditions
- Stops AI from getting run over
- Auto-spacing for convoy vehicles
- Delayed damage enabling for safety

### `MISSION_REMOTEEXEC_FIX.md` ⭐ **START HERE**
Complete guide to fixing remoteExec blocking in mission systems:
- Why missions fail due to remoteExec
- Complete remoteExec.txt configuration for A3XAI/DMS/VEMF
- RPT error signatures
- Quick diagnosis scripts
- Testing procedures

### `CONVOY_TROUBLESHOOTING.md`
Comprehensive troubleshooting guide covering:
- All common causes of convoy spawn failures (remoteExec + physical issues)
- Quick diagnosis scripts
- Mission system-specific fixes
- Testing procedures
- Prevention checklist

## Quick Start

### For A3XAI Users (Automatic)

Add to your `init.sqf` or `initServer.sqf`:

```sqf
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";
```

The script will automatically detect and patch A3XAI convoy spawns.

### For DMS/VEMF/Custom Missions (Manual)

Replace your convoy spawn code with the safe spawn function:

```sqf
// Load the fix script
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";

// Use in your mission
_vehicles = [
    _missionPosition,          // [x,y,z]
    ["Hunter_HMG_F", "MRAP_03_hmg_F", "Offroad_01_armed_F"],  // Vehicle classes
    east,                      // Side
    25,                        // Spacing between vehicles (optional, default 25m)
    3                          // AI crew per vehicle (optional, default 3)
] call CONVOY_fnc_SafeSpawn;
```

## How It Works

The fix addresses all common spawn issues:

1. **Collision Prevention** - Spawns vehicles with 25m spacing
2. **Simulation Control** - Disables physics during positioning
3. **Damage Protection** - Prevents damage during spawn sequence
4. **Position Safety** - Forces ground level, clears velocity
5. **Delayed Activation** - Enables systems after 2-second delay

## Diagnostics

To debug a mission that's failing:

```sqf
// After mission spawns
[_missionPosition, 200] call CONVOY_fnc_DiagnoseMission;
```

Check your RPT file for detailed analysis.

## Compatibility

**Tested With:**
- Arma 3 v2.00+
- Exile Mod
- A3XAI
- RMG Ravage
- Elite AI Driving

**Mission Systems:**
- A3XAI ✅ (auto-patches)
- DMS ⚙️ (manual integration)
- VEMF ⚙️ (manual integration)
- Custom ⚙️ (use safe spawn function)

## Support

For detailed troubleshooting, see `CONVOY_TROUBLESHOOTING.md`

Common issues:
- AI still dying → Check spacing (increase to 30-40m)
- Vehicles exploding → Disable damage for longer (increase delay to 3-5s)
- Random failures → Check for hostile AI nearby (A3XAI patrols, zombies)
- Specific vehicles → Some modded vehicles have broken damage models

## Contributing

If you have additional fixes or encounter new issues, please report them with:
- RPT file errors
- Mission system name/version
- Server mods loaded
- Spawn code used
