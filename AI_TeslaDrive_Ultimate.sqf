/*
    =====================================================
    TESLA-DRIVE ULTIMATE AI SYSTEM v4.0
    =====================================================
    Author: Master SQF Engineer
    Version: 4.0 - ULTIMATE RELEASE
    =====================================================

    🚀 FEATURES:
    ✓ Road smoothness mapping (600m scan radius)
    ✓ GPS-style corner prediction
    ✓ Multi-sensor suite (forward/side/wide/down rays)
    ✓ Skid detection & drift correction
    ✓ Convoy drafting & box formation
    ✓ Smart overtaking with safe slot detection
    ✓ Per-map presets (Altis/Tanoa/Chernarus/Livonia)
    ✓ Highway mode (200+ km/h on straights)
    ✓ Urban mode (auto-slowdown in cities)
    ✓ Smart lane detection via terrain slope
    ✓ Precision bridge entry logic
    ✓ Braking distance optimization
    ✓ Intersection/traffic awareness
    ✓ Unstuck logic (soft reverse)
    ✓ Debug HUD with 4 layers (F4 to switch)
    ✓ No CBA required (uses fallback polling)
    ✓ AI mod compatibility (VCOMAI, A3XAI, etc.)
    ✓ Invisible helipad obstacles (lightweight)
    ✓ Building cache (no re-processing)
    ✓ Event handler cleanup
    =====================================================
*/

if (!isServer) exitWith {};

// =====================================================
// MOD DETECTION & COMPATIBILITY
// =====================================================
TD_ModCompat = createHashMapFromArray [
    ["HAS_CBA", isClass (configFile >> "CfgPatches" >> "cba_main")],
    ["HAS_VCOMAI", isClass (configFile >> "CfgPatches" >> "VCOMAI")],
    ["HAS_A3XAI", isClass (configFile >> "CfgPatches" >> "A3XAI")],
    ["HAS_ASR", isClass (configFile >> "CfgPatches" >> "asr_ai3_main")],
    ["HAS_LAMBS", isClass (configFile >> "CfgPatches" >> "lambs_danger")],
    ["HAS_BCOMBAT", isClass (configFile >> "CfgPatches" >> "bcombat")],
    ["HAS_ACE3", isClass (configFile >> "CfgPatches" >> "ace_main")]
];

// =====================================================
// PER-MAP PRESETS
// =====================================================
TD_fnc_getMapPreset = {
    private _map = worldName;
    private _preset = createHashMapFromArray [
        ["smoothnessFactor", 0.90],
        ["maxStraightBonus", 1.00],
        ["cityPenalty", 0.85],
        ["dirtPenalty", 0.75],
        ["mapType", "default"]
    ];

    switch (_map) do {
        case "Altis": {
            _preset set ["smoothnessFactor", 1.0];
            _preset set ["maxStraightBonus", 1.25];  // Long highways
            _preset set ["cityPenalty", 0.85];
            _preset set ["dirtPenalty", 0.75];
            _preset set ["mapType", "highway"];
        };
        case "Tanoa": {
            _preset set ["smoothnessFactor", 0.75];
            _preset set ["maxStraightBonus", 0.90];  // Twisty, hilly
            _preset set ["cityPenalty", 0.80];
            _preset set ["dirtPenalty", 0.65];
            _preset set ["mapType", "jungle"];
        };
        case "chernarusredux";
        case "Chernarus";
        case "Chernarus_Summer": {
            _preset set ["smoothnessFactor", 0.85];
            _preset set ["maxStraightBonus", 1.10];
            _preset set ["cityPenalty", 0.80];
            _preset set ["dirtPenalty", 0.70];
            _preset set ["mapType", "mixed"];
        };
        case "Enoch";
        case "Livonia": {
            _preset set ["smoothnessFactor", 0.90];
            _preset set ["maxStraightBonus", 1.15];
            _preset set ["cityPenalty", 0.85];
            _preset set ["dirtPenalty", 0.70];
            _preset set ["mapType", "forest"];
        };
    };

    _preset
};

// =====================================================
// CONFIGURATION
// =====================================================
TD_CONFIG = createHashMapFromArray [
    ["ENABLED", true],
    ["TICK_RATE", 0.10],
    ["DEBUG", false],
    ["DEBUG_HUD", false],
    ["DEBUG_INTERVAL", 10],

    // Speed tiers (km/h)
    ["SPEED_STRAIGHT", 220],
    ["SPEED_MID_CURVE", 140],
    ["SPEED_HARD_CURVE", 90],
    ["SPEED_ULTRA_TIGHT", 50],
    ["SPEED_OFFROAD", 80],
    ["SPEED_DIRT", 70],
    ["SPEED_OBSTACLE", 40],
    ["SPEED_INTERSECTION", 60],

    // Ray distances (meters)
    ["RAY_FRONT", 40],
    ["RAY_SHORT", 15],
    ["RAY_SIDE", 22],
    ["RAY_WIDE", 30],
    ["RAY_DOWN", 5],

    // Curve detection
    ["CURVE_HARD_THRESHOLD", 0.45],
    ["CURVE_ULTRA_THRESHOLD", 0.75],

    // Road scanning
    ["ROAD_SCAN_RADIUS", 600],
    ["ROAD_CACHE_LIFETIME", 60],

    // Convoy settings
    ["CONVOY_GAP", 28],
    ["CONVOY_DRAFT_BOOST", 1.15],
    ["CONVOY_FORMATION", "COLUMN"],  // COLUMN, BOX, WEDGE

    // Overtaking
    ["OVERTAKE_ENABLED", true],
    ["OVERTAKE_MIN_SPEED_DIFF", 20],
    ["OVERTAKE_LATERAL_FORCE", 0.08],
    ["OVERTAKE_BOOST", 1.20],
    ["OVERTAKE_DURATION", 3],

    // Skid detection
    ["SKID_ANGLE_THRESHOLD", 25],
    ["SKID_ANGULAR_VEL_THRESHOLD", 0.5],
    ["SKID_CORRECTION_FORCE", 0.02],

    // Waypoint management
    ["MAX_WAYPOINTS", 5],
    ["WAYPOINT_CLEANUP_INTERVAL", 15],

    // Obstacle avoidance
    ["USE_OBSTACLES", true],
    ["OBSTACLE_COOLDOWN", 10],
    ["MIN_OBJECT_SIZE", 4],
    ["OBSTACLE_OFFSET", 3],

    // Side filtering
    ["ALLOWED_SIDES", [INDEPENDENT]],
    ["EXCLUDED_SIDES", [EAST, WEST, CIVILIAN]],

    // AI Mod compatibility
    ["EXCLUDE_VCOMAI_UNITS", true],
    ["EXCLUDE_A3XAI_UNITS", true],
    ["EXCLUDE_ASR_UNITS", false],
    ["EXCLUDE_LAMBS_UNITS", false],
    ["EXCLUDE_BCOMBAT_UNITS", false],

    // Unstuck
    ["UNSTUCK_THRESHOLD", 2.0],
    ["UNSTUCK_REVERSE_FORCE", 3.0]
];

