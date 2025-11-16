# Convoy Mission AI Dying on Spawn - Troubleshooting Guide

## Problem Description
Dynamic missions (especially convoys) spawn with all AI dead and vehicles destroyed.

## Common Causes

### 1. **Vehicle Collision on Spawn** ⚠️ MOST COMMON
**Symptoms:**
- All vehicles destroyed
- AI dead around vehicles
- Happens instantly when mission spawns

**Cause:** Vehicles spawning too close together or on top of each other

**Fix:**
```sqf
// BAD - Vehicles spawn in same spot
for "_i" from 0 to 3 do {
    _veh = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];
};

// GOOD - Vehicles spaced apart
for "_i" from 0 to 3 do {
    _offset = _i * 25; // 25m spacing
    _spawnPos = _pos getPos [_offset, 0];
    _veh = createVehicle [_class, _spawnPos, [], 0, "NONE"];
};
```

---

### 2. **Fall Damage**
**Symptoms:**
- Vehicles appear damaged
- AI dead in vehicles
- Happens on hilly terrain

**Cause:** Vehicles spawning in the air and falling

**Fix:**
```sqf
// Force vehicles to ground level
_pos set [2, 0];
_veh = createVehicle [_class, _pos, [], 0, "NONE"];
_veh setPos (_veh modelToWorld [0,0,0]); // Snap to ground
_veh setVectorUp [0,0,1]; // Level vehicle
```

---

### 3. **Simulation Race Condition**
**Symptoms:**
- Random deaths
- Sometimes works, sometimes doesn't
- More common on slow servers

**Cause:** Physics simulation activates before vehicle is fully positioned

**Fix:**
```sqf
// Disable simulation during spawn
_veh enableSimulationGlobal false;
_veh allowDamage false;

// Set position and crew
_veh setPos _pos;
_veh setDir _dir;
_unit moveInDriver _veh;

// Re-enable after delay
[{
    params ["_veh"];
    _veh enableSimulationGlobal true;
    uiSleep 0.5;
    _veh allowDamage true;
}, [_veh], 2] call BIS_fnc_execVM;
```

---

### 4. **AI Getting Run Over**
**Symptoms:**
- AI dead on road
- Tire marks over bodies
- Vehicles still intact

**Cause:** AI spawn in front of moving vehicles

**Fix:**
```sqf
// Don't spawn AI in front of vehicles
// Spawn them INSIDE vehicles directly
_unit = _grp createUnit [_class, [0,0,0], [], 0, "NONE"];
_unit moveInCargo _veh; // Teleport into vehicle

// OR ensure vehicles are stationary
_veh setVelocity [0,0,0];
_veh setBehaviour "SAFE";
_veh setSpeedMode "LIMITED";
```

---

### 5. **Hostile AI/Zombies Nearby**
**Symptoms:**
- AI dead with bullet wounds
- Empty casings on ground
- Takes a few seconds to die

**Cause:** A3XAI patrols, Ravage zombies, or other AI engaging immediately

**Fix:**
```sqf
// Check for hostiles before spawn
_hostiles = _pos nearEntities [["CAManBase"], 200] select {
    side _x != _side && alive _x
};

if (count _hostiles > 0) then {
    // Clear area or choose new position
    {deleteVehicle _x} forEach _hostiles;
};
```

---

### 6. **Exile/Mod Compatibility**
**Symptoms:**
- Works on vanilla server
- Fails on modded server
- Specific to certain vehicle types

**Cause:** Exile or other mods interfering with vehicle spawns

**Fix:**
```sqf
// Bypass Exile vehicle cleanup
_veh setVariable ["ExileIsPersistent", true];
_veh setVariable ["ExileAccessCode", "000000"];

// Prevent Ravage zombie spawns
{
    _x setVariable ["ExileRecruited", false];
    _x setVariable ["RMG_NoResurrect", true];
} forEach crew _veh;
```

---

## Quick Diagnosis Script

Run this in your mission spawn code:

```sqf
// After convoy spawns, run diagnostics
[_missionPos] spawn {
    params ["_pos"];

    uiSleep 5; // Wait for spawn

    private _units = _pos nearEntities [["CAManBase"], 200];
    private _vehicles = _pos nearEntities [["LandVehicle"], 200];

    private _deadUnits = _units select {!alive _x};
    private _deadVehicles = _vehicles select {!alive _x};

    if (count _deadUnits > 0 || count _deadVehicles > 0) then {
        diag_log "========================================";
        diag_log format ["[MISSION DEBUG] Mission failed at %1", _pos];
        diag_log format ["  Dead units: %1/%2", count _deadUnits, count _units];
        diag_log format ["  Dead vehicles: %1/%2", count _deadVehicles, count _vehicles];

        // Check damage types
        {
            diag_log format ["  - %1: damage=%2", typeOf _x, damage _x];
        } forEach _deadVehicles;

        // Check clustering
        {
            private _nearby = _vehicles select {_x distance _forEachIndex < 10};
            if (count _nearby > 1) then {
                diag_log format ["  WARNING: %1 vehicles clustered together", count _nearby];
            };
        } forEach _vehicles;

        diag_log "========================================";
    };
};
```

