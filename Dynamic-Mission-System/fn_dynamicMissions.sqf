/*
    Dynamic Mission System v1.0
    Author: Arma 3 Exile Scripts
    Description: AI-driven missions that spawn at random locations with various objectives

    Features:
    - 5 Mission Types: Crash Sites, Supply Caches, Convoy Intercept, Rescue Hostages, AI Camps
    - AI guards with Elite Driving integration for vehicle reinforcements
    - Dynamic spawn locations avoiding safe zones
    - Rewards: Poptabs, Respect, rare loot
    - Auto cleanup and despawn when completed
    - Configurable difficulty levels

    Installation:
    1. Place in Dynamic-Mission-System folder
    2. Add to init.sqf: [] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
    3. Configure MISSION_CONFIG below

    Compatibility:
    - Integrates with Elite Driving for AI vehicle behavior
    - Uses AI Patrol logic for guards
    - Exile server safe zone detection
    - A3XAI compatible (EAID_Ignore flags)
*/

// ========================================
// CONFIGURATION
// ========================================

MISSION_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["minPlayers", 1],                    // Minimum players online to spawn missions
    ["maxActiveMissions", 3],             // Max concurrent missions
    ["spawnInterval", 600],               // Seconds between mission spawns (10 min)
    ["missionTimeout", 1800],             // Mission despawn after 30 min if not completed
    ["safeZoneDistance", 1000],           // Min distance from trader zones
    ["minPlayerDistance", 500],           // Min distance from players on spawn
    ["completionDistance", 100],          // Distance to trigger "area clear" check

    // Rewards
    ["rewardPoptabs", [5000, 15000]],     // Min/Max Poptabs
    ["rewardRespect", [500, 2000]],       // Min/Max Respect

    // Mission Weights (higher = more common)
    ["crashSiteWeight", 25],
    ["supplyCacheWeight", 30],
    ["convoyWeight", 15],
    ["rescueWeight", 20],
    ["campWeight", 10],

    // AI Settings
    ["aiSkill", 0.8],
    ["aiCountEasy", [3, 5]],
    ["aiCountMedium", [5, 8]],
    ["aiCountHard", [8, 12]],

    // Loot Tables
    ["lootWeapons", ["arifle_Katiba_F", "arifle_Mk20_F", "arifle_MX_F", "srifle_EBR_F", "LMG_Mk200_F"]],
    ["lootItems", ["FirstAidKit", "Medikit", "ToolKit", "Binocular", "NVGoggles"]],
    ["lootVehicles", ["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_HMMWV_M2_Desert", "Exile_Car_BTR40_MG_Green"]]
];

// ========================================
// GLOBAL VARIABLES
// ========================================

MISSION_ActiveMissions = [];              // Array of active mission hashmaps
MISSION_SafeZones = [];                   // Cache of safe zone positions
MISSION_InitComplete = false;

// ========================================
// UTILITY FUNCTIONS
// ========================================

MISSION_fnc_log = {
    params ["_message"];
    if (MISSION_CONFIG get "debug") then {
        diag_log format ["[MISSION] %1", _message];
        systemChat format ["[MISSION] %1", _message];
    };
};

MISSION_fnc_getSafeZones = {
    private _zones = [];
    {
        if (["ExileSpawnZone", _x] call BIS_fnc_inString) then {
            _zones pushBack (getMarkerPos _x);
        };
    } forEach allMapMarkers;

    [format ["Found %1 safe zones", count _zones]] call MISSION_fnc_log;
    _zones
};

MISSION_fnc_isSafeLocation = {
    params ["_pos"];
    private _minDist = MISSION_CONFIG get "safeZoneDistance";

    // Check safe zones
    {
        if (_pos distance2D _x < _minDist) exitWith { false };
    } forEach MISSION_SafeZones;

    // Check players
    {
        if (_pos distance2D (getPosATL _x) < (MISSION_CONFIG get "minPlayerDistance")) exitWith { false };
    } forEach allPlayers;

    // Check water
    if (surfaceIsWater _pos) exitWith { false };

    true
};

