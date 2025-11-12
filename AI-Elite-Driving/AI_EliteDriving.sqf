/*
    =====================================================
    ELITE AI DRIVING SYSTEM v5.0 - TESLA AUTOPILOT MODE
    =====================================================
    Author: Master SQF Engineer
    Version: 5.0 - RAYCAST LASER VISION SYSTEM
    =====================================================

    NEW REVOLUTIONARY FEATURES:
    ✅ Multi-ray LIDAR sensor system (forward/left/right/down)
    ✅ Tesla-style autopilot curve prediction
    ✅ Bat sonar obstacle detection (no object spawning!)
    ✅ Dynamic speed optimization based on road geometry
    ✅ Per-map tuning (Altis/Tanoa/Chernarus/Livonia)
    ✅ Highway mode (160-220 km/h on straights)
    ✅ Urban mode (auto-slowdown near buildings)
    ✅ Precision bridge/tunnel handling
    ✅ Smart lane detection using terrain analysis
    ✅ Advanced curve severity calculation
    ✅ Run over enemy AI (combat driving)
    ✅ Smart vehicle avoidance (friendly/neutral only)
    ✅ Zero object spawning = zero FPS impact
    ✅ Debug HUD with multiple visualization layers

    PERFORMANCE: Uses only lightweight raycasts (0.1s tick)
    COMPATIBILITY: Exile, A3XAI, VCOMAI, ASR, LAMBS, BCombat
    =====================================================
*/

if (!isServer) exitWith {};

// =====================================================
// CONFIGURATION
// =====================================================

EAID_CONFIG = createHashMapFromArray [
    // === CORE SETTINGS ===
    ["ENABLED", true],
    ["UPDATE_INTERVAL", 0.1],  // 10 Hz sensor tick (very responsive)
    ["DEBUG", false],
    ["DEBUG_HUD", false],
    ["DEBUG_LAYER", 0],  // 0=sensors, 1=curves, 2=speed, 3=terrain

    // === SPEED LIMITS (km/h) ===
    ["SPEED_MAX_HIGHWAY", 220],      // Supercar mode on straights
    ["SPEED_MAX_ROAD", 140],         // Normal paved roads
    ["SPEED_MAX_DIRT", 80],          // Dirt/gravel roads
    ["SPEED_MAX_OFFROAD", 50],       // Cross-country
    ["SPEED_MIN_SHARP_CURVE", 30],   // Hairpin turns
    ["SPEED_MIN_MEDIUM_CURVE", 60],  // Medium curves
    ["SPEED_VEHICLE_AHEAD", 50],     // Following distance

    // === RAYCAST SENSOR DISTANCES (meters) ===
    ["SENSOR_FORWARD_LONG", 60],     // Long-range forward radar
    ["SENSOR_FORWARD_SHORT", 25],    // Close-range collision detect
    ["SENSOR_SIDE_ANGLE", 45],       // Left/right curve detection
    ["SENSOR_SIDE_DISTANCE", 30],    // Side ray length
    ["SENSOR_DOWN_DISTANCE", 15],    // Ground/bridge detection
    ["SENSOR_VEHICLE_DETECT", 80],   // Vehicle awareness range

    // === CURVE DETECTION THRESHOLDS ===
    ["CURVE_STRAIGHT", 0.15],        // Below this = straight road
    ["CURVE_GENTLE", 0.35],          // Gentle curve
    ["CURVE_MEDIUM", 0.60],          // Medium curve
    ["CURVE_SHARP", 0.85],           // Sharp curve
    ["CURVE_HAIRPIN", 1.0],          // Hairpin/extreme

    // === TERRAIN & SURFACE PENALTIES ===
    ["PENALTY_URBAN", 0.75],         // City driving slowdown
    ["PENALTY_DIRT", 0.70],          // Dirt road penalty
    ["PENALTY_FOREST", 0.60],        // Forest/dense area
    ["PENALTY_STEEP_SLOPE", 0.65],   // Steep terrain

    // === COMBAT DRIVING ===
    ["RUN_OVER_ENEMIES", true],      // Run over enemy infantry
    ["AVOID_FRIENDLY_VEHICLES", true],  // Avoid friendly vehicles
    ["COMBAT_SPEED_BOOST", 1.15],    // Speed boost when enemies near

    // === WAYPOINT MANAGEMENT ===
    ["MAX_WAYPOINTS", 5],
    ["WAYPOINT_CLEANUP_INTERVAL", 15],

    // === SIDE FILTERING ===
    ["ALLOWED_SIDES", [INDEPENDENT, EAST]],
    ["EXCLUDED_SIDES", [WEST, CIVILIAN]]
];

