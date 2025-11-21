/*
    A3XAI Elite - Spawn Infantry Group
    Spawns an infantry patrol group

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: NUMBER - Unit count (default: 4)
        2: STRING - Difficulty level (default: "medium")
        3: BOOL - Static spawn (doesn't roam) (default: false)

    Returns:
        HASHMAP - Spawn data or empty hashmap on failure
*/

params ["_pos", ["_unitCount", 4], ["_difficulty", "medium"], ["_static", false]];

// Validate spawn
private _canSpawn = [_pos] call A3XAI_fnc_canSpawn;
if (!(_canSpawn select 0)) exitWith {
    [4, format ["Cannot spawn infantry: %1", _canSpawn select 1]] call A3XAI_fnc_log;
    createHashMap
};

// Validate position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid infantry spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create group
private _group = createGroup [EAST, true];

// ✅ FIX: Check if group was created with wrong side (happens when EAST side group limit reached)
// Arma 3 has 144 group limit per side - if exceeded, createGroup returns CIVILIAN group
if (isNull _group) exitWith {
    [1, "Cannot spawn infantry: Failed to create group (returned null)"] call A3XAI_fnc_log;
    createHashMap
};

private _groupSide = side _group;
if (_groupSide != EAST) exitWith {
    private _eastGroups = {side _x == EAST} count allGroups;
    deleteGroup _group;
    [1, format ["Cannot spawn infantry: Group created as %1 instead of EAST (EAST groups: %2/144)", _groupSide, _eastGroups]] call A3XAI_fnc_log;
    [1, "This usually means EAST side group limit (144) has been reached"] call A3XAI_fnc_log;
    createHashMap
};

// Spawn units
for "_i" from 0 to (_unitCount - 1) do {
    private _unitPos = _pos getPos [3 + random 4, random 360];
    private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "NONE"];  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// ✅ VERIFICATION: Check if units actually spawned as EAST side
private _units = units _group;
if (count _units > 0) then {
    private _firstUnit = _units select 0;
    private _unitSide = side _firstUnit;
    if (_unitSide != EAST) then {
        [1, format ["WARNING: Units spawned as %1 instead of EAST! Group was %2", _unitSide, _groupSide]] call A3XAI_fnc_log;
        [1, format ["Unit classname: %1, Group: %2", typeOf _firstUnit, _group]] call A3XAI_fnc_log;
    };
};

// Set group behavior
if (_static) then {
    [_group, "defend"] call A3XAI_fnc_setGroupBehavior;

    // Static patrol waypoints
    for "_i" from 0 to 3 do {
        private _wpPos = _pos getPos [30 + random 20, 90 * _i];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
    };

    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";
} else {
    [_group, "patrol"] call A3XAI_fnc_setGroupBehavior;

    // Roaming patrol waypoints
    for "_i" from 0 to 4 do {
        private _wpPos = _pos getPos [100 + random 100, random 360];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
    };

    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";
};

// Track group
A3XAI_activeGroups pushBack _group;

// Create spawn data
private _spawnData = createHashMapFromArray [
    ["type", "infantry"],
    ["position", _pos],
    ["groups", [_group]],
    ["difficulty", _difficulty],
    ["unitCount", _unitCount],
    ["spawnTime", time],
    ["static", _static],
    ["persistent", false]
];

// Register in spatial grid
[_spawnData] call A3XAI_fnc_registerSpawn;

// Offload to HC if available
if (A3XAI_HCConnected && count A3XAI_HCClients > 0) then {
    [_group] call A3XAI_fnc_offloadGroup;
};

[4, format ["Spawned infantry group (%1 units, %2) at %3", _unitCount, _difficulty, _pos]] call A3XAI_fnc_log;

_spawnData
