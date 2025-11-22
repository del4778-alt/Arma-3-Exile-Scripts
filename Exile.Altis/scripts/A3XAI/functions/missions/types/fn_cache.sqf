/*
    A3XAI Elite - Weapons Cache Mission
    Spawns hidden weapons cache guarded by AI

    Replaces rescue mission (no CIVILIAN hostages = no faction problems)

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Cache_%1", floor(random 9999)];
[3, format ["Spawning weapons cache mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid cache spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "cache"],
    ["status", "active"],
    ["triggerType", "clear"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// Find suitable location
private _cachePos = [_pos, 20, 80, 5, 0, 0.15, 0] call BIS_fnc_findSafePos;

// Create cache structures
private _missionObjects = [];

// Central cache storage building
private _warehouse = "Land_Cargo_House_V3_F" createVehicle _cachePos;
_missionObjects pushBack _warehouse;

// Defensive fortifications
private _fortTypes = ["Land_BagBunker_Small_F", "Land_HBarrier_3_F", "Land_BagFence_Long_F"];
for "_i" from 0 to 5 do {
    private _fortPos = _cachePos getPos [12 + random 5, 60 * _i];
    private _fort = (selectRandom _fortTypes) createVehicle _fortPos;
    _fort setDir (60 * _i + 30);
    _missionObjects pushBack _fort;
};

// Camouflage netting
private _camoPos = _cachePos getPos [8, random 360];
private _camo = "CamoNet_OPFOR_big_F" createVehicle _camoPos;
_missionObjects pushBack _camo;

// Determine guard count based on difficulty
private _guardCount = switch (_difficulty) do {
    case "easy": {5};
    case "medium": {8};
    case "hard": {12};
    case "extreme": {16};
    default {5};
};

// Spawn guards
private _group = createGroup [EAST, true];

for "_i" from 0 to (_guardCount - 1) do {
    private _guardPos = _cachePos getPos [8 + random 15, random 360];

    private _unitType = "O_Soldier_F";
    private _unit = _group createUnit [_unitType, _guardPos, [], 0, "NONE"];

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Set group to defend cache
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// Defensive waypoints - guards stay close to cache
for "_i" from 0 to 5 do {
    private _wpPos = _cachePos getPos [15, 60 * _i];
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "GUARD";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "COMBAT";
    _wp setWaypointCombatMode "RED";
    _wp setWaypointCompletionRadius 10;
};

// Return to cache and loop
private _wp = _group addWaypoint [_cachePos, 0];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 8;

// Spawn multiple loot crates with high-value items
private _lootBoxes = [];
private _crateCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {4};
    case "extreme": {5};
    default {2};
};

private _crateTypes = [
    "Box_NATO_Wps_F",
    "Box_NATO_AmmoOrd_F",
    "Box_NATO_Support_F",
    "Box_East_Wps_F"
];

for "_i" from 0 to (_crateCount - 1) do {
    private _lootPos = _cachePos getPos [5 + random 5, (360 / _crateCount) * _i];
    private _box = (selectRandom _crateTypes) createVehicle _lootPos;

    // High-value loot for cache missions
    [_box, _difficulty, "cache"] call A3XAI_fnc_spawnLoot;

    // Add loot detection
    _box addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _box;
    _missionObjects pushBack _box;
};

// Spawn military vehicle reward
private _vehTypes = switch (_difficulty) do {
    case "easy": {["O_MRAP_02_F", "O_Truck_02_covered_F"]};
    case "medium": {["O_MRAP_02_hmg_F", "O_Truck_02_Ammo_F"]};
    case "hard": {["O_APC_Wheeled_02_rcws_F", "O_MBT_02_cannon_F"]};
    case "extreme": {["O_MBT_02_cannon_F", "O_APC_Tracked_02_cannon_F"]};
    default {["O_MRAP_02_F"]};
};

private _vehPos = _cachePos getPos [25, random 360];
private _vehicle = (selectRandom _vehTypes) createVehicle _vehPos;
_vehicle setFuel 0.5;
_vehicle setDamage 0.2;

[_vehicle] call A3XAI_fnc_initVehicle;
_missionObjects pushBack _vehicle;

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _cachePos];
    _marker setMarkerType "mil_box";
    _marker setMarkerColor "ColorOrange";
    _marker setMarkerText format ["Weapons Cache (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", [_vehicle]];
_missionData set ["lootBoxes", _lootBoxes];
_missionData set ["missionObjects", _missionObjects];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Intel received: Enemy weapons cache located (%1 difficulty)", _difficulty];
    remoteExec ["systemChat", -2];
};

[3, format ["Cache mission '%1' spawned with %2 guards and %3 crates", _missionName, _guardCount, _crateCount]] call A3XAI_fnc_log;

_missionData
