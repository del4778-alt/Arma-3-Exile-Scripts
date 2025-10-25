/*
    =====================================================
    ELITE AI DRIVING SYSTEM - ALL-IN-ONE
    =====================================================
    Author: Master SQF Engineer
    Version: 2.4 - COMPREHENSIVE FIX (All bugs fixed)
    =====================================================
    
    FIXES APPLIED:
    1. Tagged spawned obstacles
    2. Filtered tagged obstacles in detection
    3. Fixed missing parentheses in restoreDriver
    4. Replaced infinite while loops with if statements
    5. Added null check in cleanup
    6. Optimized nearObjects to nearEntities
    7. Increased speed filter to catch faster vehicles
    8. Added stuck vehicle auto-recovery
    9. Cached config lookups and reduced log spam
    10. Fixed _minSpeed scope error
    =====================================================
*/

if (!isServer) exitWith {};

// =====================================================
// CONFIGURATION
// =====================================================
EAID_CONFIG = createHashMapFromArray [
    ["ENABLED", true],
    ["UPDATE_INTERVAL", 0.5],
    ["DEBUG", true],
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
    ["ROAD_SEARCH", 200],
    
    // Avoidance
    ["USE_OBSTACLES", true],
    ["OBSTACLE_COOLDOWN", 10],
    ["MIN_OBJECT_SIZE", 4],
    ["MIN_OBSTACLE_DISTANCE", 15]
];

// Global tracking
EAID_ActiveDrivers = createHashMap;

diag_log "==========================================";
diag_log "Elite AI Driving System - Initializing...";
diag_log "==========================================";

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
    private _netId = netId _unit;
    _netId in (keys EAID_ActiveDrivers)
};

// =====================================================
// CORE FUNCTIONS
// =====================================================

EAID_fnc_selectBestRoad = {
    params ["_vehicle", "_roads"];
    
    private _vehicleDir = getDir _vehicle;
    private _vehiclePos = getPos _vehicle;
    private _bestRoad = objNull;
    private _bestScore = -1;
    
    {
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
    } forEach _roads;
    
    _bestRoad
};

