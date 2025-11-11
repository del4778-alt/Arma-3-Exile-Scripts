/*
    =====================================================
    ELITE AI DRIVING SYSTEM - FIXED & ENHANCED
    =====================================================
    Author: Master SQF Engineer
    Version: 3.3 - PERFORMANCE & STABILITY RELEASE
    =====================================================

    FIXES APPLIED IN v3.3:
    ✓ Fixed AI mod detection logic (VCOMAI, A3XAI, etc.)
    ✓ Replaced object spawning with invisible helipads (major performance boost)
    ✓ Implemented building cache to prevent re-processing
    ✓ Added event handler cleanup in fallback mode
    ✓ Improved waypoint cleanup interval (30s → 15s)
    ✓ Enhanced null checks in all spawned code blocks
    ✓ Optimized obstacle avoidance system

    PREVIOUS FIXES (v3.2):
    ✓ VCOMAI detection and exclusion
    ✓ Proper CBA fallback
    ✓ Waypoint cleanup/recycling
    ✓ Null checks throughout
    ✓ Event handler cleanup
    ✓ Compatibility with major AI mods
    ✓ Performance optimizations
    =====================================================
*/

if (!isServer) exitWith {};

// =====================================================
// MOD DETECTION & COMPATIBILITY
// =====================================================
EAID_ModCompat = createHashMapFromArray [
    ["HAS_CBA", isClass (configFile >> "CfgPatches" >> "cba_main")],
    ["HAS_VCOMAI", isClass (configFile >> "CfgPatches" >> "VCOMAI")],
    ["HAS_A3XAI", isClass (configFile >> "CfgPatches" >> "A3XAI")],
    ["HAS_ASR", isClass (configFile >> "CfgPatches" >> "asr_ai3_main")],
    ["HAS_LAMBS", isClass (configFile >> "CfgPatches" >> "lambs_danger")],
    ["HAS_BCOMBAT", isClass (configFile >> "CfgPatches" >> "bcombat")],
    ["HAS_ACE3", isClass (configFile >> "CfgPatches" >> "ace_main")]
];

// =====================================================
// CONFIGURATION
// =====================================================
EAID_CONFIG = createHashMapFromArray [
    ["ENABLED", true],
    ["UPDATE_INTERVAL", 0.5],
    ["DEBUG", false],
    ["DEBUG_MARKERS", false],
    ["DEBUG_INTERVAL", 10],
    
    // Speed limits (km/h)
    ["SPEED_HIGHWAY", 160],
    ["SPEED_ROAD", 120],
    ["SPEED_OFFROAD", 80],
    ["SPEED_CURVE", 70],
    ["SPEED_OBSTACLE", 40],
    
    // Distances (meters)
    ["LOOKAHEAD_POINTS", [25, 50, 75, 100]],
    ["OBSTACLE_RADIUS", 12],
    ["OBSTACLE_OFFSET", 3],
    ["ROAD_SEARCH", 200],
    
    // Avoidance
    ["USE_OBSTACLES", true],
    ["OBSTACLE_COOLDOWN", 10],
    ["MIN_OBJECT_SIZE", 4],
    ["MIN_OBSTACLE_DISTANCE", 15],
    
    // Waypoint management
    ["MAX_WAYPOINTS", 5],
    ["WAYPOINT_CLEANUP_INTERVAL", 15],
    
    // === SIDE-BASED FILTERING ===
    ["ALLOWED_SIDES", [INDEPENDENT, EAST]],  // INDEPENDENT (custom AI) + EAST (A3XAI)
    ["EXCLUDED_SIDES", [WEST, CIVILIAN]],  // Exclude WEST (zombies) and CIVILIAN

    // === MOD COMPATIBILITY ===
    ["EXCLUDE_VCOMAI_UNITS", true],
    ["EXCLUDE_A3XAI_UNITS", false],  // FIXED: Enable enhanced driving for A3XAI vehicles
    ["EXCLUDE_ASR_UNITS", false],  // ASR usually plays nice
    ["EXCLUDE_LAMBS_UNITS", false], // LAMBS usually compatible
    ["EXCLUDE_BCOMBAT_UNITS", false]
];

