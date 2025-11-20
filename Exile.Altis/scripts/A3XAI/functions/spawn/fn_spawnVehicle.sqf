/*
    A3XAI Elite - Spawn Vehicle Patrol
    Spawns a ground vehicle patrol

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level (default: "medium")
        2: STRING - Vehicle class (optional, auto-selected if nil)

    Returns:
        HASHMAP - Spawn data or empty hashmap on failure
*/

params ["_pos", ["_difficulty", "medium"], ["_vehicleClass", ""]];

// Validate spawn
private _canSpawn = [_pos] call A3XAI_fnc_canSpawn;
if (!(_canSpawn select 0)) exitWith {
    [4, format ["Cannot spawn vehicle: %1", _canSpawn select 1]] call A3XAI_fnc_log;
    createHashMap
};

// Find road position
private _roads = _pos nearRoads 200;
if (count _roads == 0) exitWith {
    [2, format ["No roads found near position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

private _roadPos = [_pos] call A3XAI_fnc_findValidRoad;
if (count _roadPos == 0) then {
    _roadPos = position (_roads select 0);
};

// Select vehicle class if not provided
if (_vehicleClass == "") then {
    _vehicleClass = switch (_difficulty) do {
        case "easy": {selectRandom ["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_Offroad_Armed_Guerilla02"]};
        case "medium": {selectRandom ["O_MRAP_02_hmg_F", "O_MRAP_02_gmg_F"]};  // FIX: Changed from I_MRAP (INDEPENDENT) to O_MRAP (EAST Ifrit)
        case "hard": {selectRandom ["O_APC_Wheeled_02_rcws_F", "O_APC_Tracked_02_cannon_F"]};  // FIX: EAST Marid/BTR-K
        case "extreme": {selectRandom ["O_APC_Wheeled_02_rcws_F", "O_MBT_02_cannon_F"]};  // FIX: EAST T-100
        default {"Exile_Car_Offroad_Armed_Guerilla01"};
    };
};

// Spawn vehicle
private _vehicle = createVehicle [_vehicleClass, _roadPos, [], 0, "NONE"];
_vehicle setDir (random 360);
_vehicle setFuel (0.7 + random 0.3);
_vehicle lock 2;

// Create crew
private _group = createGroup [EAST, true];

// ✅ FIX: Check if group was created with wrong side (happens when EAST side group limit reached)
if (!isNull _group && {side _group != EAST}) then {
    deleteGroup _group;
    deleteVehicle _vehicle;
    [1, format ["Cannot spawn vehicle: EAST side group limit reached (144 max). Current groups: %1", {side _x == EAST} count allGroups]] call A3XAI_fnc_log;
    createHashMap
} exitWith {};

private _crewCount = switch (true) do {
    case (_vehicleClass isKindOf "Car"): {3};
    case (_vehicleClass isKindOf "APC"): {4};
    case (_vehicleClass isKindOf "Tank"): {3};
    default {2};
};

for "_i" from 0 to (_crewCount - 1) do {
    private _unit = _group createUnit ["O_Soldier_F", _roadPos, [], 0, "NONE"];  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)

    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;

    if (_i == 0) then {
        _unit assignAsDriver _vehicle;
        _unit moveInDriver _vehicle;
    } else {
        _unit assignAsGunner _vehicle;
        _unit moveInAny _vehicle;
    };
};

// Set group behavior
[_group, "vehicle"] call A3XAI_fnc_setGroupBehavior;

// Generate route
private _waypoints = [_roadPos, 1500, 10] call A3XAI_fnc_generateRoute;

// Add waypoints
if (count _waypoints > 0) then {
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointFormation "COLUMN";
    } forEach _waypoints;

    private _wp = _group addWaypoint [_waypoints select 0, 0];
    _wp setWaypointType "CYCLE";
} else {
    // Fallback: simple patrol around spawn
    for "_i" from 0 to 3 do {
        private _wpPos = _roadPos getPos [500, 90 * _i];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
    };

    private _wp = _group addWaypoint [_roadPos, 0];
    _wp setWaypointType "CYCLE";
};

// Initialize vehicle
[_vehicle] call A3XAI_fnc_initVehicle;
[_vehicle] call A3XAI_fnc_addVehicleEventHandlers;

// EAD integration - register driver for elite driving
if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {
    private _driver = driver _vehicle;
    if (!isNull _driver) then {
        private _result = [EAD_fnc_registerDriver, [_driver], "EAD_driver"] call A3XAI_fnc_safeCall;
        if (!isNil "_result") then {
            _vehicle setVariable ["EAD_enabled", true];
            [4, "EAD enabled for vehicle patrol driver"] call A3XAI_fnc_log;
        };
    };
};

// Track
A3XAI_activeGroups pushBack _group;
A3XAI_activeVehicles pushBack _vehicle;

// Create spawn data
private _spawnData = createHashMapFromArray [
    ["type", "vehicle"],
    ["position", _roadPos],
    ["groups", [_group]],
    ["vehicles", [_vehicle]],
    ["difficulty", _difficulty],
    ["vehicleClass", _vehicleClass],
    ["spawnTime", time],
    ["persistent", false]
];

[_spawnData] call A3XAI_fnc_registerSpawn;

// HC offload
if (A3XAI_HCConnected && count A3XAI_HCClients > 0) then {
    [_group] call A3XAI_fnc_offloadGroup;
};

[4, format ["Spawned vehicle patrol (%1, %2) at %3", _vehicleClass, _difficulty, _roadPos]] call A3XAI_fnc_log;

_spawnData