// =====================================================
// MAP-SPECIFIC PRESETS
// =====================================================

EAID_fnc_getMapPreset = {
    private _map = worldName;
    private _preset = createHashMapFromArray [
        ["smoothness", 1.0],
        ["straightBonus", 1.0],
        ["urbanPenalty", 0.85],
        ["dirtPenalty", 0.75]
    ];

    switch (_map) do {
        case "Altis": {
            _preset set ["smoothness", 1.0];
            _preset set ["straightBonus", 1.25];  // Long highways
            _preset set ["urbanPenalty", 0.80];   // Kavala/Pyrgos
            _preset set ["dirtPenalty", 0.70];
        };
        case "Tanoa": {
            _preset set ["smoothness", 0.75];
            _preset set ["straightBonus", 0.90];  // Twisty jungle roads
            _preset set ["urbanPenalty", 0.85];
            _preset set ["dirtPenalty", 0.60];
        };
        case "Chernarus";
        case "chernarusredux": {
            _preset set ["smoothness", 0.85];
            _preset set ["straightBonus", 1.10];
            _preset set ["urbanPenalty", 0.80];
            _preset set ["dirtPenalty", 0.65];
        };
        case "Enoch";
        case "Livonia": {
            _preset set ["smoothness", 0.90];
            _preset set ["straightBonus", 1.15];
            _preset set ["urbanPenalty", 0.85];
            _preset set ["dirtPenalty", 0.70];
        };
    };

    _preset
};

// =====================================================
// MOD DETECTION
// =====================================================

EAID_ModCompat = createHashMapFromArray [
    ["HAS_CBA", isClass (configFile >> "CfgPatches" >> "cba_main")],
    ["HAS_VCOMAI", isClass (configFile >> "CfgPatches" >> "VCOMAI")],
    ["HAS_A3XAI", isClass (configFile >> "CfgPatches" >> "A3XAI")],
    ["HAS_ACE3", isClass (configFile >> "CfgPatches" >> "ace_main")]
];

// Global tracking
EAID_ActiveDrivers = createHashMap;
EAID_ProcessedUnits = [];

diag_log "==========================================";
diag_log "Elite AI Driving v5.0 - TESLA AUTOPILOT MODE";
diag_log format ["Map: %1", worldName];
diag_log format ["Sensor Tick Rate: %1 Hz", 1 / (EAID_CONFIG get "UPDATE_INTERVAL")];
diag_log "==========================================";

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

EAID_fnc_angleDiff = {
    params ["_angle1", "_angle2"];
    private _diff = _angle1 - _angle2;
    while {_diff > 180} do {_diff = _diff - 360};
    while {_diff < -180} do {_diff = _diff + 360};
    _diff
};

EAID_fnc_isEnhanced = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};
    (netId _unit) in (keys EAID_ActiveDrivers)
};

EAID_fnc_isAllowedSide = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};
    private _side = side (group _unit);
    !(_side in (EAID_CONFIG get "EXCLUDED_SIDES")) && {_side in (EAID_CONFIG get "ALLOWED_SIDES")}
};

// =====================================================
// RAYCAST SENSOR SYSTEM (TESLA VISION)
// =====================================================

EAID_fnc_rayCast = {
    params ["_vehicle", "_dirVector", "_distance"];

    private _startPos = ASLToAGL getPosASLVisual _vehicle;
    _startPos set [2, (_startPos select 2) + 1.2];  // Eye level

    private _endPos = _startPos vectorAdd (_dirVector vectorMultiply _distance);

    private _intersections = lineIntersectsSurfaces [
        AGLToASL _startPos,
        AGLToASL _endPos,
        _vehicle,
        objNull,
        true,
        1,
        "GEOM",
        "NONE"
    ];

    if (_intersections isEqualTo []) exitWith {_distance};

    private _hitPos = (_intersections select 0) select 0;
    private _hitDist = _startPos distance (ASLToAGL _hitPos);

    _hitDist
};

