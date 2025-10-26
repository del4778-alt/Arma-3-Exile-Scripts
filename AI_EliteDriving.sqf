/*
    File: fn_aiPatrolSystem_Enhanced.sqf
    Author: Elite Battle System v4.0 - Modified for Military Building Patrols
    Description:
        Modified patrol system with custom gear that patrols military buildings
        - Automatically finds all ExileSpawnZone markers
        - Only spawns patrols at zones where players are nearby (2000m)
        - Dynamically activates/deactivates based on player proximity
        - Custom gear: Bandanna, backpack, gorka uniform, gold weapons
        - Patrols nearby military buildings instead of circular patrol
        - Cleans up all AI when no players online
        
    CONFIGURATION:
        - Edit EXILE_PATROL_CONFIG below to set units per city, respawn delay, etc.
*/

if (!isServer) exitWith {};

// ============================================
// GLOBAL VARS
// ============================================

PATROL_Active = false;
PATROL_ZoneHandles = [];
PATROL_AllGroups = [];
PATROL_playerCheckTime = 0;
PATROL_nearbyPlayers = [];

// ============================================
// EXILE SPAWN ZONE PATROL CONFIGURATION
// ============================================

EXILE_PATROL_CONFIG = [
    3,      // Units per patrol group
    300,    // Respawn delay (seconds) after all units killed
    1000,   // Cache distance (meters) - patrols despawn if no players within this range
    999,    // Max respawn attempts (999 = unlimited)
    2000    // Player detection radius (meters) - only spawn AI at zones within this distance of players
];

// ============================================
// ENHANCED CONFIGURATION
// ============================================

DEFENDER_DETECTION_RADIUS = 1500;
DEFENDER_AUDIO_DETECTION_RADIUS = 2000;
DEFENDER_ENHANCED_MOVEMENT = true;
DEFENDER_COVER_DISTANCE = 50;
DEFENDER_REARM_CHECK_INTERVAL = 30;
DEFENDER_GRENADE_USAGE_CHANCE = 0.7;
DEFENDER_STATIC_WEAPON_DISTANCE = 100;
DEFENDER_CALLOUT_INTERVAL = 8;
DEFENDER_MILITARY_SEARCH_RADIUS = 300;  // Search radius for military buildings

// ============================================
// FACTION RELATIONS - SET ONCE GLOBALLY
// ============================================

if (isNil "PATROL_FactionsConfigured") then {
    PATROL_FactionsConfigured = true;
    publicVariable "PATROL_FactionsConfigured";
    
    // Make RESISTANCE hostile to both WEST and EAST
    RESISTANCE setFriend [WEST, 0];
    WEST setFriend [RESISTANCE, 0];
    RESISTANCE setFriend [EAST, 0];
    EAST setFriend [RESISTANCE, 0];
    
    // Keep EAST hostile to WEST
    EAST setFriend [WEST, 0];
    WEST setFriend [EAST, 0];
    
    diag_log "[AI] Faction relations configured: RESISTANCE patrols will engage WEST & EAST";
};

diag_log "[AI] Starting Modified Patrol System - Military Building Patrols...";

// ============================================
// UTILITY FUNCTIONS
// ============================================

DEFENDER_fnc_getDirectionName = {
    params ["_dir"];
    
    switch (true) do {
        case (_dir >= 337.5 || _dir < 22.5): {"North"};
        case (_dir >= 22.5 && _dir < 67.5): {"NE"};
        case (_dir >= 67.5 && _dir < 112.5): {"East"};
        case (_dir >= 112.5 && _dir < 157.5): {"SE"};
        case (_dir >= 157.5 && _dir < 202.5): {"South"};
        case (_dir >= 202.5 && _dir < 247.5): {"SW"};
        case (_dir >= 247.5 && _dir < 292.5): {"West"};
        default {"NW"};
    };
};

// Safe unit check - prevents "Object not found" errors
DEFENDER_fnc_isUnitValid = {
    params ["_unit"];
    
    if (isNil "_unit") exitWith {false};
    if (isNull _unit) exitWith {false};
    if (!alive _unit) exitWith {false};
    
    true
};

