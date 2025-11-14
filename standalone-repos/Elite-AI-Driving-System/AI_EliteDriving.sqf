/*
    =====================================================
    ELITE AI DRIVING SYSTEM v4.2 - PRODUCTION FIXED
    =====================================================
    Pure driving system - NO crew management
    =====================================================

    FIXES IN THIS VERSION:
    ✅ EXCLUDES RECRUIT AI - Won't interfere with player's recruits
    ✅ Fixed vehicle floating (removed position changes)
    ✅ Added building detection at intersections
    ✅ Fixed highway sway oscillation
    ✅ Improved drift detection
    ✅ Better steering stability
    ✅ No physics conflicts with other systems

    EXCLUSION LOGIC:
    - Checks for ExileRecruited variable
    - Checks for player's group membership
    - Only applies to hostile/neutral AI
*/

if (!isServer) exitWith {};

// =====================================================
// CONFIGURATION
// =====================================================

AIS_CONFIG = createHashMapFromArray [
    // === CORE SETTINGS ===
    ["ENABLED", true],
    ["DEBUG", true],
    ["UPDATE_INTERVAL", 0.15],

    // === DRIVING SYSTEM ===
    ["SPEED_MAX_HIGHWAY", 90],
    ["SPEED_MAX_ROAD", 75],
    ["SPEED_MAX_DIRT", 55],
    ["SPEED_MAX_OFFROAD", 35],
    ["SPEED_CITY", 45],
    ["SPEED_MIN_SHARP_CURVE", 25],
    ["SPEED_MIN_MEDIUM_CURVE", 40],
    ["SPEED_RAIN_PENALTY", 0.70],
    ["SPEED_DAMAGED_PENALTY", 0.55],

    // === SENSORS ===
    ["SENSOR_FORWARD_LONG", 100],
    ["SENSOR_FORWARD_SHORT", 30],
    ["SENSOR_SIDE_ANGLE", 45],
    ["SENSOR_SIDE_DISTANCE", 35],
    ["SENSOR_DOWN_DISTANCE", 20],
    ["SENSOR_VEHICLE_SCAN_DISTANCE", 80],
    ["SENSOR_VEHICLE_SCAN_ANGLE", 60],
    ["SENSOR_BUILDING_SCAN_DISTANCE", 50],  // NEW: Building detection

    // === SAFETY ===
    ["ANTI_FLIP_ENABLED", true],
    ["CLIFF_DETECTION_ENABLED", true],
    ["MAX_ROLL_ANGLE", 35],
    ["MAX_PITCH_ANGLE", 40],

    // === RECOVERY ===
    ["UNSTUCK_SPEED_THRESHOLD", 2],
    ["UNSTUCK_TIME_THRESHOLD", 4],
    ["UNSTUCK_MAX_ATTEMPTS", 5],
    ["UNSTUCK_REVERSE_FORCE", -3.0],
    ["FLIP_RECOVERY_ENABLED", true],

    // === PERFORMANCE ===
    ["MAX_ACTIVE_DRIVERS", 50],
    ["CLEANUP_INTERVAL", 30],
    ["CURVE_STRAIGHT", 0.08],
    ["CURVE_GENTLE", 0.18],
    ["CURVE_MEDIUM", 0.35],
    ["CURVE_SHARP", 0.6],
    ["DRIFT_ANGLE_THRESHOLD", 0.30],
    ["DRIFT_YAW_THRESHOLD", 0.30],
    ["DRIFT_SPEED_PENALTY", 0.70],
    ["DRIFT_CORRECTION_STRENGTH", 0.15],
    ["COUNTER_STEER_STRENGTH", 0.15],
    ["SPEED_INTERPOLATION", 15],
    ["STEERING_SMOOTHING", 0.90],
    ["STEERING_DEADZONE", 0.02],
    ["BEHAVIOR_REFRESH_INTERVAL", 10],
    ["WAYPOINT_CLEANUP_INTERVAL", 15],
    ["MAX_WAYPOINTS", 4],
    ["PENALTY_URBAN", 0.50],
    ["PENALTY_DIRT", 0.75],
    ["PENALTY_FOREST", 0.65],
    ["PENALTY_STEEP_SLOPE", 0.60]
];

// =====================================================
// GLOBAL STATE
// =====================================================

AIS_ActiveDrivers = createHashMap;
AIS_ProcessedUnits = [];
AIS_ModCompat = createHashMapFromArray [
    ["HAS_CBA", isClass (configFile >> "CfgPatches" >> "cba_main")]
];

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

AIS_fnc_validateUnit = {
    params ["_unit"];
    if (isNil "_unit") exitWith {false};
    if (isNull _unit) exitWith {false};
    if (!alive _unit) exitWith {false};
    if (isPlayer _unit) exitWith {false};
    true
};

