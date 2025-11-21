/*
    A3XAI Elite - Outpost Mission
    Fortified military outpost with AI reinforcement waves
    Inspired by DMS slums/occupation missions

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Outpost_%1", floor(random 9999)];
[3, format ["Spawning outpost mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid outpost spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "outpost"],
    ["status", "active"],
    ["triggerType", "hybrid"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []],
    ["reinforcementsActive", true],
    ["reinforcementWaves", 0],
    ["maxReinforcements", 3],
    ["lastReinforcementCheck", time]
];

// Find flat area for outpost
private _outpostPos = [_pos, 30, 100, 10, 0, 0.2, 0] call BIS_fnc_findSafePos;

// Build outpost structures
private _outpostObjects = [];

// Central command post
private _commandPost = "Land_Cargo_HQ_V3_F" createVehicle _outpostPos;
_commandPost setDir (random 360);
_outpostObjects pushBack _commandPost;

// Determine base size based on difficulty
private _wallCount = switch (_difficulty) do {
    case "easy": {8};
    case "medium": {12};
    case "hard": {16};
    case "extreme": {20};
    default {8};
};

// Build perimeter walls/bunkers
private _baseRadius = 40;
for "_i" from 0 to (_wallCount - 1) do {
    private _angle = (360 / _wallCount) * _i;
    private _wallPos = _outpostPos getPos [_baseRadius, _angle];

    private _structure = selectRandom [
        "Land_BagBunker_Large_F",
        "Land_HBarrier_Big_F",
        "Land_HBarrierWall6_F",
        "Land_BagFence_Long_F"
    ];

    private _obj = _structure createVehicle _wallPos;
    _obj setDir (_angle + 180); // Face inward
    _outpostObjects pushBack _obj;
};

// Add watchtowers at corners
private _towerPositions = [0, 90, 180, 270];
{
    private _towerPos = _outpostPos getPos [_baseRadius + 5, _x];
    private _tower = "Land_Cargo_Tower_V3_F" createVehicle _towerPos;
    _tower setDir _x;
    _outpostObjects pushBack _tower;
} forEach _towerPositions;

// Add static weapons
private _staticCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {4};
    case "extreme": {5};
    default {2};
};

private _staticPositions = [];
for "_i" from 0 to (_staticCount - 1) do {
    private _staticPos = _outpostPos getPos [_baseRadius - 5, (360 / _staticCount) * _i];
    private _static = "O_HMG_01_high_F" createVehicle _staticPos;
    _static setDir ((360 / _staticCount) * _i);
    _outpostObjects pushBack _static;
    _staticPositions pushBack _staticPos;
};

// Determine defender count
private _defenderCount = switch (_difficulty) do {
    case "easy": {8};
    case "medium": {12};
    case "hard": {16};
    case "extreme": {20};
    default {8};
};

// Spawn initial defenders
private _group = createGroup [EAST, true];

// Define spawn positions (for initial + reinforcements)
private _spawnLocations = [];
for "_i" from 0 to 7 do {
    private _spawnPos = _outpostPos getPos [_baseRadius + 10, 45 * _i];
    _spawnLocations pushBack _spawnPos;
};

// Add center position multiple times (higher spawn probability)
_spawnLocations pushBack _outpostPos;
_spawnLocations pushBack _outpostPos;
_spawnLocations pushBack _outpostPos;

// Spawn defenders
for "_i" from 0 to (_defenderCount - 1) do {
    private _spawnPos = selectRandom _spawnLocations;
    private _defPos = [_spawnPos, 0, 15, 3, 0, 0.3, 0] call BIS_fnc_findSafePos;

    private _unitType = "O_Soldier_F";
    private _unit = _group createUnit [_unitType, _defPos, [], 0, "NONE"];

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Man static weapons
private _staticCrew = [];
for "_i" from 0 to (count _staticPositions - 1) min (_defenderCount - 1) do {
    private _staticPos = _staticPositions select _i;
    private _nearestUnits = (units _group) select {!isNull objectParent _x && _x distance2D _staticPos < 30};
    if (count _nearestUnits == 0) continue;

    private _gunner = _nearestUnits select 0;
    private _static = nearestObject [_staticPos, "StaticWeapon"];
    if (!isNull _static) then {
        _gunner assignAsGunner _static;
        _gunner moveInGunner _static;
        _staticCrew pushBack _gunner;
    };
};

// Set group to defend outpost
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// Add defensive waypoints
for "_i" from 0 to 5 do {
    private _wpPos = _outpostPos getPos [25, 60 * _i];
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "GUARD";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCombatMode "RED";
    _wp setWaypointCompletionRadius 20;
};

private _wp = _group addWaypoint [_outpostPos, 0];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 15;

// Spawn patrol vehicles
private _vehicles = [];
if (_difficulty in ["hard", "extreme"]) then {
    private _vehCount = if (_difficulty == "extreme") then {2} else {1};

    for "_i" from 0 to (_vehCount - 1) do {
        private _vehPos = _outpostPos getPos [_baseRadius + 15, (360 / _vehCount) * _i];
        private _vehClass = selectRandom [
            "ivory_suburban_marked",
            "ivory_charger_marked",
            "ivory_challenger_marked"
        ];

        private _vehicle = createVehicle [_vehClass, _vehPos, [], 0, "NONE"];
        _vehicle setDir (random 360);
        _vehicle setFuel 0.7;
        _vehicle lock 2;

        [_vehicle] call A3XAI_fnc_initVehicle;
        _vehicles pushBack _vehicle;
        _outpostObjects pushBack _vehicle;
    };
};

// Create loot crates
private _lootCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {4};
    case "extreme": {5};
    default {2};
};

private _lootBoxes = [];
for "_i" from 0 to (_lootCount - 1) do {
    private _lootPos = _outpostPos getPos [8 + random 5, (360 / _lootCount) * _i];
    private _boxTypes = ["Box_NATO_Wps_F", "Box_NATO_Ammo_F", "Box_NATO_Support_F"];
    private _box = (selectRandom _boxTypes) createVehicle _lootPos;

    [_box, _difficulty, "outpost"] call A3XAI_fnc_spawnLoot;

    // Add loot detection
    _box addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _box;
    _outpostObjects pushBack _box;
};

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _outpostPos];
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Military Outpost (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", _vehicles];
_missionData set ["lootBoxes", _lootBoxes];
_missionData set ["outpostObjects", _outpostObjects];
_missionData set ["spawnLocations", _spawnLocations];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Start reinforcement monitoring (DMS-style)
[_missionData, _group, _outpostPos, _difficulty] spawn {
    params ["_missionData", "_group", "_outpostPos", "_difficulty"];

    private _reinforcementThreshold = 8; // Spawn reinforcements when below 8 AI
    private _reinforcementCount = 7; // Spawn 7 units per wave
    private _checkInterval = 60; // Check every 60 seconds
    private _reinforcementDelay = 240; // 4 minutes between waves

    while {_missionData get "status" == "active"} do {
        sleep _checkInterval;

        // Check if reinforcements still active
        if (!(_missionData get "reinforcementsActive")) exitWith {};

        // Check if max waves reached
        private _waves = _missionData get "reinforcementWaves";
        private _maxWaves = _missionData get "maxReinforcements";
        if (_waves >= _maxWaves) exitWith {
            [3, format ["Outpost '%1' reached max reinforcement waves (%2)", _missionData get "name", _maxWaves]] call A3XAI_fnc_log;
        };

        // Check last reinforcement time
        private _lastCheck = _missionData get "lastReinforcementCheck";
        if (time - _lastCheck < _reinforcementDelay) then {continue};

        // Check AI count
        private _aliveCount = {alive _x} count units _group;
        if (_aliveCount >= _reinforcementThreshold) then {continue};

        // Spawn reinforcements!
        [2, format ["Outpost '%1' spawning reinforcements (wave %2) - AI count: %3/%4",
            _missionData get "name", _waves + 1, _aliveCount, _reinforcementThreshold]] call A3XAI_fnc_log;

        private _spawnLocs = _missionData get "spawnLocations";
        for "_i" from 0 to (_reinforcementCount - 1) do {
            private _spawnPos = selectRandom _spawnLocs;
            private _spawnPoint = [_spawnPos, 0, 20, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

            private _unit = _group createUnit ["O_Soldier_F", _spawnPoint, [], 0, "NONE"];

            // Initialize reinforcement AI
            [_unit, _difficulty] call A3XAI_fnc_initAI;
            [_unit, _difficulty] call A3XAI_fnc_setAISkill;
            [_unit, _difficulty] call A3XAI_fnc_equipAI;
            [_unit] call A3XAI_fnc_addAIEventHandlers;

            // Spawn smoke for visibility
            if (_i == 0) then {
                "SmokeShellGreen" createVehicle _spawnPoint;
            };

            sleep 0.5;
        };

        // Update mission data
        _missionData set ["reinforcementWaves", _waves + 1];
        _missionData set ["lastReinforcementCheck", time];

        // Notify players
        if (A3XAI_enableMissionNotifications) then {
            private _msg = format ["Enemy reinforcements arriving at outpost! (Wave %1/%2)", _waves + 1, _maxWaves];
            [_msg] remoteExec ["systemChat", -2];
        };
    };
};

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Enemy outpost detected (%1 difficulty)", _difficulty];
    [_msg] remoteExec ["systemChat", -2];
};

[3, format ["Outpost mission '%1' spawned with %2 defenders (reinforcements enabled)", _missionName, _defenderCount]] call A3XAI_fnc_log;

_missionData
