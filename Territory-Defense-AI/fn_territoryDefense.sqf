/*
    Territory Defense AI v1.0
    Author: Arma 3 Exile Scripts
    Description: AI defenders that spawn when enemy players approach player territories

    Features:
    - Auto-detect Exile territory flags
    - Spawn AI defenders based on territory level
    - Patrol perimeter using AI Patrol logic
    - Vehicle patrols using Elite Driving
    - Dynamic despawn when no threats detected
    - Configurable defense levels and AI counts

    Installation:
    1. Place in Territory-Defense-AI folder
    2. Add to init.sqf: [] execVM "Territory-Defense-AI\fn_territoryDefense.sqf";
    3. Configure TERRITORY_CONFIG below

    Compatibility:
    - Exile mod required (territory flag detection)
    - Elite Driving integration for vehicle patrols
    - VCOMAI support for enhanced AI
    - A3XAI compatible
*/

// ========================================
// CONFIGURATION
// ========================================

TERRITORY_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["updateInterval", 15],               // Check territories every 15 seconds
    ["threatDistance", 300],              // Distance to detect enemy players
    ["despawnDistance", 500],             // Despawn AI when enemies this far
    ["maxDefendersPerTerritory", 8],      // Max AI defenders per territory

    // Territory level scaling (Exile territories have levels 1-10)
    ["defendersLevel1", 2],               // Basic flag
    ["defendersLevel3", 4],
    ["defendersLevel5", 6],
    ["defendersLevel7", 8],
    ["defendersLevel10", 10],             // Max level

    // Vehicle patrols (spawns at level 5+)
    ["vehiclePatrolMinLevel", 5],
    ["vehiclePatrolTypes", ["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_BTR40_MG_Green"]],

    // AI Settings
    ["aiSide", EAST],
    ["aiSkill", 0.85],
    ["patrolRadius", 100],                // How far AI patrol from flag

    // Respawn settings
    ["respawnDelay", 300],                // 5 min cooldown after wipe
    ["persistDefenders", false]           // Keep defenders even after threat gone
];

// ========================================
// GLOBAL VARIABLES
// ========================================

TERRITORY_ActiveDefenses = createHashMap;    // Territory object -> defense data
TERRITORY_InitComplete = false;

// ========================================
// UTILITY FUNCTIONS
// ========================================

TERRITORY_fnc_log = {
    params ["_message"];
    if (TERRITORY_CONFIG get "debug") then {
        diag_log format ["[TERRITORY] %1", _message];
    };
};

TERRITORY_fnc_getTerritoryLevel = {
    params ["_flag"];

    // Exile stores territory level in flag variable
    private _level = _flag getVariable ["ExileTerritoryLevel", 1];

    _level
};

TERRITORY_fnc_getTerritoryOwner = {
    params ["_flag"];

    // Get territory owner UID
    private _ownerUID = _flag getVariable ["ExileTerritoryOwnerUID", ""];

    _ownerUID
};

TERRITORY_fnc_getDefenderCount = {
    params ["_territoryLevel"];

    private _count = 2;  // Default

    if (_territoryLevel >= 10) then {
        _count = TERRITORY_CONFIG get "defendersLevel10";
    } else {
        if (_territoryLevel >= 7) then {
            _count = TERRITORY_CONFIG get "defendersLevel7";
        } else {
            if (_territoryLevel >= 5) then {
                _count = TERRITORY_CONFIG get "defendersLevel5";
            } else {
                if (_territoryLevel >= 3) then {
                    _count = TERRITORY_CONFIG get "defendersLevel3";
                } else {
                    _count = TERRITORY_CONFIG get "defendersLevel1";
                };
            };
        };
    };

    (_count min (TERRITORY_CONFIG get "maxDefendersPerTerritory"))
};

TERRITORY_fnc_isEnemyNear = {
    params ["_flag", "_ownerUID"];

    private _flagPos = getPosATL _flag;
    private _threatDist = TERRITORY_CONFIG get "threatDistance";
    private _enemiesFound = false;

    {
        if (isPlayer _x && alive _x) then {
            private _playerUID = getPlayerUID _x;

            // Check if player is not owner and within threat distance
            if (_playerUID != _ownerUID && _x distance _flagPos < _threatDist) then {
                _enemiesFound = true;
            };
        };
    } forEach allPlayers;

    _enemiesFound
};

TERRITORY_fnc_shouldDespawn = {
    params ["_flag"];

    private _flagPos = getPosATL _flag;
    private _despawnDist = TERRITORY_CONFIG get "despawnDistance";
    private _anyPlayerNear = false;

    {
        if (isPlayer _x && alive _x && _x distance _flagPos < _despawnDist) exitWith {
            _anyPlayerNear = true;
        };
    } forEach allPlayers;

    (!_anyPlayerNear)
};

// ========================================
// AI SPAWNING FUNCTIONS
// ========================================