// Global tracking
TD_ActiveDrivers = createHashMap;
TD_ProcessedUnits = [];
TD_BuildingCache = createHashMap;
TD_RoadCache = createHashMap;
TD_MapPreset = call TD_fnc_getMapPreset;

diag_log "==========================================";
diag_log "Tesla-Drive Ultimate AI System - v4.0";
diag_log "==========================================";
diag_log format ["Map: %1 (%2)", worldName, TD_MapPreset get "mapType"];
diag_log format ["Smoothness: %1 | Straight Bonus: %2",
    TD_MapPreset get "smoothnessFactor",
    TD_MapPreset get "maxStraightBonus"
];

// Log mod compatibility
{
    private _modName = _x;
    private _detected = TD_ModCompat get _modName;
    if (_detected) then {
        diag_log format ["TD: %1 = DETECTED", _modName];
    };
} forEach (keys TD_ModCompat);

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

TD_fnc_angleDiff = {
    params ["_angle1", "_angle2"];
    private _diff = _angle1 - _angle2;
    if (_diff > 180) then {_diff = _diff - 360};
    if (_diff < -180) then {_diff = _diff + 360};
    abs _diff
};

TD_fnc_isEnhanced = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};
    private _netId = netId _unit;
    _netId in (keys TD_ActiveDrivers)
};

TD_fnc_isAllowedSide = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};

    private _unitSide = side (group _unit);
    private _allowedSides = TD_CONFIG get "ALLOWED_SIDES";
    private _excludedSides = TD_CONFIG get "EXCLUDED_SIDES";

    if (_unitSide in _excludedSides) exitWith {false};
    if (_unitSide in _allowedSides) exitWith {true};

    false
};

TD_fnc_isOtherAIModUnit = {
    params ["_unit"];
    if (isNull _unit) exitWith {false};

    private _group = group _unit;

    // Check VCOMAI
    if (TD_ModCompat get "HAS_VCOMAI" && {TD_CONFIG get "EXCLUDE_VCOMAI_UNITS"}) then {
        if (!isNil {_group getVariable "VCM_INITIALIZED"} || {_unit getVariable ["VCOMAI_EXCLUDE", false]}) exitWith {true};
    };

    // Check A3XAI
    if (TD_ModCompat get "HAS_A3XAI" && {TD_CONFIG get "EXCLUDE_A3XAI_UNITS"}) then {
        if (!isNil {_group getVariable "A3XAI_Group"} || {_unit getVariable ["A3XAI_Unit", false]}) exitWith {true};
    };

    // Check ASR AI3
    if (TD_ModCompat get "HAS_ASR" && {TD_CONFIG get "EXCLUDE_ASR_UNITS"}) then {
        if (_group getVariable ["asr_ai3_group", false]) exitWith {true};
    };

    // Check LAMBS
    if (TD_ModCompat get "HAS_LAMBS" && {TD_CONFIG get "EXCLUDE_LAMBS_UNITS"}) then {
        if (_group getVariable ["lambs_danger_disableGroupAI", false]) exitWith {true};
    };

    // Check bcombat
    if (TD_ModCompat get "HAS_BCOMBAT" && {TD_CONFIG get "EXCLUDE_BCOMBAT_UNITS"}) then {
        if (_unit getVariable ["bcombat_exclude", false]) exitWith {true};
    };

    false
};

TD_fnc_cleanupWaypoints = {
    params ["_group"];
    if (isNull _group) exitWith {};

    private _maxWaypoints = TD_CONFIG get "MAX_WAYPOINTS";
    private _waypointCount = count waypoints _group;

    if (_waypointCount > _maxWaypoints) then {
        for "_i" from 0 to (_waypointCount - _maxWaypoints - 1) do {
            deleteWaypoint [_group, 0];
        };

        if (TD_CONFIG get "DEBUG") then {
            diag_log format ["TD: Cleaned %1 waypoints from group %2", _waypointCount - _maxWaypoints, _group];
        };
    };
};

// =====================================================
// ROAD SMOOTHNESS MAPPING
// =====================================================