AIS_fnc_validateVehicle = {
    params ["_vehicle"];
    if (isNil "_vehicle") exitWith {false};
    if (isNull _vehicle) exitWith {false};
    if (!alive _vehicle) exitWith {false};
    true
};

AIS_fnc_angleDiff = {
    params ["_angle1", "_angle2"];
    private _diff = _angle1 - _angle2;
    while {_diff > 180} do {_diff = _diff - 360};
    while {_diff < -180} do {_diff = _diff + 360};
    abs _diff
};

// =====================================================
// EXCLUSION LOGIC - PREVENT RECRUIT AI CONFLICTS
// =====================================================

AIS_fnc_isRecruitAI = {
    params ["_unit"];

    // Check if unit is marked as recruited
    if (_unit getVariable ["ExileRecruited", false]) exitWith {true};

    // Check if unit is in a player's group
    private _grp = group _unit;
    if (!isNull _grp) then {
        private _leader = leader _grp;
        if (!isNull _leader && isPlayer _leader) exitWith {true};
    };

    // Check if unit has OwnerUID (recruit system marker)
    if (!isNil {_unit getVariable "OwnerUID"}) exitWith {true};

    false
};

AIS_fnc_shouldApplyDriving = {
    params ["_unit", "_vehicle"];

    // Basic validation
    if (!([_unit] call AIS_fnc_validateUnit)) exitWith {false};
    if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {false};
    if (driver _vehicle != _unit) exitWith {false};
    if (!(_vehicle isKindOf "LandVehicle")) exitWith {false};

    // CRITICAL: Exclude recruit AI
    if ([_unit] call AIS_fnc_isRecruitAI) exitWith {
        if (AIS_CONFIG get "DEBUG") then {
            diag_log format ["[AIS] Skipping recruit AI: %1", name _unit];
        };
        false
    };

    // Exclude if already enhanced
    if ((netId _unit) in (keys AIS_ActiveDrivers)) exitWith {false};

    true
};

// =====================================================
// DRIVING SYSTEM - SENSORS WITH BUILDING DETECTION
// =====================================================

AIS_fnc_rayCastSafe = {
    params ["_vehicle", "_dirVector", "_distance"];

    private _result = _distance;

    try {
        if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {_distance};

        private _startPos = ASLToAGL getPosASLVisual _vehicle;
        _startPos set [2, (_startPos select 2) + 1.2];

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

        if !(_intersections isEqualTo []) then {
            private _hitPos = (_intersections select 0) select 0;
            _result = _startPos distance (ASLToAGL _hitPos);
        };
    } catch {
        _result = _distance;
    };

    _result
};

AIS_fnc_detectBuildingsAhead = {
    params ["_vehicle"];

    private _pos = getPosATL _vehicle;
    private _dir = getDir _vehicle;
    private _scanDistance = AIS_CONFIG get "SENSOR_BUILDING_SCAN_DISTANCE";

    // Check for buildings in front arc
    private _scanPos = _pos vectorAdd [sin _dir * (_scanDistance/2), cos _dir * (_scanDistance/2), 0];
    private _nearBuildings = nearestObjects [_scanPos, ["Building", "House"], _scanDistance];

    private _blockingBuilding = objNull;
    private _minDistance = _scanDistance;

    {
        if (alive _x) then {
            private _buildingPos = getPosATL _x;
            private _relDir = _pos getDir _buildingPos;
            private _angleDiff = [_dir, _relDir] call AIS_fnc_angleDiff;

            // Check if building is in front (45° arc for buildings)
            if (_angleDiff < 45) then {
                private _dist = _pos distance2D _buildingPos;
                if (_dist < _minDistance) then {
                    _minDistance = _dist;
                    _blockingBuilding = _x;
                };
            };
        };
    } forEach _nearBuildings;

    [_blockingBuilding, _minDistance]
};

AIS_fnc_detectVehiclesAhead = {
    params ["_vehicle"];

    private _pos = getPosATL _vehicle;
    private _dir = getDir _vehicle;
    private _speed = speed _vehicle;

    private _scanDistance = AIS_CONFIG get "SENSOR_VEHICLE_SCAN_DISTANCE";
    private _scanAngle = AIS_CONFIG get "SENSOR_VEHICLE_SCAN_ANGLE";

    private _nearVehicles = _pos nearEntities [["Car", "Tank", "Truck"], _scanDistance];
    private _blockingVehicle = objNull;
    private _minDistance = _scanDistance;

    {
        if (_x != _vehicle && alive _x) then {
            private _targetPos = getPosATL _x;
            private _relDir = _pos getDir _targetPos;
            private _angleDiff = [_dir, _relDir] call AIS_fnc_angleDiff;

            if (_angleDiff < _scanAngle) then {
                private _dist = _pos distance2D _targetPos;
                if (_dist < _minDistance) then {
                    _minDistance = _dist;
                    _blockingVehicle = _x;
                };
            };
        };
    } forEach _nearVehicles;

    [_blockingVehicle, _minDistance]
};