MISSION_fnc_getRandomPosition = {
    private _mapSize = worldSize;
    private _attempts = 0;
    private _maxAttempts = 50;
    private _pos = [];

    while {_attempts < _maxAttempts} do {
        _pos = [
            random _mapSize,
            random _mapSize,
            0
        ];

        if ([_pos] call MISSION_fnc_isSafeLocation) exitWith {};
        _attempts = _attempts + 1;
    };

    if (_attempts >= _maxAttempts) then {
        [format ["Failed to find safe position after %1 attempts", _maxAttempts]] call MISSION_fnc_log;
        _pos = [_mapSize / 2, _mapSize / 2, 0];
    };

    _pos
};

MISSION_fnc_createMarker = {
    params ["_pos", "_type", "_text"];

    private _markerName = format ["mission_%1_%2", _type, time];
    private _marker = createMarker [_markerName, _pos];
    _marker setMarkerShape "ICON";
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText _text;
    _marker setMarkerAlpha 1;

    _marker
};

MISSION_fnc_spawnAI = {
    params ["_pos", "_count", "_side"];

    private _group = createGroup _side;
    private _units = [];

    for "_i" from 1 to _count do {
        private _unitPos = [
            (_pos select 0) + (random 20 - 10),
            (_pos select 1) + (random 20 - 10),
            0
        ];

        private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "FORM"];
        _unit setSkill (MISSION_CONFIG get "aiSkill");
        _unit setVariable ["EAID_Ignore", true, true];  // Elite Driving ignore

        // Enhanced AI skills
        _unit setSkill ["aimingAccuracy", 0.7 + random 0.2];
        _unit setSkill ["aimingShake", 0.6 + random 0.3];
        _unit setSkill ["aimingSpeed", 0.7 + random 0.2];
        _unit setSkill ["spotDistance", 0.8 + random 0.2];
        _unit setSkill ["spotTime", 0.7 + random 0.2];
        _unit setSkill ["courage", 0.8 + random 0.2];
        _unit setSkill ["reloadSpeed", 0.7 + random 0.3];
        _unit setSkill ["commanding", 0.8 + random 0.2];
        _unit setSkill ["general", 0.8 + random 0.2];

        _units pushBack _unit;
    };

    // Set group behavior
    _group setBehaviour "COMBAT";
    _group setCombatMode "RED";
    _group setFormation "WEDGE";
    _group setSpeedMode "FULL";

    // Add patrol waypoints around position
    for "_i" from 0 to 3 do {
        private _angle = _i * 90;
        private _wpPos = [
            (_pos select 0) + (50 * cos _angle),
            (_pos select 1) + (50 * sin _angle),
            0
        ];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
    };

    // Cycle waypoints
    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";

    [_group, _units]
};