// Global tracking
EAID_ActiveDrivers = createHashMap;
EAID_ProcessedUnits = []; // Track units that have been given event handlers
EAID_BuildingCache = createHashMap; // Track processed buildings to prevent re-spawning obstacles

diag_log "==========================================";
diag_log "Elite AI Driving System - Initializing...";
diag_log "==========================================";

// Log mod compatibility
{
    private _modName = _x;
    private _detected = EAID_ModCompat get _modName;
    diag_log format ["EAID: %1 = %2", _modName, _detected];
} forEach (keys EAID_ModCompat);

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

EAID_fnc_angleDiff = {
    params ["_angle1", "_angle2"];
    private _diff = _angle1 - _angle2;
    if (_diff > 180) then {_diff = _diff - 360};
    if (_diff < -180) then {_diff = _diff + 360};
    _diff
};

EAID_fnc_isEnhanced = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};
    private _netId = netId _unit;
    _netId in (keys EAID_ActiveDrivers)
};

EAID_fnc_isAllowedSide = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};
    
    private _unitSide = side (group _unit);
    private _allowedSides = EAID_CONFIG get "ALLOWED_SIDES";
    private _excludedSides = EAID_CONFIG get "EXCLUDED_SIDES";
    
    // Check if explicitly excluded first
    if (_unitSide in _excludedSides) exitWith {false};
    
    // Check if in allowed list
    if (_unitSide in _allowedSides) exitWith {true};
    
    // Default: not allowed
    false
};

// NEW: Check if unit belongs to another AI mod
EAID_fnc_isOtherAIModUnit = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};

    private _group = group _unit;

    // Check VCOMAI
    if (EAID_ModCompat get "HAS_VCOMAI" && {EAID_CONFIG get "EXCLUDE_VCOMAI_UNITS"}) then {
        if (!isNil {_group getVariable "VCM_INITIALIZED"} || {_unit getVariable ["VCOMAI_EXCLUDE", false]}) exitWith {true};
    };

    // Check A3XAI
    if (EAID_ModCompat get "HAS_A3XAI" && {EAID_CONFIG get "EXCLUDE_A3XAI_UNITS"}) then {
        if (!isNil {_group getVariable "A3XAI_Group"} || {_unit getVariable ["A3XAI_Unit", false]}) exitWith {true};
    };

    // Check ASR AI3
    if (EAID_ModCompat get "HAS_ASR" && {EAID_CONFIG get "EXCLUDE_ASR_UNITS"}) then {
        if (_group getVariable ["asr_ai3_group", false]) exitWith {true};
    };

    // Check LAMBS
    if (EAID_ModCompat get "HAS_LAMBS" && {EAID_CONFIG get "EXCLUDE_LAMBS_UNITS"}) then {
        if (_group getVariable ["lambs_danger_disableGroupAI", false]) exitWith {true};
    };

    // Check bcombat
    if (EAID_ModCompat get "HAS_BCOMBAT" && {EAID_CONFIG get "EXCLUDE_BCOMBAT_UNITS"}) then {
        if (_unit getVariable ["bcombat_exclude", false]) exitWith {true};
    };

    false
};

// NEW: Waypoint cleanup function
EAID_fnc_cleanupWaypoints = {
    params ["_group"];
    if (isNull _group) exitWith {};
    
    private _maxWaypoints = EAID_CONFIG get "MAX_WAYPOINTS";
    private _waypointCount = count waypoints _group;
    
    if (_waypointCount > _maxWaypoints) then {
        for "_i" from 0 to (_waypointCount - _maxWaypoints - 1) do {
            deleteWaypoint [_group, 0];
        };
        
        if (EAID_CONFIG get "DEBUG") then {
            diag_log format ["EAID: Cleaned %1 waypoints from group %2", _waypointCount - _maxWaypoints, _group];
        };
    };
};

// =====================================================
// CORE FUNCTIONS
// =====================================================