AIS_fnc_scanSensors = {
    params ["_vehicle"];

    private _pos = getPosATL _vehicle;
    private _dir = vectorDir _vehicle;
    private _dirAngle = getDir _vehicle;

    // Forward detection
    private _angles = [-45, -30, -15, 0, 15, 30, 45];
    private _forwardRays = [];

    {
        private _rayAngle = _dirAngle + _x;
        private _rayDir = [sin _rayAngle, cos _rayAngle, 0];
        private _dist = [_vehicle, _rayDir, AIS_CONFIG get "SENSOR_FORWARD_LONG"] call AIS_fnc_rayCastSafe;
        _forwardRays pushBack _dist;
    } forEach _angles;

    // Side detection
    private _leftAngle = _dirAngle + (AIS_CONFIG get "SENSOR_SIDE_ANGLE");
    private _rightAngle = _dirAngle - (AIS_CONFIG get "SENSOR_SIDE_ANGLE");
    private _leftDir = [sin _leftAngle, cos _leftAngle, 0];
    private _rightDir = [sin _rightAngle, cos _rightAngle, 0];

    private _downDir = [0, 0, -1];
    private _downDist = [_vehicle, _downDir, AIS_CONFIG get "SENSOR_DOWN_DISTANCE"] call AIS_fnc_rayCastSafe;

    private _downForwardDir = vectorNormalized (_dir vectorAdd [0, 0, -0.5]);
    private _downForwardDist = [_vehicle, _downForwardDir, 30] call AIS_fnc_rayCastSafe;

    // Vehicle detection
    private _vehicleData = [_vehicle] call AIS_fnc_detectVehiclesAhead;

    // Building detection
    private _buildingData = [_vehicle] call AIS_fnc_detectBuildingsAhead;

    createHashMapFromArray [
        ["forwardRays", _forwardRays],
        ["forwardMin", selectMin _forwardRays],
        ["forwardLong", _forwardRays select 3],
        ["forwardShort", [_vehicle, _dir, AIS_CONFIG get "SENSOR_FORWARD_SHORT"] call AIS_fnc_rayCastSafe],
        ["left", [_vehicle, _leftDir, AIS_CONFIG get "SENSOR_SIDE_DISTANCE"] call AIS_fnc_rayCastSafe],
        ["right", [_vehicle, _rightDir, AIS_CONFIG get "SENSOR_SIDE_DISTANCE"] call AIS_fnc_rayCastSafe],
        ["down", _downDist],
        ["downForward", _downForwardDist],
        ["vehicleAhead", _vehicleData select 0],
        ["vehicleDistance", _vehicleData select 1],
        ["buildingAhead", _buildingData select 0],
        ["buildingDistance", _buildingData select 1]
    ]
};

// =====================================================
// DRIVING SYSTEM - SAFETY (FIXED FLIP RECOVERY)
// =====================================================

AIS_fnc_detectFlip = {
    params ["_vehicle"];

    if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {[false, 0, 0]};

    private _vectorUp = vectorUp _vehicle;
    private _pitch = asin (_vectorUp select 1);
    private _roll = asin (_vectorUp select 0);

    private _pitchDeg = _pitch * 57.2958;
    private _rollDeg = _roll * 57.2958;

    private _maxRoll = AIS_CONFIG get "MAX_ROLL_ANGLE";
    private _maxPitch = AIS_CONFIG get "MAX_PITCH_ANGLE";

    private _isFlipped = (abs _rollDeg > _maxRoll) || (abs _pitchDeg > _maxPitch);

    [_isFlipped, _rollDeg, _pitchDeg]
};

AIS_fnc_recoverFlip = {
    params ["_vehicle"];

    if (!(AIS_CONFIG get "FLIP_RECOVERY_ENABLED")) exitWith {};

    try {
        private _dir = getDir _vehicle;

        // CRITICAL FIX: Only fix orientation, NO position changes
        _vehicle setVectorUp [0, 0, 1];
        _vehicle setDir _dir;
        _vehicle setVelocity [0, 0, 0];

        // Let physics settle naturally (no setPos!)
        sleep 0.1;
    } catch {};
};

AIS_fnc_detectCliff = {
    params ["_sensors"];

    private _downDist = _sensors get "down";
    private _downForwardDist = _sensors get "downForward";
    private _maxSafeDown = AIS_CONFIG get "SENSOR_DOWN_DISTANCE";

    (_downForwardDist > (_maxSafeDown * 0.8)) && (_downDist < _maxSafeDown * 0.5)
};

// =====================================================
// DRIVING SYSTEM - DRIFT DETECTION
// =====================================================