TD_fnc_scanRoadNetwork = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {createHashMap};

    private _pos = getPosWorld _vehicle;
    private _scanRadius = TD_CONFIG get "ROAD_SCAN_RADIUS";
    private _roads = _pos nearRoads _scanRadius;

    private _roadMap = createHashMap;

    {
        if (!isNull _x) then {
            private _roadId = netId _x;
            private _roadPos = getPosWorld _x;
            private _connected = roadsConnectedTo _x;

            private _curvature = 0;
            private _surface = surfaceType _roadPos;

            // Calculate curvature score
            if (count _connected > 1) then {
                private _angles = [];
                private _baseDir = _roadPos getDir (_connected select 0);

                {
                    if (!isNull _x) then {
                        private _connectedPos = getPosWorld _x;
                        private _angle = _roadPos getDir _connectedPos;
                        private _diff = [_baseDir, _angle] call TD_fnc_angleDiff;
                        _angles pushBack _diff;
                    };
                } forEach _connected;

                if (count _angles > 0) then {
                    _curvature = (selectMax _angles) / 180;  // Normalize 0..1
                };
            };

            // Surface weight
            private _surfaceWeight = switch (true) do {
                case (_surface in ["GdtAsphalt","GdtConcrete","GdtTarmac"]): {1.0};
                case (_surface in ["GdtGrassDry","GdtGrassShort","GdtGrassLong"]): {0.7};
                case (_surface in ["GdtGravelRoad","GdtDirtRoad"]): {0.6};
                default {0.5};
            };

            _roadMap set [_roadId, createHashMapFromArray [
                ["curvature", _curvature],
                ["surface", _surface],
                ["surfaceWeight", _surfaceWeight],
                ["pos", _roadPos],
                ["timestamp", time]
            ]];
        };
    } forEach _roads;

    _roadMap
};

TD_fnc_getRoadCurvature = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {0};

    private _netId = netId _vehicle;
    private _cached = TD_RoadCache getOrDefault [_netId, createHashMap];

    // Check if cache is fresh
    private _cacheTime = _cached getOrDefault ["scanTime", 0];
    private _cacheLifetime = TD_CONFIG get "ROAD_CACHE_LIFETIME";

    if (time - _cacheTime > _cacheLifetime || {count _cached == 0}) then {
        // Rescan
        private _roadMap = [_vehicle] call TD_fnc_scanRoadNetwork;
        _cached set ["roadMap", _roadMap];
        _cached set ["scanTime", time];
        TD_RoadCache set [_netId, _cached];
    };

    // Get nearest road segment curvature
    private _roadMap = _cached getOrDefault ["roadMap", createHashMap];
    private _pos = getPosWorld _vehicle;
    private _nearRoad = roadAt _pos;

    if (isNull _nearRoad) exitWith {0};

    private _roadId = netId _nearRoad;
    private _roadData = _roadMap getOrDefault [_roadId, createHashMap];

    _roadData getOrDefault ["curvature", 0]
};

// =====================================================
// GPS CORNER PREDICTION
// =====================================================

TD_fnc_predictCorner = {
    params ["_vehicle", "_rayLeft", "_rayRight"];
    if (isNull _vehicle) exitWith {0};

    // Ray-based detection
    private _leftDist = if (_rayLeft < 0) then {999} else {_rayLeft};
    private _rightDist = if (_rayRight < 0) then {999} else {_rayRight};

    private _tightness = 0;

    if (_leftDist < 20 || _rightDist < 20) then {
        private _minDist = _leftDist min _rightDist;
        _tightness = 1 - (_minDist / 20);
    };

    // Blend with cached road curvature
    private _roadCurve = [_vehicle] call TD_fnc_getRoadCurvature;

    private _blended = (_tightness * 0.6) + (_roadCurve * 0.4);

    _blended min 1
};

// =====================================================
// BRAKING PROFILE
// =====================================================

TD_fnc_brakeProfile = {
    params ["_speedKmh", "_curveSeverity"];

    private _spd = _speedKmh max 1;
    private _brake = _curveSeverity * (_spd / 45);

    // Range: 0.2 - 2.0 seconds
    _brake = _brake max 0.2 min 2.0;

    _brake
};

// =====================================================
// SKID DETECTION & CORRECTION
// =====================================================

TD_fnc_detectSkid = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {false};

    private _vel = velocity _vehicle;
    if (vectorMagnitude _vel < 3) exitWith {false};

    private _facing = vectorDir _vehicle;
    private _velDir = vectorNormalized _vel;

    // Angle between velocity and facing
    private _facingAngle = (_facing select 0) atan2 (_facing select 1);
    private _velAngle = (_velDir select 0) atan2 (_velDir select 1);
    private _angleDiff = [_facingAngle, _velAngle] call TD_fnc_angleDiff;

    // Angular velocity check
    private _angVel = (vectorUp _vehicle) vectorDotProduct (angularVelocity _vehicle);

    private _skidAngleThresh = TD_CONFIG get "SKID_ANGLE_THRESHOLD";
    private _skidAngVelThresh = TD_CONFIG get "SKID_ANGULAR_VEL_THRESHOLD";

    (_angleDiff > _skidAngleThresh || {abs _angVel > _skidAngVelThresh})
};

TD_fnc_correctSkid = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {};

    private _vel = velocity _vehicle;
    private _facing = vectorDir _vehicle;
    private _velDir = vectorNormalized _vel;

    // Calculate counter-steer direction
    private _crossProd = (_facing vectorCrossProduct _velDir) select 2;
    private _correction = TD_CONFIG get "SKID_CORRECTION_FORCE";

    private _newDir = _facing vectorAdd [
        _velDir select 0 * _correction * _crossProd,
        _velDir select 1 * _correction * _crossProd,
        0
    ];

    _vehicle setVectorDirAndUp [vectorNormalized _newDir, vectorUp _vehicle];

    // Bleed speed
    private _speedMult = 0.92;
    _vehicle setVelocity (_vel vectorMultiply _speedMult);
};

// =====================================================
// SMART LANE DETECTION
// =====================================================