EAID_fnc_selectBestRoad = {
    params ["_vehicle", "_roads"];
    if (isNull _vehicle || count _roads == 0) exitWith {objNull};
    
    private _vehicleDir = getDir _vehicle;
    private _vehiclePos = getPos _vehicle;
    private _bestRoad = objNull;
    private _bestScore = -1;
    
    {
        if (!isNull _x) then {
            private _roadPos = getPos _x;
            private _roadDir = _vehiclePos getDir _roadPos;
            private _distance = _vehiclePos distance2D _roadPos;
            private _dirDiff = [_vehicleDir, _roadDir] call EAID_fnc_angleDiff;
            
            private _angleScore = 1 - ((abs _dirDiff) / 180);
            private _distScore = 1 - ((_distance / 200) min 1);
            private _totalScore = (_angleScore * 0.7) + (_distScore * 0.3);
            
            if (_totalScore > _bestScore) then {
                _bestScore = _totalScore;
                _bestRoad = _x;
            };
        };
    } forEach _roads;
    
    _bestRoad
};

EAID_fnc_roadFollowing = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};
    
    private _group = group _unit;
    private _lastLogTime = 0;
    private _lastCleanup = time;
    
    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {

        // Periodic waypoint cleanup
        if (!isNull _group && time - _lastCleanup > (EAID_CONFIG get "WAYPOINT_CLEANUP_INTERVAL")) then {
            [_group] call EAID_fnc_cleanupWaypoints;
            _lastCleanup = time;
        };

        private _currentPos = getPosASL _vehicle;
        private _currentRoads = _currentPos nearRoads 50;
        
        if (count _currentRoads > 0) then {
            private _currentRoad = _currentRoads select 0;
            private _connectedRoads = roadsConnectedTo _currentRoad;
            
            if (count _connectedRoads > 0) then {
                private _bestRoad = [_vehicle, _connectedRoads] call EAID_fnc_selectBestRoad;
                
                if (!isNull _bestRoad) then {
                    private _roadPos = getPos _bestRoad;
                    private _wpIndex = currentWaypoint _group;
                    
                    if ((count waypoints _group) <= _wpIndex) then {
                        private _wp = _group addWaypoint [_roadPos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "CARELESS";
                        _wp setWaypointCombatMode "BLUE";
                        _wp setWaypointTimeout [0, 0, 0];
                    };
                    
                    [_group, _wpIndex] setWaypointPosition [_roadPos, 0];
                    
                    // Lookahead
                    private _nextConnected = roadsConnectedTo _bestRoad;
                    if (count _nextConnected > 0) then {
                        private _nextBest = [_vehicle, _nextConnected] call EAID_fnc_selectBestRoad;
                        if (!isNull _nextBest) then {
                            private _nextPos = getPos _nextBest;
                            
                            if ((count waypoints _group) <= (_wpIndex + 1)) then {
                                private _wp = _group addWaypoint [_nextPos, 0];
                                _wp setWaypointType "MOVE";
                                _wp setWaypointSpeed "FULL";
                                _wp setWaypointBehaviour "CARELESS";
                                _wp setWaypointCombatMode "BLUE";
                                _wp setWaypointTimeout [0, 0, 0];
                            };
                            
                            [_group, _wpIndex + 1] setWaypointPosition [_nextPos, 0];
                        };
                    };
                };
            };
        } else {
            // Off-road - find nearest road
            private _nearRoads = _currentPos nearRoads (EAID_CONFIG get "ROAD_SEARCH");
            if (count _nearRoads > 0) then {
                private _targetRoad = _nearRoads select 0;
                private _wpIndex = currentWaypoint _group;
                
                if ((count waypoints _group) <= _wpIndex) then {
                    _group addWaypoint [getPos _targetRoad, 0];
                };
                
                [_group, _wpIndex] setWaypointPosition [getPos _targetRoad, 0];
                
                if (time - _lastLogTime > (EAID_CONFIG get "DEBUG_INTERVAL")) then {
                    if (EAID_CONFIG get "DEBUG") then {
                        diag_log format ["EAID: %1 off-road -> road %2m away", name _unit, round (_currentPos distance2D (getPos _targetRoad))];
                    };
                    _lastLogTime = time;
                };
            };
        };
        
        sleep 2;
    };
};