// Enhanced target validation with proper visibility checking
DEFENDER_fnc_isValidTarget = {
    params ["_unit", "_target"];
    
    // Must be alive
    if (!alive _target) exitWith {false};
    
    // Must be hostile side (WEST or EAST)
    if (side _target != WEST && side _target != EAST) exitWith {false};
    
    // Must not be friendly
    if (side _target getFriend side _unit >= 0.6) exitWith {false};
    
    // For vehicles, must have crew (ignore empty vehicles)
    if (_target isKindOf "LandVehicle" || _target isKindOf "Air") then {
        if (count crew _target == 0) exitWith {false};
    };
    
    // Check visibility using lineIntersectsSurfaces (more reliable than checkVisibility)
    private _intersects = lineIntersectsSurfaces [eyePos _unit, eyePos _target, _unit, _target, true, 1];
    if (count _intersects > 0) exitWith {false};
    
    // Must be within reasonable range
    if (_unit distance _target > DEFENDER_DETECTION_RADIUS) exitWith {false};
    
    true
};

// ============================================
// MILITARY BUILDING FINDER
// ============================================

DEFENDER_fnc_findMilitaryBuildings = {
    params ["_centerPos", "_radius"];
    
    // Specific military building classnames to search for
    private _militaryClassnames = [
        "Land_TentHangar_V1_F",
        "Land_Hangar_F",
        "Land_Airport_Tower_F",
        "Land_Cargo_House_V1_F",
        "Land_Cargo_House_V3_F",
        "Land_Cargo_HQ_V1_F",
        "Land_Cargo_HQ_V2_F",
        "Land_Cargo_HQ_V3_F",
        "Land_u_Barracks_V2_F",
        "Land_i_Barracks_V2_F",
        "Land_i_Barracks_V1_F",
        "Land_Cargo_Patrol_V1_F",
        "Land_Cargo_Patrol_V2_F",
        "Land_Cargo_Tower_V1_F",
        "Land_Cargo_Tower_V1_No1_F",
        "Land_Cargo_Tower_V1_No2_F",
        "Land_Cargo_Tower_V1_No3_F",
        "Land_Cargo_Tower_V1_No4_F",
        "Land_Cargo_Tower_V1_No5_F",
        "Land_Cargo_Tower_V1_No6_F",
        "Land_Cargo_Tower_V1_No7_F",
        "Land_Cargo_Tower_V2_F",
        "Land_Cargo_Tower_V3_F",
        "Land_MilOffices_V1_F",
        "Land_Radar_F"
    ];
    
    private _militaryBuildings = [];
    private _allBuildings = nearestObjects [_centerPos, ["House", "Building"], _radius];
    
    {
        private _building = _x;
        private _typeOf = typeOf _building;
        
        // Check if building classname matches our military list
        if (_typeOf in _militaryClassnames) then {
            _militaryBuildings pushBack _building;
        };
    } forEach _allBuildings;
    
    diag_log format["[AI] Found %1 military buildings near position %2", count _militaryBuildings, _centerPos];
    _militaryBuildings
};


// ============================================
// EXILE SPAWN ZONE DETECTOR
// ============================================

DEFENDER_fnc_findExileSpawnZones = {
    private _exileZones = [];
    
    // Search through all markers
    {
        private _markerName = _x;
        private _markerType = markerType _markerName;
        
        // Check if it's an ExileSpawnZone marker
        if (_markerType == "ExileSpawnZone") then {
            private _markerPos = getMarkerPos _markerName;
            private _markerText = markerText _markerName;
            
            // Only add if it has a valid position
            if ((_markerPos select 0) != 0 || (_markerPos select 1) != 0) then {
                _exileZones pushBack [_markerName, _markerText, _markerPos];
                diag_log format["[AI] Found ExileSpawnZone: %1 (%2) at %3", _markerName, _markerText, _markerPos];
            };
        };
    } forEach allMapMarkers;
    
    diag_log format["[AI] Total ExileSpawnZones detected: %1", count _exileZones];
    _exileZones
};

// ============================================
// ENHANCED AMMO TRACKING
// ============================================

