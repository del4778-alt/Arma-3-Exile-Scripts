/*
    A3XAI Elite - Bandit Camp Mission
    Spawns fortified camp with AI defenders

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Camp_%1", floor(random 9999)];
[3, format ["Spawning camp mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid camp spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "camp"],
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

// Find flat area for camp
private _campPos = [_pos, 20, 80, 5, 0, 0.15, 0] call BIS_fnc_findSafePos;

// Build camp structures
private _campObjects = [];

// Central tent/structure
private _centerTent = "CamoNet_INDP_big_F" createVehicle _campPos;
_campObjects pushBack _centerTent;

// Surrounding fortifications based on difficulty
private _fortCount = switch (_difficulty) do {
    case "easy": {4};
    case "medium": {6};
    case "hard": {8};
    case "extreme": {10};
    default {4};
};

for "_i" from 0 to (_fortCount - 1) do {
    private _angle = (360 / _fortCount) * _i;
    private _fortPos = _campPos getPos [20, _angle];

    private _fortType = selectRandom ["Land_BagFence_Long_F", "Land_BagFence_Round_F", "Land_BagBunker_Small_F"];
    private _fort = _fortType createVehicle _fortPos;
    _fort setDir _angle;
    _campObjects pushBack _fort;
};

// Add camp equipment
private _equipment = ["Land_CampingTable_F", "Land_CampingChair_V2_F", "Land_TentA_F", "Land_Campfire_F", "Land_WoodenBox_F"];
for "_i" from 0 to 4 do {
    private _eqPos = _campPos getPos [10 + random 5, random 360];
    private _obj = (selectRandom _equipment) createVehicle _eqPos;
    _obj setDir (random 360);
    _campObjects pushBack _obj;
};

// Add light source
private _campfire = "Campfire_burning_F" createVehicle (_campPos getPos [5, 45]);
_campObjects pushBack _campfire;

// Determine defender count
private _defenderCount = switch (_difficulty) do {
    case "easy": {5};
    case "medium": {7};
    case "hard": {9};
    case "extreme": {12};
    default {5};
};

// Spawn defenders
private _group = createGroup [EAST, true];

for "_i" from 0 to (_defenderCount - 1) do {
    private _defPos = _campPos getPos [15 + random 10, random 360];

    private _unitType = "I_Soldier_F";
    private _unit = _group createUnit [_unitType, _defPos, [], 0, "NONE"];

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Set group to defend camp
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// Add patrol waypoints
for "_i" from 0 to 5 do {
    private _wpPos = _campPos getPos [25, 60 * _i];
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "SAFE";
    _wp setWaypointCombatMode "YELLOW";
};

private _wp = _group addWaypoint [_campPos, 0];
_wp setWaypointType "CYCLE";

// Spawn patrol vehicles (higher difficulties)
private _vehicles = [];
if (_difficulty in ["hard", "extreme"]) then {
    private _vehCount = if (_difficulty == "extreme") then {2} else {1};

    for "_i" from 0 to (_vehCount - 1) do {
        private _vehPos = _campPos getPos [40 + random 10, (360 / _vehCount) * _i];
        private _vehClass = selectRandom ["Exile_Car_Offroad_Armed_Guerilla01", "I_MRAP_03_hmg_F"];

        private _vehicle = createVehicle [_vehClass, _vehPos, [], 0, "NONE"];
        _vehicle setDir (random 360);
        _vehicle setFuel 0.5;
        _vehicle lock 2;

        [_vehicle] call A3XAI_fnc_initVehicle;
        _vehicles pushBack _vehicle;
        _campObjects pushBack _vehicle;
    };
};

// Create loot crates
private _lootCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {2};
    case "hard": {3};
    case "extreme": {4};
    default {2};
};

private _lootBoxes = [];
for "_i" from 0 to (_lootCount - 1) do {
    private _lootPos = _campPos getPos [5 + random 3, (360 / _lootCount) * _i];
    private _boxTypes = ["Box_NATO_Wps_F", "Box_NATO_Ammo_F", "Box_NATO_Support_F"];
    private _box = (selectRandom _boxTypes) createVehicle _lootPos;

    [_box, _difficulty, "camp"] call A3XAI_fnc_spawnLoot;

    // Add loot detection
    _box addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _box;
    _campObjects pushBack _box;
};

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _campPos];
    _marker setMarkerType "mil_dot";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Bandit Camp (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", _vehicles];
_missionData set ["lootBoxes", _lootBoxes];
_missionData set ["campObjects", _campObjects]; // For cleanup

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Bandit camp discovered (%1 difficulty)", _difficulty];
    remoteExec ["systemChat", -2];
};

[3, format ["Camp mission '%1' spawned with %2 defenders", _missionName, _defenderCount]] call A3XAI_fnc_log;

_missionData