AIS_fnc_detectDrift = {
    params ["_vehicle"];

    if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {[false, 1.0, 0]};

    private _speed = speed _vehicle;
    if (_speed < 25) exitWith {[false, 1.0, 0]};

    try {
        private _dir = vectorDir _vehicle;
        private _vel = velocity _vehicle;

        if (_vel isEqualTo [0,0,0]) exitWith {[false, 1.0, 0]};

        private _velNorm = vectorNormalized _vel;
        private _dotProduct = (_velNorm vectorDotProduct _dir) max -1 min 1;
        private _driftAngle = acos _dotProduct;

        private _angVel = angularVelocity _vehicle;
        private _yaw = _angVel select 2;

        private _threshold = AIS_CONFIG get "DRIFT_ANGLE_THRESHOLD";
        private _yawThreshold = AIS_CONFIG get "DRIFT_YAW_THRESHOLD";

        private _isDrifting = (_driftAngle > _threshold) || (abs _yaw > _yawThreshold);

        if (_isDrifting) then {
            private _correctionStrength = AIS_CONFIG get "DRIFT_CORRECTION_STRENGTH";

            private _targetVel = _dir vectorMultiply (vectorMagnitude _vel);
            private _currentVel = velocity _vehicle;
            private _correctedVel = _currentVel vectorAdd ((_targetVel vectorDiff _currentVel) vectorMultiply _correctionStrength);

            _vehicle setVelocity _correctedVel;

            [true, AIS_CONFIG get "DRIFT_SPEED_PENALTY", _driftAngle]
        } else {
            [false, 1.0, 0]
        };
    } catch {
        [false, 1.0, 0]
    };
};

// =====================================================
// DRIVING SYSTEM - UNSTUCK
// =====================================================

AIS_fnc_handleStuck = {
    params ["_vehicle", "_unit"];

    private _speed = speed _vehicle;
    private _threshold = AIS_CONFIG get "UNSTUCK_SPEED_THRESHOLD";

    if (_speed < _threshold) then {
        private _stuckData = _vehicle getVariable ["AIS_stuckData", [diag_tickTime, 0]];
        private _stuckTime = _stuckData select 0;
        private _attempts = _stuckData select 1;
        private _timeDiff = diag_tickTime - _stuckTime;

        if (_timeDiff > (AIS_CONFIG get "UNSTUCK_TIME_THRESHOLD")) then {
            if (_attempts < (AIS_CONFIG get "UNSTUCK_MAX_ATTEMPTS")) then {
                private _reverseForce = AIS_CONFIG get "UNSTUCK_REVERSE_FORCE";

                switch (_attempts) do {
                    case 0: {
                        _vehicle setVelocityModelSpace [0, _reverseForce, 0];
                    };
                    case 1: {
                        private _currentDir = getDir _vehicle;
                        _vehicle setDir (_currentDir + 15);
                        _vehicle setVelocityModelSpace [0, _reverseForce * 1.5, 0];
                    };
                    case 2: {
                        private _currentDir = getDir _vehicle;
                        _vehicle setDir (_currentDir - 15);
                        _vehicle setVelocityModelSpace [0, _reverseForce * 2.0, 0];
                    };
                    case 3: {
                        _vehicle setVelocityModelSpace [0, 5, 0];
                    };
                    case 4: {
                        // Last resort: gentle lift (minimal to avoid floating)
                        private _pos = getPosATL _vehicle;
                        _vehicle setPos [_pos select 0, _pos select 1, (_pos select 2) + 0.1];
                        _vehicle setVelocity [0, 0, 0];
                    };
                };

                _vehicle setVariable ["AIS_stuckData", [diag_tickTime + 3, _attempts + 1]];
            };
        };
    } else {
        _vehicle setVariable ["AIS_stuckData", [diag_tickTime, 0]];
    };
};

// =====================================================
// DRIVING SYSTEM - SPEED CALCULATION
// =====================================================

AIS_fnc_calculateCurveSeverity = {
    params ["_sensors"];

    private _forwardRays = _sensors get "forwardRays";
    private _leftDist = _sensors get "left";
    private _rightDist = _sensors get "right";
    private _maxDist = AIS_CONFIG get "SENSOR_SIDE_DISTANCE";

    private _leftRays = [_forwardRays select 0, _forwardRays select 1];
    private _rightRays = [_forwardRays select 5, _forwardRays select 6];
    private _centerRay = _forwardRays select 3;

    private _leftAvg = ((_leftRays select 0) + (_leftRays select 1)) / 2;
    private _rightAvg = ((_rightRays select 0) + (_rightRays select 1)) / 2;

    private _sideAsymmetry = abs (_leftDist - _rightDist) / (_maxDist max 1);
    private _rayAsymmetry = abs (_leftAvg - _rightAvg) / (_centerRay max 1);
    private _narrowness = 1 - ((_leftDist + _rightDist) / (2 * _maxDist));

    private _severity = (_sideAsymmetry * 0.4) + (_rayAsymmetry * 0.3) + (_narrowness * 0.3);

    _severity min 1.5
};

