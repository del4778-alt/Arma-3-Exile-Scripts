# Arma 3 Line Intersection Functions - Complete Reference

This guide covers all line intersection and visibility detection functions in Arma 3, with practical examples from this repository.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Function Details](#function-details)
  - [lineIntersects](#lineintersects)
  - [lineIntersectsObjs](#lineintersectsobjs)
  - [lineIntersectsSurfaces](#lineintersectssurfaces)
  - [lineIntersectsWith](#lineintersectswith)
  - [terrainIntersectAtASL](#terrainintersectatasl)
  - [checkVisibility](#checkvisibility)
- [Performance Optimization](#performance-optimization)
- [Common Use Cases](#common-use-cases)
- [Gotchas and Limitations](#gotchas-and-limitations)

---

## Quick Reference

| Function | Returns | Max Distance | Works Underwater | Use Case |
|----------|---------|--------------|------------------|----------|
| `lineIntersects` | Boolean | 1000m | ❌ | Quick yes/no check |
| `lineIntersectsObjs` | Array of objects | ? | ❌ | Get specific objects |
| `lineIntersectsSurfaces` | Detailed array | 5000m | ✅ | Full surface info |
| `lineIntersectsWith` | Array of objects | 1000m | ❌ | Simple object list |
| `terrainIntersectAtASL` | Position | ? | ? | Terrain hit position |
| `checkVisibility` | Number (0-1) | ? | ? | Visibility percentage |

---

## Function Details

### lineIntersects

**Purpose**: Fast boolean check for any intersection between two points.

**Syntax**:
```sqf
lineIntersects [begPos, endPos, objIgnore1, objIgnore2]
```

**Key Points**:
- ❌ Does NOT work underwater
- ❌ Max hardcoded distance: **1000m**
- ❌ Does NOT detect terrain (only objects)
- ✅ Fastest intersection check
- ✅ Alternative batch syntax available (Arma 3 v2.20+)

**Example from this repo** (`AI-Patrol-System/fn_aiPatrolSystem.sqf:188`):
```sqf
// Cover detection - check if position blocks line of sight
if (lineIntersects [_testASL, _ePos, _u, objNull]) then {
    // This position provides cover from enemy
    private _distScore = 1000 - (sqrt (_u distanceSqr _testPos));
    // ... calculate cover score
};
```

**Batch Processing (v2.20+)** - Check multiple lines in parallel:
```sqf
private _enemies = units opfor;
private _checks = _enemies apply {
    [eyePos player, aimPos _x, player, _x]
};
private _results = lineIntersects [_checks];
// Returns: [true, false, true, ...] for each check
```

---

### lineIntersectsObjs

**Purpose**: Get a list of objects that intersect the line.

**Syntax**:
```sqf
lineIntersectsObjs [begPos, endPos, ignoreObj1, ignoreObj2, sortByDistance, flags]
```

**Flags** (can be combined with `+`):
- `1` - CF_ONLY_WATER
- `2` - CF_NEAREST_CONTACT
- `4` - CF_ONLY_STATIC (buildings, rocks)
- `8` - CF_ONLY_DYNAMIC (vehicles, units)
- `16` - CF_FIRST_CONTACT (stop at first hit)
- `32` - CF_ALL_OBJECTS (with CF_FIRST_CONTACT: one contact per object)

**Key Points**:
- Returns array of objects (unsorted by default)
- `sortByDistance`: `true` = furthest first, `false` = unsorted
- Distance sorting is relative to object model center (not hit point)

**Example**:
```sqf
// Get all static objects (buildings) in line of sight
private _obstacles = lineIntersectsObjs [
    eyePos player,
    aimPos enemy,
    player,
    enemy,
    true,     // Sort by distance
    4         // CF_ONLY_STATIC
];

// Get first dynamic object (vehicles/units) hit
private _targets = lineIntersectsObjs [
    getPosASL vehicle player,
    targetPos,
    objNull,
    objNull,
    false,
    8 + 16    // CF_ONLY_DYNAMIC + CF_FIRST_CONTACT
];
```

---

### lineIntersectsSurfaces

**Purpose**: Most detailed intersection check - returns surface information, normals, and selection names.

**Syntax**:
```sqf
lineIntersectsSurfaces [begPosASL, endPosASL, ignoreObj1, ignoreObj2, sortMode, maxResults, LOD1, LOD2, returnUnique]
```

**Parameters**:
- `sortMode`: `true` = closest first, `false` = furthest first
- `maxResults`: `-1` for all results (since v1.52)
- `LOD1`: Primary LOD - `"FIRE"`, `"VIEW"`, `"GEOM"`, `"IFIRE"`, `"PHYSX"` (v2.02+), `"ROADWAY"` (v2.08+)
- `LOD2`: Secondary LOD (fallback)
- `returnUnique`: `true` = only first intersection per object, `false` = all

**Returns**: Array of intersections
```sqf
[
    [intersectPosASL, surfaceNormal, intersectObj, parentObject, selectionNames, pathToBisurf],
    ...
]
```

**Key Points**:
- ✅ Works underwater (unlike lineIntersects)
- ✅ Max distance: **5000m**
- ✅ Returns surface normals (useful for physics)
- ⚠️ Only checks a single LOD (LOD2 only if LOD1 unavailable)
- ⚠️ If `begPos` is underground and `endPos` above ground, only returns ground intersection

**LOD Selection Guide**:
- `"VIEW"` - Default, visual geometry
- `"FIRE"` - Ballistics geometry (bullets)
- `"GEOM"` - Physical geometry (best for collision detection)
- `"IFIRE"` - Indirect fire (mortars, artillery)
- `"PHYSX"` - PhysX geometry (v2.02+)
- `"ROADWAY"` - Roads only (only works from above)

**Example from this repo** (`AI-Patrol-System/fn_aiPatrolSystem.sqf:139`):
```sqf
// Line of sight check with full details
DEFENDER_fnc_isValidTarget = {
    params ["_u", "_t"];
    if (!alive _t || isNull _t) exitWith {false};
    // ...distance and side checks...

    // Check if there are any surfaces blocking line of sight
    (count lineIntersectsSurfaces [eyePos _u, eyePos _t, _u, _t, true, 1] == 0)
};
```

**Example from this repo** (`Elite-AI-Driving/ead.sqf:114-115`):
```sqf
// Obstacle detection using GEOM LOD for accurate physical geometry
EAD_fnc_ray = {
    params ["_veh","_dirVec","_dist"];

    private _startLow = (getPosASL _veh) vectorAdd [0, 0, 0.3];
    private _endLow = _startLow vectorAdd (_dirVec vectorMultiply _dist);

    // Use GEOM for accurate rock/bush/tree detection
    private _hitLow = lineIntersectsSurfaces [
        _startLow,
        _endLow,
        _veh,
        objNull,
        true,     // Closest first
        1,        // Max 1 result
        "GEOM",   // Physical geometry
        "NONE"    // No fallback
    ];

    if (count _hitLow > 0) then {
        _startLow vectorDistance (_hitLow#0#0)
    } else {
        _dist
    }
};
```

**Detecting Glass/Fences** (since v1.52):
```sqf
// Use GEOM+NONE to detect glass windows and wire fences
private _intersections = lineIntersectsSurfaces [
    AGLToASL positionCameraToWorld [0,0,0],
    AGLToASL positionCameraToWorld [0,0,1000],
    player,
    objNull,
    true,
    1,
    "GEOM",   // Primary: physical geometry
    "NONE"    // Secondary: none (don't use VIEW/FIRE)
];
```

**Batch Processing (v2.20+)**:
```sqf
private _enemies = units opfor;
private _checks = _enemies apply {
    [eyePos player, eyePos _x, player, _x]
};
private _results = lineIntersectsSurfaces [_checks];
// Returns: array of intersection arrays for each check
```

---

### lineIntersectsWith

**Purpose**: Returns objects intersecting with the virtual line (simplified version of lineIntersectsObjs).

**Syntax**:
```sqf
lineIntersectsWith [begPos, endPos, objIgnore1, objIgnore2, sortByDistance]
```

**Key Points**:
- ❌ Does NOT work underwater
- ❌ Max hardcoded distance: **1000m**
- Returns array of objects (unsorted by default)
- `sortByDistance`: `true` = furthest first (descending distance)

**Example**:
```sqf
// Get all objects between player and screen center
private _objects = lineIntersectsWith [
    eyePos player,
    AGLToASL screenToWorld [0.5, 0.5],
    player,
    objNull,
    true  // Sort by distance
];
```

---

### terrainIntersectAtASL

**Purpose**: Returns the intersection position with terrain (not objects).

**Syntax**:
```sqf
terrainIntersectAtASL [startPos, endPos]
```

**Key Points**:
- Returns position `[x, y, z]` or empty array `[]`
- Only checks terrain (not buildings/objects)
- Use `terrainIntersectASL` for boolean check
- ⚠️ Will report intersection if either position is underwater (even if no clear intersection)

**Example**:
```sqf
// Find where a line hits the ground
private _groundHit = terrainIntersectAtASL [
    eyePos player,
    getPosASL chopper
];

if (count _groundHit > 0) then {
    // Line hits terrain at _groundHit position
};
```

**Practical Use** - Spawn object on floor inside building:
```sqf
// Correct weapon holder position to be on floor
private _weaponHolder = createVehicle ["groundWeaponHolder", _pos, [], 0, "CAN_COLLIDE"];
private _whPos = getPosASL _weaponHolder;
private _floorPos = _pos; _floorPos set [2, (ATLToASL _pos select 2) - 10];

private _intersections = lineIntersectsSurfaces [
    _whPos,
    _floorPos,
    _weaponHolder,
    objNull,
    true,
    1,
    "VIEW",
    "FIRE"
];

if (count _intersections > 0) then {
    private _surfaceDistance = (_intersections#0#0) distance _whPos;
    _whPos set [2, (getPosASL _weaponHolder select 2) - _surfaceDistance];
    _weaponHolder setPosASL _whPos;
};
```

---

### checkVisibility

**Purpose**: Returns how visible one position is from another (0 = not visible, 1 = fully visible).

**Syntax**:
```sqf
[ignore, LOD, ignore2] checkVisibility [begPos, endPos]
```

**Key Points**:
- Returns value `0..1` (1 = fully visible)
- Affected by: terrain, grid obstacles, particles with `blockAIVisibility = 1`
- NOT affected by: daylight, distance, overcast, fog
- Particles never make it return 0 (very small number instead)

**Example**:
```sqf
// Check how much of the target unit is visible
private _visibility = [objNull, "VIEW"] checkVisibility [
    eyePos player,
    eyePos targetUnit
];

if (_visibility > 0.5) then {
    // Target is at least 50% visible
};
```

**Advanced - Check Multiple Points**:
```sqf
// Check visibility to multiple body parts
private _bodyParts = [
    targetUnit modelToWorldVisual (targetUnit selectionPosition "head"),
    targetUnit modelToWorldVisual (targetUnit selectionPosition "spine3"),
    targetUnit modelToWorldVisual (targetUnit selectionPosition "pelvis")
];

private _maxVisibility = 0;
{
    private _vis = [objNull, "VIEW"] checkVisibility [eyePos player, AGLToASL _x];
    _maxVisibility = _maxVisibility max _vis;
} forEach _bodyParts;

// _maxVisibility = highest visibility to any body part
```

---

## Performance Optimization

### 1. Use Batch Processing (Arma 3 v2.20+)

**Bad** - Sequential checks:
```sqf
private _results = [];
{
    private _hasLOS = lineIntersects [eyePos player, eyePos _x, player, _x];
    _results pushBack _hasLOS;
} forEach _enemies;
```

**Good** - Parallel batch processing:
```sqf
private _checks = _enemies apply {[eyePos player, eyePos _x, player, _x]};
private _results = lineIntersects [_checks];
// Much faster for multiple checks!
```

### 2. Choose the Right Function

- **Simple yes/no**: Use `lineIntersects` (fastest)
- **Need object list**: Use `lineIntersectsWith` or `lineIntersectsObjs`
- **Need surface details**: Use `lineIntersectsSurfaces`
- **Underwater checks**: Must use `lineIntersectsSurfaces`

### 3. Limit Results

```sqf
// Don't get all intersections if you only need the first
private _hit = lineIntersectsSurfaces [
    _start,
    _end,
    _ignore,
    objNull,
    true,
    1,        // Only return first result
    "GEOM",
    "NONE"
];
```

### 4. Cache Calculations

```sqf
// Bad - recalculate every frame
onEachFrame {
    private _hasLOS = lineIntersects [eyePos player, eyePos enemy, player, enemy];
};

// Good - cache and update periodically
if (time > _nextCheckTime) then {
    _cachedLOS = lineIntersects [eyePos player, eyePos enemy, player, enemy];
    _nextCheckTime = time + 0.5; // Check every 0.5s
};
```

---

## Common Use Cases

### 1. Line of Sight Check (AI Detection)

```sqf
// From AI-Patrol-System
DEFENDER_fnc_isValidTarget = {
    params ["_u", "_t"];
    if (!alive _t || isNull _t) exitWith {false};
    if (side _t getFriend side _u >= 0.6) exitWith {false};

    // Quick distance check first (cheap)
    private _maxDistSqr = DETECT_RAD * DETECT_RAD;
    if ((_u distanceSqr _t) > _maxDistSqr) exitWith {false};

    // Then do expensive raycast
    (count lineIntersectsSurfaces [eyePos _u, eyePos _t, _u, _t, true, 1] == 0)
};
```

### 2. Cover Detection

```sqf
// From AI-Patrol-System - find cover from enemy
DEFENDER_fnc_findCover = {
    params ["_u", "_e"];
    private _uPos = getPosASL _u;
    private _ePos = getPosASL _e;
    private _best = [];
    private _bestScore = -1e9;

    // Test 12 positions around unit
    for "_i" from 0 to 11 do {
        private _testPos = [_u, 20, _i * 30] call BIS_fnc_relPos;
        private _testASL = AGLToASL _testPos;

        // Check if this position blocks line of sight to enemy
        if (lineIntersects [_testASL, _ePos, _u, objNull]) then {
            private _distScore = 1000 - (_u distance _testPos);
            // ... calculate best cover position
            if (_score > _bestScore) then {
                _bestScore = _score;
                _best = _testPos;
            };
        };
    };
    _best
};
```

### 3. Vehicle Obstacle Detection

```sqf
// From Elite-AI-Driving - raycast in driving direction
EAD_fnc_ray = {
    params ["_veh", "_dirVec", "_dist"];

    // Check at two heights (low and mid)
    private _startLow = (getPosASL _veh) vectorAdd [0, 0, 0.3];
    private _endLow = _startLow vectorAdd (_dirVec vectorMultiply _dist);

    private _startMid = (getPosASL _veh) vectorAdd [0, 0, 1.2];
    private _endMid = _startMid vectorAdd (_dirVec vectorMultiply _dist);

    // Use GEOM LOD for physical obstacles (rocks, bushes, trees)
    private _hitLow = lineIntersectsSurfaces [_startLow, _endLow, _veh, objNull, true, 1, "GEOM"];
    private _hitMid = lineIntersectsSurfaces [_startMid, _endMid, _veh, objNull, true, 1, "GEOM"];

    // Return closest obstacle distance
    private _distLow = if (count _hitLow > 0) then {
        _startLow vectorDistance (_hitLow#0#0)
    } else {_dist};

    private _distMid = if (count _hitMid > 0) then {
        _startMid vectorDistance (_hitMid#0#0)
    } else {_dist};

    _distLow min _distMid
};
```

### 4. Check if Inside Building

```sqf
// Fast check if player is inside a house
KK_fnc_inHouse = {
    private _intersections = lineIntersectsSurfaces [
        getPosWorld _this,
        getPosWorld _this vectorAdd [0, 0, 50],  // Ray straight up
        _this,
        objNull,
        true,
        1,
        "GEOM",
        "NONE"
    ];

    if (count _intersections > 0) then {
        _intersections#0 params ["", "", "", "_house"];
        if (_house isKindOf "House") exitWith {true};
    };
    false
};
```

---

## Gotchas and Limitations

### 1. Underwater Limitations

❌ These do NOT work underwater:
- `lineIntersects`
- `lineIntersectsObjs`
- `lineIntersectsWith`

✅ Use `lineIntersectsSurfaces` for underwater checks.

### 2. Distance Limits

- `lineIntersects`, `lineIntersectsWith`: **1000m** (hardcoded)
- `lineIntersectsSurfaces`: **5000m** (hardcoded)

### 3. Position Types

Most functions require **PositionASL** (Above Sea Level), not ATL or AGL.

```sqf
// Convert if needed
private _posASL = getPosASL _obj;        // Correct
private _posASL = AGLToASL _posAGL;      // Convert from AGL
private _posASL = ATLToASL _posATL;      // Convert from ATL
```

### 4. Underground Limitation

If `beginPos` is underground and `endPos` is above ground, functions only return the ground intersection (engine limitation).

### 5. Terrain vs Objects

- `lineIntersects`: Objects only (NOT terrain)
- `terrainIntersect*`: Terrain only (NOT objects)
- `lineIntersectsSurfaces`: Both terrain AND objects

### 6. LOD Behavior

`lineIntersectsSurfaces` only checks **one LOD**. LOD2 is only used if LOD1 is unavailable.

```sqf
// This checks GEOM first, falls back to FIRE if GEOM doesn't exist
lineIntersectsSurfaces [_start, _end, _ign, objNull, true, 1, "GEOM", "FIRE"]

// This checks GEOM ONLY (no fallback)
lineIntersectsSurfaces [_start, _end, _ign, objNull, true, 1, "GEOM", "NONE"]
```

### 7. Sort Order Confusion

- `lineIntersectsObjs`: `true` = **furthest first** (descending)
- `lineIntersectsSurfaces`: `true` = **closest first** (ascending)
- `lineIntersectsWith`: `true` = **furthest first** (descending)

### 8. Particles Never Block Completely

Particles with `blockAIVisibility = 1` influence `checkVisibility` but never make it return `0` - it returns a very small number instead.

### 9. Special Cases

- **Dome objects**: Some dome objects have glass roofs that `lineIntersectsSurfaces` cannot detect
- **Road detection**: `ROADWAY` LOD only works from above (not from the side)

---

## Summary

**For quick checks**: `lineIntersects` (boolean, fastest)

**For object lists**: `lineIntersectsObjs` (with flags) or `lineIntersectsWith`

**For detailed info**: `lineIntersectsSurfaces` (normals, selections, works underwater)

**For terrain**: `terrainIntersectAtASL` or `terrainIntersectASL`

**For visibility %**: `checkVisibility` (0-1 value)

**For performance**: Use batch syntax (v2.20+) when checking multiple lines

**Always remember**:
- Use ASL positions
- Check distance limits
- Choose correct LOD
- Use batch processing when possible
- Most functions don't work underwater (except `lineIntersectsSurfaces`)

---

## References

- [BI Wiki: lineIntersects](https://community.bistudio.com/wiki/lineIntersects)
- [BI Wiki: lineIntersectsObjs](https://community.bistudio.com/wiki/lineIntersectsObjs)
- [BI Wiki: lineIntersectsSurfaces](https://community.bistudio.com/wiki/lineIntersectsSurfaces)
- [BI Wiki: lineIntersectsWith](https://community.bistudio.com/wiki/lineIntersectsWith)
- [BI Wiki: terrainIntersectAtASL](https://community.bistudio.com/wiki/terrainIntersectAtASL)
- [BI Wiki: checkVisibility](https://community.bistudio.com/wiki/checkVisibility)