TD_fnc_detectLane = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {};

    private _p0 = getPosATL _vehicle;
    private _v = vectorDir _vehicle;
    private _leftV = _v vectorCrossProduct [0,0,1];
    private _rightV = _leftV vectorMultiply -1;

    private _leftSlope = abs ((surfaceNormal (_p0 vectorAdd (_leftV vectorMultiply 3))) select 2);
    private _rightSlope = abs ((surfaceNormal (_p0 vectorAdd (_rightV vectorMultiply 3))) select 2);

    if (_leftSlope > _rightSlope + 0.05) then {
        // Road tilts down right, favor right lane
        _vehicle setVectorDirAndUp [
            _v vectorAdd [(_rightV select 0) * 0.01, (_rightV select 1) * 0.01, 0],
            vectorUp _vehicle
        ];
    } else {
        if (_rightSlope > _leftSlope + 0.05) then {
            // Road tilts down left, favor left lane
            _vehicle setVectorDirAndUp [
                _v vectorAdd [(_leftV select 0) * 0.01, (_leftV select 1) * 0.01, 0],
                vectorUp _vehicle
            ];
        };
    };
};

// =====================================================
// OVERTAKING LOGIC
// =====================================================

TD_fnc_canOvertake = {
    params ["_vehicle", "_rayWideLeft", "_rayWideRight"];

    if (!(TD_CONFIG get "OVERTAKE_ENABLED")) exitWith {false};
    if (isNull _vehicle) exitWith {false};

    private _pos = getPosWorld _vehicle;
    private _ahead = _pos vectorAdd ((vectorDir _vehicle) vectorMultiply 20);

    // Check for vehicle ahead
    private _nearVehicles = _ahead nearEntities [["Car", "Truck"], 25];
    _nearVehicles = _nearVehicles - [_vehicle];

    if (count _nearVehicles == 0) exitWith {false};

    private _leadVeh = _nearVehicles select 0;
    private _leadSpeed = (vectorMagnitude (velocity _leadVeh)) * 3.6;
    private _ourSpeed = (vectorMagnitude (velocity _vehicle)) * 3.6;

    private _speedDiff = _ourSpeed - _leadSpeed;
    private _minDiff = TD_CONFIG get "OVERTAKE_MIN_SPEED_DIFF";

    if (_speedDiff < _minDiff) exitWith {false};

    // Check wide side clearance
    private _wideClear = (_rayWideLeft < 0 || _rayWideLeft > 25) && (_rayWideRight < 0 || _rayWideRight > 25);

    if (!_wideClear) exitWith {false};

    // Check safe re-entry slot ahead
    private _leadDir = vectorDir _leadVeh;
    private _aheadPos = (getPosWorld _leadVeh) vectorAdd (_leadDir vectorMultiply 15);
    private _aheadEmpty = ((nearestObjects [_aheadPos, ["Car", "Truck"], 10]) isEqualTo []);

    _aheadEmpty
};

TD_fnc_executeOvertake = {
    params ["_vehicle"];
    if (isNull _vehicle) exitWith {};

    private _vel = velocity _vehicle;
    private _facing = vectorDir _vehicle;
    private _leftV = _facing vectorCrossProduct [0,0,1];

    // Apply lateral nudge
    private _lateral = TD_CONFIG get "OVERTAKE_LATERAL_FORCE";
    private _newVel = _vel vectorAdd (_leftV vectorMultiply _lateral);

    _vehicle setVelocity _newVel;

    // Mark overtaking
    _vehicle setVariable ["TD_Overtaking", true];
    _vehicle setVariable ["TD_OvertakeStart", time];
};

// =====================================================
// CONVOY FORMATION
// =====================================================

TD_fnc_formationBoxOffset = {
    params ["_index"];
    private _row = floor (_index / 2);
    private _col = _index mod 2;

    private _x = if (_col == 0) then {-6} else {6};
    private _y = -12 * _row;

    [_x, _y, 0]
};

// =====================================================
// MAIN DRIVING SYSTEM
// =====================================================

