/*
    A3XAI Elite - Spawn Helicopter Patrol
    Spawns an air patrol helicopter

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level (default: "medium")
        2: STRING - Helicopter class (optional, auto-selected if nil)

    Returns:
        HASHMAP - Spawn data or empty hashmap on failure
*/

params ["_pos", ["_difficulty", "medium"], ["_heliClass", ""]];

// Validate spawn
private _canSpawn = [_pos] call A3XAI_fnc_canSpawn;
if (!(_canSpawn select 0)) exitWith {
    [4, format ["Cannot spawn helicopter: %1", _canSpawn select 1]] call A3XAI_fnc_log;
    createHashMap
};

// Set altitude
private _spawnPos = [_pos select 0, _pos select 1, 100 + random 100];

// Select helicopter class if not provided
if (_heliClass == "") then {
    _heliClass = switch (_difficulty) do {
        case "easy": {"O_Heli_Light_02_unarmed_F"};  // FIX: Changed from I_Heli (INDEPENDENT) to O_Heli (EAST)
        case "medium": {"O_Heli_Light_02_dynamicLoadout_F"};  // FIX: EAST Orca armed
        case "hard": {"O_Heli_Attack_02_black_F"};  // FIX: Changed from B_Heli (WEST) to O_Heli (EAST)
        case "extreme": {"O_Heli_Attack_02_F"};
        default {"O_Heli_Light_02_unarmed_F"};  // FIX: EAST default
    };
};

// Spawn helicopter
private _heli = createVehicle [_heliClass, _spawnPos, [], 0, "FLY"];
_heli allowDamage false;  // v3.12: IMMEDIATE vehicle protection during crew loading
_heli setDir (random 360);
_heli setFuel 1;
_heli lock 2;
_heli flyInHeight (100 + random 50);

// Create crew
private _group = createGroup [EAST, true];

// ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
if (isNull _group) exitWith {
    deleteVehicle _heli;
    [1, format ["Cannot spawn heli: createGroup returned null - EAST group limit reached"]] call A3XAI_fnc_log;
    createHashMap
};

if (side _group != EAST) exitWith {
    deleteGroup _group;
    deleteVehicle _heli;
    [1, format ["Cannot spawn heli: Group created as %1 instead of EAST (EAST groups: %2/144)", side _group, {side _x == EAST} count allGroups]] call A3XAI_fnc_log;
    createHashMap
};

private _crewCount = 3; // Pilot + copilot + gunner

for "_i" from 0 to (_crewCount - 1) do {
    private _unit = _group createUnit ["O_helipilot_F", _spawnPos, [], 0, "NONE"];  // FIX: Changed from I_helipilot_F (INDEPENDENT) to O_helipilot_F (EAST)

    // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
    _unit allowDamage false;

    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;

    if (_i == 0) then {
        _unit assignAsDriver _heli;
        _unit moveInDriver _heli;
    } else {
        _unit assignAsGunner _heli;
        _unit moveInAny _heli;
    };
};

// Set group behavior
[_group, "air"] call A3XAI_fnc_setGroupBehavior;

// Create patrol waypoints
private _patrolRadius = 2000;
for "_i" from 0 to 5 do {
    private _wpPos = _spawnPos getPos [_patrolRadius, 60 * _i];
    _wpPos set [2, 100 + random 100]; // Altitude

    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "NORMAL";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCombatMode "RED";
};

private _wp = _group addWaypoint [_spawnPos, 0];
_wp setWaypointType "CYCLE";

// Initialize vehicle
[_heli] call A3XAI_fnc_initVehicle;
[_heli] call A3XAI_fnc_addVehicleEventHandlers;

// Track
A3XAI_activeGroups pushBack _group;
A3XAI_activeVehicles pushBack _heli;

// Create spawn data
private _spawnData = createHashMapFromArray [
    ["type", "air"],
    ["position", _spawnPos],
    ["groups", [_group]],
    ["vehicles", [_heli]],
    ["difficulty", _difficulty],
    ["vehicleClass", _heliClass],
    ["spawnTime", time],
    ["persistent", false]
];

[_spawnData] call A3XAI_fnc_registerSpawn;

// HC offload
if (A3XAI_HCConnected && count A3XAI_HCClients > 0) then {
    [_group] call A3XAI_fnc_offloadGroup;
};

[4, format ["Spawned helicopter patrol (%1, %2) at %3", _heliClass, _difficulty, _spawnPos]] call A3XAI_fnc_log;

_spawnData