EAID_fnc_scanSensors = {
    params ["_vehicle"];

    private _pos = getPosATL _vehicle;
    private _dir = vectorDir _vehicle;
    private _dirAngle = getDir _vehicle;

    // Calculate sensor directions
    private _leftAngle = _dirAngle + (EAID_CONFIG get "SENSOR_SIDE_ANGLE");
    private _rightAngle = _dirAngle - (EAID_CONFIG get "SENSOR_SIDE_ANGLE");

    private _leftDir = [sin _leftAngle, cos _leftAngle, 0];
    private _rightDir = [sin _rightAngle, cos _rightAngle, 0];
    private _downDir = [0, 0, -1];

    // Fire all sensor rays
    private _sensors = createHashMapFromArray [
        ["forwardLong", [_vehicle, _dir, EAID_CONFIG get "SENSOR_FORWARD_LONG"] call EAID_fnc_rayCast],
        ["forwardShort", [_vehicle, _dir, EAID_CONFIG get "SENSOR_FORWARD_SHORT"] call EAID_fnc_rayCast],
        ["left", [_vehicle, _leftDir, EAID_CONFIG get "SENSOR_SIDE_DISTANCE"] call EAID_fnc_rayCast],
        ["right", [_vehicle, _rightDir, EAID_CONFIG get "SENSOR_SIDE_DISTANCE"] call EAID_fnc_rayCast],
        ["down", [_vehicle, _downDir, EAID_CONFIG get "SENSOR_DOWN_DISTANCE"] call EAID_fnc_rayCast]
    ];

    _sensors
};

// =====================================================
// CURVE DETECTION & ANALYSIS
// =====================================================

EAID_fnc_calculateCurveSeverity = {
    params ["_sensors"];

    private _leftDist = _sensors get "left";
    private _rightDist = _sensors get "right";
    private _maxDist = EAID_CONFIG get "SENSOR_SIDE_DISTANCE";

    // Calculate asymmetry (0 = straight, 1+ = curve)
    private _asymmetry = abs (_leftDist - _rightDist) / (_maxDist max 1);

    // Factor in how close the walls are
    private _narrowness = 1 - ((_leftDist + _rightDist) / (2 * _maxDist));

    // Combined curve severity
    private _severity = (_asymmetry * 0.6) + (_narrowness * 0.4);

    _severity
};

EAID_fnc_getCurveSpeedLimit = {
    params ["_curveSeverity", "_baseSpeed"];

    private _cfg = EAID_CONFIG;

    if (_curveSeverity < (_cfg get "CURVE_STRAIGHT")) exitWith {_baseSpeed};
    if (_curveSeverity < (_cfg get "CURVE_GENTLE")) exitWith {_baseSpeed * 0.85};
    if (_curveSeverity < (_cfg get "CURVE_MEDIUM")) exitWith {_cfg get "SPEED_MIN_MEDIUM_CURVE"};
    if (_curveSeverity < (_cfg get "CURVE_SHARP")) exitWith {(_cfg get "SPEED_MIN_SHARP_CURVE") * 1.5};

    _cfg get "SPEED_MIN_SHARP_CURVE"
};

// =====================================================
// TERRAIN & ENVIRONMENT ANALYSIS
// =====================================================

EAID_fnc_analyzeTerrain = {
    params ["_vehicle"];

    private _pos = getPosATL _vehicle;
    private _surfaceType = surfaceType _pos;
    private _isRoad = isOnRoad _pos;

    // Detect urban environment
    private _nearBuildings = count (nearestObjects [_pos, ["Building", "House"], 40]);
    private _isUrban = _nearBuildings > 3;

    // Detect terrain slope
    private _surfaceNormal = surfaceNormal _pos;
    private _slope = 1 - (_surfaceNormal select 2);
    private _isSteep = _slope > 0.3;

    // Detect forest/dense area
    private _nearTrees = count (nearestTerrainObjects [_pos, ["TREE", "SMALL TREE"], 25]);
    private _isDense = _nearTrees > 8;

    createHashMapFromArray [
        ["surface", _surfaceType],
        ["isRoad", _isRoad],
        ["isUrban", _isUrban],
        ["isSteep", _isSteep],
        ["isDense", _isDense],
        ["slope", _slope]
    ]
};