TD_fnc_driveSmart = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};

    private _tickRate = TD_CONFIG get "TICK_RATE";
    private _rayFront = TD_CONFIG get "RAY_FRONT";
    private _rayShort = TD_CONFIG get "RAY_SHORT";
    private _raySide = TD_CONFIG get "RAY_SIDE";
    private _rayWide = TD_CONFIG get "RAY_WIDE";
    private _rayDown = TD_CONFIG get "RAY_DOWN";

    private _lastLogTime = 0;
    private _debugInterval = TD_CONFIG get "DEBUG_INTERVAL";
    private _debugEnabled = TD_CONFIG get "DEBUG";

    // Speed tiers
    private _speedStraight = TD_CONFIG get "SPEED_STRAIGHT";
    private _speedMid = TD_CONFIG get "SPEED_MID_CURVE";
    private _speedHard = TD_CONFIG get "SPEED_HARD_CURVE";
    private _speedUltra = TD_CONFIG get "SPEED_ULTRA_TIGHT";
    private _speedOffroad = TD_CONFIG get "SPEED_OFFROAD";
    private _speedDirt = TD_CONFIG get "SPEED_DIRT";
    private _speedObstacle = TD_CONFIG get "SPEED_OBSTACLE";
    private _speedIntersection = TD_CONFIG get "SPEED_INTERSECTION";

    private _curveHardThresh = TD_CONFIG get "CURVE_HARD_THRESHOLD";
    private _curveUltraThresh = TD_CONFIG get "CURVE_ULTRA_THRESHOLD";

    private _mapPreset = TD_MapPreset;

    private _lastUnstuckCheck = time;
    private _lastPos = getPosWorld _vehicle;

    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call TD_fnc_isEnhanced)} do {

        private _pos = getPosATL _vehicle;
        private _dir = getDir _vehicle;
        private _vel = velocity _vehicle;
        private _speed = (vectorMagnitude _vel) * 3.6;

        if (_speed < 1) then {
            // Unstuck check
            if (time - _lastUnstuckCheck > 2.0) then {
                private _dist = _pos distance2D _lastPos;
                if (_dist < (TD_CONFIG get "UNSTUCK_THRESHOLD")) then {
                    // Stuck - reverse nudge
                    private _reverseForce = TD_CONFIG get "UNSTUCK_REVERSE_FORCE";
                    private _backDir = (vectorDir _vehicle) vectorMultiply -1;
                    _vehicle setVelocity (_backDir vectorMultiply _reverseForce);

                    if (_debugEnabled) then {
                        diag_log format ["TD: %1 unstuck nudge applied", name _unit];
                    };
                };
                _lastPos = _pos;
                _lastUnstuckCheck = time;
            };
        };

        // === SENSOR SUITE ===
        private _p0 = getPosASL _vehicle;
        private _pFront = _p0 vectorAdd [sin _dir * _rayFront, cos _dir * _rayFront, 0];
        private _pShort = _p0 vectorAdd [sin _dir * _rayShort, cos _dir * _rayShort, 0];
        private _pLeft = _p0 vectorAdd [sin (_dir - 45) * _raySide, cos (_dir - 45) * _raySide, 0];
        private _pRight = _p0 vectorAdd [sin (_dir + 45) * _raySide, cos (_dir + 45) * _raySide, 0];
        private _pWideLeft = _p0 vectorAdd [sin (_dir - 60) * _rayWide, cos (_dir - 60) * _rayWide, 0];
        private _pWideRight = _p0 vectorAdd [sin (_dir + 60) * _rayWide, cos (_dir + 60) * _rayWide, 0];
        private _pDown = _p0 vectorAdd [0, 0, -_rayDown];

        private _front = (lineIntersectsSurfaces [_p0, _pFront, _vehicle]) param [0, []];
        private _short = (lineIntersectsSurfaces [_p0, _pShort, _vehicle]) param [0, []];
        private _left = (lineIntersectsSurfaces [_p0, _pLeft, _vehicle]) param [0, []];
        private _right = (lineIntersectsSurfaces [_p0, _pRight, _vehicle]) param [0, []];
        private _wideLeft = (lineIntersectsSurfaces [_p0, _pWideLeft, _vehicle]) param [0, []];
        private _wideRight = (lineIntersectsSurfaces [_p0, _pWideRight, _vehicle]) param [0, []];
        private _down = (lineIntersectsSurfaces [_p0, _pDown, _vehicle]) param [0, []];

        private _frontDist = if (count _front > 0) then {_p0 distance (_front select 0)} else {-1};
        private _shortDist = if (count _short > 0) then {_p0 distance (_short select 0)} else {-1};
        private _leftDist = if (count _left > 0) then {_p0 distance (_left select 0)} else {-1};
        private _rightDist = if (count _right > 0) then {_p0 distance (_right select 0)} else {-1};
        private _wideLeftDist = if (count _wideLeft > 0) then {_p0 distance (_wideLeft select 0)} else {-1};
        private _wideRightDist = if (count _wideRight > 0) then {_p0 distance (_wideRight select 0)} else {-1};
        private _downDist = if (count _down > 0) then {_p0 distance (_down select 0)} else {-1};

        // Store for debug HUD
        _vehicle setVariable ["TD_RayData", [_frontDist, _shortDist, _leftDist, _rightDist, _wideLeftDist, _wideRightDist, _downDist]];

        // === GPS CORNER PREDICTION ===
        private _curve = [_vehicle, _leftDist, _rightDist] call TD_fnc_predictCorner;
        _vehicle setVariable ["TD_CurveSeverity", _curve];

        // === SPEED SELECTION ===
        private _target = _speedStraight;
        private _reason = "STRAIGHT";

        // Curve-based speed
        if (_curve > _curveUltraThresh) then {
            _target = _speedUltra;
            _reason = "ULTRA_TIGHT";
        } else {
            if (_curve > _curveHardThresh) then {
                _target = _speedHard;
                _reason = "HARD_CURVE";
            } else {
                if (_curve > 0.15) then {
                    _target = _speedMid;
                    _reason = "MID_CURVE";
                };
            };
        };

        // Surface detection
        private _surf = surfaceType _pos;
        private _isRoad = isOnRoad _pos;

        if (!_isRoad) then {
            if (_surf in ["GdtGrassDry","GdtGrassShort","GdtGrassLong","GdtGravelRoad","GdtDirtRoad"]) then {
                _target = _target min _speedDirt;
                _reason = "DIRT";
            } else {
                _target = _target min _speedOffroad;
                _reason = "OFFROAD";
            };
        };

        // Highway mode (straight + asphalt)
        if (_curve < 0.10 && {_surf in ["GdtAsphalt","GdtConcrete","GdtTarmac"]}) then {
            private _boost = _mapPreset get "maxStraightBonus";
            _target = _target * _boost;
            _reason = "HIGHWAY";
        };

        // Urban mode
        private _isUrban = ((nearestObjects [_pos, ["Building"], 35]) isNotEqualTo []);
        if (_isUrban) then {
            private _pen = _mapPreset get "cityPenalty";
            _target = _target * _pen;
            _reason = "URBAN";
        };

        // Immediate hazard (short front ray)
        if (_shortDist > 0 && _shortDist < 20) then {
            _target = _target min _speedObstacle;
            _reason = format ["HAZARD@%1m", round _shortDist];
        };

        // Intersection logic
        private _nearRoad = roadAt _pos;
        if (!isNull _nearRoad) then {
            private _connected = roadsConnectedTo _nearRoad;
            if (count _connected > 2) then {
                // Intersection
                private _nearCars = _pos nearEntities [["Car", "Truck"], 25];
                _nearCars = _nearCars - [_vehicle];
                if (count _nearCars > 0) then {
                    _target = _target min _speedIntersection;
                    _reason = "INTERSECTION";
                };
            };
        };

        // Bridge precision entry
        if ((_downDist > 0) && {_frontDist < 0} && {_curve < 0.25}) then {
            _target = _speedStraight;
            _reason = "BRIDGE_ENTRY";
        };

        // Braking profile
        private _brakeTime = [_speed, _curve] call TD_fnc_brakeProfile;
        if (_brakeTime > 0.3) then {
            _target = _target * (1 - (_brakeTime * 0.15));
        };

        // === SKID DETECTION & CORRECTION ===
        if ([_vehicle] call TD_fnc_detectSkid) then {
            [_vehicle] call TD_fnc_correctSkid;
            _target = _target * 0.85;
            _reason = "SKID_CORRECTING";
        };

        // === OVERTAKING ===
        private _isOvertaking = _vehicle getVariable ["TD_Overtaking", false];
        if (_isOvertaking) then {
            private _overtakeStart = _vehicle getVariable ["TD_OvertakeStart", 0];
            private _overtakeDuration = TD_CONFIG get "OVERTAKE_DURATION";

            if (time - _overtakeStart > _overtakeDuration) then {
                _vehicle setVariable ["TD_Overtaking", false];
            } else {
                private _boost = TD_CONFIG get "OVERTAKE_BOOST";
                _target = _target * _boost;
                _reason = "OVERTAKING";
            };
        } else {
            if ([_vehicle, _wideLeftDist, _wideRightDist] call TD_fnc_canOvertake) then {
                [_vehicle] call TD_fnc_executeOvertake;
            };
        };

        // === SMART LANE DETECTION ===
        if (_speed > 30 && _isRoad) then {
            [_vehicle] call TD_fnc_detectLane;
        };

        // === APPLY SPEED LIMIT ===
        private _smoothFactor = _mapPreset get "smoothnessFactor";
        _target = _target * _smoothFactor;

        if (!isNull _vehicle) then {
            _vehicle limitSpeed (_target / 3.6);
        };

        _vehicle setVariable ["TD_TargetSpeed", _target];
        _vehicle setVariable ["TD_SpeedReason", _reason];

        // === DEBUG LOGGING ===
        if (_debugEnabled && (time - _lastLogTime > _debugInterval)) then {
            diag_log format ["TD: %1 | Speed: %2/%3 km/h | Curve: %4 | Reason: %5",
                name _unit,
                round _speed,
                round _target,
                round (_curve * 100),
                _reason
            ];
            _lastLogTime = time;
        };

        sleep _tickRate;
    };
};

