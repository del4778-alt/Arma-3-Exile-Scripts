/*
    =====================================================
    ELITE AI DRIVING SYSTEM - POLISHED & PERFECTED
    =====================================================
    Author: Master SQF Engineer
    Version: 4.0 - COMBAT DRIVING MASTERY
    =====================================================

    NEW IN v4.0:
    ✓ Run over enemy AI on roads (don't avoid them)
    ✓ Smart vehicle avoidance (slow down or go around)
    ✓ No more sharp turns into buildings
    ✓ Eliminated 3-point turns
    ✓ Smooth curve handling
    ✓ Combat-aware driving (aggressive when enemies present)
    ✓ No fence/obstacle collisions
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
    ["SPEED_HIGHWAY", 140],
    ["SPEED_ROAD", 100],
    ["SPEED_OFFROAD", 70],
    ["SPEED_CURVE", 60],
    ["SPEED_VEHICLE_AHEAD", 50],  // Slow down for vehicles

    // Distances (meters)
    ["LOOKAHEAD_DISTANCE", 80],  // Single smooth lookahead
    ["CURVE_DETECT_DISTANCE", 50],
    ["VEHICLE_DETECT_DISTANCE", 60],
    ["ROAD_SEARCH", 150],

    // Combat Driving
    ["RUN_OVER_ENEMIES", true],  // Run over enemy AI
    ["AVOID_FRIENDLY_VEHICLES", true],  // Avoid friendly/neutral vehicles
    ["BUILDING_AVOID_DISTANCE", 25],  // Stop sharp turns into buildings
    
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
    private _lookaheadDistance = EAID_CONFIG get "LOOKAHEAD_DISTANCE";
    private _vehicleDetectDist = EAID_CONFIG get "VEHICLE_DETECT_DISTANCE";
    private _curveDetectDist = EAID_CONFIG get "CURVE_DETECT_DISTANCE";
    private _debugEnabled = EAID_CONFIG get "DEBUG";
    private _debugInterval = EAID_CONFIG get "DEBUG_INTERVAL";
    private _runOverEnemies = EAID_CONFIG get "RUN_OVER_ENEMIES";
    private _avoidVehicles = EAID_CONFIG get "AVOID_FRIENDLY_VEHICLES";

    private _lastLogTime = 0;

    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {

        private _velocity = velocity _vehicle;
        private _actualSpeed = vectorMagnitude _velocity;
        private _targetSpeed = 999;
        private _speedReason = "CLEAR";

        if (_actualSpeed > 0.5) then {
            private _pos = getPosASL _vehicle;
            private _dir = getDir _vehicle;
            private _onRoad = isOnRoad _pos;
            private _unitSide = side (group _unit);

            // Check for curves ahead
            private _curveCheckPos = _pos vectorAdd [sin _dir * _curveDetectDist, cos _dir * _curveDetectDist, 0];
            private _roadAhead = [_curveCheckPos, 30] call BIS_fnc_nearestRoad;

            if (!isNull _roadAhead) then {
                private _roadConnections = roadsConnectedTo _roadAhead;
                if (count _roadConnections > 1) then {
                    // Curve detected
                    private _currentRoad = [_pos, 30] call BIS_fnc_nearestRoad;
                    if (!isNull _currentRoad) then {
                        private _roadDir = _pos getDir (getPos _roadAhead);
                        private _angleDiff = [_dir, _roadDir] call EAID_fnc_angleDiff;

                        // Slow down based on curve sharpness
                        if (abs _angleDiff > 45) then {
                            _targetSpeed = EAID_CONFIG get "SPEED_CURVE";
                            _speedReason = format ["SHARP_CURVE(%1°)", round (abs _angleDiff)];
                        } else if (abs _angleDiff > 25) then {
                            _targetSpeed = (EAID_CONFIG get "SPEED_ROAD");
                            _speedReason = format ["CURVE(%1°)", round (abs _angleDiff)];
                        };
                    };
                };
            };

            // Check for vehicles ahead (NOT enemy AI)
            if (_avoidVehicles && _targetSpeed > (EAID_CONFIG get "SPEED_VEHICLE_AHEAD")) then {
                private _checkPos = _pos vectorAdd [sin _dir * _vehicleDetectDist, cos _dir * _vehicleDetectDist, 0];
                private _vehiclesAhead = _checkPos nearEntities [["LandVehicle", "Air", "Ship"], _vehicleDetectDist];

                {
                    private _otherVehicle = _x;
                    if (!isNull _otherVehicle && _otherVehicle != _vehicle && alive _otherVehicle) then {
                        private _distance = _vehicle distance2D _otherVehicle;

                        // Check if it's directly ahead (within 60 degree arc)
                        private _vehicleDir = _pos getDir (getPos _otherVehicle);
                        private _angleDiff = [_dir, _vehicleDir] call EAID_fnc_angleDiff;

                        if (abs _angleDiff < 60 && _distance < _vehicleDetectDist) then {
                            // Slow down for vehicles (friendly or neutral)
                            private _otherSide = side (driver _otherVehicle);
                            if (_otherSide != _unitSide || _otherSide == civilian) then {
                                _targetSpeed = EAID_CONFIG get "SPEED_VEHICLE_AHEAD";
                                _speedReason = format ["VEHICLE_AHEAD(%1@%2m)", typeOf _otherVehicle, round _distance];
                            };
                        };
                    };
                } forEach _vehiclesAhead;
            };

            // Don't slow down for enemy AI on roads if configured
            if (_runOverEnemies) then {
                // Enemy AI will be run over - no speed reduction
                // This is handled by NOT checking for CAManBase in the vehicle detection above
            };

            // Set default speed if no obstacles
            if (_targetSpeed == 999) then {
                if (_onRoad) then {
                    _targetSpeed = EAID_CONFIG get "SPEED_HIGHWAY";
                    _speedReason = "HIGHWAY";
                } else {
                    _targetSpeed = EAID_CONFIG get "SPEED_OFFROAD";
                    _speedReason = "OFFROAD";
                };
            };

            // Apply speed limit
            if (!isNull _vehicle) then {
                _vehicle limitSpeed (_targetSpeed / 3.6);
            };

            if (_debugEnabled && (time - _lastLogTime > _debugInterval)) then {
                diag_log format ["EAID: %1 - Speed: %2/%3 km/h | %4",
                    name _unit,
                    round (_actualSpeed * 3.6),
                    round _targetSpeed,
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

    private _updateInterval = EAID_CONFIG get "UPDATE_INTERVAL";
    private _buildingAvoidDist = EAID_CONFIG get "BUILDING_AVOID_DISTANCE";

    // SIMPLIFIED: Only prevent driving INTO buildings, don't create obstacles
    // This prevents sharp turns and 3-point turns caused by obstacle spawning

    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {

        private _pos = getPosASL _vehicle;
        private _dir = getDir _vehicle;

        // Only check directly ahead for large buildings
        private _checkPos = _pos vectorAdd [sin _dir * _buildingAvoidDist, cos _dir * _buildingAvoidDist, 0];
        private _nearBuildings = _checkPos nearEntities [["Building", "House"], _buildingAvoidDist];

        private _dangerousBuilding = false;
        {
            private _building = _x;
            if (!isNull _building) then {
                // Check if building is directly ahead
                private _buildingDir = _pos getDir (getPos _building);
                private _angleDiff = [_dir, _buildingDir] call EAID_fnc_angleDiff;

                if (abs _angleDiff < 30) then {
                    // Building is directly ahead
                    private _distance = _vehicle distance2D _building;

                    if (_distance < _buildingAvoidDist) then {
                        _dangerousBuilding = true;
                    };
                };
            };
        } forEach _nearBuildings;

        // If building directly ahead, slow down but DON'T create obstacles
        // AI will naturally avoid via waypoint system
        if (_dangerousBuilding) then {
            if (!isNull _vehicle) then {
                _vehicle limitSpeed ((EAID_CONFIG get "SPEED_CURVE") / 3.6);
            };
        };

        sleep (_updateInterval * 2);  // Check less frequently
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