AIS_fnc_getCurveSpeedLimit = {
    params ["_curveSeverity", "_baseSpeed"];

    private _cfg = AIS_CONFIG;

    if (_curveSeverity < (_cfg get "CURVE_STRAIGHT")) exitWith {_baseSpeed};
    if (_curveSeverity < (_cfg get "CURVE_GENTLE")) exitWith {_baseSpeed * 0.85};
    if (_curveSeverity < (_cfg get "CURVE_MEDIUM")) exitWith {_cfg get "SPEED_MIN_MEDIUM_CURVE"};
    if (_curveSeverity < (_cfg get "CURVE_SHARP")) exitWith {(_cfg get "SPEED_MIN_SHARP_CURVE") * 1.3};

    _cfg get "SPEED_MIN_SHARP_CURVE"
};

AIS_fnc_analyzeTerrain = {
    params ["_vehicle"];

    if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {createHashMap};

    private _pos = getPosATL _vehicle;
    private _isRoad = isOnRoad _pos;

    private _nearBuildings = count (nearestObjects [_pos, ["Building", "House"], 40]);
    private _isUrban = _nearBuildings > 3;

    private _surfaceNormal = surfaceNormal _pos;
    private _slope = 1 - (_surfaceNormal select 2);
    private _isSteep = _slope > 0.3;

    private _nearTrees = count (nearestTerrainObjects [_pos, ["TREE", "SMALL TREE"], 25]);
    private _isDense = _nearTrees > 8;

    createHashMapFromArray [
        ["isRoad", _isRoad],
        ["isUrban", _isUrban],
        ["isSteep", _isSteep],
        ["isDense", _isDense],
        ["slope", _slope]
    ]
};

AIS_fnc_getTerrainPenalty = {
    params ["_terrain"];

    private _penalty = 1.0;
    private _cfg = AIS_CONFIG;

    if (_terrain get "isUrban") then {
        _penalty = _penalty * (_cfg get "PENALTY_URBAN");
    };

    if (!(_terrain get "isRoad")) then {
        _penalty = _penalty * (_cfg get "PENALTY_DIRT");
    };

    if (_terrain get "isDense") then {
        _penalty = _penalty * (_cfg get "PENALTY_FOREST");
    };

    if (_terrain get "isSteep") then {
        _penalty = _penalty * (_cfg get "PENALTY_STEEP_SLOPE");
    };

    _penalty
};

AIS_fnc_calculateOptimalSpeed = {
    params ["_vehicle", "_unit", "_sensors", "_terrain"];

    private _cfg = AIS_CONFIG;

    // City speed limit
    if (_terrain get "isUrban") exitWith {
        private _targetSpeed = _cfg get "SPEED_CITY";

        if (rain > 0.3) then {
            _targetSpeed = _targetSpeed * (_cfg get "SPEED_RAIN_PENALTY");
        };

        _targetSpeed max 20
    };

    private _baseSpeed = if (_terrain get "isRoad") then {
        _cfg get "SPEED_MAX_ROAD"
    } else {
        _cfg get "SPEED_MAX_DIRT"
    };

    private _curveSeverity = [_sensors] call AIS_fnc_calculateCurveSeverity;
    private _curveSpeed = [_curveSeverity, _baseSpeed] call AIS_fnc_getCurveSpeedLimit;

    private _terrainPenalty = [_terrain] call AIS_fnc_getTerrainPenalty;
    private _targetSpeed = _curveSpeed * _terrainPenalty;

    if (rain > 0.3) then {
        _targetSpeed = _targetSpeed * (_cfg get "SPEED_RAIN_PENALTY");
    };

    private _damage = damage _vehicle;
    if (_damage > 0.3) then {
        _targetSpeed = _targetSpeed * (_cfg get "SPEED_DAMAGED_PENALTY");
    };

    if ([_sensors] call AIS_fnc_detectCliff) then {
        _targetSpeed = 15;
    };

    // Building ahead detection - SLOW DOWN!
    private _buildingAhead = _sensors get "buildingAhead";
    private _buildingDist = _sensors get "buildingDistance";

    if (!isNull _buildingAhead && _buildingDist < 40) then {
        _targetSpeed = (_buildingDist / 40) * 35;  // Slow to 35 km/h max near buildings
    };

    // Vehicle ahead detection
    private _vehicleAhead = _sensors get "vehicleAhead";
    private _vehicleDist = _sensors get "vehicleDistance";

    if (!isNull _vehicleAhead && _vehicleDist < 50) then {
        private _aheadSpeed = speed _vehicleAhead;
        if (_aheadSpeed < 5) then {
            _targetSpeed = (_vehicleDist / 50) * 30;
        } else {
            _targetSpeed = (_aheadSpeed * 0.85) min _targetSpeed;
        };
    };

    private _forwardMin = _sensors get "forwardMin";
    if (_forwardMin < 40) then {
        _targetSpeed = _targetSpeed * (_forwardMin / 40);
    };

    // Highway speed only on STRAIGHT roads
    if (_curveSeverity < (_cfg get "CURVE_STRAIGHT") &&
        _terrain get "isRoad" &&
        !(_terrain get "isUrban") &&
        _forwardMin > 80) then {
        _targetSpeed = _cfg get "SPEED_MAX_HIGHWAY";
    };

    _targetSpeed max 15
};