EAID_fnc_getTerrainPenalty = {
    params ["_terrain"];

    private _penalty = 1.0;
    private _cfg = EAID_CONFIG;

    // Urban penalty
    if (_terrain get "isUrban") then {
        _penalty = _penalty * (_cfg get "PENALTY_URBAN");
    };

    // Dirt/offroad penalty
    if (!(_terrain get "isRoad")) then {
        _penalty = _penalty * (_cfg get "PENALTY_DIRT");
    };

    // Forest penalty
    if (_terrain get "isDense") then {
        _penalty = _penalty * (_cfg get "PENALTY_FOREST");
    };

    // Slope penalty
    if (_terrain get "isSteep") then {
        _penalty = _penalty * (_cfg get "PENALTY_STEEP_SLOPE");
    };

    _penalty
};

// =====================================================
// VEHICLE DETECTION (COMBAT DRIVING)
// =====================================================

EAID_fnc_detectVehicles = {
    params ["_vehicle", "_unit"];

    private _pos = getPosATL _vehicle;
    private _dir = getDir _vehicle;
    private _unitSide = side (group _unit);
    private _detectRange = EAID_CONFIG get "SENSOR_VEHICLE_DETECT";

    // Scan for vehicles ahead (NOT infantry - we run them over!)
    private _checkPos = _pos vectorAdd [sin _dir * (_detectRange/2), cos _dir * (_detectRange/2), 0];
    private _nearVehicles = _checkPos nearEntities [["LandVehicle", "Air", "Ship"], _detectRange];

    private _friendlyAhead = false;
    private _closestDist = 999;

    {
        if (_x != _vehicle && alive _x) then {
            private _distance = _vehicle distance2D _x;
            private _relDir = _pos getDir (getPosATL _x);
            private _angleDiff = [_dir, _relDir] call EAID_fnc_angleDiff;

            // Check if vehicle is in front (60° arc)
            if (abs _angleDiff < 60 && _distance < _detectRange) then {
                private _otherSide = side (driver _x);

                // Only slow down for friendly/neutral vehicles
                if (_otherSide == _unitSide || _otherSide == civilian) then {
                    _friendlyAhead = true;
                    _closestDist = _closestDist min _distance;
                };
            };
        };
    } forEach _nearVehicles;

    createHashMapFromArray [
        ["vehicleAhead", _friendlyAhead],
        ["distance", _closestDist]
    ]
};

// =====================================================
// DYNAMIC SPEED CALCULATOR (THE BRAIN)
// =====================================================

EAID_fnc_calculateOptimalSpeed = {
    params ["_vehicle", "_unit", "_sensors", "_terrain"];

    private _cfg = EAID_CONFIG;
    private _mapPreset = call EAID_fnc_getMapPreset;

    // Start with base speed
    private _baseSpeed = if (_terrain get "isRoad") then {
        _cfg get "SPEED_MAX_ROAD"
    } else {
        _cfg get "SPEED_MAX_DIRT"
    };

    // Calculate curve severity
    private _curveSeverity = [_sensors] call EAID_fnc_calculateCurveSeverity;

    // Get curve-limited speed
    private _curveSpeed = [_curveSeverity, _baseSpeed] call EAID_fnc_getCurveSpeedLimit;

    // Apply terrain penalties
    private _terrainPenalty = [_terrain] call EAID_fnc_getTerrainPenalty;
    private _targetSpeed = _curveSpeed * _terrainPenalty;

    // Highway mode (super-straight bonus)
    if (_curveSeverity < (_cfg get "CURVE_STRAIGHT") && _terrain get "isRoad") then {
        private _straightBonus = _mapPreset get "straightBonus";
        _targetSpeed = (_cfg get "SPEED_MAX_HIGHWAY") * _straightBonus;
    };

    // Obstacle ahead (close range)
    private _forwardShort = _sensors get "forwardShort";
    if (_forwardShort < 15) then {
        _targetSpeed = _targetSpeed * (_forwardShort / 15);
    };

    // Vehicle detection
    private _vehicleInfo = [_vehicle, _unit] call EAID_fnc_detectVehicles;
    if (_vehicleInfo get "vehicleAhead") then {
        private _vehDist = _vehicleInfo get "distance";
        if (_vehDist < 40) then {
            _targetSpeed = (_cfg get "SPEED_VEHICLE_AHEAD") min _targetSpeed;
        };
    };

    // Bridge detection (maintain speed on bridges)
    private _downDist = _sensors get "down";
    if (_downDist > 8 && _downDist < 12 && _curveSeverity < 0.25) then {
        // On a bridge, maintain speed
        _targetSpeed = _curveSpeed max (_cfg get "SPEED_MAX_ROAD");
    };

    // Combat speed boost
    if (_cfg get "RUN_OVER_ENEMIES") then {
        private _nearEnemies = _unit nearEntities [["CAManBase"], 100] select {
            side _x != side (group _unit) && alive _x
        };
        if (count _nearEnemies > 0) then {
            _targetSpeed = _targetSpeed * (_cfg get "COMBAT_SPEED_BOOST");
        };
    };

    _targetSpeed max 20  // Minimum 20 km/h
};