EAID_fnc_dynamicSpeed = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};
    
    private _updateInterval = EAID_CONFIG get "UPDATE_INTERVAL";
    private _obstacleRadius = EAID_CONFIG get "OBSTACLE_RADIUS";
    private _lookaheadPoints = EAID_CONFIG get "LOOKAHEAD_POINTS";
    private _debugEnabled = EAID_CONFIG get "DEBUG";
    private _debugInterval = EAID_CONFIG get "DEBUG_INTERVAL";
    
    private _lastLogTime = 0;
    
    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {

        private _velocity = velocity _vehicle;
        private _actualSpeed = vectorMagnitude _velocity;
        private _minSpeed = 999;
        private _speedReason = "CLEAR";
        
        if (_actualSpeed > 0.5) then {
            private _pos = getPosASL _vehicle;
            private _dir = getDir _vehicle;
            private _onRoad = isOnRoad _pos;
            
            // Multi-point lookahead
            {
                private _distance = _x;
                private _checkPos = _pos vectorAdd [sin _dir * _distance, cos _dir * _distance, 0];
                
                private _roadInfo = [_checkPos, 30] call BIS_fnc_nearestRoad;
                if (!isNull _roadInfo) then {
                    private _roadConnections = roadsConnectedTo _roadInfo;
                    if (count _roadConnections > 1) then {
                        if (_minSpeed > (EAID_CONFIG get "SPEED_CURVE")) then {
                            _minSpeed = EAID_CONFIG get "SPEED_CURVE";
                            _speedReason = "CURVE";
                        };
                    };
                };
                
                if (EAID_CONFIG get "USE_OBSTACLES") then {
                    private _objects = _checkPos nearEntities [["LandVehicle", "Air", "Ship", "Building", "House", "Wall"], _obstacleRadius];
                    
                    {
                        private _object = _x;
                        if (!isNull _object && _object != _vehicle && !(_object getVariable ["EAID_SpawnedObstacle", false])) then {
                            private _objectSize = [configFile >> "CfgVehicles" >> typeOf _object, "maximumLoad", 0] call BIS_fnc_returnConfigEntry;
                            
                            if (_objectSize > (EAID_CONFIG get "MIN_OBJECT_SIZE")) then {
                                private _objDist = _pos distance2D _object;
                                
                                if (_objDist < (EAID_CONFIG get "MIN_OBSTACLE_DISTANCE")) then {
                                    if (_minSpeed > (EAID_CONFIG get "SPEED_OBSTACLE")) then {
                                        _minSpeed = EAID_CONFIG get "SPEED_OBSTACLE";
                                        _speedReason = format ["OBSTACLE(%1@%2m)", typeOf _object, round _objDist];
                                    };
                                };
                            };
                        };
                    } forEach _objects;
                };
                
            } forEach _lookaheadPoints;
            
            if (_minSpeed == 999) then {
                if (_onRoad) then {
                    _minSpeed = EAID_CONFIG get "SPEED_HIGHWAY";
                } else {
                    _minSpeed = EAID_CONFIG get "SPEED_OFFROAD";
                };
            };
            
            // NULL CHECK before limiting speed
            if (!isNull _vehicle) then {
                _vehicle limitSpeed (_minSpeed / 3.6);
            };
            
            if (_debugEnabled && (time - _lastLogTime > _debugInterval)) then {
                diag_log format ["EAID: %1 (%2) - Speed: %3/%4 km/h | Reason: %5", 
                    name _unit,
                    side (group _unit),
                    round (_actualSpeed * 3.6), 
                    round _minSpeed,
                    _speedReason
                ];
                _lastLogTime = time;
            };
        } else {
            if (!isNull _vehicle) then {
                _vehicle limitSpeed -1;
            };
        };
        
        sleep _updateInterval;
    };
};

