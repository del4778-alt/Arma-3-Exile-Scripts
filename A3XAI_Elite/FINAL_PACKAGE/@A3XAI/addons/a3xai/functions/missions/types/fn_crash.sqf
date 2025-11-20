/*
    A3XAI Elite - Crash Site Mission
    Spawns crashed helicopter with defending AI

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Crash_%1", floor(random 9999)];
[3, format ["Spawning crash mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid crash spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "crash"],
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

// Select crashed helicopter type
private _crashTypes = ["B_Heli_Transport_01_F", "B_Heli_Light_01_F", "I_Heli_light_03_F", "I_Heli_Transport_02_F"];
private _crashHeli = selectRandom _crashTypes;

// Find suitable crash position (open area, slight elevation)
private _crashPos = [_pos, 50, 150, 10, 0, 0.3, 0] call BIS_fnc_findSafePos;

// Create crashed helicopter
private _heli = createVehicle [_crashHeli, _crashPos, [], 0, "CAN_COLLIDE"];
_heli setPos _crashPos;
_heli setDir (random 360);
_heli setDamage 0.9;
_heli setFuel 0;
_heli setVehicleLock "LOCKED";

// Add fire/smoke effects
private _smoke = "test_EmptyObjectForSmoke" createVehicle _crashPos;
_smoke attachTo [_heli, [0, 0, 0]];

private _fire = "#particlesource" createVehicle _crashPos;
_fire setParticleParams [
    ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 10, 12],
    "", "Billboard", 1, 3.5, [0, 0, 0],
    [0, 0, 1.5], 1, 1.275, 1, 0,
    [1.5, 1.5], [[1, 1, 1, 0.4], [1, 1, 1, 0.2], [1, 1, 1, 0]],
    [0.5], 0.1, 0.05, "", "", _heli
];
_fire setParticleRandom [2, [0.5, 0.5, 0.3], [0.2, 0.2, 0.2], 0.3, 0.3, [0, 0, 0, 0], 0, 0];
_fire setDropInterval 0.03;

// Determine defender count based on difficulty
private _defenderCount = switch (_difficulty) do {
    case "easy": {4};
    case "medium": {6};
    case "hard": {8};
    case "extreme": {10};
    default {4};
};

// Spawn defenders around crash site
private _group = createGroup [EAST, true];
private _defenderPositions = [_crashPos, _defenderCount, 25, 50] call A3XAI_fnc_generateDefensePositions;

for "_i" from 0 to (_defenderCount - 1) do {
    private _defPos = if (_i < count _defenderPositions) then {
        _defenderPositions select _i
    } else {
        _crashPos getPos [30 + random 20, random 360]
    };

    private _unitType = "I_Soldier_F";
    private _unit = _group createUnit [_unitType, _defPos, [], 0, "NONE"];

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Set group to defend crash site
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// Add patrol waypoints around crash
for "_i" from 0 to 3 do {
    private _wpPos = _crashPos getPos [40, 90 * _i];
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCombatMode "RED";
};

private _wp = _group addWaypoint [_crashPos, 0];
_wp setWaypointType "CYCLE";

// Create loot crates
private _lootCount = switch (_difficulty) do {
    case "easy": {1};
    case "medium": {2};
    case "hard": {2};
    case "extreme": {3};
    default {1};
};

private _lootBoxes = [];
for "_i" from 0 to (_lootCount - 1) do {
    private _lootPos = _crashPos getPos [8 + random 4, (360 / _lootCount) * _i];
    private _box = "Box_NATO_Wps_F" createVehicle _lootPos;

    [_box, _difficulty, "crash"] call A3XAI_fnc_spawnLoot;

    // Add loot detection
    _box addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _box;
};

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _crashPos];
    _marker setMarkerType "mil_destroy";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Crash Site (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", [_heli, _smoke, _fire]];
_missionData set ["lootBoxes", _lootBoxes];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Helicopter crash site detected (%1 difficulty)", _difficulty];
    remoteExec ["systemChat", -2];
};

[3, format ["Crash mission '%1' spawned with %2 defenders", _missionName, _defenderCount]] call A3XAI_fnc_log;

_missionData