DEFENDER_fnc_getAmmoPercentage = {
    params ["_unit"];
    
    if (!alive _unit) exitWith {0};

    private _startMags = _unit getVariable ["DEFENDER_startMags", []];
    if (count _startMags == 0) exitWith {0};

    private _currentMags = magazines _unit;

    // Get unique magazine types
    private _allMagTypes = (_startMags + _currentMags);
    _allMagTypes = _allMagTypes arrayIntersect _allMagTypes;

    private _totalStart = 0;
    private _totalCurrent = 0;

    {
        private _magType = _x;
        _totalStart = _totalStart + ({_x == _magType} count _startMags);
        _totalCurrent = _totalCurrent + ({_x == _magType} count _currentMags);
    } forEach _allMagTypes;

    if (_totalStart <= 0) exitWith {0};
    (_totalCurrent / _totalStart)
};

// ============================================
// ENHANCED COVER DETECTION
// ============================================

DEFENDER_fnc_findCover = {
    params ["_unit", "_enemyPos"];
    
    if (!alive _unit) exitWith {[]};
    
    private _bestPos = [];
    private _bestScore = -1e9;
    private _unitPosASL = getPosASL _unit;
    private _enemyPosASL = getPosASL _enemyPos;
    
    for "_i" from 0 to 8 do {
        private _angleDeg = _i * 45;
        private _angleRad = _angleDeg * (pi / 180);
        private _distance = 20 + (random 30);
        
        private _testPos = [
            (_unitPosASL select 0) + (sin _angleRad) * _distance,
            (_unitPosASL select 1) + (cos _angleRad) * _distance,
            (_unitPosASL select 2) + 1.5
        ];
        
        private _blocked = lineIntersects [
            ASLToAGL _testPos, 
            ASLToAGL _enemyPosASL, 
            _unit,
            objNull
        ];
        
        if (_blocked) then {
            private _score = 1000 - (_unit distance2D (ASLToAGL _testPos));
            
            if (_score > _bestScore) then {
                _bestScore = _score;
                _bestPos = ASLToAGL _testPos;
            };
        };
    };
    
    _bestPos
};

// ============================================
// BASIC WEAPON LOADOUT (Simple loadout)
// ============================================

DEFENDER_fnc_giveBasicWeapons = {
    params ["_unit"];
    
    if (!alive _unit) exitWith {};
    
    // Give GOLD AK (Exile version)
    _unit addWeapon "Exile_Weapon_AKS_Gold";
    for "_i" from 1 to 6 do {
        _unit addMagazine "Exile_Magazine_30Rnd_762x39_AK";
    };
    
    // Give GOLD TAURUS pistol (Exile version)
    _unit addWeapon "Exile_Weapon_TaurusGold";
    for "_i" from 1 to 3 do {
        _unit addMagazine "Exile_Magazine_6Rnd_45ACP";
    };
    
    // Basic items
    for "_i" from 1 to 2 do {
        _unit addMagazine "SmokeShell";
        _unit addMagazine "HandGrenade";
    };
    
    for "_i" from 1 to 2 do {
        _unit addItem "FirstAidKit";
    };
    
    // Snapshot starting magazines for ammo tracking
    _unit setVariable ["DEFENDER_startMags", magazines _unit];
};

// ============================================
// ENHANCED AI SKILL CONFIGURATION
// ============================================

DEFENDER_fnc_setEnhancedSkills = {
    params ["_unit"];
    
    if (!alive _unit) exitWith {};
    
    // Enhanced skills
    _unit setSkill ["aimingAccuracy", 0.8];
    _unit setSkill ["aimingShake", 0.8];
    _unit setSkill ["aimingSpeed", 0.8];
    _unit setSkill ["spotDistance", 0.9];
    _unit setSkill ["spotTime", 0.9];
    _unit setSkill ["courage", 1.0];
    _unit setSkill ["reloadSpeed", 0.8];
    _unit setSkill ["commanding", 0.8];
    _unit setSkill ["general", 0.8];
    
    
    // 1.4x MOVEMENT SPEED (AI move faster than player)
    _unit setAnimSpeedCoef 1.4;
    
    // EXTREME AI BEHAVIOR SETTINGS
    _unit setBehaviour "AWARE";
    _unit setCombatMode "YELLOW";
    _unit allowFleeing 0;
    _unit disableAI "SUPPRESSION";
    _unit setUnitPos "AUTO";
    
    // Maximize aggression and awareness
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "MOVE";
    _unit enableAI "ANIM";
    _unit enableAI "FSM";
    _unit enableAI "AIMINGERROR";
    _unit enableAI "COVER";
    _unit enableAI "AUTOCOMBAT";
    
    // Disable auto rearm
    _unit setVariable ["BIS_noCoreConversations", true];
};