TERRITORY_fnc_createDefender = {
    params ["_group", "_pos", "_index"];

    private _unitPos = [
        (_pos select 0) + (random 20 - 10),
        (_pos select 1) + (random 20 - 10),
        0
    ];

    private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "FORM"];

    // Set AI skills
    _unit setSkill (TERRITORY_CONFIG get "aiSkill");
    _unit setSkill ["aimingAccuracy", 0.75 + random 0.15];
    _unit setSkill ["aimingShake", 0.7 + random 0.2];
    _unit setSkill ["aimingSpeed", 0.75 + random 0.15];
    _unit setSkill ["spotDistance", 0.85 + random 0.15];
    _unit setSkill ["spotTime", 0.75 + random 0.15];
    _unit setSkill ["courage", 0.9 + random 0.1];
    _unit setSkill ["reloadSpeed", 0.8 + random 0.2];
    _unit setSkill ["commanding", 0.85 + random 0.15];
    _unit setSkill ["general", 0.85 + random 0.15];

    // Mark for Elite Driving ignore
    _unit setVariable ["EAID_Ignore", true, true];

    // Mark as territory defender
    _unit setVariable ["TerritoryDefender", true, true];

    _unit
};

TERRITORY_fnc_spawnDefenders = {
    params ["_flag", "_count"];

    private _pos = getPosATL _flag;
    private _group = createGroup (TERRITORY_CONFIG get "aiSide");
    private _units = [];

    [format ["Spawning %1 defenders at territory %2", _count, _pos]] call TERRITORY_fnc_log;

    // Create defenders
    for "_i" from 0 to (_count - 1) do {
        private _unit = [_group, _pos, _i] call TERRITORY_fnc_createDefender;
        _units pushBack _unit;
    };

    // Set group behavior
    _group setBehaviour "COMBAT";
    _group setCombatMode "RED";
    _group setFormation "WEDGE";
    _group setSpeedMode "FULL";

    // Create patrol waypoints around flag
    private _patrolRadius = TERRITORY_CONFIG get "patrolRadius";
    for "_i" from 0 to 7 do {
        private _angle = _i * 45;
        private _wpPos = [
            (_pos select 0) + (_patrolRadius * cos _angle),
            (_pos select 1) + (_patrolRadius * sin _angle),
            0
        ];

        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "LIMITED";
    };

    // Cycle waypoints
    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";

    [_group, _units]
};

TERRITORY_fnc_spawnVehiclePatrol = {
    params ["_flag"];

    private _pos = getPosATL _flag;
    private _vehicleType = selectRandom (TERRITORY_CONFIG get "vehiclePatrolTypes");

    [format ["Spawning vehicle patrol (%1) at territory %2", _vehicleType, _pos]] call TERRITORY_fnc_log;

    // Find spawn position 50m from flag
    private _angle = random 360;
    private _spawnPos = [
        (_pos select 0) + (50 * cos _angle),
        (_pos select 1) + (50 * sin _angle),
        0
    ];

    // Create vehicle
    private _vehicle = _vehicleType createVehicle _spawnPos;
    _vehicle setDir (random 360);
    _vehicle setFuel 1;
    _vehicle setVariable ["EAID_Ignore", false, true];  // Allow Elite Driving control
    _vehicle setVariable ["TerritoryVehicle", true, true];

    // Create crew
    private _group = createGroup (TERRITORY_CONFIG get "aiSide");

    private _driver = _group createUnit ["O_Soldier_F", _spawnPos, [], 0, "FORM"];
    _driver moveInDriver _vehicle;
    _driver setSkill (TERRITORY_CONFIG get "aiSkill");
    _driver setVariable ["EAID_Ignore", true, true];

    private _gunner = _group createUnit ["O_Soldier_F", _spawnPos, [], 0, "FORM"];
    _gunner moveInGunner _vehicle;
    _gunner setSkill (TERRITORY_CONFIG get "aiSkill");
    _gunner setVariable ["EAID_Ignore", true, true];

    // Set group behavior
    _group setBehaviour "COMBAT";
    _group setCombatMode "RED";

    // Create patrol waypoints in wider circle
    private _patrolRadius = (TERRITORY_CONFIG get "patrolRadius") * 1.5;
    for "_i" from 0 to 5 do {
        private _wpAngle = _i * 60;
        private _wpPos = [
            (_pos select 0) + (_patrolRadius * cos _wpAngle),
            (_pos select 1) + (_patrolRadius * sin _wpAngle),
            0
        ];

        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointSpeed "LIMITED";
    };

    // Cycle
    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";

    [_group, _vehicle]
};

// ========================================
// DEFENSE MANAGEMENT
// ========================================