EAID_fnc_smartAvoidance = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};
    
    // Pass config values to avoid closure issues
    private _obstacleRadius = EAID_CONFIG get "OBSTACLE_RADIUS";
    private _obstacleOffset = EAID_CONFIG get "OBSTACLE_OFFSET";
    private _minObjectSize = EAID_CONFIG get "MIN_OBJECT_SIZE";
    private _obstacleCooldown = EAID_CONFIG get "OBSTACLE_COOLDOWN";
    private _lookaheadPoints = EAID_CONFIG get "LOOKAHEAD_POINTS";
    private _updateInterval = EAID_CONFIG get "UPDATE_INTERVAL";
    private _useObstacles = EAID_CONFIG get "USE_OBSTACLES";
    
    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {

        if (_useObstacles) then {
            private _pos = getPosASL _vehicle;
            private _dir = getDir _vehicle;
            
            {
                private _distance = _x;
                private _checkPos = _pos vectorAdd [sin _dir * _distance, cos _dir * _distance, 0];
                
                private _objects = _checkPos nearEntities [["Building", "House", "Wall"], _obstacleRadius];
                
                {
                    private _building = _x;
                    if (!isNull _building) then {
                        private _buildingNetId = netId _building;
                        private _lastProcessTime = EAID_BuildingCache getOrDefault [_buildingNetId, 0];

                        // Only process if cooldown has expired
                        if (time - _lastProcessTime > _obstacleCooldown) then {
                            EAID_BuildingCache set [_buildingNetId, time];

                            private _bbr = boundingBoxReal _building;
                            private _p1 = _bbr select 0;
                            private _p2 = _bbr select 1;
                            private _buildingSize = (_p2 distance _p1);

                            if (_buildingSize > _minObjectSize) then {
                                private _buildingPos = getPosASL _building;
                                private _obstacleCount = 0;

                                for "_i" from 0 to 7 do {
                                    private _angle = _i * 45;
                                    private _obstaclePos = _buildingPos vectorAdd [sin _angle * _obstacleOffset, cos _angle * _obstacleOffset, 0];

                                    if (!isOnRoad _obstaclePos) then {
                                        // Use invisible helipad - AI naturally avoids these
                                        private _obstacle = createVehicle ["Land_HelipadEmpty_F", _obstaclePos, [], 0, "CAN_COLLIDE"];
                                        if (!isNull _obstacle) then {
                                            _obstacle setPosASL _obstaclePos;
                                            _obstacle enableSimulationGlobal false;
                                            _obstacle hideObjectGlobal true;
                                            _obstacle setVariable ["EAID_SpawnedObstacle", true, false];
                                            _obstacle setVariable ["EAID_BuildingParent", _building, false];

                                            _obstacleCount = _obstacleCount + 1;
                                        };
                                    };
                                };

                                if (_obstacleCount > 0) then {
                                    // Pass all required values to spawned code
                                    [_building, _obstacleCooldown, _buildingNetId] spawn {
                                        params ["_building", "_cooldown", "_buildingNetId"];
                                        sleep _cooldown;

                                        if (!isNull _building) then {
                                            private _obstacles = nearestObjects [getPosASL _building, ["Land_HelipadEmpty_F"], 10];
                                            {
                                                if (!isNull _x && {(_x getVariable ["EAID_BuildingParent", objNull]) == _building}) then {
                                                    deleteVehicle _x;
                                                };
                                            } forEach _obstacles;
                                        };

                                        // Reset building cache after cleanup
                                        EAID_BuildingCache deleteAt _buildingNetId;
                                    };
                                };
                            };
                        };
                    };
                } forEach _objects;
                
            } forEach _lookaheadPoints;
        };
        
        sleep _updateInterval;
    };
};

// =====================================================
// APPLY/RESTORE FUNCTIONS
// =====================================================