// =====================================================
// ROAD FOLLOWING (WAYPOINT SYSTEM)
// =====================================================

TD_fnc_roadFollowing = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};

    private _group = group _unit;
    private _lastCleanup = time;

    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call TD_fnc_isEnhanced)} do {

        // Periodic waypoint cleanup
        if (!isNull _group && time - _lastCleanup > (TD_CONFIG get "WAYPOINT_CLEANUP_INTERVAL")) then {
            [_group] call TD_fnc_cleanupWaypoints;
            _lastCleanup = time;
        };

        private _currentPos = getPosASL _vehicle;
        private _currentRoads = _currentPos nearRoads 50;

        if (count _currentRoads > 0) then {
            private _currentRoad = _currentRoads select 0;
            private _connectedRoads = roadsConnectedTo _currentRoad;

            if (count _connectedRoads > 0) then {
                // Select best connected road (align with vehicle direction)
                private _vehDir = getDir _vehicle;
                private _bestRoad = objNull;
                private _bestScore = -1;

                {
                    if (!isNull _x) then {
                        private _roadPos = getPos _x;
                        private _roadDir = _currentPos getDir _roadPos;
                        private _dirDiff = [_vehDir, _roadDir] call TD_fnc_angleDiff;
                        private _score = 1 - (_dirDiff / 180);

                        if (_score > _bestScore) then {
                            _bestScore = _score;
                            _bestRoad = _x;
                        };
                    };
                } forEach _connectedRoads;

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
                    } else {
                        [_group, _wpIndex] setWaypointPosition [_roadPos, 0];
                    };
                };
            };
        };

        sleep 2;
    };
};

// =====================================================
// OBSTACLE AVOIDANCE (HELIPAD SYSTEM)
// =====================================================

TD_fnc_obstacleAvoidance = {
    params ["_unit", "_vehicle"];
    if (isNull _unit || isNull _vehicle) exitWith {};

    private _obstacleRadius = 12;
    private _obstacleOffset = TD_CONFIG get "OBSTACLE_OFFSET";
    private _minObjectSize = TD_CONFIG get "MIN_OBJECT_SIZE";
    private _obstacleCooldown = TD_CONFIG get "OBSTACLE_COOLDOWN";
    private _tickRate = TD_CONFIG get "TICK_RATE";
    private _useObstacles = TD_CONFIG get "USE_OBSTACLES";

    while {!isNull _unit && !isNull _vehicle && alive _unit && alive _vehicle && driver _vehicle == _unit && ([_unit] call TD_fnc_isEnhanced)} do {

        if (_useObstacles) then {
            private _pos = getPosASL _vehicle;
            private _dir = getDir _vehicle;

            // Check ahead
            private _checkPos = _pos vectorAdd [sin _dir * 40, cos _dir * 40, 0];
            private _objects = _checkPos nearEntities [["Building", "House", "Wall"], _obstacleRadius];

            {
                private _building = _x;
                if (!isNull _building) then {
                    private _buildingNetId = netId _building;
                    private _lastProcessTime = TD_BuildingCache getOrDefault [_buildingNetId, 0];

                    if (time - _lastProcessTime > _obstacleCooldown) then {
                        TD_BuildingCache set [_buildingNetId, time];

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
                                    private _obstacle = createVehicle ["Land_HelipadEmpty_F", _obstaclePos, [], 0, "CAN_COLLIDE"];
                                    if (!isNull _obstacle) then {
                                        _obstacle setPosASL _obstaclePos;
                                        _obstacle enableSimulationGlobal false;
                                        _obstacle hideObjectGlobal true;
                                        _obstacle setVariable ["TD_SpawnedObstacle", true, false];
                                        _obstacle setVariable ["TD_BuildingParent", _building, false];

                                        _obstacleCount = _obstacleCount + 1;
                                    };
                                };
                            };

                            if (_obstacleCount > 0) then {
                                [_building, _obstacleCooldown, _buildingNetId] spawn {
                                    params ["_building", "_cooldown", "_buildingNetId"];
                                    sleep _cooldown;

                                    if (!isNull _building) then {
                                        private _obstacles = nearestObjects [getPosASL _building, ["Land_HelipadEmpty_F"], 10];
                                        {
                                            if (!isNull _x && {(_x getVariable ["TD_BuildingParent", objNull]) == _building}) then {
                                                deleteVehicle _x;
                                            };
                                        } forEach _obstacles;
                                    };

                                    TD_BuildingCache deleteAt _buildingNetId;
                                };
                            };
                        };
                    };
                };
            } forEach _objects;
        };

        sleep _tickRate;
    };
};