TERRITORY_fnc_activateDefense = {
    params ["_flag"];

    private _territoryLevel = [_flag] call TERRITORY_fnc_getTerritoryLevel;
    private _defenderCount = [_territoryLevel] call TERRITORY_fnc_getDefenderCount;
    private _pos = getPosATL _flag;

    [format ["Activating defense for territory at %1 (Level %2)", _pos, _territoryLevel]] call TERRITORY_fnc_log;

    // Spawn foot defenders
    private _defenderData = [_flag, _defenderCount] call TERRITORY_fnc_spawnDefenders;

    private _defenseData = createHashMapFromArray [
        ["active", true],
        ["flag", _flag],
        ["territoryLevel", _territoryLevel],
        ["activationTime", time],
        ["lastWipeTime", 0],
        ["groups", [_defenderData select 0]],
        ["units", _defenderData select 1],
        ["vehicles", []]
    ];

    // Spawn vehicle patrol if territory level is high enough
    if (_territoryLevel >= (TERRITORY_CONFIG get "vehiclePatrolMinLevel")) then {
        private _vehicleData = [_flag] call TERRITORY_fnc_spawnVehiclePatrol;
        (_defenseData get "groups") pushBack (_vehicleData select 0);
        (_defenseData get "vehicles") pushBack (_vehicleData select 1);
    };

    // Store defense data
    TERRITORY_ActiveDefenses set [_flag, _defenseData];

    _defenseData
};

TERRITORY_fnc_deactivateDefense = {
    params ["_flag"];

    private _defenseData = TERRITORY_ActiveDefenses get _flag;
    if (isNil "_defenseData") exitWith {};

    [format ["Deactivating defense for territory at %1", getPosATL _flag]] call TERRITORY_fnc_log;

    // Delete AI groups
    {
        {
            deleteVehicle _x;
        } forEach (units _x);
        deleteGroup _x;
    } forEach (_defenseData get "groups");

    // Delete vehicles
    {
        deleteVehicle _x;
    } forEach (_defenseData get "vehicles");

    // Remove from active defenses
    TERRITORY_ActiveDefenses deleteAt _flag;
};

TERRITORY_fnc_checkDefenseIntegrity = {
    params ["_flag", "_defenseData"];

    private _aliveCount = 0;

    {
        {
            if (alive _x) then {
                _aliveCount = _aliveCount + 1;
            };
        } forEach (units _x);
    } forEach (_defenseData get "groups");

    // If all defenders dead
    if (_aliveCount == 0) then {
        private _timeSinceLastWipe = time - (_defenseData get "lastWipeTime");
        private _respawnDelay = TERRITORY_CONFIG get "respawnDelay";

        // Check if enough time passed for respawn
        if (_timeSinceLastWipe > _respawnDelay || (_defenseData get "lastWipeTime") == 0) then {
            [format ["All defenders eliminated, respawning after cooldown"]] call TERRITORY_fnc_log;

            // Deactivate current defense
            [_flag] call TERRITORY_fnc_deactivateDefense;

            // Reactivate with new defenders
            private _newDefense = [_flag] call TERRITORY_fnc_activateDefense;
            _newDefense set ["lastWipeTime", time];
        };
    };
};

// ========================================
// MAIN UPDATE LOOP
// ========================================

TERRITORY_fnc_updateDefenses = {
    // Get all Exile territory flags
    private _allFlags = allMissionObjects "Exile_Construction_Flag_Static";

    {
        private _flag = _x;
        private _ownerUID = [_flag] call TERRITORY_fnc_getTerritoryOwner;

        // Skip if no owner
        if (_ownerUID != "") then {
            private _enemyNear = [_flag, _ownerUID] call TERRITORY_fnc_isEnemyNear;
            private _isActive = TERRITORY_ActiveDefenses get _flag;

            // Activate defense if enemy near and not already active
            if (_enemyNear && isNil "_isActive") then {
                [_flag] call TERRITORY_fnc_activateDefense;
            };

            // If defense is active
            if (!isNil "_isActive") then {
                // Check if should despawn
                if (!(TERRITORY_CONFIG get "persistDefenders")) then {
                    if ([_flag] call TERRITORY_fnc_shouldDespawn) then {
                        [_flag] call TERRITORY_fnc_deactivateDefense;
                    } else {
                        // Check defender integrity and respawn if needed
                        [_flag, _isActive] call TERRITORY_fnc_checkDefenseIntegrity;
                    };
                } else {
                    // Always check integrity if persistent
                    [_flag, _isActive] call TERRITORY_fnc_checkDefenseIntegrity;
                };
            };
        };
    } forEach _allFlags;
};

// ========================================
// INITIALIZATION
// ========================================

TERRITORY_fnc_init = {
    ["Territory Defense AI v1.0 initializing..."] call TERRITORY_fnc_log;

    if (!(TERRITORY_CONFIG get "enabled")) exitWith {
        ["Territory Defense AI is disabled in config"] call TERRITORY_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Start update loop
    [] spawn {
        while {true} do {
            call TERRITORY_fnc_updateDefenses;
            sleep (TERRITORY_CONFIG get "updateInterval");
        };
    };

    TERRITORY_InitComplete = true;
    ["Territory Defense AI v1.0 initialized successfully"] call TERRITORY_fnc_log;
};

// Start the system
[] call TERRITORY_fnc_init;