---

## Solution: Use the Convoy Spawn Fix Script

The `convoy_spawn_fix.sqf` script in this folder provides:

1. **Safe spawn function** - Handles all the above issues
2. **A3XAI auto-patching** - Automatically fixes A3XAI if detected
3. **Diagnostic tools** - Debug mission spawn issues

### Installation:

**Option 1: Init.sqf** (loads for all missions)
```sqf
// In your server init.sqf or mission init
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";
```

**Option 2: Per-Mission** (A3XAI example)
```sqf
// In your A3XAI mission file (e.g., A3XAI\missions\convoy.sqf)
// Replace vehicle spawn code with:

_vehicles = [
    _missionPos,              // Center position
    _vehicleClassArray,       // ["Offroad_01_armed_F", "Hunter_HMG_F", ...]
    east,                     // Side
    25,                       // Spacing (meters)
    3                         // Crew per vehicle
] call CONVOY_fnc_SafeSpawn;
```

**Option 3: DMS** (if using Defent's Mission System)
```sqf
// In DMS config, replace:
_veh = [_class, _pos] call DMS_fnc_SpawnVehicle;

// With:
_veh = createVehicle [_class, _pos, [], 0, "NONE"];
_veh allowDamage false;
_veh enableSimulationGlobal false;
// ... (see convoy_spawn_fix.sqf for full implementation)
```

---

## Testing

After applying the fix:

1. Teleport to a mission area: `player setPos _missionPos`
2. Watch the spawn happen
3. Check RPT logs for `[CONVOY FIX]` messages
4. Verify AI are alive and vehicles intact

---

## Still Having Issues?

### Enable Debug Logging

Add to your mission spawn code:
```sqf
[_missionPos, 200] call CONVOY_fnc_DiagnoseMission;
```

This will output detailed diagnostics to your RPT file.

### Check Your RPT File

Look for:
- `"Server: Object X:XXX not found"` - Simulation issues
- `"Strange convex component"` - Model/physics errors
- Vehicle damage reports
- A3XAI/DMS error messages

### Common A3XAI Issues

If using A3XAI, check:
1. `A3XAI_config.sqf` - Vehicle spawn settings
2. Mission difficulty settings
3. Black/white listed areas (missions may spawn in restricted zones)

---

## Prevention Checklist

✅ Vehicles spawn with 20m+ spacing
✅ `enableSimulationGlobal false` during spawn
✅ `allowDamage false` during spawn
✅ Position forced to ground level (`_pos set [2, 0]`)
✅ Velocity cleared (`setVelocity [0,0,0]`)
✅ AI spawned INSIDE vehicles (not nearby)
✅ 2+ second delay before enabling damage
✅ Spawn position checked for hostiles
✅ Not spawning in trader zones or blacklisted areas

---

## Example: Working Convoy Spawn

```sqf
_missionPos = _this select 0;
_vehicleClasses = ["Offroad_01_armed_F", "Hunter_HMG_F", "MRAP_03_hmg_F"];

_vehicles = [];
_spacing = 25;

for "_i" from 0 to (count _vehicleClasses - 1) do {
    _offset = _i * _spacing;
    _spawnPos = _missionPos getPos [_offset, 0];
    _spawnPos set [2, 0];

    _veh = createVehicle [_vehicleClasses select _i, _spawnPos, [], 0, "NONE"];
    _veh allowDamage false;
    _veh enableSimulationGlobal false;
    _veh setPos _spawnPos;
    _veh setVectorUp [0,0,1];
    _veh setVelocity [0,0,0];

    _grp = createGroup [east, true];
    _driver = _grp createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
    _driver allowDamage false;
    _driver moveInDriver _veh;

    _vehicles pushBack _veh;
};

// Enable after 2 seconds
[{
    params ["_vehs"];
    {
        _x enableSimulationGlobal true;
        {_x allowDamage true} forEach crew _x;
    } forEach _vehs;
    uiSleep 1;
    {_x allowDamage true} forEach _vehs;
}, [_vehicles], 2] call BIS_fnc_execVM;
```

---

## Support

If the issue persists:
1. Post your RPT file errors
2. Specify which mission system (A3XAI, DMS, VEMF, custom)
3. Provide mission spawn code
4. Note server mods loaded (Exile, Ravage, etc.)