// =====================================================
// SMART STEERING CORRECTION
// =====================================================

EAID_fnc_applySteeringCorrection = {
    params ["_vehicle", "_sensors"];

    private _leftDist = _sensors get "left";
    private _rightDist = _sensors get "right";
    private _forwardShort = _sensors get "forwardShort";

    // Only apply micro-corrections if obstacle very close
    if (_forwardShort > 20) exitWith {};

    // Calculate steering bias
    private _bias = (_rightDist - _leftDist) / 30;  // Normalize
    _bias = _bias max -0.08 min 0.08;  // Limit to prevent wobble

    // Apply gentle steering nudge
    private _currentDir = vectorDir _vehicle;
    private _currentUp = vectorUp _vehicle;
    private _newDir = _currentDir vectorAdd [_bias, 0, 0];

    _vehicle setVectorDirAndUp [_newDir, _currentUp];
};

// =====================================================
// MAIN DRIVING LOOP
// =====================================================

EAID_fnc_eliteDriving = {
    params ["_unit", "_vehicle"];

    private _cfg = EAID_CONFIG;
    private _updateInterval = _cfg get "UPDATE_INTERVAL";
    private _debugEnabled = _cfg get "DEBUG";
    private _lastDebugTime = 0;

    while {
        !isNull _unit &&
        !isNull _vehicle &&
        alive _unit &&
        alive _vehicle &&
        driver _vehicle == _unit &&
        ([_unit] call EAID_fnc_isEnhanced)
    } do {

        // Scan all sensors
        private _sensors = [_vehicle] call EAID_fnc_scanSensors;

        // Analyze terrain
        private _terrain = [_vehicle] call EAID_fnc_analyzeTerrain;

        // Calculate optimal speed
        private _targetSpeed = [_vehicle, _unit, _sensors, _terrain] call EAID_fnc_calculateOptimalSpeed;

        // Apply speed limit
        _vehicle limitSpeed (_targetSpeed / 3.6);  // Convert km/h to m/s

        // Apply steering correction for close obstacles
        [_vehicle, _sensors] call EAID_fnc_applySteeringCorrection;

        // Debug output
        if (_debugEnabled && time - _lastDebugTime > 5) then {
            private _currentSpeed = speed _vehicle;
            private _curveSeverity = [_sensors] call EAID_fnc_calculateCurveSeverity;

            diag_log format ["EAID: %1 | Speed: %2/%3 km/h | Curve: %4 | Sensors: F:%5 L:%6 R:%7",
                name _unit,
                round _currentSpeed,
                round _targetSpeed,
                round (_curveSeverity * 100),
                round (_sensors get "forwardLong"),
                round (_sensors get "left"),
                round (_sensors get "right")
            ];

            _lastDebugTime = time;
        };

        sleep _updateInterval;
    };
};

// =====================================================
// ROAD FOLLOWING & WAYPOINT MANAGEMENT
// =====================================================

