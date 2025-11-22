/*
    A3XAI Elite - Spawn Boat Patrol
    Spawns a water patrol boat

    Parameters:
        0: ARRAY - Spawn position [x,y,z] (must be in water)
        1: STRING - Difficulty level (default: "medium")
        2: STRING - Boat class (optional, auto-selected if nil)

    Returns:
        HASHMAP - Spawn data or empty hashmap on failure
*/

params ["_pos", ["_difficulty", "medium"], ["_boatClass", ""]];

// Validate spawn
private _canSpawn = [_pos] call A3XAI_fnc_canSpawn;
if (!(_canSpawn select 0)) exitWith {
    [4, format ["Cannot spawn boat: %1", _canSpawn select 1]] call A3XAI_fnc_log;
    createHashMap
};

// Validate water position
if !([_pos, "water"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid water spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Select boat class if not provided
if (_boatClass == "") then {
    _boatClass = switch (_difficulty) do {
        case "easy": {"O_Boat_Transport_01_F"};  // FIX: Changed from I_Boat (INDEPENDENT) to O_Boat (EAST)
        case "medium": {"O_Boat_Armed_01_hmg_F"};  // FIX: EAST armed boat
        case "hard": {"O_Boat_Armed_01_hmg_F"};  // FIX: Changed from B_Boat (WEST) to O_Boat (EAST)
        case "extreme": {"O_Boat_Armed_01_hmg_F"};
        default {"O_Boat_Armed_01_hmg_F"};  // FIX: EAST default
    };
};

// Spawn boat
private _boat = createVehicle [_boatClass, _pos, [], 0, "NONE"];
_boat allowDamage false;  // v3.12: IMMEDIATE vehicle protection during crew loading
_boat setDir (random 360);
_boat setFuel 1;
_boat lock 2;

// Create crew
private _group = createGroup [EAST, true];

// ✅ FIX: Check if group was created with wrong side (happens when EAST side group limit reached)
if (!isNull _group && {side _group != EAST}) exitWith {
    deleteGroup _group;
    deleteVehicle _boat;
    [1, format ["Cannot spawn boat: EAST side group limit reached (144 max). Current groups: %1", {side _x == EAST} count allGroups]] call A3XAI_fnc_log;
    createHashMap
};

private _crewCount = 3; // Driver + gunner + passenger

for "_i" from 0 to (_crewCount - 1) do {
    private _unit = _group createUnit ["O_Soldier_F", _pos, [], 0, "NONE"];  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)

    // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
    _unit allowDamage false;

    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;

    if (_i == 0) then {
        _unit assignAsDriver _boat;
        _unit moveInDriver _boat;
    } else {
        _unit assignAsGunner _boat;
        _unit moveInAny _boat;
    };
};

// Set group behavior
[_group, "vehicle"] call A3XAI_fnc_setGroupBehavior;

// Create coastal patrol waypoints
private _patrolRadius = 1000;
for "_i" from 0 to 4 do {
    private _wpPos = _pos getPos [_patrolRadius, 72 * _i];

    // Ensure waypoint is in water
    if (surfaceIsWater _wpPos) then {
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointCombatMode "YELLOW";
    };
};

private _wp = _group addWaypoint [_pos, 0];
_wp setWaypointType "CYCLE";

// Initialize vehicle
[_boat] call A3XAI_fnc_initVehicle;
[_boat] call A3XAI_fnc_addVehicleEventHandlers;

// Track
A3XAI_activeGroups pushBack _group;
A3XAI_activeVehicles pushBack _boat;

// Create spawn data
private _spawnData = createHashMapFromArray [
    ["type", "sea"],
    ["position", _pos],
    ["groups", [_group]],
    ["vehicles", [_boat]],
    ["difficulty", _difficulty],
    ["vehicleClass", _boatClass],
    ["spawnTime", time],
    ["persistent", false]
];

[_spawnData] call A3XAI_fnc_registerSpawn;

// HC offload
if (A3XAI_HCConnected && count A3XAI_HCClients > 0) then {
    [_group] call A3XAI_fnc_offloadGroup;
};

[4, format ["Spawned boat patrol (%1, %2) at %3", _boatClass, _difficulty, _pos]] call A3XAI_fnc_log;

_spawnData
