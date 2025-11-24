/*
    A3XAI Elite - Highway Patrol Mission
    Spawns armed vehicle patrols on highways between Exile spawn zones

    These are continuous patrols that roam the main roads, providing
    dynamic encounters for players traveling between zones.

    Parameters:
        0: ARRAY - Spawn position [x,y,z] (optional - will pick random highway if empty)
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params [["_pos", []], ["_difficulty", "medium"]];

// ============================================================
// EXILE SPAWN ZONE COORDINATES (Altis)
// ============================================================
private _spawnZones = [
    ["Kavala", [3874, 13281, 0]],
    ["Zaros", [9927, 12083, 0]],
    ["Selekano", [20978, 7046, 0]],
    ["Pyrgos", [17138, 12719, 0]],
    ["Sofia", [25713, 21330, 0]],
    ["Syrta", [8613, 18272, 0]]
];

// ============================================================
// HIGHWAY ROUTES BETWEEN ZONES
// These are the major road corridors
// ============================================================
private _highwayRoutes = [
    // [Start Zone, End Zone, Midpoint for spawn variety]
    ["Kavala", "Zaros", [6500, 12500, 0]],
    ["Kavala", "Syrta", [6000, 16000, 0]],
    ["Zaros", "Pyrgos", [13500, 12400, 0]],
    ["Pyrgos", "Selekano", [19000, 10000, 0]],
    ["Pyrgos", "Sofia", [21000, 17000, 0]],
    ["Sofia", "Syrta", [17000, 20000, 0]],
    ["Syrta", "Zaros", [9200, 15000, 0]],
    ["Selekano", "Sofia", [23000, 14000, 0]]
];

private _missionName = format ["HighwayPatrol_%1", floor(random 9999)];
[3, format ["Spawning highway patrol (difficulty: %1)", _difficulty]] call A3XAI_fnc_log;

// ============================================================
// SELECT SPAWN LOCATION
// ============================================================
private _routeData = [];
private _startZone = "";
private _endZone = "";

if (count _pos == 0) then {
    // Pick a random highway route
    _routeData = selectRandom _highwayRoutes;
    _startZone = _routeData select 0;
    _endZone = _routeData select 1;
    _pos = _routeData select 2;  // Spawn at midpoint

    // Add some randomization to spawn point along the route
    private _startPos = (_spawnZones select {(_x select 0) == _startZone}) select 0 select 1;
    private _endPos = (_spawnZones select {(_x select 0) == _endZone}) select 0 select 1;

    if (!isNil "_startPos" && !isNil "_endPos") then {
        // Pick random point between start/midpoint or midpoint/end
        private _t = 0.3 + random 0.4;  // 30-70% along route
        if (random 1 > 0.5) then {
            _pos = [
                (_startPos select 0) + ((_pos select 0) - (_startPos select 0)) * _t,
                (_startPos select 1) + ((_pos select 1) - (_startPos select 1)) * _t,
                0
            ];
        } else {
            _pos = [
                (_pos select 0) + ((_endPos select 0) - (_pos select 0)) * _t,
                (_pos select 1) + ((_endPos select 1) - (_pos select 1)) * _t,
                0
            ];
        };
    };
};

// Find nearest road to spawn position
private _roads = _pos nearRoads 500;
if (count _roads == 0) then {
    _roads = _pos nearRoads 1000;
};

if (count _roads < 3) exitWith {
    [2, format ["No highway found near: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Find best road (highest quality)
private _bestRoad = objNull;
private _bestQuality = 0;
{
    private _quality = [_x] call A3XAI_fnc_getRoadQuality;
    if (_quality > _bestQuality) then {
        _bestQuality = _quality;
        _bestRoad = _x;
    };
} forEach _roads;

if (isNull _bestRoad) exitWith {
    [2, format ["No valid road at: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

private _spawnPos = getPos _bestRoad;
private _roadDir = (roadsConnectedTo _bestRoad) apply {_spawnPos getDir (getPos _x)};
private _patrolDir = if (count _roadDir > 0) then {_roadDir select 0} else {random 360};

// ============================================================
// VEHICLE SELECTION (Fast patrol vehicles)
// ============================================================
private _vehicleClasses = switch (_difficulty) do {
    case "easy": {[
        "Exile_Car_Offroad_Armed_Guerilla01",
        "Exile_Car_Offroad_Armed_Guerilla02"
    ]};
    case "medium": {[
        "ivory_charger_marked",
        "ivory_taurus_marked",
        "ivory_cv_marked",
        "ivory_impala_marked"
    ]};
    case "hard": {[
        "ivory_challenger_marked",
        "ivory_suburban_marked",
        "ivory_charger_slicktop"
    ]};
    case "extreme": {[
        "ivory_evox_marked",
        "ivory_wrx_marked",
        "ivory_rs4_marked",
        "Exile_Car_BTR40_MG_Green"
    ]};
    default {["Exile_Car_Offroad_Armed_Guerilla01"]};
};

// 1-2 vehicles for highway patrol (smaller than convoy)
private _vehicleCount = switch (_difficulty) do {
    case "easy": {1};
    case "medium": {1 + floor(random 2)};  // 1-2
    case "hard": {2};
    case "extreme": {2};
    default {1};
};

// ============================================================
// CREATE MISSION DATA
// ============================================================
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "highwayPatrol"],
    ["status", "active"],
    ["triggerType", "roaming"],
    ["position", _spawnPos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["route", [_startZone, _endZone]],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// ============================================================
// GENERATE PATROL ROUTE (Long highway route)
// ============================================================
private _routeLength = switch (_difficulty) do {
    case "easy": {3000};
    case "medium": {5000};
    case "hard": {7000};
    case "extreme": {10000};
    default {4000};
};

private _waypoints = [_spawnPos, _routeLength, 15] call A3XAI_fnc_generateRoute;
if (count _waypoints < 5) then {
    // Fallback: generate simpler route
    _waypoints = [];
    private _currentPos = _spawnPos;
    for "_i" from 0 to 10 do {
        private _nextRoads = _currentPos nearRoads 500;
        if (count _nextRoads > 0) then {
            private _nextRoad = selectRandom _nextRoads;
            private _nextPos = getPos _nextRoad;
            if (_nextPos distance2D _currentPos > 200) then {
                _waypoints pushBack _nextPos;
                _currentPos = _nextPos;
            };
        };
    };
};

if (count _waypoints < 3) exitWith {
    [2, format ["Failed to generate highway route at: %1", _spawnPos]] call A3XAI_fnc_log;
    createHashMap
};

// ============================================================
// SPAWN PATROL VEHICLES
// ============================================================
private _allGroups = [];
private _allVehicles = [];
private _vehicleSpawnPos = _spawnPos;

for "_i" from 0 to (_vehicleCount - 1) do {
    private _vehicleClass = selectRandom _vehicleClasses;

    // Find road position for this vehicle
    private _roadPos = [_vehicleSpawnPos] call A3XAI_fnc_findValidRoad;
    if (count _roadPos == 0) then {
        _roadPos = _vehicleSpawnPos;
    };

    // Spawn vehicle facing patrol direction
    private _vehicle = createVehicle [_vehicleClass, _roadPos, [], 0, "NONE"];

    // ✅ v3.9: IMMEDIATE vehicle protection - prevents explosion during crew loading
    _vehicle allowDamage false;

    _vehicle setDir _patrolDir;
    _vehicle setFuel (0.8 + random 0.2);
    _vehicle lock 2;

    // Create crew (2-3 per vehicle)
    private _group = createGroup [EAST, true];

    // ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
    if (isNull _group) then {
        [1, format ["Highway patrol vehicle %1 SKIPPED: createGroup returned null - EAST group limit reached", _v]] call A3XAI_fnc_log;
        deleteVehicle _vehicle;
        continue;
    };

    private _groupSide = side _group;
    if (_groupSide != EAST) then {
        private _eastGroups = {side _x == EAST} count allGroups;
        deleteGroup _group;
        deleteVehicle _vehicle;
        [1, format ["Highway patrol vehicle %1 SKIPPED: Group created as %2 instead of EAST (EAST groups: %3/144)", _v, _groupSide, _eastGroups]] call A3XAI_fnc_log;
        continue;
    };

    private _crewCount = 2 + floor(random 2);  // 2-3 crew

    for "_j" from 0 to (_crewCount - 1) do {
        private _unitType = "O_Soldier_F";
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
            _unit assignAsCargo _vehicle;
            _unit moveInAny _vehicle;
        };
    };

    // Set group behavior for patrol - HIGH-SPEED pursuit mode
    // v3.18: Changed to CARELESS/FULL for maximum pursuit speed (was AWARE/YELLOW/NORMAL)
    _group setBehaviour "CARELESS";   // No speed limit from behavior
    _group setCombatMode "RED";       // v3.18: Changed from YELLOW - engage at will
    _group setSpeedMode "FULL";       // Maximum speed
    _group setFormation "COLUMN";

    // Add patrol waypoints
    // ✅ v3.18: HIGH-SPEED highway patrol - FULL speed + CARELESS (was NORMAL/SAFE)
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "FULL";          // v3.18: Changed from NORMAL for max speed
        _wp setWaypointBehaviour "CARELESS";  // v3.18: Changed from SAFE - no speed cap
        _wp setWaypointFormation "COLUMN";
        _wp setWaypointCombatMode "RED";      // v3.18: Changed from YELLOW
        _wp setWaypointCompletionRadius 15;   // Prevents offroad shortcuts
    } forEach _waypoints;

    // Cycle waypoints (continuous patrol)
    private _wp = _group addWaypoint [_waypoints select 0, 0];
    _wp setWaypointType "CYCLE";

    // Initialize vehicle with A3XAI
    [_vehicle] call A3XAI_fnc_initVehicle;
    [_vehicle] call A3XAI_fnc_addVehicleEventHandlers;

    // EAD integration for highway driving
    if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {
        private _driver = driver _vehicle;
        if (!isNull _driver) then {
            private _result = [EAD_fnc_registerDriver, [_driver, _vehicle], "EAD_highway"] call A3XAI_fnc_safeCall;
            if (!isNil "_result") then {
                _vehicle setVariable ["EAD_enabled", true];
                _vehicle setVariable ["EAD_highway", true];
                // Highway patrol gets speed boost
                _vehicle setVariable ["EAD_speedBoost", 1.15];
            };
        };
    };

    // Track vehicle and group
    _vehicle setVariable ["A3XAI_mission", _missionName];
    _vehicle setVariable ["A3XAI_difficulty", _difficulty];
    _vehicle setVariable ["A3XAI_patrolType", "highway"];
    _group setVariable ["A3XAI_mission", _missionName];

    _allGroups pushBack _group;
    _allVehicles pushBack _vehicle;

    // Next vehicle spawns 30m behind (tighter than convoy)
    _vehicleSpawnPos = _vehicleSpawnPos getPos [30 * (_i + 1), _patrolDir + 180];
};

// ============================================================
// ADD LOOT TO PATROL VEHICLES
// ============================================================
private _lootBoxes = [];
{
    // Create small supply crate in each vehicle
    private _lootBox = "Box_East_Support_F" createVehicle (position _x);
    _lootBox attachTo [_x, [0, -0.5, 0.3]];

    // Less loot than convoy (it's just a patrol)
    private _lootDifficulty = if (_difficulty == "extreme") then {"hard"} else {_difficulty};
    [_lootBox, _lootDifficulty, "patrol"] call A3XAI_fnc_spawnLoot;

    _lootBox addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _lootBox;
} forEach _allVehicles;

// ============================================================
// CREATE MARKERS (optional - can be disabled for stealth patrols)
// ============================================================
// Highway patrols are unmarked by default - they're surprise encounters
// Uncomment below to show markers:
/*
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _spawnPos];
    _marker setMarkerType "mil_warning";
    _marker setMarkerColor "ColorOrange";
    _marker setMarkerText format ["Highway Patrol (%1)", _difficulty];
    _missionData set ["markers", [_marker]];
};
*/

// ============================================================
// STORE MISSION DATA
// ============================================================
_missionData set ["aiGroups", _allGroups];
_missionData set ["vehicles", _allVehicles];
_missionData set ["lootBoxes", _lootBoxes];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Log success
[3, format ["Highway patrol spawned: %1 vehicles on %2-%3 route (difficulty: %4)",
    count _allVehicles, _startZone, _endZone, _difficulty]] call A3XAI_fnc_log;

// Return mission data
_missionData
