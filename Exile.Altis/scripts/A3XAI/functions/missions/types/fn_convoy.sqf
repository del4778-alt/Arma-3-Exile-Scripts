/*
    A3XAI Elite - Convoy Mission
    Spawns armed vehicle convoy transporting supplies

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Convoy_%1", floor(random 9999)];
[3, format ["Spawning convoy mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid convoy spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Find road network for convoy route
private _roads = _pos nearRoads 500;
if (count _roads < 5) exitWith {
    [2, format ["Insufficient road network for convoy at: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Select convoy vehicles based on difficulty (Ivory car pack - no tanks!)
private _vehicleClasses = switch (_difficulty) do {
    case "easy": {["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_Offroad_Armed_Guerilla02"]};
    case "medium": {["ivory_cv_marked", "ivory_taurus_marked", "ivory_charger_marked"]};
    case "hard": {["ivory_suburban_marked", "ivory_m3_marked", "ivory_rs4_marked"]};
    case "extreme": {["ivory_challenger_marked", "ivory_evox_marked", "ivory_wrx_marked", "ivory_charger_slicktop"]};
    default {["Exile_Car_Offroad_Armed_Guerilla01"]};
};

// Select number of vehicles
private _vehicleCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {4};
    case "extreme": {5};
    default {2};
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "convoy"],
    ["status", "active"],
    ["triggerType", "hybrid"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// Create convoy route
private _waypoints = [_pos, 1500, 10] call A3XAI_fnc_generateRoute;
if (count _waypoints < 3) exitWith {
    [2, format ["Failed to generate convoy route at: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Spawn convoy vehicles
private _allGroups = [];
private _allVehicles = [];
private _spawnPos = _pos;

for "_i" from 0 to (_vehicleCount - 1) do {
    // Select vehicle class (rotate through available types)
    private _vehicleClass = selectRandom _vehicleClasses;

    // Find spawn position on road
    private _roadPos = [_spawnPos] call A3XAI_fnc_findValidRoad;
    if (count _roadPos == 0) then {
        _roadPos = _spawnPos;
    };

    // Spawn vehicle
    private _vehicle = createVehicle [_vehicleClass, _roadPos, [], 0, "NONE"];

    // ✅ v3.9: IMMEDIATE vehicle protection - prevents explosion during crew loading
    _vehicle allowDamage false;

    _vehicle setDir (random 360);
    _vehicle setFuel (0.7 + random 0.3);
    _vehicle lock 2; // Lock for AI

    // Create crew
    private _group = createGroup [EAST, true];
    private _crewCount = switch (true) do {
        case (_vehicleClass isKindOf "Car"): {3}; // Driver + gunner + passenger
        case (_vehicleClass isKindOf "APC"): {4}; // + commander
        case (_vehicleClass isKindOf "Tank"): {3}; // Minimal crew
        default {2};
    };

    for "_j" from 0 to (_crewCount - 1) do {
        private _unitType = "O_Soldier_F";  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)
        private _unit = _group createUnit [_unitType, _roadPos, [], 0, "NONE"];

        // Initialize AI
        [_unit, _difficulty] call A3XAI_fnc_initAI;
        [_unit, _difficulty] call A3XAI_fnc_setAISkill;
        [_unit, _difficulty] call A3XAI_fnc_equipAI;
        [_unit] call A3XAI_fnc_addAIEventHandlers;

        // Assign to vehicle
        if (_j == 0) then {
            _unit assignAsDriver _vehicle;
            _unit moveInDriver _vehicle;
        } else {
            _unit assignAsGunner _vehicle;
            _unit moveInAny _vehicle;
        };
    };

    // Set group behavior for convoy
    [_group, "convoy"] call A3XAI_fnc_setGroupBehavior;

    // Add waypoints for convoy route
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointFormation "COLUMN";
        _wp setWaypointCombatMode "YELLOW";
    } forEach _waypoints;

    // Cycle waypoints
    private _wp = _group addWaypoint [_waypoints select 0, 0];
    _wp setWaypointType "CYCLE";

    // Initialize vehicle
    [_vehicle] call A3XAI_fnc_initVehicle;
    [_vehicle] call A3XAI_fnc_addVehicleEventHandlers;

    // EAD integration - register driver for elite driving
    if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {
        private _driver = driver _vehicle;
        if (!isNull _driver) then {
            private _result = [EAD_fnc_registerDriver, [_driver, _vehicle], "EAD_convoy"] call A3XAI_fnc_safeCall;
            if (!isNil "_result") then {
                _vehicle setVariable ["EAD_enabled", true];
                _vehicle setVariable ["EAD_convoy", true];
                _vehicle setVariable ["EAD_convoyIndex", _i];
            };
        };
    };

    // Track vehicle and group
    _vehicle setVariable ["A3XAI_mission", _missionName];
    _vehicle setVariable ["A3XAI_difficulty", _difficulty];
    _group setVariable ["A3XAI_mission", _missionName];

    _allGroups pushBack _group;
    _allVehicles pushBack _vehicle;

    // Next vehicle spawns 50m behind
    _spawnPos = _spawnPos getPos [50 * (_i + 1), 180];
};

// Create supply crate in lead vehicle
private _leadVehicle = _allVehicles select 0;
private _lootBox = "Box_NATO_Ammo_F" createVehicle (position _leadVehicle);
_lootBox attachTo [_leadVehicle, [0, -1.5, 0.5]];

[_lootBox, _difficulty, "convoy"] call A3XAI_fnc_spawnLoot;

// Add loot detection
_lootBox addEventHandler ["ContainerOpened", {
    params ["_container", "_player"];
    _container setVariable ["looted", true, true];
}];

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _pos];
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Convoy (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", _allGroups];
_missionData set ["vehicles", _allVehicles];
_missionData set ["lootBoxes", [_lootBox]];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Supply convoy detected (%1 difficulty)", _difficulty];
    remoteExec ["systemChat", -2];
};

[3, format ["Convoy mission '%1' spawned with %2 vehicles", _missionName, _vehicleCount]] call A3XAI_fnc_log;

_missionData