// ============================================
// ENHANCED COMBAT AI (CONSOLIDATED)
// ============================================

DEFENDER_fnc_enhancedCombatAI = {
    params ["_unit", "_defensePos"];
    
    while {alive _unit} do {
        sleep 5;
        
        if (!([_unit] call DEFENDER_fnc_isUnitValid)) exitWith {};
        
        private _nearestEnemy = objNull;
        private _minDist = DEFENDER_DETECTION_RADIUS;
        
        // Find nearest valid target
        {
            if ([_unit, _x] call DEFENDER_fnc_isValidTarget) then {
                private _dist = _unit distance _x;
                if (_dist < _minDist) then {
                    _minDist = _dist;
                    _nearestEnemy = _x;
                };
            };
        } forEach (_unit nearEntities [["CAManBase", "LandVehicle", "Air"], DEFENDER_DETECTION_RADIUS]);
        
        // Combat behavior when enemy detected
        if (!isNull _nearestEnemy && alive _nearestEnemy) then {
            private _grp = group _unit;
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
            _grp setSpeedMode "FULL";
            
            // Target callout removed to reduce log spam
            
            // Use grenade if close
            if (_minDist < 40 && random 1 < DEFENDER_GRENADE_USAGE_CHANCE) then {
                if ("HandGrenade" in magazines _unit) then {
                    _unit doTarget _nearestEnemy;
                    sleep 0.5;
                    _unit fire currentMuzzle _unit;
                };
            };
            
            // Move to cover if needed
            if (random 1 < 0.4) then {
                private _coverPos = [_unit, _nearestEnemy] call DEFENDER_fnc_findCover;
                if (count _coverPos > 0) then {
                    _unit doMove _coverPos;
                    _unit setUnitPos "MIDDLE"; // Crouch in combat
                };
            };
        } else {
            // Patrol behavior when no enemy
            _unit setUnitPos "AUTO";
        };
    };
};

// ============================================
// ENHANCED SPAWN FUNCTION WITH MILITARY BUILDING PATROL
// ============================================

