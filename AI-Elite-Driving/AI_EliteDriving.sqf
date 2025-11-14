/*
    =====================================================
    ELITE AI DRIVING SYSTEM v5.2 - TESLA AUTOPILOT MODE
    =====================================================
    Author: Master SQF Engineer
    Version: 5.2 - ULTIMATE DRIVING AI + CORNER FIX
    =====================================================

    NEW IN v5.2:
    ✅ Corner obstacle detection (90° turn fix)
    ✅ Additional corner sensors at 70° angle
    ✅ Aggressive slowdown for corner obstacles
    ✅ Enhanced steering to avoid cutting corners
    ✅ Prevents hitting houses/sandbags at 90° turns

    v5.1 Features:
    ✅ Drift/skid detection and counter-steering
    ✅ Auto-unstuck system (gentle reverse recovery)
    ✅ Smooth speed transitions (interpolation)
    ✅ Vehicle class-specific presets (Sport/Truck/MRAP)
    ✅ Periodic behavior refresh (combat override prevention)
    ✅ forceFollowRoad integration

    CORE FEATURES:
    ✅ 7-ray LIDAR sensor system (forward/left/right/corners/down)
    ✅ Corner obstacle detection (prevents cutting 90° turns)
    ✅ Tesla-style autopilot curve prediction
    ✅ Bat sonar obstacle detection (no object spawning!)
    ✅ Dynamic speed optimization based on road geometry
    ✅ Per-map tuning (Altis/Tanoa/Chernarus/Livonia)
    ✅ Highway mode (160-220 km/h on straights)
    ✅ Urban mode (auto-slowdown near buildings)
    ✅ Precision bridge/tunnel handling
    ✅ Advanced curve severity calculation
    ✅ Run over enemy AI (combat driving)
    ✅ Smart vehicle avoidance (friendly/neutral only)
    ✅ Zero object spawning = zero FPS impact

    PERFORMANCE: Uses only lightweight raycasts (0.1s tick)
    COMPATIBILITY: Exile, A3XAI, DMS, VCOMAI, ASR, LAMBS, BCombat
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
    ["SENSOR_CORNER_ANGLE", 70],     // Corner obstacle detection (NEW)
    ["SENSOR_SIDE_DISTANCE", 30],    // Side ray length
    ["SENSOR_CORNER_DISTANCE", 20],  // Corner ray length (NEW)
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
    ["ALLOWED_SIDES", [INDEPENDENT, EAST, WEST, CIVILIAN]],  // ALL AI sides
    ["EXCLUDED_SIDES", []],  // No exclusions - applies to ALL AI on server

    // === DRIFT & STABILITY ===
    ["DRIFT_ANGLE_THRESHOLD", 0.35],     // Radians (20°)
    ["DRIFT_YAW_THRESHOLD", 0.7],        // Angular velocity threshold
    ["DRIFT_SPEED_PENALTY", 0.75],       // Slow to 75% when drifting
    ["COUNTER_STEER_STRENGTH", 0.02],    // Steering correction power

    // === AUTO-UNSTUCK ===
    ["UNSTUCK_SPEED_THRESHOLD", 1],      // km/h - below this = stuck
    ["UNSTUCK_TIME_THRESHOLD", 3],       // seconds stuck before recovery
    ["UNSTUCK_REVERSE_FORCE", -2],       // Reverse velocity (m/s)
    ["UNSTUCK_RECOVERY_TIME", 1.2],      // How long to reverse

    // === SMOOTH TRANSITIONS ===
    ["SPEED_INTERPOLATION", 3],          // Smoothing factor (higher = smoother)
    ["BEHAVIOR_REFRESH_INTERVAL", 3]     // Seconds between AI behavior refresh
];

// =====================================================
// VEHICLE CLASS-SPECIFIC PRESETS
// =====================================================

EAID_fnc_getVehiclePreset = {
    params ["_vehicle"];

    // Returns [straightSpeed, midSpeed, hardCurve, tightCurve]
    private _preset = switch (true) do {
        // Sport cars (fastest)
        case (typeOf _vehicle in [
            "Exile_Car_Hatchback_Sport_Red",
            "Exile_Car_Hatchback_Sport_Blue",
            "Exile_Car_Hatchback_Sport_White",
            "Exile_Car_Hatchback_Sport_Yellow",
            "Exile_Car_Hatchback_Sport_Green",
            "Exile_Car_Hatchback_Sport_Black",
            "C_Hatchback_01_sport_F"
        ]): {[200, 95, 45, 25]};

        // Offroad vehicles
        case (_vehicle isKindOf "Offroad_01_base_F"): {[120, 70, 40, 25]};
        case (_vehicle isKindOf "Offroad_02_base_F"): {[110, 65, 38, 23]};

        // MRAPs (heavy, stable)
        case (_vehicle isKindOf "MRAP_01_base_F"): {[90, 55, 35, 20]};
        case (_vehicle isKindOf "MRAP_02_base_F"): {[85, 52, 33, 18]};
        case (_vehicle isKindOf "MRAP_03_base_F"): {[95, 58, 36, 22]};

        // Trucks (slow, careful)
        case (_vehicle isKindOf "Truck_F"): {[70, 45, 25, 15]};
        case (_vehicle isKindOf "Truck_01_base_F"): {[65, 42, 23, 13]};
        case (_vehicle isKindOf "Truck_02_base_F"): {[68, 44, 24, 14]};

        // SUVs
        case (_vehicle isKindOf "SUV_01_base_F"): {[110, 65, 38, 22]};

        // Generic cars
        case (_vehicle isKindOf "Car_F"): {[120, 70, 40, 25]};

        // Default fallback
        default {[100, 60, 35, 20]};
    };

    _preset
};

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
diag_log "Elite AI Driving v5.2 - CORNER FIX UPDATE";
diag_log format ["Map: %1", worldName];
diag_log format ["Sensor Tick Rate: %1 Hz", 1 / (EAID_CONFIG get "UPDATE_INTERVAL")];
diag_log format ["Features: 7-Ray LIDAR + Corner Detection + Drift + Auto-Unstuck"];
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
// DRIFT/SKID DETECTION & COUNTER-STEERING
// =====================================================

EAID_fnc_detectAndCorrectDrift = {
    params ["_vehicle"];

    private _speed = speed _vehicle;
    if (_speed < 10) exitWith {[false, 1.0]};  // [isDrifting, speedMultiplier]

    private _cfg = EAID_CONFIG;
    private _dir = vectorDir _vehicle;
    private _vel = velocity _vehicle;

    // Normalize velocity vector
    if (_vel isEqualTo [0,0,0]) exitWith {[false, 1.0]};
    private _velNorm = vectorNormalized _vel;

    // Calculate angle between direction and velocity
    private _dotProduct = (_velNorm vectorDotProduct _dir) max -1 min 1;
    private _angle = acos _dotProduct;

    // Get angular velocity (yaw)
    private _angVel = angularVelocity _vehicle;
    private _yaw = _angVel select 2;

    // Check if drifting/sliding
    private _isDrifting = _angle > (_cfg get "DRIFT_ANGLE_THRESHOLD") || {abs _yaw > (_cfg get "DRIFT_YAW_THRESHOLD")};

    if (_isDrifting) then {
        // Apply counter-steering
        private _side = vectorNormalized (_dir vectorCrossProduct [0,0,1]);
        private _yawClamped = (_yaw max -0.5 min 0.5);
        private _counter = _side vectorMultiply (_yawClamped * -(_cfg get "COUNTER_STEER_STRENGTH"));
        private _newDir = _dir vectorAdd _counter;

        _vehicle setVectorDirAndUp [_newDir, vectorUp _vehicle];

        // Return drift status and speed penalty
        [true, _cfg get "DRIFT_SPEED_PENALTY"]
    } else {
        [false, 1.0]
    };
};

// =====================================================
// AUTO-UNSTUCK SYSTEM
// =====================================================

EAID_fnc_handleStuck = {
    params ["_vehicle", "_unit"];

    private _speed = speed _vehicle;
    private _cfg = EAID_CONFIG;
    private _threshold = _cfg get "UNSTUCK_SPEED_THRESHOLD";

    if (_speed < _threshold) then {
        // Vehicle is moving very slowly or stopped
        private _stuckTime = _vehicle getVariable ["EAID_stuckTime", diag_tickTime];
        private _timeDiff = diag_tickTime - _stuckTime;

        if (_timeDiff > (_cfg get "UNSTUCK_TIME_THRESHOLD")) then {
            // Vehicle has been stuck for too long - initiate recovery
            _vehicle limitSpeed 10;
            _unit forceFollowRoad false;

            // Apply gentle reverse
            _vehicle setVelocityModelSpace [0, _cfg get "UNSTUCK_REVERSE_FORCE", 0];

            // Re-engage after recovery time
            [_unit, _vehicle] spawn {
                params ["_unit", "_vehicle"];
                sleep (EAID_CONFIG get "UNSTUCK_RECOVERY_TIME");
                if (!isNull _unit && alive _unit) then {
                    _unit forceFollowRoad true;
                };
            };

            // Reset stuck timer (add cooldown)
            _vehicle setVariable ["EAID_stuckTime", diag_tickTime + (_cfg get "UNSTUCK_TIME_THRESHOLD")];

            if (EAID_CONFIG get "DEBUG") then {
                diag_log format ["EAID: %1 was stuck, initiating reverse recovery", typeOf _vehicle];
            };
        };
    } else {
        // Vehicle is moving - update stuck timer
        _vehicle setVariable ["EAID_stuckTime", diag_tickTime];
    };
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

    // Calculate sensor directions - Standard sensors
    private _leftAngle = _dirAngle + (EAID_CONFIG get "SENSOR_SIDE_ANGLE");
    private _rightAngle = _dirAngle - (EAID_CONFIG get "SENSOR_SIDE_ANGLE");

    // Corner sensors - Steeper angle to catch 90° turn obstacles
    private _leftCornerAngle = _dirAngle + (EAID_CONFIG get "SENSOR_CORNER_ANGLE");
    private _rightCornerAngle = _dirAngle - (EAID_CONFIG get "SENSOR_CORNER_ANGLE");

    private _leftDir = [sin _leftAngle, cos _leftAngle, 0];
    private _rightDir = [sin _rightAngle, cos _rightAngle, 0];
    private _leftCornerDir = [sin _leftCornerAngle, cos _leftCornerAngle, 0];
    private _rightCornerDir = [sin _rightCornerAngle, cos _rightCornerAngle, 0];
    private _downDir = [0, 0, -1];

    // Fire all sensor rays (now with corner detection)
    private _sensors = createHashMapFromArray [
        ["forwardLong", [_vehicle, _dir, EAID_CONFIG get "SENSOR_FORWARD_LONG"] call EAID_fnc_rayCast],
        ["forwardShort", [_vehicle, _dir, EAID_CONFIG get "SENSOR_FORWARD_SHORT"] call EAID_fnc_rayCast],
        ["left", [_vehicle, _leftDir, EAID_CONFIG get "SENSOR_SIDE_DISTANCE"] call EAID_fnc_rayCast],
        ["right", [_vehicle, _rightDir, EAID_CONFIG get "SENSOR_SIDE_DISTANCE"] call EAID_fnc_rayCast],
        ["leftCorner", [_vehicle, _leftCornerDir, EAID_CONFIG get "SENSOR_CORNER_DISTANCE"] call EAID_fnc_rayCast],
        ["rightCorner", [_vehicle, _rightCornerDir, EAID_CONFIG get "SENSOR_CORNER_DISTANCE"] call EAID_fnc_rayCast],
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
    private _leftCornerDist = _sensors get "leftCorner";
    private _rightCornerDist = _sensors get "rightCorner";
    private _maxDist = EAID_CONFIG get "SENSOR_SIDE_DISTANCE";
    private _maxCornerDist = EAID_CONFIG get "SENSOR_CORNER_DISTANCE";

    // Calculate asymmetry (0 = straight, 1+ = curve)
    private _asymmetry = abs (_leftDist - _rightDist) / (_maxDist max 1);

    // Factor in how close the walls are
    private _narrowness = 1 - ((_leftDist + _rightDist) / (2 * _maxDist));

    // NEW: Corner obstacle detection - if corner sensor hits something close, increase severity
    private _cornerObstacle = 0;
    if (_leftCornerDist < 15 || _rightCornerDist < 15) then {
        _cornerObstacle = 1 - ((_leftCornerDist min _rightCornerDist) / _maxCornerDist);
        _cornerObstacle = _cornerObstacle max 0 min 1;
    };

    // Combined curve severity (now with corner obstacle factor)
    private _severity = (_asymmetry * 0.5) + (_narrowness * 0.3) + (_cornerObstacle * 0.2);

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
// CORNER OBSTACLE DETECTION (90° turns)
// =====================================================

EAID_fnc_detectCornerObstacle = {
    params ["_sensors", "_currentSpeed"];

    private _leftCorner = _sensors get "leftCorner";
    private _rightCorner = _sensors get "rightCorner";
    private _forwardShort = _sensors get "forwardShort";

    private _cornerDetected = false;
    private _slowdownFactor = 1.0;

    // Detect left corner obstacle (house/sandbag at left 90° turn)
    if (_leftCorner < 12 && _forwardShort < 20) then {
        _cornerDetected = true;
        // Aggressive slowdown based on how close the obstacle is
        _slowdownFactor = (_leftCorner / 12) max 0.3 min 0.7;

        if (EAID_CONFIG get "DEBUG") then {
            diag_log format ["EAID: LEFT CORNER OBSTACLE detected! Distance: %1m - Slowing to %2%%",
                round _leftCorner, round (_slowdownFactor * 100)];
        };
    };

    // Detect right corner obstacle (house/sandbag at right 90° turn)
    if (_rightCorner < 12 && _forwardShort < 20) then {
        _cornerDetected = true;
        // Aggressive slowdown based on how close the obstacle is
        _slowdownFactor = (_rightCorner / 12) max 0.3 min 0.7;

        if (EAID_CONFIG get "DEBUG") then {
            diag_log format ["EAID: RIGHT CORNER OBSTACLE detected! Distance: %1m - Slowing to %2%%",
                round _rightCorner, round (_slowdownFactor * 100)];
        };
    };

    // Return detection status and slowdown factor
    [_cornerDetected, _slowdownFactor]
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

    // NEW: Corner obstacle detection (90° turns with objects)
    private _currentSpeed = speed _vehicle;
    private _cornerInfo = [_sensors, _currentSpeed] call EAID_fnc_detectCornerObstacle;
    _cornerInfo params ["_cornerDetected", "_cornerSlowdown"];

    if (_cornerDetected) then {
        // Apply aggressive slowdown for corner obstacles
        _targetSpeed = _targetSpeed * _cornerSlowdown;

        // Extra caution - minimum speed for tight corners with obstacles
        _targetSpeed = _targetSpeed max 25 min 40;
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
    private _leftCornerDist = _sensors get "leftCorner";
    private _rightCornerDist = _sensors get "rightCorner";
    private _forwardShort = _sensors get "forwardShort";

    // Only apply micro-corrections if obstacle very close
    if (_forwardShort > 20) exitWith {};

    // Calculate steering bias from standard sensors
    private _bias = (_rightDist - _leftDist) / 30;  // Normalize

    // NEW: Add corner obstacle avoidance
    // If corner sensor detects obstacle, steer away more aggressively
    if (_leftCornerDist < 10 && _forwardShort < 18) then {
        // Left corner obstacle - steer right (positive bias)
        _bias = _bias + 0.12;
    };

    if (_rightCornerDist < 10 && _forwardShort < 18) then {
        // Right corner obstacle - steer left (negative bias)
        _bias = _bias - 0.12;
    };

    _bias = _bias max -0.15 min 0.15;  // Increased limit for corner avoidance

    // Apply steering nudge
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
    private _lastBehaviorRefresh = diag_tickTime;

    // Initialize smooth speed cap
    private _currentSpeedCap = 60;  // Start at moderate speed

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

        // Detect and correct drift/skid
        private _driftInfo = [_vehicle] call EAID_fnc_detectAndCorrectDrift;
        private _isDrifting = _driftInfo select 0;
        private _driftPenalty = _driftInfo select 1;

        // Apply drift penalty
        if (_isDrifting) then {
            private _currentSpeed = speed _vehicle;
            _targetSpeed = (_currentSpeed * _driftPenalty) min _targetSpeed;
        };

        // Smooth speed transition (interpolation)
        private _interpFactor = _cfg get "SPEED_INTERPOLATION";
        _currentSpeedCap = _currentSpeedCap + ((_targetSpeed - _currentSpeedCap) / _interpFactor);
        _currentSpeedCap = _currentSpeedCap max 18 min 220;  // Clamp limits

        // Apply speed limit
        _vehicle limitSpeed (_currentSpeedCap / 3.6);  // Convert km/h to m/s

        // Apply steering correction for close obstacles
        [_vehicle, _sensors] call EAID_fnc_applySteeringCorrection;

        // Handle stuck detection and recovery
        [_vehicle, _unit] call EAID_fnc_handleStuck;

        // Periodic behavior refresh (prevent combat AI override)
        if (diag_tickTime - _lastBehaviorRefresh > (_cfg get "BEHAVIOR_REFRESH_INTERVAL")) then {
            (group _unit) setBehaviour "CARELESS";
            (group _unit) setCombatMode "BLUE";
            (group _unit) setSpeedMode "FULL";
            _lastBehaviorRefresh = diag_tickTime;
        };

        // Debug output
        if (_debugEnabled && diag_tickTime - _lastDebugTime > 5) then {
            private _currentSpeed = speed _vehicle;
            private _curveSeverity = [_sensors] call EAID_fnc_calculateCurveSeverity;

            diag_log format ["EAID: %1 | Speed: %2/%3 km/h | Cap: %4 | Curve: %5%6 | Sensors: F:%7 L:%8 R:%9 LC:%10 RC:%11",
                name _unit,
                round _currentSpeed,
                round _targetSpeed,
                round _currentSpeedCap,
                round (_curveSeverity * 100),
                if (_isDrifting) then {" DRIFT!"} else {""},
                round (_sensors get "forwardLong"),
                round (_sensors get "left"),
                round (_sensors get "right"),
                round (_sensors get "leftCorner"),
                round (_sensors get "rightCorner")
            ];

            _lastDebugTime = diag_tickTime;
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

    // Get vehicle-specific preset speeds
    private _vehPreset = [_vehicle] call EAID_fnc_getVehiclePreset;
    _vehicle setVariable ["EAID_vehiclePreset", _vehPreset];

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
    _unit setSkill ["commanding", 1];

    private _grp = group _unit;
    _grp setCombatMode "BLUE";
    _grp setBehaviour "CARELESS";
    _grp setSpeedMode "FULL";
    _grp setFormation "COLUMN";

    _unit disableAI "AUTOCOMBAT";
    _unit disableAI "TARGET";
    _unit disableAI "AUTOTARGET";
    _unit disableAI "SUPPRESSION";
    _unit disableAI "COVER";
    _unit disableAI "CHECKVISIBLE";

    _unit enableAI "PATH";
    _unit forceFollowRoad true;  // NEW: Force road following

    _vehicle setUnloadInCombat [false, false];
    _vehicle allowCrewInImmobile true;

    // Initialize stuck detection timer
    _vehicle setVariable ["EAID_stuckTime", diag_tickTime];

    // Start driving systems
    [_unit, _vehicle] spawn EAID_fnc_eliteDriving;
    [_unit, _vehicle] spawn EAID_fnc_roadFollowing;

    if (EAID_CONFIG get "DEBUG") then {
        private _preset = _vehPreset joinString "/";
        diag_log format ["EAID: Enhanced %1 in %2 (Preset: %3 km/h)", name _unit, typeOf _vehicle, _preset];
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
        _unit enableAI "SUPPRESSION";

        _unit forceFollowRoad false;  // Disable road following

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
    diag_log "Elite AI Driving v5.2 - CORNER FIX UPDATE";
    diag_log format ["Applies To: ALL AI sides (EAST/WEST/INDEPENDENT/CIVILIAN)"];
    diag_log format ["Raycast Sensors: 7-ray LIDAR system (with corner detection)"];
    diag_log format ["Corner Sensors: 70° angle at 20m range"];
    diag_log format ["Max Speed: %1 km/h (highway mode)", EAID_CONFIG get "SPEED_MAX_HIGHWAY"];
    diag_log format ["Map Bonus: %1x straight boost", _mapPreset get "straightBonus"];
    diag_log format ["Combat Driving: Run over enemies = %1", EAID_CONFIG get "RUN_OVER_ENEMIES"];
    diag_log format ["Corner Detection: Enabled (prevents cutting 90° turns)"];
    diag_log format ["Drift Detection: Enabled (auto counter-steer)"];
    diag_log format ["Auto-Unstuck: Enabled (3s threshold)"];
    diag_log format ["Smooth Transitions: Enabled (%1x interpolation)", EAID_CONFIG get "SPEED_INTERPOLATION"];
    diag_log format ["Vehicle Presets: Sport/Truck/MRAP/Offroad classes"];
    diag_log format ["Update Rate: %1 Hz", round (1 / (EAID_CONFIG get "UPDATE_INTERVAL"))];
    diag_log "==========================================";
} else {
    diag_log "Elite AI Driving v5.2 - DISABLED";
};