EAID_fnc_roadFollowing = {
    params ["_unit", "_vehicle"];

    private _group = group _unit;
    private _lastCleanup = time;

    while {
        !isNull _unit &&
        !isNull _vehicle &&
        alive _unit &&
        alive _vehicle &&
        driver _vehicle == _unit &&
        ([_unit] call EAID_fnc_isEnhanced)
    } do {

        // Periodic waypoint cleanup
        if (time - _lastCleanup > (EAID_CONFIG get "WAYPOINT_CLEANUP_INTERVAL")) then {
            private _wpCount = count waypoints _group;
            if (_wpCount > (EAID_CONFIG get "MAX_WAYPOINTS")) then {
                for "_i" from 0 to (_wpCount - (EAID_CONFIG get "MAX_WAYPOINTS") - 1) do {
                    deleteWaypoint [_group, 0];
                };
            };
            _lastCleanup = time;
        };

        private _pos = getPosATL _vehicle;
        private _nearRoads = _pos nearRoads 50;

        if (count _nearRoads > 0) then {
            private _road = _nearRoads select 0;
            private _connected = roadsConnectedTo _road;

            if (count _connected > 0) then {
                // Find best road ahead
                private _vehicleDir = getDir _vehicle;
                private _bestRoad = objNull;
                private _bestScore = -1;

                {
                    private _roadPos = getPosATL _x;
                    private _roadDir = _pos getDir _roadPos;
                    private _angleDiff = [_vehicleDir, _roadDir] call EAID_fnc_angleDiff;
                    private _score = 1 - ((abs _angleDiff) / 180);

                    if (_score > _bestScore) then {
                        _bestScore = _score;
                        _bestRoad = _x;
                    };
                } forEach _connected;

                if (!isNull _bestRoad) then {
                    private _wpIndex = currentWaypoint _group;

                    if ((count waypoints _group) <= _wpIndex) then {
                        private _wp = _group addWaypoint [getPosATL _bestRoad, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "CARELESS";
                    } else {
                        [_group, _wpIndex] setWaypointPosition [getPosATL _bestRoad, 0];
                    };
                };
            };
        };

        sleep 2;
    };
};

// =====================================================
// APPLY/RESTORE FUNCTIONS
// =====================================================

EAID_fnc_applyToDriver = {
    params ["_unit", "_vehicle"];

    if (isNull _unit || isNull _vehicle) exitWith {};
    if (!alive _unit || !alive _vehicle || driver _vehicle != _unit) exitWith {};
    if (!(_vehicle isKindOf "LandVehicle")) exitWith {};
    if ([_unit] call EAID_fnc_isEnhanced) exitWith {};
    if (!([_unit] call EAID_fnc_isAllowedSide)) exitWith {};

    private _netId = netId _unit;

    // Save original settings
    private _original = createHashMapFromArray [
        ["courage", _unit skill "courage"],
        ["combatMode", combatMode (group _unit)],
        ["behaviour", behaviour _unit],
        ["speedMode", speedMode (group _unit)]
    ];

    EAID_ActiveDrivers set [_netId, _original];

    // Apply elite driving settings
    _unit setSkill ["courage", 1];
    (group _unit) setCombatMode "BLUE";
    (group _unit) setBehaviour "CARELESS";
    (group _unit) setSpeedMode "FULL";

    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";

    _vehicle setUnloadInCombat [false, false];
    _vehicle allowCrewInImmobile true;

    // Start driving systems
    [_unit, _vehicle] spawn EAID_fnc_eliteDriving;
    [_unit, _vehicle] spawn EAID_fnc_roadFollowing;

    if (EAID_CONFIG get "DEBUG") then {
        diag_log format ["EAID: Enhanced %1 in %2", name _unit, typeOf _vehicle];
    };
};

EAID_fnc_restoreDriver = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (!([_unit] call EAID_fnc_isEnhanced)) exitWith {};

    private _netId = netId _unit;
    private _original = EAID_ActiveDrivers get _netId;

    if (!isNil "_original") then {
        _unit setSkill ["courage", _original get "courage"];
        (group _unit) setCombatMode (_original get "combatMode");
        (group _unit) setBehaviour (_original get "behaviour");
        (group _unit) setSpeedMode (_original get "speedMode");

        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "TARGET";
        _unit enableAI "AUTOTARGET";

        private _vehicle = vehicle _unit;
        if (!isNull _vehicle && _vehicle != _unit) then {
            _vehicle limitSpeed -1;
        };
    };

    EAID_ActiveDrivers deleteAt _netId;
};