// =====================================================
// DRIVING SYSTEM - STEERING
// =====================================================

AIS_fnc_applySteeringCorrection = {
    params ["_vehicle", "_sensors"];

    if (!([_vehicle] call AIS_fnc_validateVehicle)) exitWith {};

    private _leftDist = _sensors get "left";
    private _rightDist = _sensors get "right";
    private _forwardShort = _sensors get "forwardShort";

    if (_forwardShort > 25) exitWith {};

    try {
        private _bias = (_rightDist - _leftDist) / 35;

        private _deadzone = AIS_CONFIG get "STEERING_DEADZONE";
        if (abs _bias < _deadzone) exitWith {};

        _bias = _bias max -0.04 min 0.04;

        private _prevBias = _vehicle getVariable ["AIS_prevSteerBias", 0];
        private _smoothing = AIS_CONFIG get "STEERING_SMOOTHING";
        private _smoothedBias = (_prevBias * _smoothing) + (_bias * (1 - _smoothing));

        _vehicle setVariable ["AIS_prevSteerBias", _smoothedBias];

        private _currentDir = vectorDir _vehicle;
        private _currentUp = vectorUp _vehicle;

        private _perpDir = vectorNormalized (_currentDir vectorCrossProduct [0,0,1]);
        private _newDir = vectorNormalized (_currentDir vectorAdd (_perpDir vectorMultiply _smoothedBias));

        _vehicle setVectorDirAndUp [_newDir, _currentUp];
    } catch {};
};

// =====================================================
// DRIVING SYSTEM - MAIN LOOP
// =====================================================

AIS_fnc_eliteDriving = {
    params ["_unit", "_vehicle"];

    private _cfg = AIS_CONFIG;
    private _updateInterval = _cfg get "UPDATE_INTERVAL";
    private _currentSpeedCap = 40;
    private _lastBehaviorRefresh = diag_tickTime;

    while {
        ([_unit] call AIS_fnc_validateUnit) &&
        ([_vehicle] call AIS_fnc_validateVehicle) &&
        driver _vehicle == _unit &&
        ((netId _unit) in (keys AIS_ActiveDrivers)) &&
        !([_unit] call AIS_fnc_isRecruitAI)  // CRITICAL: Exit if becomes recruit
    } do {

        try {
            private _sensors = [_vehicle] call AIS_fnc_scanSensors;
            private _terrain = [_vehicle] call AIS_fnc_analyzeTerrain;
            private _targetSpeed = [_vehicle, _unit, _sensors, _terrain] call AIS_fnc_calculateOptimalSpeed;

            if (AIS_CONFIG get "ANTI_FLIP_ENABLED") then {
                private _flipData = [_vehicle] call AIS_fnc_detectFlip;
                if (_flipData select 0) then {
                    [_vehicle] call AIS_fnc_recoverFlip;
                };
            };

            private _driftInfo = [_vehicle] call AIS_fnc_detectDrift;
            if (_driftInfo select 0) then {
                _targetSpeed = _targetSpeed * (_driftInfo select 1);
            };

            private _interpFactor = _cfg get "SPEED_INTERPOLATION";
            _currentSpeedCap = _currentSpeedCap + ((_targetSpeed - _currentSpeedCap) / _interpFactor);
            _currentSpeedCap = _currentSpeedCap max 15 min 90;

            _vehicle limitSpeed (_currentSpeedCap / 3.6);

            [_vehicle, _sensors] call AIS_fnc_applySteeringCorrection;
            [_vehicle, _unit] call AIS_fnc_handleStuck;

            if (diag_tickTime - _lastBehaviorRefresh > (_cfg get "BEHAVIOR_REFRESH_INTERVAL")) then {
                (group _unit) setBehaviour "CARELESS";
                (group _unit) setCombatMode "BLUE";
                (group _unit) setSpeedMode "FULL";
                _lastBehaviorRefresh = diag_tickTime;
            };

        } catch {};

        sleep _updateInterval;
    };

    [_unit] call AIS_fnc_restoreDriver;
};