EAID_fnc_roadFollowing = {
    params ["_unit", "_vehicle"];
    
    private _group = group _unit;
    private _lastLogTime = 0;
    
    while {alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {
        
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
                
                // Only log every X seconds
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
    
    // FIX: Cache config lookups for performance
    private _updateInterval = EAID_CONFIG get "UPDATE_INTERVAL";
    private _obstacleRadius = EAID_CONFIG get "OBSTACLE_RADIUS";
    private _lookaheadPoints = EAID_CONFIG get "LOOKAHEAD_POINTS";
    private _debugEnabled = EAID_CONFIG get "DEBUG";
    private _debugInterval = EAID_CONFIG get "DEBUG_INTERVAL";
    
    private _lastLogTime = 0;
    
    while {alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {
        
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
                private _lookDist = _x;
                private _checkPos = _pos getPos [_lookDist, _dir];
                
                // Check obstacles - FILTER OUT SPAWNED AND OWN VEHICLE
                private _objects = _checkPos nearEntities [["Car", "Truck", "Tank", "Ship", "Air", "Building", "House", "Wall"], _obstacleRadius];
                _objects = _objects select {
                    private _obj = _x;
                    _obj != _vehicle && 
                    !(_obj isKindOf "Man") && 
                    !(_obj isKindOf "Logic") &&
                    !(_obj isKindOf "Helper_Base_F") &&
                    !(_obj getVariable ["EAID_SpawnedObstacle", false]) &&
                    (speed _obj) < 30 &&
                    (_obj distance _vehicle) > 5
                };
                
                if (count _objects > 0) then {
                    private _obstacleSpeed = EAID_CONFIG get "SPEED_OBSTACLE";
                    if (_obstacleSpeed < _minSpeed) then {
                        _minSpeed = _obstacleSpeed;
                        _speedReason = format ["OBSTACLE (%1 objects at %2m)", count _objects, round _lookDist];
                    };
                };
                
                // Check curves
                if (_onRoad) then {
                    private _nearRoads = _checkPos nearRoads 15;
                    if (count _nearRoads > 0) then {
                        private _road = _nearRoads select 0;
                        private _roadDir = _pos getDir (getPos _road);
                        private _angleDiff = [_dir, _roadDir] call EAID_fnc_angleDiff;
                        
                        if (abs _angleDiff > 30) then {
                            private _curveSpeed = EAID_CONFIG get "SPEED_CURVE";
                            if (_curveSpeed < _minSpeed) then {
                                _minSpeed = _curveSpeed;
                                _speedReason = format ["CURVE (%1°)", round (abs _angleDiff)];
                            };
                        };
                    };
                };
                
                // Check road end
                private _nearRoads = _checkPos nearRoads 10;
                if (count _nearRoads == 0 && _onRoad) then {
                    if (50 < _minSpeed) then {
                        _minSpeed = 50;
                        _speedReason = "ROAD_END";
                    };
                };
                
                // Check slopes
                private _heightDiff = abs ((getTerrainHeightASL _checkPos) - (_pos select 2));
                if (_heightDiff > 10) then {
                    private _slopeSpeed = EAID_CONFIG get "SPEED_OFFROAD";
                    if (_slopeSpeed < _minSpeed) then {
                        _minSpeed = _slopeSpeed;
                        _speedReason = format ["SLOPE (%1m)", round _heightDiff];
                    };
                };
                
            } forEach _lookaheadPoints;
            
            // Apply speed limit
            if (_minSpeed < 999) then {
                _vehicle limitSpeed _minSpeed;
                
                if (time - _lastLogTime > _debugInterval) then {
                    if (_debugEnabled) then {
                        diag_log format ["EAID: %1 | Speed: %2/%3 km/h | Reason: %4", name _unit, round _actualSpeed, round _minSpeed, _speedReason];
                    };
                    _lastLogTime = time;
                };
            } else {
                // Set appropriate speed for terrain
                private _maxSpeed = if (_onRoad) then {
                    EAID_CONFIG get "SPEED_HIGHWAY"
                } else {
                    EAID_CONFIG get "SPEED_OFFROAD"
                };
                _vehicle limitSpeed _maxSpeed;
            };
        };
        
        // FIX: Stuck vehicle detection and recovery
        private _pos = getPosASL _vehicle;
        private _stuckTime = _vehicle getVariable ["EAID_StuckTime", 0];
        
        if (_actualSpeed < 0.5 && _minSpeed < 50) then {
            if (_stuckTime == 0) then {
                _vehicle setVariable ["EAID_StuckTime", time];
            } else {
                if (time - _stuckTime > 10) then {
                    private _nearbyObstacles = _pos nearObjects ["All", 30];
                    private _clearedCount = 0;
                    {
                        if (_x getVariable ["EAID_SpawnedObstacle", false]) then {
                            deleteVehicle _x;
                            _clearedCount = _clearedCount + 1;
                        };
                    } forEach _nearbyObstacles;
                    if (_clearedCount > 0 && _debugEnabled) then {
                        diag_log format ["EAID: %1 stuck - cleared %2 spawned obstacles", name _unit, _clearedCount];
                    };
                    _vehicle setVariable ["EAID_StuckTime", 0];
                };
            };
        } else {
            _vehicle setVariable ["EAID_StuckTime", 0];
        };
        
        sleep _updateInterval;
    };
};

EAID_fnc_smartAvoidance = {
    params ["_unit", "_vehicle"];
    
    while {alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call EAID_fnc_isEnhanced)} do {
        
        if (EAID_CONFIG get "USE_OBSTACLES") then {
            private _pos = getPosASL _vehicle;
            private _dir = getDir _vehicle;
            
            {
                private _lookDist = _x;
                private _checkPos = _pos getPos [_lookDist, _dir];
                
                // Find large objects
                private _objects = _checkPos nearObjects ["All", EAID_CONFIG get "OBSTACLE_RADIUS"];
                _objects = _objects select {
                    private _obj = _x;
                    _obj != _vehicle &&
                    !(_obj isKindOf "Man") &&
                    !(_obj isKindOf "Logic") &&
                    !(_obj isKindOf "Helper_Base_F") &&
                    !(_obj getVariable ["EAID_SpawnedObstacle", false]) &&
                    (speed _obj) < 10 &&
                    (_obj distance _vehicle) > (EAID_CONFIG get "MIN_OBSTACLE_DISTANCE")
                };
                
                {
                    private _obstacle = _x;
                    private _objSize = (boundingBoxReal _obstacle) select 1 select 0;
                    
                    if (_objSize > (EAID_CONFIG get "MIN_OBJECT_SIZE")) then {
                        if (!(_obstacle getVariable ["EAID_Processed", false])) then {
                            _obstacle setVariable ["EAID_Processed", true, false];
                            
                            // Calculate bounding box corners
                            private _bbox = boundingBoxReal _obstacle;
                            private _p1 = _bbox select 0;
                            private _p2 = _bbox select 1;
                            
                            private _positions = [
                                _obstacle modelToWorld [_p2 select 0, _p2 select 1, 0],
                                _obstacle modelToWorld [_p1 select 0, _p2 select 1, 0],
                                _obstacle modelToWorld [_p1 select 0, _p1 select 1, 0],
                                _obstacle modelToWorld [_p2 select 0, _p1 select 1, 0]
                            ];
                            
                            private _obstacles = [];
                            
                            // Spawn obstacles at corners
                            {
                                private _obstacleObj = createVehicle ["Land_CanOpener_F", _x, [], 0, "CAN_COLLIDE"];
                                _obstacleObj setVariable ["EAID_SpawnedObstacle", true, false];
                                _obstacleObj enableSimulation false;
                                _obstacleObj hideObjectGlobal true;
                                _obstacles pushBack _obstacleObj;
                            } forEach _positions;
                            
                            if (EAID_CONFIG get "DEBUG") then {
                                private _building = nearestBuilding (getPos _obstacle);
                                diag_log format ["EAID: Spawned %1 obstacles around %2 (size: %3m)", count _obstacles, typeOf _building, round _objSize];
                            };
                            
                            // Cleanup after delay
                            [_obstacle, _obstacles] spawn {
                                params ["_building", "_obstacles"];
                                sleep (EAID_CONFIG get "OBSTACLE_COOLDOWN");
                                {
                                    if (!isNull _x) then {
                                        deleteVehicle _x;
                                    };
                                } forEach _obstacles;
                                if (!isNull _building) then {
                                    _building setVariable ["EAID_Processed", false, false];
                                };
                            };
                        };
                    };
                } forEach _objects;
                
            } forEach (EAID_CONFIG get "LOOKAHEAD_POINTS");
        };
        
        sleep (EAID_CONFIG get "UPDATE_INTERVAL");
    };
};

