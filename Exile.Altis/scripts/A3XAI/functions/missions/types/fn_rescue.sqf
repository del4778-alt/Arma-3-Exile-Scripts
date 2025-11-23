/*
    A3XAI Elite - Rescue Mission
    Spawns captive hostages guarded by AI, with extraction vehicle

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Rescue_%1", floor(random 9999)];
[3, format ["Spawning rescue mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid rescue spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "rescue"],
    ["status", "active"],
    ["triggerType", "hybrid"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["hostages", []],
    ["markers", []]
];

// Find suitable location
private _rescuePos = [_pos, 20, 80, 5, 0, 0.15, 0] call BIS_fnc_findSafePos;

// Create holding area structures
private _missionObjects = [];

// Central holding cage/building
private _cage = "Land_Cargo_House_V3_F" createVehicle _rescuePos;
_missionObjects pushBack _cage;

// Guard posts
for "_i" from 0 to 3 do {
    private _guardPos = _rescuePos getPos [15, 90 * _i];
    private _cover = "Land_BagBunker_Small_F" createVehicle _guardPos;
    _cover setDir (90 * _i);
    _missionObjects pushBack _cover;
};

// Determine guard count
private _guardCount = switch (_difficulty) do {
    case "easy": {4};
    case "medium": {6};
    case "hard": {8};
    case "extreme": {10};
    default {4};
};

// Spawn guards
private _group = createGroup [EAST, true];

// ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
if (isNull _group) exitWith {
    [1, format ["Rescue '%1' FAILED: createGroup returned null - EAST group limit reached", _missionName]] call A3XAI_fnc_log;
    createHashMap
};

private _groupSide = side _group;
if (_groupSide != EAST) exitWith {
    private _eastGroups = {side _x == EAST} count allGroups;
    deleteGroup _group;
    [1, format ["Rescue '%1' FAILED: Group created as %2 instead of EAST (EAST groups: %3/144)", _missionName, _groupSide, _eastGroups]] call A3XAI_fnc_log;
    createHashMap
};

for "_i" from 0 to (_guardCount - 1) do {
    private _guardPos = _rescuePos getPos [12 + random 8, random 360];

    private _unitType = "O_Soldier_F";  // FIX: Changed from I_Soldier_F (INDEPENDENT) to O_Soldier_F (EAST)
    private _unit = _group createUnit [_unitType, _guardPos, [], 0, "NONE"];

    // Initialize AI
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;
};

// Set group to defend hostages
[_group, "defend"] call A3XAI_fnc_setGroupBehavior;

// ✅ FIX: Use defensive waypoints (small radius, GUARD type) instead of patrol
// Guards should stay close to hostages, not wander off
for "_i" from 0 to 3 do {
    private _wpPos = _rescuePos getPos [15, 90 * _i];  // 15m radius, 4 points (was 20m, 5 points)
    private _wp = _group addWaypoint [_wpPos, 0];
    _wp setWaypointType "GUARD";  // GUARD stays in area vs MOVE (wanders)
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointBehaviour "COMBAT";  // Stay alert for rescue attempts (was SAFE)
    _wp setWaypointCombatMode "RED";  // Engage threats (was YELLOW)
    _wp setWaypointCompletionRadius 12;  // Stay within 12m of waypoint
};

// Return to hostages and loop
private _wp = _group addWaypoint [_rescuePos, 0];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 10;

// Spawn hostages
private _hostageCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {3};
    case "extreme": {4};
    default {2};
};

private _hostages = [];
private _hostageTypes = ["C_man_1", "C_man_polo_1_F", "C_man_polo_2_F", "C_Man_casual_1_F"];

for "_i" from 0 to (_hostageCount - 1) do {
    private _hostagePos = _rescuePos getPos [3, (360 / _hostageCount) * _i];

    // ✅ FIX: Set captive in init string so it's applied BEFORE AI can target
    private _hostage = (selectRandom _hostageTypes) createUnit [_hostagePos, createGroup CIVILIAN, "this disableAI 'MOVE'; this setCaptive true; this setVariable ['A3XAI_hostage', true, true];"];

    _hostage setDamage 0.25; // Injured
    _hostage setCaptive true;  // Redundant but ensures it's set
    _hostage setVariable ["A3XAI_hostage", true, true];
    _hostage setVariable ["A3XAI_mission", _missionName, true];

    // ✅ FIX: Add zombie protection - hostages should NOT spawn zombies when killed
    _hostage setVariable ["NoRessurect", true, true];
    _hostage setVariable ["RVG_ZedIgnore", true, true];
    _hostage setVariable ["RYANZOMBIES_ignore", true, true];

    // ✅ FIX: Make guards explicitly not target this hostage
    {
        _x reveal [_hostage, 0];  // Guards don't know about hostage
        _x forgetTarget _hostage;
    } forEach units _group;

    // Add rescue action
    _hostage addAction [
        "Rescue Hostage",
        {
            params ["_target", "_caller"];

            // Free hostage
            _target enableAI "MOVE";
            _target setCaptive false;
            _target setVariable ["A3XAI_rescued", true, true];

            // Heal slightly
            _target setDamage 0;

            // Join rescuer's group (optional)
            if (A3XAI_hostagesJoinRescuer) then {
                [_target] join (group _caller);
            };

            // Remove action
            _target removeAction (_this select 2);

            // Reward
            if (isClass (configFile >> "CfgPatches" >> "exile_server")) then {
                private _reward = switch (A3XAI_currentDifficulty) do {
                    case "easy": {500};
                    case "medium": {1000};
                    case "hard": {2000};
                    case "extreme": {5000};
                    default {500};
                };

                [_caller, "showFragRequest", [[format ["+%1 Respect for rescuing hostage", _reward]], 5]] call ExileClient_system_network_send;
                private _respect = _caller getVariable ["ExileScore", 0];
                _caller setVariable ["ExileScore", _respect + _reward];
            };

            systemChat format ["Hostage rescued! %1 remaining.", count ((_target getVariable ["A3XAI_mission", ""]) getVariable ["hostages", []]) - 1];
        },
        [],
        6,
        true,
        true,
        "",
        "!(_target getVariable ['A3XAI_rescued', false]) && _this distance _target < 3"
    ];

    _hostages pushBack _hostage;
};

// Spawn extraction vehicle
private _extractVehPos = _rescuePos getPos [50, random 360];
private _extractVeh = "O_Heli_Light_02_unarmed_F" createVehicle _extractVehPos;  // FIX: Changed from I_Heli (INDEPENDENT) to O_Heli (EAST)
_extractVeh setFuel 0; // No fuel until guards dead
_extractVeh setDamage 0.3; // Damaged, needs repair
_extractVeh lock 2; // Locked until rescued

_extractVeh setVariable ["A3XAI_extractionVehicle", true];
_extractVeh setVariable ["A3XAI_mission", _missionName];

// Add extraction vehicle action
_extractVeh addAction [
    "Refuel & Unlock Vehicle",
    {
        params ["_target", "_caller"];

        private _mission = _target getVariable ["A3XAI_mission", ""];
        if (_mission == "") exitWith {systemChat "Mission data error!"};

        // Check if all guards dead
        private _missionData = A3XAI_activeMissions select {(_x get "name") == _mission};
        if (count _missionData == 0) exitWith {};

        private _groups = (_missionData select 0) get "aiGroups";
        private _allDead = true;
        {
            if (count units _x > 0) then {_allDead = false};
        } forEach _groups;

        if (!_allDead) exitWith {
            systemChat "Clear the area of hostiles first!";
        };

        // Refuel and unlock
        _target setFuel 1;
        _target lock 0;
        _target setDamage 0;

        systemChat "Extraction vehicle ready!";

        // Remove action
        _target removeAction (_this select 2);
    },
    [],
    6,
    false,
    true,
    "",
    "_this distance _target < 5"
];

[_extractVeh] call A3XAI_fnc_initVehicle;
_missionObjects pushBack _extractVeh;

// Create reward crates
private _lootCount = 1;
private _lootBoxes = [];

private _lootPos = _rescuePos getPos [10, 90];
private _box = "Box_NATO_Support_F" createVehicle _lootPos;

[_box, _difficulty, "rescue"] call A3XAI_fnc_spawnLoot;

// Add loot detection
_box addEventHandler ["ContainerOpened", {
    params ["_container", "_player"];
    _container setVariable ["looted", true, true];
}];

_lootBoxes pushBack _box;
_missionObjects pushBack _box;

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _rescuePos];
    _marker setMarkerType "mil_marker";
    _marker setMarkerColor "ColorGreen";
    _marker setMarkerText format ["Rescue Mission (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", [_extractVeh]];
_missionData set ["lootBoxes", _lootBoxes];
_missionData set ["hostages", _hostages];
_missionData set ["missionObjects", _missionObjects];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Hostage rescue operation (%1 difficulty, %2 hostages)", _difficulty, _hostageCount];
    remoteExec ["systemChat", -2];
};

[3, format ["Rescue mission '%1' spawned with %2 hostages and %3 guards", _missionName, _hostageCount, _guardCount]] call A3XAI_fnc_log;

_missionData