// =====================================================
// DRIVING SYSTEM - ROAD FOLLOWING
// =====================================================

AIS_fnc_roadFollowing = {
    params ["_unit", "_vehicle"];

    private _group = group _unit;
    private _lastCleanup = time;

    while {
        ([_unit] call AIS_fnc_validateUnit) &&
        ([_vehicle] call AIS_fnc_validateVehicle) &&
        driver _vehicle == _unit &&
        ((netId _unit) in (keys AIS_ActiveDrivers)) &&
        !([_unit] call AIS_fnc_isRecruitAI)  // CRITICAL: Exit if becomes recruit
    } do {

        try {
            if (time - _lastCleanup > (AIS_CONFIG get "WAYPOINT_CLEANUP_INTERVAL")) then {
                private _wpCount = count waypoints _group;
                if (_wpCount > (AIS_CONFIG get "MAX_WAYPOINTS")) then {
                    for "_i" from 0 to (_wpCount - (AIS_CONFIG get "MAX_WAYPOINTS") - 1) do {
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
                    private _vehicleDir = getDir _vehicle;
                    private _bestRoad = objNull;
                    private _bestScore = -1;

                    {
                        private _roadPos = getPosATL _x;
                        private _roadDir = _pos getDir _roadPos;
                        private _angleDiff = [_vehicleDir, _roadDir] call AIS_fnc_angleDiff;
                        private _score = 1 - (_angleDiff / 180);

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

        } catch {};

        sleep 2;
    };
};

// =====================================================
// DRIVING SYSTEM - APPLY/RESTORE
// =====================================================

AIS_fnc_applyToDriver = {
    params ["_unit", "_vehicle"];

    // Use comprehensive validation
    if (!([_unit, _vehicle] call AIS_fnc_shouldApplyDriving)) exitWith {};

    if (count (keys AIS_ActiveDrivers) >= (AIS_CONFIG get "MAX_ACTIVE_DRIVERS")) exitWith {};

    private _netId = netId _unit;

    private _original = createHashMapFromArray [
        ["courage", _unit skill "courage"],
        ["combatMode", combatMode (group _unit)],
        ["behaviour", behaviour _unit],
        ["speedMode", speedMode (group _unit)]
    ];

    AIS_ActiveDrivers set [_netId, _original];

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

    _unit forceFollowRoad true;

    _vehicle setUnloadInCombat [false, false];
    _vehicle allowCrewInImmobile true;
    _vehicle setVariable ["AIS_stuckData", [diag_tickTime, 0]];
    _vehicle setVariable ["AIS_prevSteerBias", 0];

    [_unit, _vehicle] spawn AIS_fnc_eliteDriving;
    [_unit, _vehicle] spawn AIS_fnc_roadFollowing;

    if (AIS_CONFIG get "DEBUG") then {
        diag_log format ["[AIS] Applied Elite Driving to %1 in %2", name _unit, typeOf _vehicle];
    };
};

AIS_fnc_restoreDriver = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (!((netId _unit) in (keys AIS_ActiveDrivers))) exitWith {};

    private _netId = netId _unit;
    private _original = AIS_ActiveDrivers get _netId;

    if (!isNil "_original") then {
        try {
            _unit setSkill ["courage", _original get "courage"];
            (group _unit) setCombatMode (_original get "combatMode");
            (group _unit) setBehaviour (_original get "behaviour");
            (group _unit) setSpeedMode (_original get "speedMode");

            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "TARGET";
            _unit enableAI "AUTOTARGET";
            _unit enableAI "SUPPRESSION";

            _unit forceFollowRoad false;

            private _vehicle = vehicle _unit;
            if (([_vehicle] call AIS_fnc_validateVehicle) && _vehicle != _unit) then {
                _vehicle limitSpeed -1;
                _vehicle setVariable ["AIS_prevSteerBias", nil];
            };
        } catch {};
    };

    AIS_ActiveDrivers deleteAt _netId;

    if (AIS_CONFIG get "DEBUG") then {
        diag_log format ["[AIS] Restored AI: %1", name _unit];
    };
};

// =====================================================
// EVENT HANDLERS
// =====================================================

AIS_fnc_addEventHandlers = {
    // Initialize existing AI drivers
    {
        if (!isPlayer _x && alive _x) then {
            private _veh = vehicle _x;
            if (_veh != _x && driver _veh == _x && _veh isKindOf "LandVehicle") then {
                if ([_x, _veh] call AIS_fnc_shouldApplyDriving) then {
                    [_x, _veh] call AIS_fnc_applyToDriver;
                };
            };
        };
    } forEach allUnits;

    if (AIS_ModCompat get "HAS_CBA") then {
        ["CAManBase", "init", {
            params ["_unit"];
            if (!isPlayer _unit) then {
                _unit addEventHandler ["GetInMan", {
                    params ["_unit", "_role", "_vehicle"];
                    if (_role == "driver" && _vehicle isKindOf "LandVehicle") then {
                        [_unit, _vehicle] spawn {
                            params ["_unit", "_vehicle"];
                            sleep 0.5;
                            if ([_unit, _vehicle] call AIS_fnc_shouldApplyDriving) then {
                                [_unit, _vehicle] call AIS_fnc_applyToDriver;
                            };
                        };
                    };
                }];

                _unit addEventHandler ["GetOutMan", {
                    params ["_unit"];
                    [_unit] call AIS_fnc_restoreDriver;
                }];

                _unit addEventHandler ["Killed", {
                    params ["_unit"];
                    [_unit] call AIS_fnc_restoreDriver;
                }];
            };
        }] call CBA_fnc_addClassEventHandler;
    } else {
        [] spawn {
            while {AIS_CONFIG get "ENABLED"} do {
                {
                    if (!isPlayer _x && alive _x && !(_x in AIS_ProcessedUnits)) then {
                        AIS_ProcessedUnits pushBack _x;

                        _x addEventHandler ["GetInMan", {
                            params ["_unit", "_role", "_vehicle"];
                            if (_role == "driver" && _vehicle isKindOf "LandVehicle") then {
                                [_unit, _vehicle] spawn {
                                    params ["_unit", "_vehicle"];
                                    sleep 0.5;
                                    if ([_unit, _vehicle] call AIS_fnc_shouldApplyDriving) then {
                                        [_unit, _vehicle] call AIS_fnc_applyToDriver;
                                    };
                                };
                            };
                        }];

                        _x addEventHandler ["GetOutMan", {
                            params ["_unit"];
                            [_unit] call AIS_fnc_restoreDriver;
                        }];

                        _x addEventHandler ["Killed", {
                            params ["_unit"];
                            [_unit] call AIS_fnc_restoreDriver;
                        }];
                    };

                    private _veh = vehicle _x;
                    if (!isPlayer _x && _veh != _x && driver _veh == _x && !((netId _x) in (keys AIS_ActiveDrivers))) then {
                        if ([_x, _veh] call AIS_fnc_shouldApplyDriving) then {
                            [_x, _veh] call AIS_fnc_applyToDriver;
                        };
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
    while {AIS_CONFIG get "ENABLED"} do {
        sleep (AIS_CONFIG get "CLEANUP_INTERVAL");

        {
            private _netId = _x;
            private _unit = objectFromNetId _netId;

            // Remove if unit is gone, dead, not driving, or became recruit AI
            if (isNull _unit || !alive _unit || vehicle _unit == _unit || [_unit] call AIS_fnc_isRecruitAI) then {
                if (!isNull _unit) then {
                    [_unit] call AIS_fnc_restoreDriver;
                } else {
                    AIS_ActiveDrivers deleteAt _netId;
                };
            };
        } forEach (keys AIS_ActiveDrivers);

        AIS_ProcessedUnits = AIS_ProcessedUnits select {!isNull _x && alive _x};

        if (AIS_CONFIG get "DEBUG") then {
            diag_log format ["[AIS] Active drivers: %1", count (keys AIS_ActiveDrivers)];
        };
    };
};

// =====================================================
// INITIALIZATION
// =====================================================

if (AIS_CONFIG get "ENABLED") then {
    call AIS_fnc_addEventHandlers;

    diag_log "==========================================";
    diag_log "Elite AI Driving System v4.2 - PRODUCTION FIXED";
    diag_log "==========================================";
    diag_log "FIXES APPLIED:";
    diag_log "✅ EXCLUDES RECRUIT AI (ExileRecruited check)";
    diag_log "✅ Building detection at intersections";
    diag_log "✅ Fixed vehicle floating (no setPos in flip recovery)";
    diag_log "✅ Improved highway stability";
    diag_log "✅ Better drift detection & correction";
    diag_log "✅ Smoother steering with deadzone";
    diag_log "✅ No conflicts with recruit AI system";
    diag_log "==========================================";
    diag_log format ["Max Highway Speed: %1 km/h", AIS_CONFIG get "SPEED_MAX_HIGHWAY"];
    diag_log format ["Max Road Speed: %1 km/h", AIS_CONFIG get "SPEED_MAX_ROAD"];
    diag_log format ["City Speed Limit: %1 km/h", AIS_CONFIG get "SPEED_CITY"];
    diag_log format ["Max Active Drivers: %1", AIS_CONFIG get "MAX_ACTIVE_DRIVERS"];
    diag_log format ["Recruit AI Exclusion: ENABLED"];
    diag_log "==========================================";
} else {
    diag_log "Elite AI Driving System v4.2 - DISABLED";
};