DEFENDER_fnc_spawnPatrolZones = {
    params ["_spawnZones"];
    
    PATROL_Active = true;
    
    {
        _x params ["_zoneMarker", "_defendersPerGroup", "_respawnDelay", "_cacheDistance", "_maxRespawnAttempts"];
        
        private _markerPos = getMarkerPos _zoneMarker;
        private _cityName = markerText _zoneMarker;
        
        if (_cityName == "") then {
            _cityName = _zoneMarker;
        };
        
        diag_log format["[AI] Initializing patrol zone: %1 at %2", _cityName, _markerPos];
        
        if ((_markerPos select 0) != 0 || (_markerPos select 1) != 0) then {
            private _handle = [_zoneMarker, _cityName, _markerPos, _defendersPerGroup, _respawnDelay, _cacheDistance, _maxRespawnAttempts] spawn {
                params ["_zoneMarker", "_cityName", "_markerPos", "_defendersPerGroup", "_respawnDelay", "_cacheDistance", "_maxRespawnAttempts"];
                
                private _respawnAttempts = 0;
                
                while {_respawnAttempts < _maxRespawnAttempts && PATROL_Active} do {
                    private _defenderGrp = createGroup RESISTANCE;
                    PATROL_AllGroups pushBack _defenderGrp;
                    
                    for "_i" from 1 to _defendersPerGroup do {
                        private _spawnPos = [_markerPos, 5, 30, 5, 0, 60, 0] call BIS_fnc_findSafePos;
                        private _defender = _defenderGrp createUnit ["I_Soldier_F", _spawnPos, [], 0, "FORM"];
                        
                        // Remove default gear
                        removeAllWeapons _defender;
                        removeAllItems _defender;
                        removeAllAssignedItems _defender;
                        removeBackpack _defender;
                        removeVest _defender;
                        removeHeadgear _defender;
                        removeGoggles _defender;
                        
                        // === ADD CUSTOM GEAR ===
                        // Uniform
                        _defender forceAddUniform "U_O_R_Gorka_01_black_F";
                        
                        // Vest
                        _defender addVest "V_Rangemaster_belt";
                        
                        // Backpack
                        _defender addBackpack "B_CivilianBackpack_01_Everyday_IDAP_F";
                        
                        // Headgear
                        _defender addHeadgear "H_Bandanna_surfer_blk";
                        
                        // Goggles
                        _defender addGoggles "G_Bandanna_Syndikat2";
                        
                        // Add basic items
                        _defender linkItem "ItemMap";
                        _defender linkItem "ItemCompass";
                        _defender linkItem "ItemWatch";
                        _defender linkItem "ItemGPS";
                        
                        // Give basic weapons
                        [_defender] call DEFENDER_fnc_giveBasicWeapons;
                        
                        // Apply enhanced skills
                        [_defender] call DEFENDER_fnc_setEnhancedSkills;
                        
                        // Audio detection event handler
                        private _audioEH = _defender addEventHandler ["FiredNear", {
                            params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];
                            
                            if (side _firer != side _unit && _distance < DEFENDER_AUDIO_DETECTION_RADIUS) then {
                                if ([_unit, _firer] call DEFENDER_fnc_isValidTarget) then {
                                    _unit doTarget _firer;
                                    _unit doFire _firer;
                                };
                            };
                        }];
                        
                        _defender setVariable ["DEFENDER_audioEH", _audioEH];
                        
                        // Start combat AI thread
                        [_defender, _markerPos] spawn DEFENDER_fnc_enhancedCombatAI;
                    };
                    

                    // === ENHANCE GROUP LEADER ===
                    private _leader = leader _defenderGrp;
                    if (!isNull _leader && alive _leader) then {
                        // Boost leader-specific skills
                        _leader setSkill ["commanding", 1.0];
                        _leader setSkill ["courage", 1.0];
                        _leader setSkill ["general", 1.0];
                        
                        // Leader has better awareness
                        _leader setSkill ["spotDistance", 1.0];
                        _leader setSkill ["spotTime", 1.0];
                        
                        // Ensure leader is properly set
                        _defenderGrp selectLeader _leader;
                        
                        diag_log format["[AI] Leader enhanced for group at %1", _cityName];
                    };
                    // Configure group
                    _defenderGrp setFormation "WEDGE";  // Better for patrols and combat
                    _defenderGrp setSpeedMode "LIMITED";
                    _defenderGrp enableAttack true;
                    _defenderGrp setCombatMode "YELLOW";  // Engage at will
                    _defenderGrp setBehaviour "SAFE";  // Alert but not combat stance while patrolling
                    
                    // === FIND AND PATROL MILITARY BUILDINGS ===
                    private _militaryBuildings = [_markerPos, DEFENDER_MILITARY_SEARCH_RADIUS] call DEFENDER_fnc_findMilitaryBuildings;
                    
                    if (count _militaryBuildings > 0) then {
                        diag_log format["[AI] Creating waypoints for %1 military buildings near %2", count _militaryBuildings, _cityName];
                        
                        // Create waypoints for each military building (up to 10)
                        private _buildingCount = count _militaryBuildings min 10;
                        for "_i" from 0 to (_buildingCount - 1) do {
                            private _building = _militaryBuildings select _i;
                            private _buildingPos = getPosATL _building;
                            
                            private _wp = _defenderGrp addWaypoint [_buildingPos, 0];
                            _wp setWaypointType "MOVE";
                            _wp setWaypointSpeed "LIMITED";
                            _wp setWaypointBehaviour "SAFE";
                            _wp setWaypointCombatMode "YELLOW";
                            _wp setWaypointCompletionRadius 30;
                            _wp setWaypointTimeout [20, 40, 60];
                        };
                        
                        // Add cycle waypoint to loop the patrol
                        private _cycleWp = _defenderGrp addWaypoint [_markerPos, 0];
                        _cycleWp setWaypointType "CYCLE";
                    } else {
                        diag_log format["[AI] No military buildings found near %1, using circular patrol", _cityName];
                        
                        // Fallback to circular patrol if no military buildings found
                        for "_i" from 0 to 7 do {
                            private _angle = _i * 45;
                            private _dist = 300;
                            private _patrolPos = [
                                (_markerPos select 0) + (_dist * sin _angle), 
                                (_markerPos select 1) + (_dist * cos _angle), 
                                0
                            ];
                            _patrolPos = [_patrolPos, 0, 50, 5, 0, 60, 0] call BIS_fnc_findSafePos;
                            
                            private _wp = _defenderGrp addWaypoint [_patrolPos, 0];
                            _wp setWaypointType "MOVE";
                            _wp setWaypointSpeed "LIMITED";
                            _wp setWaypointBehaviour "SAFE";
                            _wp setWaypointCombatMode "YELLOW";
                            _wp setWaypointCompletionRadius 30;
                            _wp setWaypointTimeout [15, 30, 45];
                        };
                        
                        private _cycleWp = _defenderGrp addWaypoint [_markerPos, 0];
                        _cycleWp setWaypointType "CYCLE";
                    };
                    
                    diag_log format["[AI] Spawned %1 patrol units at %2 (%3)", _defendersPerGroup, _cityName, _zoneMarker];
                    
                    _respawnAttempts = _respawnAttempts + 1;
                    
                    // === MONITORING LOOP ===
                    private _deathTime = -1;
                    
                    while {PATROL_Active} do {
                        sleep 30;
                        
                        if (isNull _defenderGrp || {count units _defenderGrp == 0}) exitWith {
                            diag_log format["[AI] Patrol group at %1 was deleted externally", _cityName];
                        };
                        
                        private _defendersAlive = {alive _x} count units _defenderGrp;
                        
                        if (_defendersAlive == 0) then {
                            if (_deathTime < 0) then {
                                _deathTime = time;
                                diag_log format["[AI] %1: All patrol units eliminated!", _cityName];
                            };
                            if (time - _deathTime > _respawnDelay) exitWith {
                                {
                                    if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                        _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                        _x setVariable ["DEFENDER_audioEH", nil];
                                    };
                                    deleteVehicle _x;
                                } forEach units _defenderGrp;
                                deleteGroup _defenderGrp;
                                PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                                diag_log format["[AI] Patrol cleanup complete at %1", _cityName];
                            };
                        } else {
                            _deathTime = -1;
                        };
                        
                        if (time > PATROL_playerCheckTime) then {
                            PATROL_nearbyPlayers = allPlayers;
                            PATROL_playerCheckTime = time + 15;
                        };
                        
                        private _players = PATROL_nearbyPlayers select {(_x distance2D _markerPos) < _cacheDistance};
                        if (count _players == 0) exitWith {
                            {
                                if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                    _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                    _x setVariable ["DEFENDER_audioEH", nil];
                                };
                                deleteVehicle _x;
                            } forEach units _defenderGrp;
                            deleteGroup _defenderGrp;
                            PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                            diag_log format["[AI] Patrol cached at %1 (no nearby players)", _cityName];
                        };
                    };
                    
                    if (!PATROL_Active) exitWith {
                        {
                            if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                _x setVariable ["DEFENDER_audioEH", nil];
                            };
                            deleteVehicle _x;
                        } forEach units _defenderGrp;
                        deleteGroup _defenderGrp;
                        PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                    };
                    
                    sleep _respawnDelay;
                };
                
                if (_respawnAttempts >= _maxRespawnAttempts) then {
                    diag_log format["[AI] ERROR: Patrol zone %1 exceeded respawn limit, disabling", _cityName];
                };
            };
            
            PATROL_ZoneHandles pushBack _handle;
        };
    } forEach _spawnZones;
    
    diag_log format["[AI] Patrol System Active - %1 zones initialized", count PATROL_ZoneHandles];
};

