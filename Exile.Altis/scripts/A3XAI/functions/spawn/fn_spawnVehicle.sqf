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
        case "medium": {selectRandom [
            "ivory_cv_marked", "ivory_cv_unmarked",
            "ivory_taurus_marked", "ivory_taurus_unmarked",
            "ivory_charger_marked", "ivory_charger_unmarked"
        ]};
        case "hard": {selectRandom [
            "ivory_suburban_marked", "ivory_suburban_unmarked",
            "ivory_m3_marked", "ivory_m3_unmarked",
            "ivory_rs4_marked", "ivory_rs4_unmarked"
        ]};
        case "extreme": {selectRandom [
            "ivory_challenger_marked", "ivory_challenger_unmarked",
            "ivory_evox_marked", "ivory_wrx_marked",
            "ivory_charger_slicktop", "ivory_cv_slicktop", "ivory_taurus_slicktop",
            "ivory_rev_unmarked"
        ]};
        default {"Exile_Car_Offroad_Armed_Guerilla01"};
    };
};

// Spawn vehicle
private _vehicle = createVehicle [_vehicleClass, _roadPos, [], 0, "NONE"];
_vehicle setDir (random 360);
_vehicle setFuel 1;
_vehicle lock 0;  // Always unlocked
_vehicle setVariable ["A3XAI_vehicle", true, true];
_vehicle setVariable ["A3XAI_spawnPos", _roadPos, true];  // For unstick function

// Get vehicle turret info (Sarge-AI style recursive exploration)
private _turretInfo = [_vehicleClass] call A3XAI_fnc_getVehicleTurrets;
private _armedTurrets = _turretInfo select {_x select 1};  // Filter for armed turrets

[4, format ["Vehicle %1 has %2 turrets (%3 armed)", _vehicleClass, count _turretInfo, count _armedTurrets]] call A3XAI_fnc_log;

// Create crew
private _group = createGroup [EAST, true];

// ✅ FIX: Check if group was created with wrong side (happens when EAST side group limit reached)
if (!isNull _group && {side _group != EAST}) exitWith {
    deleteGroup _group;
    deleteVehicle _vehicle;
    [1, format ["Cannot spawn vehicle: EAST side group limit reached (144 max). Current groups: %1", {side _x == EAST} count allGroups]] call A3XAI_fnc_log;
    createHashMap
};

private _crewCount = switch (true) do {
    case (_vehicleClass isKindOf "Car"): {3};
    case (_vehicleClass isKindOf "APC"): {4};
    case (_vehicleClass isKindOf "Tank"): {3};
    default {2};
};

private _crewUnits = [];
private _turretIndex = 0;

for "_i" from 0 to (_crewCount - 1) do {
    private _unit = _group createUnit ["O_Soldier_F", _roadPos, [], 0, "CAN_COLLIDE"];

    // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
    _unit allowDamage false;

    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;

    _unit setVariable ["A3XAI_vehicle", _vehicle, true];

    // Assign crew positions using turret info (Sarge-AI style)
    if (_i == 0) then {
        // First unit is always driver
        _unit assignAsDriver _vehicle;
        _unit moveInDriver _vehicle;
    } else {
        // Try to assign to armed turrets first
        if (_turretIndex < count _armedTurrets) then {
            private _turretPath = (_armedTurrets select _turretIndex) select 0;
            _unit assignAsTurret [_vehicle, _turretPath];
            _unit moveInTurret [_vehicle, _turretPath];
            _turretIndex = _turretIndex + 1;
        } else {
            // Fallback to any available position
            _unit moveInAny _vehicle;
        };
    };

    // Start ammo/fuel refresh loop for this AI (Sarge-AI style)
    [_unit] spawn A3XAI_fnc_refreshAI;

    _crewUnits pushBack _unit;
};

// Store crew on vehicle
_vehicle setVariable ["A3XAI_crew", _crewUnits, true];

// Set group behavior - aggressive police
_group setBehaviour "AWARE";
_group setCombatMode "RED";  // Engage at will
_group setFormation "COLUMN";
_group setSpeedMode "NORMAL";

// Enable all AI behaviors
{
    _x enableAI "ALL";
} forEach (units _group);

// Generate route between Exile spawn zone towns
private _spawnZones = if (!isNil "DyCE_SpawnZones") then {
    DyCE_SpawnZones
} else {
    createHashMapFromArray [
        ["Kavala", [3874, 13281, 0]],
        ["Zaros", [9927, 12083, 0]],
        ["Pyrgos", [17138, 12719, 0]],
        ["Sofia", [25713, 21330, 0]],
        ["Syrta", [8613, 18272, 0]]
    ]
};

private _townNames = keys _spawnZones;
private _waypoints = [];

// Build route through multiple towns
if (count _townNames >= 2) then {
    // Shuffle towns for random patrol order
    private _shuffled = _townNames call BIS_fnc_arrayShuffle;

    // Add waypoints to each town
    {
        private _townPos = _spawnZones get _x;
        private _roads = _townPos nearRoads 300;
        if (count _roads > 0) then {
            _waypoints pushBack (position (_roads select 0));
        } else {
            _waypoints pushBack _townPos;
        };
    } forEach _shuffled;
};

// Add waypoints
if (count _waypoints > 1) then {
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointFormation "COLUMN";
    } forEach _waypoints;

    // Cycle back to first waypoint
    private _wp = _group addWaypoint [_waypoints select 0, 0];
    _wp setWaypointType "CYCLE";

    [4, format ["Vehicle patrol route: %1 towns", count _waypoints]] call A3XAI_fnc_log;
} else {
    // Fallback: use generated route
    private _generatedWaypoints = [_roadPos, 1500, 10] call A3XAI_fnc_generateRoute;

    if (count _generatedWaypoints > 0) then {
        {
            private _wp = _group addWaypoint [_x, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "LIMITED";
        } forEach _generatedWaypoints;

        private _wp = _group addWaypoint [_generatedWaypoints select 0, 0];
        _wp setWaypointType "CYCLE";
    } else {
        // Final fallback: simple patrol around spawn
        for "_i" from 0 to 3 do {
            private _wpPos = _roadPos getPos [500, 90 * _i];
            private _wp = _group addWaypoint [_wpPos, 0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "LIMITED";
        };

        private _wp = _group addWaypoint [_roadPos, 0];
        _wp setWaypointType "CYCLE";
    };
};

// Initialize vehicle
[_vehicle] call A3XAI_fnc_initVehicle;
[_vehicle] call A3XAI_fnc_addVehicleEventHandlers;

// EAD integration - register driver for elite driving
if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {
    private _driver = driver _vehicle;
    if (!isNull _driver) then {
        private _result = [EAD_fnc_registerDriver, [_driver, _vehicle], "EAD_driver"] call A3XAI_fnc_safeCall;
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