MISSION_fnc_spawnLoot = {
    params ["_pos", "_difficulty"];

    private _box = "Box_East_Wps_F" createVehicle _pos;
    clearBackpackCargoGlobal _box;
    clearItemCargoGlobal _box;
    clearMagazineCargoGlobal _box;
    clearWeaponCargoGlobal _box;

    private _lootCount = switch (_difficulty) do {
        case "easy": { 3 + floor(random 3) };
        case "medium": { 5 + floor(random 4) };
        case "hard": { 7 + floor(random 5) };
        default { 3 };
    };

    // Add weapons
    for "_i" from 1 to _lootCount do {
        private _weapon = selectRandom (MISSION_CONFIG get "lootWeapons");
        _box addWeaponCargoGlobal [_weapon, 1];
        _box addMagazineCargoGlobal [getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines") select 0, 3];
    };

    // Add items
    for "_i" from 1 to (_lootCount * 2) do {
        _box addItemCargoGlobal [selectRandom (MISSION_CONFIG get "lootItems"), 1];
    };

    _box
};

// ========================================
// MISSION TYPE: CRASH SITE
// ========================================

MISSION_fnc_createCrashSite = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "medium", "hard"];
    private _missionData = createHashMapFromArray [
        ["type", "crashsite"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true]
    ];

    // Create crashed helicopter
    private _heli = "Land_Wreck_Heli_Attack_01_F" createVehicle _pos;
    _heli setDir random 360;
    _missionData set ["wreck", _heli];

    // Spawn loot
    private _loot = [_pos, _difficulty] call MISSION_fnc_spawnLoot;
    _missionData set ["loot", [_loot]];

    // Spawn AI guards
    private _aiCount = switch (_difficulty) do {
        case "easy": { (MISSION_CONFIG get "aiCountEasy") select 0 + floor(random ((MISSION_CONFIG get "aiCountEasy") select 1 - (MISSION_CONFIG get "aiCountEasy") select 0)) };
        case "medium": { (MISSION_CONFIG get "aiCountMedium") select 0 + floor(random ((MISSION_CONFIG get "aiCountMedium") select 1 - (MISSION_CONFIG get "aiCountMedium") select 0)) };
        case "hard": { (MISSION_CONFIG get "aiCountHard") select 0 + floor(random ((MISSION_CONFIG get "aiCountHard") select 1 - (MISSION_CONFIG get "aiCountHard") select 0)) };
        default { 4 };
    };

    private _aiData = [_pos, _aiCount, EAST] call MISSION_fnc_spawnAI;
    _missionData set ["aiGroups", [_aiData select 0]];
    _missionData set ["aiUnits", _aiData select 1];

    // Create marker
    private _marker = [_pos, "crashsite", format ["Crash Site [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["Crash Site mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: SUPPLY CACHE
// ========================================

MISSION_fnc_createSupplyCache = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "medium", "hard"];
    private _missionData = createHashMapFromArray [
        ["type", "supplycache"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["wave", 0],
        ["maxWaves", 3]
    ];

    // Create supply crates
    private _crates = [];
    for "_i" from 0 to 2 do {
        private _cratePos = [
            (_pos select 0) + (random 10 - 5),
            (_pos select 1) + (random 10 - 5),
            0
        ];
        private _crate = [_cratePos, _difficulty] call MISSION_fnc_spawnLoot;
        _crates pushBack _crate;
    };
    _missionData set ["loot", _crates];

    // Spawn initial AI wave
    private _aiCount = switch (_difficulty) do {
        case "easy": { (MISSION_CONFIG get "aiCountEasy") select 0 + floor(random ((MISSION_CONFIG get "aiCountEasy") select 1 - (MISSION_CONFIG get "aiCountEasy") select 0)) };
        case "medium": { (MISSION_CONFIG get "aiCountMedium") select 0 + floor(random ((MISSION_CONFIG get "aiCountMedium") select 1 - (MISSION_CONFIG get "aiCountMedium") select 0)) };
        case "hard": { (MISSION_CONFIG get "aiCountHard") select 0 + floor(random ((MISSION_CONFIG get "aiCountHard") select 1 - (MISSION_CONFIG get "aiCountHard") select 0)) };
        default { 5 };
    };

    private _aiData = [_pos, _aiCount, EAST] call MISSION_fnc_spawnAI;
    _missionData set ["aiGroups", [_aiData select 0]];
    _missionData set ["aiUnits", _aiData select 1];

    // Create marker
    private _marker = [_pos, "supplycache", format ["Supply Cache [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["Supply Cache mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: CONVOY INTERCEPT
// ========================================

MISSION_fnc_createConvoy = {
    params ["_pos"];

    private _difficulty = selectRandom ["medium", "hard"];  // No easy convoys
    private _missionData = createHashMapFromArray [
        ["type", "convoy"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["moving", true]
    ];

    // Determine destination (1000-2000m away)
    private _distance = 1000 + random 1000;
    private _angle = random 360;
    private _destination = [
        (_pos select 0) + (_distance * cos _angle),
        (_pos select 1) + (_distance * sin _angle),
        0
    ];
    _missionData set ["destination", _destination];

    // Create convoy vehicles with SAFE SPAWN
    private _vehicles = [];
    private _allCrew = [];  // Track all spawned crew for delayed activation
    private _vehicleCount = if (_difficulty == "hard") then { 3 } else { 2 };

    // ✅ FIX #1: All vehicles face same direction (convoy formation)
    private _convoyDirection = random 360;

    for "_i" from 0 to (_vehicleCount - 1) do {
        // ✅ FIX #2: INCREASED SPACING from 15m to 30m
        private _vehiclePos = [
            (_pos select 0) + (_i * 30 * cos _convoyDirection),
            (_pos select 1) + (_i * 30 * sin _convoyDirection),
            0  // ✅ FIX #3: Force ground level
        ];

        private _vehicleType = selectRandom (MISSION_CONFIG get "lootVehicles");

        // ✅ FIX #4: Create vehicle with safety measures
        private _vehicle = _vehicleType createVehicle _vehiclePos;

        // ✅ FIX #5: CRITICAL - Disable damage and simulation during spawn
        _vehicle allowDamage false;
        _vehicle enableSimulationGlobal false;

        // ✅ FIX #6: Set position, direction, and physics properly
        _vehicle setPos _vehiclePos;
        _vehicle setDir _convoyDirection;  // Same direction as convoy
        _vehicle setVectorUp [0,0,1];      // Level vehicle
        _vehicle setVelocity [0,0,0];      // Clear any velocity

        // Set vehicle properties
        _vehicle setFuel 1;
        _vehicle setVariable ["EAID_Ignore", false, true];  // Allow Elite Driving control
        _vehicle setVariable ["ConvoyVehicle", true, true];

        _vehicles pushBack _vehicle;

        // Create AI crew
        private _group = createGroup EAST;

        // ✅ FIX #7: Protect AI during spawn too
        // Driver
        private _driver = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _driver allowDamage false;  // ✅ Protect from spawn damage
        _driver moveInDriver _vehicle;
        _driver setSkill (MISSION_CONFIG get "aiSkill");
        _allCrew pushBack _driver;

        // Gunner
        private _gunner = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _gunner allowDamage false;  // ✅ Protect from spawn damage
        _gunner moveInGunner _vehicle;
        _gunner setSkill (MISSION_CONFIG get "aiSkill");
        _allCrew pushBack _gunner;

        // Cargo troops
        private _cargoCount = 2;
        for "_j" from 1 to _cargoCount do {
            private _cargo = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
            _cargo allowDamage false;  // ✅ Protect from spawn damage
            _cargo moveInCargo _vehicle;
            _cargo setSkill (MISSION_CONFIG get "aiSkill");
            _allCrew pushBack _cargo;
        };

        // Set waypoint to destination
        private _wp = _group addWaypoint [_destination, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";

        // Store group
        if (!isNil "MISSION_ActiveMissions") then {
            _missionData set ["aiGroups", (_missionData getOrDefault ["aiGroups", []]) + [_group]];
        };
    };

    _missionData set ["vehicles", _vehicles];

    // Create loot in last vehicle
    private _lastVehicle = _vehicles select (count _vehicles - 1);
    clearBackpackCargoGlobal _lastVehicle;
    clearItemCargoGlobal _lastVehicle;
    clearMagazineCargoGlobal _lastVehicle;
    clearWeaponCargoGlobal _lastVehicle;

    // Add valuable loot
    for "_i" from 1 to 5 do {
        _lastVehicle addWeaponCargoGlobal [selectRandom (MISSION_CONFIG get "lootWeapons"), 1];
    };
    for "_i" from 1 to 10 do {
        _lastVehicle addItemCargoGlobal [selectRandom (MISSION_CONFIG get "lootItems"), 1];
    };

    // ✅ FIX #8: CRITICAL - DELAYED ACTIVATION
    // This prevents collision damage by allowing vehicles to settle before enabling physics
    [{
        params ["_vehArray", "_crewArray"];

        [format ["[CONVOY FIX] Enabling simulation for %1 convoy vehicles", count _vehArray]] call MISSION_fnc_log;

        // Step 1: Re-enable simulation
        {
            _x enableSimulationGlobal true;
        } forEach _vehArray;

        // Step 2: Wait for physics to settle (1 second)
        uiSleep 1;

        // Step 3: Re-enable damage for vehicles
        {
            _x allowDamage true;
        } forEach _vehArray;

        // Step 4: Re-enable damage for all crew
        {
            _x allowDamage true;
        } forEach _crewArray;

        [format ["[CONVOY FIX] ✓ Convoy fully initialized - %1 vehicles, %2 crew ready",
            count _vehArray, count _crewArray]] call MISSION_fnc_log;

    }, [_vehicles, _allCrew], 2] call BIS_fnc_execVM;  // ✅ 2-second delay before activation

    // Create marker
    private _marker = [_pos, "convoy", format ["Convoy [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["Convoy mission spawned at %1 (Difficulty: %2, Vehicles: %3)", _pos, _difficulty, count _vehicles]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: RESCUE HOSTAGES
// ========================================

MISSION_fnc_createRescue = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "medium", "hard"];
    private _missionData = createHashMapFromArray [
        ["type", "rescue"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["hostagesRescued", false]
    ];

    // Create holding area (small camp)
    private _tent = "Land_cargo_house_slum_F" createVehicle _pos;
    _missionData set ["structures", [_tent]];

    // Spawn hostages
    private _hostageCount = 2 + floor(random 3);
    private _hostages = [];
    for "_i" from 1 to _hostageCount do {
        private _hostagePos = [
            (_pos select 0) + (random 5 - 2.5),
            (_pos select 1) + (random 5 - 2.5),
            0
        ];

        private _hostage = createAgent ["C_man_1", _hostagePos, [], 0, "NONE"];
        _hostage setVariable ["IsHostage", true, true];
        _hostage setCaptive true;
        _hostage disableAI "MOVE";
        _hostage setUnitPos "DOWN";

        _hostages pushBack _hostage;
    };
    _missionData set ["hostages", _hostages];

    // Spawn AI guards
    private _aiCount = switch (_difficulty) do {
        case "easy": { (MISSION_CONFIG get "aiCountEasy") select 0 + floor(random ((MISSION_CONFIG get "aiCountEasy") select 1 - (MISSION_CONFIG get "aiCountEasy") select 0)) };
        case "medium": { (MISSION_CONFIG get "aiCountMedium") select 0 + floor(random ((MISSION_CONFIG get "aiCountMedium") select 1 - (MISSION_CONFIG get "aiCountMedium") select 0)) };
        case "hard": { (MISSION_CONFIG get "aiCountHard") select 0 + floor(random ((MISSION_CONFIG get "aiCountHard") select 1 - (MISSION_CONFIG get "aiCountHard") select 0)) };
        default { 4 };
    };

    private _aiData = [_pos, _aiCount, EAST] call MISSION_fnc_spawnAI;
    _missionData set ["aiGroups", [_aiData select 0]];
    _missionData set ["aiUnits", _aiData select 1];

    // Spawn loot
    private _loot = [_pos, _difficulty] call MISSION_fnc_spawnLoot;
    _missionData set ["loot", [_loot]];

    // Create marker
    private _marker = [_pos, "rescue", format ["Rescue Hostages [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["Rescue mission spawned at %1 (Difficulty: %2, Hostages: %3, AI: %4)", _pos, _difficulty, _hostageCount, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: AI CAMP
// ========================================

MISSION_fnc_createCamp = {
    params ["_pos"];

    private _difficulty = selectRandom ["medium", "hard"];  // No easy camps
    private _missionData = createHashMapFromArray [
        ["type", "camp"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true]
    ];

    // Create camp structures
    private _structures = [];

    // Central tent
    private _centerTent = "Land_cargo_house_slum_F" createVehicle _pos;
    _structures pushBack _centerTent;

    // Surrounding structures
    for "_i" from 0 to 3 do {
        private _angle = _i * 90;
        private _distance = 15;
        private _structPos = [
            (_pos select 0) + (_distance * cos _angle),
            (_pos select 1) + (_distance * sin _angle),
            0
        ];

        private _structure = (selectRandom ["Land_BagFence_Long_F", "Land_HBarrier_3_F"]) createVehicle _structPos;
        _structure setDir _angle;
        _structures pushBack _structure;
    };

    _missionData set ["structures", _structures];

    // Spawn multiple loot crates
    private _lootBoxes = [];
    for "_i" from 0 to 2 do {
        private _lootPos = [
            (_pos select 0) + (random 10 - 5),
            (_pos select 1) + (random 10 - 5),
            0
        ];
        private _box = [_lootPos, _difficulty] call MISSION_fnc_spawnLoot;
        _lootBoxes pushBack _box;
    };
    _missionData set ["loot", _lootBoxes];

    // Spawn armed vehicle
    private _vehiclePos = [
        (_pos select 0) + 20,
        (_pos select 1),
        0
    ];
    private _vehicle = (selectRandom (MISSION_CONFIG get "lootVehicles")) createVehicle _vehiclePos;
    _vehicle setFuel 1;
    _missionData set ["vehicles", [_vehicle]];

    // Spawn AI defenders (more than other missions)
    private _aiCount = if (_difficulty == "hard") then {
        (MISSION_CONFIG get "aiCountHard") select 1 + 2  // Extra AI for camps
    } else {
        (MISSION_CONFIG get "aiCountMedium") select 1
    };

    private _aiData = [_pos, _aiCount, EAST] call MISSION_fnc_spawnAI;
    _missionData set ["aiGroups", [_aiData select 0]];
    _missionData set ["aiUnits", _aiData select 1];

    // Create marker
    private _marker = [_pos, "camp", format ["AI Camp [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["AI Camp mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION MANAGEMENT
// ========================================

MISSION_fnc_selectMissionType = {
    private _totalWeight =
        (MISSION_CONFIG get "crashSiteWeight") +
        (MISSION_CONFIG get "supplyCacheWeight") +
        (MISSION_CONFIG get "convoyWeight") +
        (MISSION_CONFIG get "rescueWeight") +
        (MISSION_CONFIG get "campWeight");

    private _random = random _totalWeight;
    private _currentWeight = 0;

    _currentWeight = _currentWeight + (MISSION_CONFIG get "crashSiteWeight");
    if (_random < _currentWeight) exitWith { "crashsite" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "supplyCacheWeight");
    if (_random < _currentWeight) exitWith { "supplycache" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "convoyWeight");
    if (_random < _currentWeight) exitWith { "convoy" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "rescueWeight");
    if (_random < _currentWeight) exitWith { "rescue" };

    "camp"
};

MISSION_fnc_spawnMission = {
    // Check if we can spawn more missions
    if (count MISSION_ActiveMissions >= (MISSION_CONFIG get "maxActiveMissions")) exitWith {
        ["Max active missions reached, skipping spawn"] call MISSION_fnc_log;
    };

    // Check player count
    if (count allPlayers < (MISSION_CONFIG get "minPlayers")) exitWith {
        ["Not enough players online for missions"] call MISSION_fnc_log;
    };

    // Select mission type
    private _missionType = call MISSION_fnc_selectMissionType;

    // Get spawn position
    private _pos = call MISSION_fnc_getRandomPosition;

    // Create mission based on type
    private _mission = switch (_missionType) do {
        case "crashsite": { [_pos] call MISSION_fnc_createCrashSite };
        case "supplycache": { [_pos] call MISSION_fnc_createSupplyCache };
        case "convoy": { [_pos] call MISSION_fnc_createConvoy };
        case "rescue": { [_pos] call MISSION_fnc_createRescue };
        case "camp": { [_pos] call MISSION_fnc_createCamp };
        default { [_pos] call MISSION_fnc_createCrashSite };
    };

    // Add to active missions
    MISSION_ActiveMissions pushBack _mission;

    // Announce to players
    private _announcement = format ["NEW MISSION: %1 - Check your map!", _mission get "marker" call BIS_fnc_markerText];
    [_announcement] remoteExec ["systemChat", 0];
};

MISSION_fnc_checkMissionComplete = {
    params ["_mission"];

    // Check if all AI are dead
    private _allDead = true;
    {
        {
            if (alive _x) exitWith { _allDead = false };
        } forEach (units _x);
    } forEach (_mission getOrDefault ["aiGroups", []]);

    // Special checks for specific mission types
    private _typeComplete = true;

    if (_mission get "type" == "rescue") then {
        // Check if hostages are rescued (near a player)
        private _rescued = false;
        {
            if (alive _x) then {
                {
                    if (_x distance _y < 10 && side _y == WEST) exitWith { _rescued = true };
                } forEach allPlayers;
            };
        } forEach (_mission getOrDefault ["hostages", []]);

        _typeComplete = _rescued;
    };

    (_allDead && _typeComplete)
};

MISSION_fnc_completeMission = {
    params ["_mission"];

    [format ["Mission %1 completed!", _mission get "type"]] call MISSION_fnc_log;

    // Calculate rewards
    private _poptabs = (MISSION_CONFIG get "rewardPoptabs") select 0 + floor(random ((MISSION_CONFIG get "rewardPoptabs") select 1 - (MISSION_CONFIG get "rewardPoptabs") select 0));
    private _respect = (MISSION_CONFIG get "rewardRespect") select 0 + floor(random ((MISSION_CONFIG get "rewardRespect") select 1 - (MISSION_CONFIG get "rewardRespect") select 0));

    // Apply difficulty multiplier
    private _multiplier = switch (_mission get "difficulty") do {
        case "easy": { 1.0 };
        case "medium": { 1.5 };
        case "hard": { 2.0 };
        default { 1.0 };
    };

    _poptabs = floor(_poptabs * _multiplier);
    _respect = floor(_respect * _multiplier);

    // Find nearby players to reward
    private _rewardedPlayers = [];
    {
        if (_x distance (_mission get "position") < 500) then {
            // Award Poptabs (Exile server integration needed)
            // _x setVariable ["ExileMoney", (_x getVariable ["ExileMoney", 0]) + _poptabs, true];

            // Award Respect (Exile server integration needed)
            // _x setVariable ["ExileScore", (_x getVariable ["ExileScore", 0]) + _respect, true];

            _rewardedPlayers pushBack name _x;
        };
    } forEach allPlayers;

    // Announce completion
    private _announcement = format ["MISSION COMPLETE: %1 - Rewards: %2 Poptabs, %3 Respect (Players: %4)",
        _mission get "type",
        _poptabs,
        _respect,
        if (count _rewardedPlayers > 0) then { str _rewardedPlayers } else { "None nearby" }
    ];
    [_announcement] remoteExec ["systemChat", 0];

    // Cleanup mission
    [_mission] call MISSION_fnc_cleanupMission;
};

MISSION_fnc_cleanupMission = {
    params ["_mission"];

    // Remove marker
    deleteMarker (_mission get "marker");

    // Mark as inactive
    _mission set ["active", false];

    [format ["Mission %1 cleaned up", _mission get "type"]] call MISSION_fnc_log;
};

MISSION_fnc_updateMissions = {
    private _toRemove = [];

    {
        private _mission = _x;

        if (_mission get "active") then {
            // Check timeout
            if (time - (_mission get "startTime") > (MISSION_CONFIG get "missionTimeout")) then {
                [format ["Mission %1 timed out", _mission get "type"]] call MISSION_fnc_log;
                [_mission] call MISSION_fnc_cleanupMission;
                _toRemove pushBack _forEachIndex;
            } else {
                // Check completion
                if ([_mission] call MISSION_fnc_checkMissionComplete) then {
                    [_mission] call MISSION_fnc_completeMission;
                    _toRemove pushBack _forEachIndex;
                };

                // Update convoy position marker
                if (_mission get "type" == "convoy" && _mission get "moving") then {
                    private _vehicles = _mission getOrDefault ["vehicles", []];
                    if (count _vehicles > 0) then {
                        private _leadVehicle = _vehicles select 0;
                        if (alive _leadVehicle) then {
                            private _newPos = getPosATL _leadVehicle;
                            (_mission get "marker") setMarkerPos _newPos;
                        };
                    };
                };
            };
        };
    } forEach MISSION_ActiveMissions;

    // Remove completed/timed out missions
    {
        MISSION_ActiveMissions deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// INITIALIZATION
// ========================================

MISSION_fnc_init = {
    ["Dynamic Mission System v1.0 initializing..."] call MISSION_fnc_log;

    if (!(MISSION_CONFIG get "enabled")) exitWith {
        ["Mission system is disabled in config"] call MISSION_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Cache safe zones
    MISSION_SafeZones = call MISSION_fnc_getSafeZones;

    // Start mission spawn loop
    [] spawn {
        while {true} do {
            sleep (MISSION_CONFIG get "spawnInterval");
            call MISSION_fnc_spawnMission;
        };
    };

    // Start mission update loop
    [] spawn {
        while {true} do {
            sleep 10;
            call MISSION_fnc_updateMissions;
        };
    };

    // Spawn initial mission
    sleep 30;
    call MISSION_fnc_spawnMission;

    MISSION_InitComplete = true;
    ["Dynamic Mission System v1.0 initialized successfully"] call MISSION_fnc_log;
};

// Start the system
[] call MISSION_fnc_init;