// ============================================
// MAIN LOOP - DYNAMIC SPAWN BASED ON PLAYER PROXIMITY
// ============================================

[] spawn {
    while {true} do {
        sleep 10; // Check every 10 seconds
        
        // If no players online, clean everything up
        if (count allPlayers == 0) then {
            if (PATROL_Active) then {
                diag_log "[AI] No players online - Shutting down Patrol System";
                PATROL_Active = false;
                
                {terminate _x} forEach PATROL_ZoneHandles;
                PATROL_ZoneHandles = [];
                
                private _cleanupCount = 0;
                {
                    if (!isNull _x) then {
                        {
                            if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                _x setVariable ["DEFENDER_audioEH", nil];
                            };
                            deleteVehicle _x;
                        } forEach units _x;
                        deleteGroup _x;
                        _cleanupCount = _cleanupCount + 1;
                    };
                } forEach PATROL_AllGroups;
                PATROL_AllGroups = [];
                
                diag_log format["[AI] Patrol System Stopped - Removed %1 patrol groups", _cleanupCount];
            };
        } else {
            // Players are online - check which spawn zones need AI
            private _exileZones = [] call DEFENDER_fnc_findExileSpawnZones;
            private _detectionRadius = EXILE_PATROL_CONFIG select 4; // Player detection radius
            
            if (count _exileZones > 0) then {
                // Find which zones have players nearby
                private _activeZones = [];
                
                {
                    _x params ["_markerName", "_markerText", "_markerPos"];
                    
                    // Check if any player is within detection radius of this spawn zone
                    private _nearbyPlayers = allPlayers select {(_x distance2D _markerPos) < _detectionRadius};
                    
                    if (count _nearbyPlayers > 0) then {
                        _activeZones pushBack _x;
                    };
                } forEach _exileZones;
                
                // If we found zones with players nearby
                if (count _activeZones > 0 && !PATROL_Active) then {
                    // Create patrol configuration for zones with players
                    private _spawnZones = [];
                    
                    {
                        _x params ["_markerName", "_markerText", "_markerPos"];
                        
                        diag_log format["[AI] Player detected near %1 - Activating patrol", _markerText];
                        
                        // Format: [markerName, unitsPerGroup, respawnDelay, cacheDistance, maxRespawnAttempts]
                        _spawnZones pushBack [
                            _markerName,
                            EXILE_PATROL_CONFIG select 0,  // Units per group
                            EXILE_PATROL_CONFIG select 1,  // Respawn delay
                            EXILE_PATROL_CONFIG select 2,  // Cache distance
                            EXILE_PATROL_CONFIG select 3   // Max respawns
                        ];
                    } forEach _activeZones;
                    
                    if (count _spawnZones > 0) then {
                        diag_log format["[AI] Creating patrols for %1 active spawn zones (players nearby)", count _spawnZones];
                        [_spawnZones] call DEFENDER_fnc_spawnPatrolZones;
                    };
                } else {
                    if (count _activeZones == 0 && PATROL_Active) then {
                    // No players near any spawn zones - shut down
                    diag_log "[AI] No players near spawn zones - Shutting down patrols";
                    PATROL_Active = false;
                    
                    {terminate _x} forEach PATROL_ZoneHandles;
                    PATROL_ZoneHandles = [];
                    
                    private _cleanupCount = 0;
                    {
                        if (!isNull _x) then {
                            {
                                if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                    _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                    _x setVariable ["DEFENDER_audioEH", nil];
                                };
                                deleteVehicle _x;
                            } forEach units _x;
                            deleteGroup _x;
                            _cleanupCount = _cleanupCount + 1;
                        };
                    } forEach PATROL_AllGroups;
                    PATROL_AllGroups = [];
                    
                    diag_log format["[AI] Patrols cleaned up - Removed %1 groups", _cleanupCount];
                };
                };
            } else {
                if (PATROL_Active) then {
                    diag_log "[AI] WARNING: No ExileSpawnZone markers found, shutting down";
                    PATROL_Active = false;
                };
            };
        };
    };
};

// ============================================
// MONITORING THREAD
// ============================================

[] spawn {
    while {true} do {
        sleep 600; // Check every 10 minutes instead of 5
        if (PATROL_Active) then {
            private _resistanceCount = {side _x == RESISTANCE} count allUnits;
            private _activeGroups = {!isNull _x && {count units _x > 0}} count PATROL_AllGroups;
            diag_log format["[AI] Patrol Health Check: %1 patrol units | %2 active groups", 
                _resistanceCount, _activeGroups];
        };
    };
};

// ============================================
// STARTUP MESSAGE
// ============================================

diag_log "========================================";
diag_log "MODIFIED AI PATROL SYSTEM - PLAYER PROXIMITY";
diag_log "Only spawns AI at zones near players (2000m)";
diag_log "Custom Gear: Gorka Uniform + Gold Weapons";
diag_log "Patrols nearby military buildings";
diag_log "Auto-detects ExileSpawnZone markers";
diag_log "Cleans up when no players nearby";
diag_log "========================================";