EAID_fnc_applyToDriver = {
    params ["_unit", "_vehicle"];
    
    // NULL CHECKS
    if (isNull _unit || isNull _vehicle) exitWith {};
    if (!alive _unit || !alive _vehicle || driver _vehicle != _unit) exitWith {};
    if (!(_vehicle isKindOf "LandVehicle")) exitWith {};
    if ([_unit] call EAID_fnc_isEnhanced) exitWith {};
    
    // === SIDE-BASED FILTER ===
    if (!([_unit] call EAID_fnc_isAllowedSide)) exitWith {
        if (EAID_CONFIG get "DEBUG") then {
            diag_log format ["EAID: Skipped unit %1 (Side: %2) - Not in allowed sides", name _unit, side (group _unit)];
        };
    };
    
    // === CHECK FOR OTHER AI MOD UNITS ===
    if ([_unit] call EAID_fnc_isOtherAIModUnit) exitWith {
        if (EAID_CONFIG get "DEBUG") then {
            diag_log format ["EAID: Skipped unit %1 - Managed by another AI mod", name _unit];
        };
    };
    
    private _netId = netId _unit;
    
    private _originalSettings = createHashMapFromArray [
        ["courage", _unit skill "courage"],
        ["commanding", _unit skill "commanding"],
        ["combatMode", combatMode (group _unit)],
        ["behaviour", behaviour _unit],
        ["speedMode", speedMode (group _unit)],
        ["aiAutoCombat", _unit checkAIFeature "AUTOCOMBAT"],
        ["aiTarget", _unit checkAIFeature "TARGET"],
        ["aiAutoTarget", _unit checkAIFeature "AUTOTARGET"],
        ["aiSuppression", _unit checkAIFeature "SUPPRESSION"]
    ];
    
    EAID_ActiveDrivers set [_netId, _originalSettings];
    
    _unit setSkill ["courage", 1];
    _unit setSkill ["commanding", 1];
    
    private _group = group _unit;
    _group setCombatMode "BLUE";
    _group setBehaviour "CARELESS";
    _group setSpeedMode "FULL";
    
    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";
    _unit disableAI "SUPPRESSION";
    
    _vehicle setUnloadInCombat [false, false];
    _vehicle allowCrewInImmobile true;
    
    if (count units _group > 1) then {
        _group setFormation "COLUMN";
        _vehicle setConvoySeparation 50;
    };
    
    [_unit, _vehicle] spawn EAID_fnc_roadFollowing;
    [_unit, _vehicle] spawn EAID_fnc_dynamicSpeed;
    [_unit, _vehicle] spawn EAID_fnc_smartAvoidance;
    
    if (EAID_CONFIG get "DEBUG") then {
        diag_log format ["EAID: Enhanced %1 (Side: %2) in %3 (Max: %4 km/h)", name _unit, side (group _unit), typeOf _vehicle, EAID_CONFIG get "SPEED_HIGHWAY"];
    };
};

EAID_fnc_restoreDriver = {
    params ["_unit"];
    
    if (isNull _unit) exitWith {};
    if (!([_unit] call EAID_fnc_isEnhanced)) exitWith {};
    
    private _netId = netId _unit;
    private _originalSettings = EAID_ActiveDrivers get _netId;
    
    if (isNil "_originalSettings") exitWith {
        EAID_ActiveDrivers deleteAt _netId;
    };
    
    _unit setSkill ["courage", _originalSettings get "courage"];
    _unit setSkill ["commanding", _originalSettings get "commanding"];
    
    private _group = group _unit;
    if (!isNull _group) then {
        _group setCombatMode (_originalSettings get "combatMode");
        _group setBehaviour (_originalSettings get "behaviour");
        _group setSpeedMode (_originalSettings get "speedMode");
    };
    
    if (_originalSettings get "aiAutoCombat") then {_unit enableAI "AUTOCOMBAT"};
    if (_originalSettings get "aiTarget") then {_unit enableAI "TARGET"};
    if (_originalSettings get "aiAutoTarget") then {_unit enableAI "AUTOTARGET"};
    if (_originalSettings get "aiSuppression") then {_unit enableAI "SUPPRESSION"};
    
    private _vehicle = vehicle _unit;
    if (!isNull _vehicle && _vehicle != _unit) then {
        _vehicle limitSpeed -1;
    };
    
    EAID_ActiveDrivers deleteAt _netId;
    
    if (EAID_CONFIG get "DEBUG") then {
        diag_log format ["EAID: Restored %1", name _unit];
    };
};