// =====================================================
// APPLY/RESTORE FUNCTIONS
// =====================================================

EAID_fnc_applyToDriver = {
    params ["_unit", "_vehicle"];
    
    if (!alive _unit || !alive _vehicle || driver _vehicle != _unit) exitWith {};
    if (!(_vehicle isKindOf "LandVehicle")) exitWith {};
    if ([_unit] call EAID_fnc_isEnhanced) exitWith {};
    
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
        diag_log format ["EAID: Enhanced %1 in %2 (Max: %3 km/h)", name _unit, typeOf _vehicle, EAID_CONFIG get "SPEED_HIGHWAY"];
    };
};

EAID_fnc_restoreDriver = {
    params ["_unit"];
    
    if (!([_unit] call EAID_fnc_isEnhanced)) exitWith {};
    
    private _netId = netId _unit;
    private _originalSettings = EAID_ActiveDrivers get _netId;
    
    _unit setSkill ["courage", _originalSettings get "courage"];
    _unit setSkill ["commanding", _originalSettings get "commanding"];
    
    private _group = group _unit;
    _group setCombatMode (_originalSettings get "combatMode");
    _group setBehaviour (_originalSettings get "behaviour");
    _group setSpeedMode (_originalSettings get "speedMode");
    
    if (_originalSettings get "aiAutoCombat") then {_unit enableAI "AUTOCOMBAT"};
    if (_originalSettings get "aiTarget") then {_unit enableAI "TARGET"};
    if (_originalSettings get "aiAutoTarget") then {_unit enableAI "AUTOTARGET"};
    if (_originalSettings get "aiSuppression") then {_unit enableAI "SUPPRESSION"};
    
    if (!isNull vehicle _unit && vehicle _unit != _unit) then {
        (vehicle _unit) limitSpeed -1;
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
    {
        if (!isPlayer _x && alive _x) then {
            private _vehicle = vehicle _x;
            if (_vehicle != _x && driver _vehicle == _x && _vehicle isKindOf "LandVehicle") then {
                [_x, _vehicle] call EAID_fnc_applyToDriver;
            };
        };
    } forEach allUnits;
    
    ["CAManBase", "init", {
        params ["_unit"];
        
        if (!isPlayer _unit && (EAID_CONFIG get "ENABLED")) then {
            
            _unit addEventHandler ["GetInMan", {
                params ["_unit", "_role", "_vehicle"];
                
                if (_role == "driver" && !isPlayer _unit && _vehicle isKindOf "LandVehicle") then {
                    [_unit, _vehicle] spawn {
                        params ["_unit", "_vehicle"];
                        sleep 0.5;
                        [_unit, _vehicle] call EAID_fnc_applyToDriver;
                    };
                };
            }];
            
            _unit addEventHandler ["GetOutMan", {
                params ["_unit", "_role"];
                if (_role == "driver") then {[_unit] call EAID_fnc_restoreDriver};
            }];
            
            _unit addEventHandler ["Killed", {
                params ["_unit"];
                [_unit] call EAID_fnc_restoreDriver;
            }];
        };
    }] call CBA_fnc_addClassEventHandler;
};

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
                };
            };
        } forEach (keys EAID_ActiveDrivers);
        
        {
            if (!isNull _x) then {[_x] call EAID_fnc_restoreDriver};
        } forEach _toRemove;
        
        if ((EAID_CONFIG get "DEBUG") && count _toRemove > 0) then {
            diag_log format ["EAID: Cleanup - Active: %1 | Removed: %2", count EAID_ActiveDrivers, count _toRemove];
        };
    };
};