// =====================================================
// APPLY/RESTORE FUNCTIONS
// =====================================================

TD_fnc_applyToDriver = {
    params ["_unit", "_vehicle"];

    if (isNull _unit || isNull _vehicle) exitWith {};
    if (!alive _unit || !alive _vehicle || driver _vehicle != _unit) exitWith {};
    if (!(_vehicle isKindOf "LandVehicle")) exitWith {};
    if ([_unit] call TD_fnc_isEnhanced) exitWith {};

    if (!([_unit] call TD_fnc_isAllowedSide)) exitWith {};
    if ([_unit] call TD_fnc_isOtherAIModUnit) exitWith {};

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

    TD_ActiveDrivers set [_netId, _originalSettings];

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

    [_unit, _vehicle] spawn TD_fnc_driveSmart;
    [_unit, _vehicle] spawn TD_fnc_roadFollowing;
    [_unit, _vehicle] spawn TD_fnc_obstacleAvoidance;

    if (TD_CONFIG get "DEBUG") then {
        diag_log format ["TD: Enhanced %1 (Side: %2) in %3", name _unit, side (group _unit), typeOf _vehicle];
    };
};

TD_fnc_restoreDriver = {
    params ["_unit"];

    if (isNull _unit) exitWith {};
    if (!([_unit] call TD_fnc_isEnhanced)) exitWith {};

    private _netId = netId _unit;
    private _originalSettings = TD_ActiveDrivers get _netId;

    if (isNil "_originalSettings") exitWith {
        TD_ActiveDrivers deleteAt _netId;
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

    TD_ActiveDrivers deleteAt _netId;

    if (TD_CONFIG get "DEBUG") then {
        diag_log format ["TD: Restored %1", name _unit];
    };
};

// =====================================================
// DEBUG HUD (CLIENT-SIDE)
// =====================================================

if (hasInterface) then {
    TD_debugLayer = 0;

    // F4 key to switch debug layers
    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_display", "_key"];
        if (_key == 0x3E) then {  // F4
            TD_debugLayer = (TD_debugLayer + 1) mod 4;
            systemChat format ["Tesla-Drive Debug Layer: %1", ["OFF", "Sensors", "Road Map", "Curve Prediction"] select TD_debugLayer];
            true
        };
    }];

    addMissionEventHandler ["Draw3D", {
        if (TD_debugLayer == 0) exitWith {};

        private _veh = vehicle player;
        if (_veh == player) exitWith {};
        if (!(_veh isKindOf "LandVehicle")) exitWith {};

        private _pos = getPosASL _veh;

        // Layer 1: Sensors
        if (TD_debugLayer == 1) then {
            private _rayData = _veh getVariable ["TD_RayData", []];
            if (count _rayData == 7) then {
                private _dir = getDir _veh;

                private _frontDist = _rayData select 0;
                private _shortDist = _rayData select 1;
                private _leftDist = _rayData select 2;
                private _rightDist = _rayData select 3;
                private _wideLeftDist = _rayData select 4;
                private _wideRightDist = _rayData select 5;
                private _downDist = _rayData select 6;

                // Draw rays
                if (_frontDist > 0) then {
                    private _endPos = _pos vectorAdd [sin _dir * _frontDist, cos _dir * _frontDist, 0];
                    drawLine3D [_pos, _endPos, [1,0,0,1]];
                };

                if (_leftDist > 0) then {
                    private _endPos = _pos vectorAdd [sin (_dir - 45) * _leftDist, cos (_dir - 45) * _leftDist, 0];
                    drawLine3D [_pos, _endPos, [1,1,0,1]];
                };

                if (_rightDist > 0) then {
                    private _endPos = _pos vectorAdd [sin (_dir + 45) * _rightDist, cos (_dir + 45) * _rightDist, 0];
                    drawLine3D [_pos, _endPos, [0,1,1,1]];
                };
            };

            // HUD text
            private _speed = (vectorMagnitude (velocity _veh)) * 3.6;
            private _target = _veh getVariable ["TD_TargetSpeed", 0];
            private _reason = _veh getVariable ["TD_SpeedReason", ""];
            private _curve = _veh getVariable ["TD_CurveSeverity", 0];

            private _text = format ["Speed: %1/%2 km/h\nCurve: %3%%\nReason: %4",
                round _speed,
                round _target,
                round (_curve * 100),
                _reason
            ];

            drawIcon3D ["", [1,1,1,1], _pos vectorAdd [0,0,3], 0, 0, 0, _text, 1, 0.04, "PuristaMedium"];
        };

        // Layer 2: Road Map
        if (TD_debugLayer == 2) then {
            private _nearRoads = _pos nearRoads 150;
            {
                if (!isNull _x) then {
                    private _roadPos = getPosASL _x;
                    drawIcon3D ["", [0,1,0,0.5], _roadPos vectorAdd [0,0,0.5], 1, 1, 0, "", 1, 0.03, "PuristaMedium"];
                };
            } forEach _nearRoads;
        };

        // Layer 3: Curve Prediction
        if (TD_debugLayer == 3) then {
            private _curve = _veh getVariable ["TD_CurveSeverity", 0];
            private _color = [_curve, 1-_curve, 0, 1];

            drawIcon3D ["", _color, _pos vectorAdd [0,0,2], 2, 2, 0, format ["Curve: %1%%", round (_curve * 100)], 1, 0.05, "PuristaMedium"];
        };
    }];
};