// =====================================================
// EVENT HANDLERS
// =====================================================

EAID_fnc_addEventHandlers = {
    // Initial scan for existing drivers
    {
        if (!isPlayer _x && alive _x && !isNull _x) then {
            private _vehicle = vehicle _x;
            if (_vehicle != _x && driver _vehicle == _x && _vehicle isKindOf "LandVehicle") then {
                [_x, _vehicle] call EAID_fnc_applyToDriver;
            };
        };
    } forEach allUnits;
    
    // Add event handlers to all future units
    if (EAID_ModCompat get "HAS_CBA") then {
        ["CAManBase", "init", {
            params ["_unit"];
            
            if (!isPlayer _unit && (EAID_CONFIG get "ENABLED")) then {
                
                private _getInID = _unit addEventHandler ["GetInMan", {
                    params ["_unit", "_role", "_vehicle"];
                    
                    if (_role == "driver" && !isPlayer _unit && _vehicle isKindOf "LandVehicle") then {
                        [_unit, _vehicle] spawn {
                            params ["_unit", "_vehicle"];
                            sleep 0.5;
                            if (!isNull _unit && !isNull _vehicle) then {
                                [_unit, _vehicle] call EAID_fnc_applyToDriver;
                            };
                        };
                    };
                }];
                
                private _getOutID = _unit addEventHandler ["GetOutMan", {
                    params ["_unit", "_role"];
                    if (_role == "driver") then {[_unit] call EAID_fnc_restoreDriver};
                }];
                
                private _killedID = _unit addEventHandler ["Killed", {
                    params ["_unit"];
                    [_unit] call EAID_fnc_restoreDriver;
                    
                    // Clean up event handlers
                    private _getInID = _unit getVariable ["EAID_GetInHandler", -1];
                    private _getOutID = _unit getVariable ["EAID_GetOutHandler", -1];
                    private _killedID = _unit getVariable ["EAID_KilledHandler", -1];
                    
                    if (_getInID >= 0) then {_unit removeEventHandler ["GetInMan", _getInID]};
                    if (_getOutID >= 0) then {_unit removeEventHandler ["GetOutMan", _getOutID]};
                    if (_killedID >= 0) then {_unit removeEventHandler ["Killed", _killedID]};
                }];
                
                // Store handler IDs for cleanup
                _unit setVariable ["EAID_GetInHandler", _getInID];
                _unit setVariable ["EAID_GetOutHandler", _getOutID];
                _unit setVariable ["EAID_KilledHandler", _killedID];
            };
        }] call CBA_fnc_addClassEventHandler;
        
        diag_log "EAID: Using CBA event handlers";
    } else {
        diag_log "EAID: CBA not detected - using fallback polling";
    };
};

// =====================================================
// FALLBACK POLLING (NO CBA)
// =====================================================