// =====================================================
// START SYSTEM
// =====================================================

if (EAID_CONFIG get "ENABLED") then {
    
    if (isClass (configFile >> "CfgPatches" >> "cba_main")) then {
        call EAID_fnc_addEventHandlers;
    } else {
        [] spawn {
            while {EAID_CONFIG get "ENABLED"} do {
                {
                    if (!isPlayer _x && alive _x) then {
                        private _vehicle = vehicle _x;
                        if (_vehicle != _x && driver _vehicle == _x && _vehicle isKindOf "LandVehicle" && !([_x] call EAID_fnc_isEnhanced)) then {
                            [_x, _vehicle] call EAID_fnc_applyToDriver;
                        };
                    };
                } forEach allUnits;
                sleep 5;
            };
        };
        diag_log "EAID: Running in fallback mode (no CBA)";
    };
    
    [] spawn EAID_fnc_cleanupLoop;
    
    diag_log "==========================================";
    diag_log "Elite AI Driving System - ACTIVE";
    diag_log format ["Max Highway: %1 km/h", EAID_CONFIG get "SPEED_HIGHWAY"];
    diag_log format ["Debug logging every %1 seconds", EAID_CONFIG get "DEBUG_INTERVAL"];
    diag_log "==========================================";
    
} else {
    diag_log "Elite AI Driving System - DISABLED";
};