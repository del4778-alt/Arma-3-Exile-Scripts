/*
    A3XAI Elite - Bandit Camp Mission
    Spawns fortified camp with AI defenders

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data

    v2.0: Enhanced AI spawning with verification
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Camp_%1", floor(random 9999)];
[3, format ["=== CAMP MISSION START: %1 at %2 (%3) ===", _missionName, _pos, _difficulty]] call A3XAI_fnc_log;

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

// ✅ v3.20: REDUCED AI - Max 5 per mission
private _defenderCount = switch (_difficulty) do {
    case "easy": {3};
    case "medium": {4};
    case "hard": {5};
    case "extreme": {5};
    default {4};
};

// Spawn defenders
private _group = createGroup [EAST, true];

// ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
if (isNull _group) exitWith {
    [1, format ["Camp '%1' FAILED: createGroup returned null - EAST group limit reached", _missionName]] call A3XAI_fnc_log;
    createHashMap
};

private _groupSide = side _group;
if (_groupSide != EAST) exitWith {
    private _eastGroups = {side _x == EAST} count allGroups;
    deleteGroup _group;
    [1, format ["Camp '%1' FAILED: Group created as %2 instead of EAST (EAST groups: %3/144)", _missionName, _groupSide, _eastGroups]] call A3XAI_fnc_log;
    createHashMap
};

for "_i" from 0 to (_defenderCount - 1) do {
    private _defPos = _campPos getPos [15 + random 10, random 360];

    private _unitType = "O_Soldier_F";  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)
    private _unit = _group createUnit [_unitType, _defPos, [], 0, "NONE"];

    // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
    _unit allowDamage false;

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Set group to defend camp
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// ✅ FIX: Use defensive waypoints (small radius, GUARD type) instead of long patrol
// Add tight defensive perimeter waypoints - AI stay close to camp
for "_i" from 0 to 3 do {
    private _wpPos = _campPos getPos [12, 90 * _i];  // 12m radius, 4 points (was 25m, 6 points)
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "GUARD";  // GUARD stays in area vs MOVE (wanders)
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "COMBAT";  // Stay alert (was SAFE)
    _wp setWaypointCombatMode "RED";  // Engage on sight (was YELLOW)
    _wp setWaypointCompletionRadius 15;  // Stay within 15m of waypoint
};

// Return to center and loop
private _wp = _group addWaypoint [_campPos, 0];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 10;

// Spawn patrol vehicles (higher difficulties)
private _vehicles = [];
if (_difficulty in ["hard", "extreme"]) then {
    private _vehCount = if (_difficulty == "extreme") then {2} else {1};

    for "_i" from 0 to (_vehCount - 1) do {
        private _vehPos = _campPos getPos [40 + random 10, (360 / _vehCount) * _i];
        private _vehClass = selectRandom [
            "Exile_Car_Offroad_Armed_Guerilla01",
            "ivory_suburban_marked", "ivory_charger_marked", "ivory_challenger_marked"
        ];

        private _vehicle = createVehicle [_vehClass, _vehPos, [], 0, "NONE"];

        // ✅ v3.9: IMMEDIATE vehicle protection - prevents explosion during setup
        _vehicle allowDamage false;

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

// Verify AI actually spawned
private _actualAI = count units _group;
if (_actualAI == 0) then {
    [1, format ["CAMP MISSION FAILED: %1 - No AI spawned (expected %2)", _missionName, _defenderCount]] call A3XAI_fnc_log;
} else {
    [3, format ["=== CAMP MISSION SUCCESS: %1 - %2/%3 defenders spawned ===", _missionName, _actualAI, _defenderCount]] call A3XAI_fnc_log;
};

_missionData