EAID_fnc_fallbackPolling = {
    while {EAID_CONFIG get "ENABLED"} do {
        {
            if (!isPlayer _x && alive _x && !isNull _x) then {
                private _unit = _x;

                // Only process each unit once for event handler attachment
                if !(_unit in EAID_ProcessedUnits) then {
                    EAID_ProcessedUnits pushBack _unit;

                    // Add event handlers manually since no CBA
                    private _getInID = _unit addEventHandler ["GetInMan", {
                        params ["_unit", "_role", "_vehicle"];

                        if (_role == "driver" && !isPlayer _unit && _vehicle isKindOf "LandVehicle") then {
                            [_unit, _vehicle] spawn {
                                params ["_unit", "_vehicle"];
                                sleep 0.5;
                                if (!isNull _unit && !isNull _vehicle) then {
                                    [_unit, _vehicle] call EAID_fnc_applyToDriver;
                                };
                            };
                        };
                    }];

                    private _getOutID = _unit addEventHandler ["GetOutMan", {
                        params ["_unit", "_role"];
                        if (_role == "driver") then {[_unit] call EAID_fnc_restoreDriver};
                    }];

                    private _killedID = _unit addEventHandler ["Killed", {
                        params ["_unit"];
                        [_unit] call EAID_fnc_restoreDriver;

                        // Clean up event handlers
                        private _getInID = _unit getVariable ["EAID_GetInHandler", -1];
                        private _getOutID = _unit getVariable ["EAID_GetOutHandler", -1];
                        private _killedID = _unit getVariable ["EAID_KilledHandler", -1];

                        if (_getInID >= 0) then {_unit removeEventHandler ["GetInMan", _getInID]};
                        if (_getOutID >= 0) then {_unit removeEventHandler ["GetOutMan", _getOutID]};
                        if (_killedID >= 0) then {_unit removeEventHandler ["Killed", _killedID]};
                    }];

                    // Store handler IDs for cleanup
                    _unit setVariable ["EAID_GetInHandler", _getInID];
                    _unit setVariable ["EAID_GetOutHandler", _getOutID];
                    _unit setVariable ["EAID_KilledHandler", _killedID];
                };

                // Check if unit is currently driving
                private _vehicle = vehicle _unit;
                if (_vehicle != _unit && driver _vehicle == _unit && _vehicle isKindOf "LandVehicle" && !([_unit] call EAID_fnc_isEnhanced)) then {
                    [_unit, _vehicle] call EAID_fnc_applyToDriver;
                };
            };
        } forEach allUnits;

        sleep 5;
    };
};

// =====================================================
// CLEANUP LOOP
// =====================================================

EAID_fnc_cleanupLoop = {
    while {EAID_CONFIG get "ENABLED"} do {
        sleep 30;
        
        private _toRemove = [];
        {
            private _netId = _x;
            private _unit = objectFromNetId _netId;
            
            if (isNull _unit || !alive _unit || vehicle _unit == _unit || driver (vehicle _unit) != _unit) then {
                if (!isNull _unit) then {
                    _toRemove pushBack _unit;
                } else {
                    // Unit no longer exists, clean up hashmap entry
                    EAID_ActiveDrivers deleteAt _netId;
                };
            };
        } forEach (keys EAID_ActiveDrivers);
        
        {
            if (!isNull _x) then {[_x] call EAID_fnc_restoreDriver};
        } forEach _toRemove;
        
        // Clean up processed units list
        EAID_ProcessedUnits = EAID_ProcessedUnits select {!isNull _x && alive _x};
        
        if ((EAID_CONFIG get "DEBUG") && count _toRemove > 0) then {
            diag_log format ["EAID: Cleanup - Active: %1 | Removed: %2 | Tracked: %3", 
                count EAID_ActiveDrivers, 
                count _toRemove,
                count EAID_ProcessedUnits
            ];
        };
    };
};

// =====================================================
// START SYSTEM
// =====================================================

if (EAID_CONFIG get "ENABLED") then {
    
    call EAID_fnc_addEventHandlers;
    
    // Start fallback polling if no CBA
    if !(EAID_ModCompat get "HAS_CBA") then {
        [] spawn EAID_fnc_fallbackPolling;
    };
    
    [] spawn EAID_fnc_cleanupLoop;
    
    diag_log "==========================================";
    diag_log "Elite AI Driving System - ACTIVE";
    diag_log format ["Allowed Sides: %1", EAID_CONFIG get "ALLOWED_SIDES"];
    diag_log format ["Excluded Sides: %1", EAID_CONFIG get "EXCLUDED_SIDES"];
    diag_log format ["Max Highway: %1 km/h", EAID_CONFIG get "SPEED_HIGHWAY"];
    diag_log format ["Using CBA: %1", EAID_ModCompat get "HAS_CBA"];
    diag_log format ["VCOMAI Detected: %1 (Excluded: %2)", EAID_ModCompat get "HAS_VCOMAI", EAID_CONFIG get "EXCLUDE_VCOMAI_UNITS"];
    diag_log format ["Debug logging every %1 seconds", EAID_CONFIG get "DEBUG_INTERVAL"];
    diag_log "==========================================";
    
} else {
    diag_log "Elite AI Driving System - DISABLED";
};