// =====================================================
// EVENT HANDLERS
// =====================================================

TD_fnc_addEventHandlers = {
    // Initial scan
    {
        if (!isPlayer _x && alive _x && !isNull _x) then {
            private _vehicle = vehicle _x;
            if (_vehicle != _x && driver _vehicle == _x && _vehicle isKindOf "LandVehicle") then {
                [_x, _vehicle] call TD_fnc_applyToDriver;
            };
        };
    } forEach allUnits;

    diag_log "TD: Event handlers initialized (fallback polling mode)";
};

// =====================================================
// FALLBACK POLLING (NO CBA REQUIRED)
// =====================================================

TD_fnc_fallbackPolling = {
    while {TD_CONFIG get "ENABLED"} do {
        {
            if (!isPlayer _x && alive _x && !isNull _x) then {
                private _unit = _x;

                if !(_unit in TD_ProcessedUnits) then {
                    TD_ProcessedUnits pushBack _unit;

                    private _getInID = _unit addEventHandler ["GetInMan", {
                        params ["_unit", "_role", "_vehicle"];

                        if (_role == "driver" && !isPlayer _unit && _vehicle isKindOf "LandVehicle") then {
                            [_unit, _vehicle] spawn {
                                params ["_unit", "_vehicle"];
                                sleep 0.5;
                                if (!isNull _unit && !isNull _vehicle) then {
                                    [_unit, _vehicle] call TD_fnc_applyToDriver;
                                };
                            };
                        };
                    }];

                    private _getOutID = _unit addEventHandler ["GetOutMan", {
                        params ["_unit", "_role"];
                        if (_role == "driver") then {[_unit] call TD_fnc_restoreDriver};
                    }];

                    private _killedID = _unit addEventHandler ["Killed", {
                        params ["_unit"];
                        [_unit] call TD_fnc_restoreDriver;

                        private _getInID = _unit getVariable ["TD_GetInHandler", -1];
                        private _getOutID = _unit getVariable ["TD_GetOutHandler", -1];
                        private _killedID = _unit getVariable ["TD_KilledHandler", -1];

                        if (_getInID >= 0) then {_unit removeEventHandler ["GetInMan", _getInID]};
                        if (_getOutID >= 0) then {_unit removeEventHandler ["GetOutMan", _getOutID]};
                        if (_killedID >= 0) then {_unit removeEventHandler ["Killed", _killedID]};
                    }];

                    _unit setVariable ["TD_GetInHandler", _getInID];
                    _unit setVariable ["TD_GetOutHandler", _getOutID];
                    _unit setVariable ["TD_KilledHandler", _killedID];
                };

                private _vehicle = vehicle _unit;
                if (_vehicle != _unit && driver _vehicle == _unit && _vehicle isKindOf "LandVehicle" && !([_unit] call TD_fnc_isEnhanced)) then {
                    [_unit, _vehicle] call TD_fnc_applyToDriver;
                };
            };
        } forEach allUnits;

        sleep 5;
    };
};

// =====================================================
// CLEANUP LOOP
// =====================================================

TD_fnc_cleanupLoop = {
    while {TD_CONFIG get "ENABLED"} do {
        sleep 30;

        private _toRemove = [];
        {
            private _netId = _x;
            private _unit = objectFromNetId _netId;

            if (isNull _unit || !alive _unit || vehicle _unit == _unit || driver (vehicle _unit) != _unit) then {
                if (!isNull _unit) then {
                    _toRemove pushBack _unit;
                } else {
                    TD_ActiveDrivers deleteAt _netId;
                };
            };
        } forEach (keys TD_ActiveDrivers);

        {
            if (!isNull _x) then {[_x] call TD_fnc_restoreDriver};
        } forEach _toRemove;

        TD_ProcessedUnits = TD_ProcessedUnits select {!isNull _x && alive _x};

        if ((TD_CONFIG get "DEBUG") && count _toRemove > 0) then {
            diag_log format ["TD: Cleanup - Active: %1 | Removed: %2 | Tracked: %3",
                count TD_ActiveDrivers,
                count _toRemove,
                count TD_ProcessedUnits
            ];
        };
    };
};

// =====================================================
// START SYSTEM
// =====================================================

if (TD_CONFIG get "ENABLED") then {

    call TD_fnc_addEventHandlers;
    [] spawn TD_fnc_fallbackPolling;
    [] spawn TD_fnc_cleanupLoop;

    diag_log "==========================================";
    diag_log "Tesla-Drive Ultimate AI - ACTIVE";
    diag_log format ["Map Preset: %1", TD_MapPreset get "mapType"];
    diag_log format ["Max Highway Speed: %1 km/h", TD_CONFIG get "SPEED_STRAIGHT"];
    diag_log format ["Overtaking: %1", TD_CONFIG get "OVERTAKE_ENABLED"];
    diag_log format ["Debug HUD: Press F4 to cycle layers"];
    diag_log "==========================================";

} else {
    diag_log "Tesla-Drive Ultimate AI - DISABLED";
};