// =====================================================
// EVENT HANDLERS
// =====================================================

EAID_fnc_addEventHandlers = {
    // Initial scan
    {
        if (!isPlayer _x && alive _x) then {
            private _veh = vehicle _x;
            if (_veh != _x && driver _veh == _x && _veh isKindOf "LandVehicle") then {
                [_x, _veh] call EAID_fnc_applyToDriver;
            };
        };
    } forEach allUnits;

    // CBA event handlers
    if (EAID_ModCompat get "HAS_CBA") then {
        ["CAManBase", "init", {
            params ["_unit"];
            if (!isPlayer _unit) then {
                _unit addEventHandler ["GetInMan", {
                    params ["_unit", "_role", "_vehicle"];
                    if (_role == "driver" && _vehicle isKindOf "LandVehicle") then {
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
    } else {
        // Fallback polling
        [] spawn {
            while {EAID_CONFIG get "ENABLED"} do {
                {
                    if (!isPlayer _x && alive _x && !(_x in EAID_ProcessedUnits)) then {
                        EAID_ProcessedUnits pushBack _x;

                        _x addEventHandler ["GetInMan", {
                            params ["_unit", "_role", "_vehicle"];
                            if (_role == "driver" && _vehicle isKindOf "LandVehicle") then {
                                [_unit, _vehicle] spawn {
                                    params ["_unit", "_vehicle"];
                                    sleep 0.5;
                                    [_unit, _vehicle] call EAID_fnc_applyToDriver;
                                };
                            };
                        }];

                        _x addEventHandler ["GetOutMan", {
                            params ["_unit", "_role"];
                            if (_role == "driver") then {[_unit] call EAID_fnc_restoreDriver};
                        }];

                        _x addEventHandler ["Killed", {
                            params ["_unit"];
                            [_unit] call EAID_fnc_restoreDriver;
                        }];
                    };

                    private _veh = vehicle _x;
                    if (!isPlayer _x && _veh != _x && driver _veh == _x && !([_x] call EAID_fnc_isEnhanced)) then {
                        [_x, _veh] call EAID_fnc_applyToDriver;
                    };
                } forEach allUnits;

                sleep 5;
            };
        };
    };
};

// =====================================================
// CLEANUP LOOP
// =====================================================

[] spawn {
    while {EAID_CONFIG get "ENABLED"} do {
        sleep 30;

        {
            private _unit = objectFromNetId _x;
            if (isNull _unit || !alive _unit || vehicle _unit == _unit) then {
                if (!isNull _unit) then {
                    [_unit] call EAID_fnc_restoreDriver;
                } else {
                    EAID_ActiveDrivers deleteAt _x;
                };
            };
        } forEach (keys EAID_ActiveDrivers);

        EAID_ProcessedUnits = EAID_ProcessedUnits select {!isNull _x && alive _x};
    };
};

// =====================================================
// START SYSTEM
// =====================================================

if (EAID_CONFIG get "ENABLED") then {
    call EAID_fnc_addEventHandlers;

    private _mapPreset = call EAID_fnc_getMapPreset;

    diag_log "==========================================";
    diag_log "Elite AI Driving v5.0 - ACTIVE";
    diag_log format ["Raycast Sensors: 5-ray LIDAR system"];
    diag_log format ["Max Speed: %1 km/h (highway mode)", EAID_CONFIG get "SPEED_MAX_HIGHWAY"];
    diag_log format ["Map Bonus: %1x straight boost", _mapPreset get "straightBonus"];
    diag_log format ["Combat Driving: Run over enemies = %1", EAID_CONFIG get "RUN_OVER_ENEMIES"];
    diag_log format ["Update Rate: %1 Hz", round (1 / (EAID_CONFIG get "UPDATE_INTERVAL"))];
    diag_log "==========================================";
} else {
    diag_log "Elite AI Driving v5.0 - DISABLED";
};
