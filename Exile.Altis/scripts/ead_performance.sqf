/* =====================================================================================
    ELITE AI DRIVING SYSTEM (EAD) – VERSION 9.0 PERFORMANCE EDITION
    AUTHOR: OPTIMIZED FOR MAXIMUM SPEED + APEX RACING

    v9.0 PERFORMANCE ENHANCEMENTS:
        ✅ MAXIMUM SPEED MODE - Aggressive speed optimization
        ✅ APEX CURVE CUTTING - Racing line through curves
        ✅ 4-HEIGHT FORWARD RAYCASTING - Ground, Low, Mid, Eye-level
        ✅ TOP-DOWN RAYCASTING - Overhead obstacle detection
        ✅ SMART CURVE DETECTION - Gentle (fast) vs Sharp (slow)
        ✅ AGGRESSIVE BRIDGE MODE - No brakes for 4 seconds on bridges
        ✅ CONE FORWARD RAYCASTING - Wide coverage ahead
===================================================================================== */

/* =====================================================================================
    SECTION 1 — GLOBAL STATE & CONFIG
===================================================================================== */

EAD_CFG = createHashMapFromArray [
    ["TICK", 0.08],                     // ✅ FASTER: 0.08 from 0.10

    // ✅ AGGRESSIVE SPEED PROFILES
    ["HIGHWAY_BASE", 180],              // ✅ UP FROM 145
    ["CITY_BASE", 110],                 // ✅ UP FROM 85
    ["OFFROAD_MULT", 0.85],             // ✅ UP FROM 0.75

    // ✅ EXTENDED DISTANCES FOR HIGH SPEED
    ["DIST_MAIN", 80],                  // ✅ UP FROM 50 (farther lookahead)
    ["DIST_WIDE", 55],                  // ✅ UP FROM 35
    ["DIST_SIDE", 40],                  // ✅ UP FROM 28
    ["DIST_CORNER", 30],                // ✅ UP FROM 20
    ["DIST_NEAR", 18],                  // ✅ UP FROM 14

    // ✅ APEX RACING
    ["APEX_ENABLED", true],
    ["APEX_CUT_ANGLE", 35],             // Degrees to cut into apex
    ["APEX_SPEED_BOOST", 1.15],         // 15% speed boost on apex

    // ✅ SMART CURVE DETECTION
    ["CURVE_GENTLE_THRESHOLD", 65],     // > 65m side clearance = gentle curve
    ["CURVE_SHARP_THRESHOLD", 25],      // < 25m side clearance = sharp curve
    ["CURVE_GENTLE_MULT", 0.95],        // Only 5% slowdown on gentle curves
    ["CURVE_SHARP_MULT", 0.65],         // 35% slowdown on sharp/90° curves

    // ✅ AGGRESSIVE BRIDGE MODE
    ["BRIDGE_SIDE_OFFSET", 5],
    ["BRIDGE_NO_BRAKE_TIME", 4.0],      // Disable brakes for 4 seconds
    ["BRIDGE_SPEED_MAINTAIN", true],    // Maintain speed on bridges

    // Stuck logic
    ["STUCK_TIME", 2.5],                // ✅ FASTER from 3.0
    ["STUCK_SPEED", 8],
    ["REVERSE_TIME", 2.0],              // ✅ FASTER from 2.5
    ["REVERSE_SPEED_KMH", 25],          // ✅ FASTER from 20

    // Emergency brake (less aggressive)
    ["EMERGENCY_BRAKE_DIST", 3],        // ✅ DOWN FROM 5 (brake later)

    // Debug
    ["DEBUG_ENABLED", false],
    ["DEBUG_DRAW_RAYS", false],
    ["DEBUG_DRAW_TEXT", false]
];

EAD_TrackedVehicles = [];
EAD_VehicleTypes = createHashMap;
EAD_Stats = createHashMapFromArray [
    ["totalVehicles", 0],
    ["avgTickTime", 0],
    ["maxTickTime", 0]
];

/* =====================================================================================
    SECTION 2 — VEHICLE PROFILE SYSTEM (PERFORMANCE TUNED)
===================================================================================== */

EAD_fnc_getProfile = {
    params ["_veh"];

    private _type = typeOf _veh;

    if (_type isKindOf "Car") exitWith {
        createHashMapFromArray [
            ["role","CAR"], ["highway",165],["city",95],["offroad",0.80],["brute",false]
        ]
    };

    if (_type isKindOf "MRAP_01_base_F") exitWith {
        createHashMapFromArray [
            ["role","MRAP"],["highway",140],["city",80],["offroad",0.85],["brute",true]
        ]
    };

    if (_type isKindOf "Truck_F") exitWith {
        createHashMapFromArray [
            ["role","TRUCK"],["highway",120],["city",70],["offroad",0.75],["brute",false]
        ]
    };

    if (_type isKindOf "Tank") exitWith {
        createHashMapFromArray [
            ["role","TRACKED"],["highway",90],["city",55],["offroad",0.95],["brute",true]
        ]
    };

    createHashMapFromArray [
        ["role","GENERIC"],["highway",140],["city",85],["offroad",0.80],["brute",false]
    ]
};

/* =====================================================================================
    SECTION 3 — ADVANCED RAYCAST SYSTEM (4-HEIGHT + TOP-DOWN + CONE)
===================================================================================== */

// ✅ NEW: 4-height forward raycast (ground, low, mid, eye-level)
EAD_fnc_ray4Height = {
    params ["_veh","_dirVec","_dist"];

    private _posASL = getPosASL _veh;
    private _results = [];

    // ✅ HEIGHT 1: Ground level (0.15m) - detects rocks, curbs, small obstacles
    private _start1 = _posASL vectorAdd [0, 0, 0.15];
    private _end1 = _start1 vectorAdd (_dirVec vectorMultiply _dist);
    private _hit1 = lineIntersectsSurfaces [_start1, _end1, _veh, objNull, true, 1, "GEOM"];

    // ✅ HEIGHT 2: Low (0.6m) - detects bushes, low walls
    private _start2 = _posASL vectorAdd [0, 0, 0.6];
    private _end2 = _start2 vectorAdd (_dirVec vectorMultiply _dist);
    private _hit2 = lineIntersectsSurfaces [_start2, _end2, _veh, objNull, true, 1, "GEOM"];

    // ✅ HEIGHT 3: Mid (1.2m) - detects fences, medium obstacles
    private _start3 = _posASL vectorAdd [0, 0, 1.2];
    private _end3 = _start3 vectorAdd (_dirVec vectorMultiply _dist);
    private _hit3 = lineIntersectsSurfaces [_start3, _end3, _veh, objNull, true, 1, "GEOM"];

    // ✅ HEIGHT 4: Eye-level (1.8m) - detects trees, buildings, overhead obstacles
    private _start4 = _posASL vectorAdd [0, 0, 1.8];
    private _end4 = _start4 vectorAdd (_dirVec vectorMultiply _dist);
    private _hit4 = lineIntersectsSurfaces [_start4, _end4, _veh, objNull, true, 1, "GEOM"];

    // Calculate distances
    private _dist1 = if (count _hit1 > 0) then {_start1 vectorDistance (_hit1#0#0)} else {_dist};
    private _dist2 = if (count _hit2 > 0) then {_start2 vectorDistance (_hit2#0#0)} else {_dist};
    private _dist3 = if (count _hit3 > 0) then {_start3 vectorDistance (_hit3#0#0)} else {_dist};
    private _dist4 = if (count _hit4 > 0) then {_start4 vectorDistance (_hit4#0#0)} else {_dist};

    // Return minimum distance (closest obstacle at any height)
    _dist1 min _dist2 min _dist3 min _dist4
};

// ✅ NEW: Top-down raycast (detects overhead obstacles like bridges, trees)
EAD_fnc_rayTopDown = {
    params ["_veh"];

    private _pos = getPosASL _veh;
    private _checkHeight = 15; // Check 15m above vehicle

    // Cast ray straight down from above vehicle
    private _startAbove = _pos vectorAdd [0, 0, _checkHeight];
    private _endAtVehicle = _pos vectorAdd [0, 0, 0.5];

    private _hit = lineIntersectsSurfaces [_startAbove, _endAtVehicle, _veh, objNull, true, 1, "GEOM"];

    // Returns true if there's overhead obstacle (bridge, tree canopy, etc)
    (count _hit > 0)
};

// ✅ BATCH RAYCAST with 4-height cone forward
EAD_fnc_rayBatchAdvanced = {
    params ["_veh", "_rayDefs"];

    private _vehPos = getPosASL _veh;
    private _dir = getDir _veh;
    private _batch = [];

    // Build batch array: for each ray, create 4-height checks
    {
        _x params ["_angleOffset", "_dist"];
        private _ang = _dir + _angleOffset;
        private _vec = [sin _ang, cos _ang, 0];

        // ✅ 4 HEIGHTS for each ray direction
        private _heights = [0.15, 0.6, 1.2, 1.8]; // Ground, Low, Mid, Eye-level

        {
            private _startHeight = _vehPos vectorAdd [0, 0, _x];
            private _endHeight = _startHeight vectorAdd (_vec vectorMultiply _dist);
            _batch pushBack [_startHeight, _endHeight, _veh, objNull, true, 1, "GEOM", "NONE"];
        } forEach _heights;

    } forEach _rayDefs;

    // ✅ BATCH PROCESSING: Single call for all raycasts
    private _results = lineIntersectsSurfaces [_batch];

    // Process results: extract minimum distance for each ray (across all 4 heights)
    private _distances = [];
    private _idx = 0;

    {
        _x params ["_angleOffset", "_dist"];

        // Get 4 height results for this ray
        private _minDist = _dist; // Default to max distance

        for "_h" from 0 to 3 do {
            private _result = _results select (_idx + _h);

            if (count _result > 0) then {
                private _heightOffset = [0.15, 0.6, 1.2, 1.8] select _h;
                private _startPos = _vehPos vectorAdd [0, 0, _heightOffset];
                private _hitDist = _startPos vectorDistance (_result#0#0);
                _minDist = _minDist min _hitDist;
            };
        };

        _distances pushBack _minDist;
        _idx = _idx + 4; // Move to next ray (4 heights per ray)

    } forEach _rayDefs;

    _distances
};

EAD_fnc_terrainInfo = {
    params ["_veh"];

    private _pos = getPosATL _veh;
    private _norm = surfaceNormal _pos;
    private _slope = 1 - (_norm select 2);
    private _isRoad = isOnRoad _pos;

    private _now = time;
    private _last = _veh getVariable ["EAD_treeCheckTime", 0];
    private _dense = _veh getVariable ["EAD_treeDense", false];

    if ((_now - _last) > 2) then {
        private _trees = nearestTerrainObjects [_pos,["TREE","SMALL TREE","BUSH"],25];
        _dense = (count _trees) > 8;
        _veh setVariable ["EAD_treeDense", _dense];
        _veh setVariable ["EAD_treeCheckTime", _now];
    };

    [_isRoad,_slope,_dense,_norm]
};

// ✅ IMPROVED BRIDGE DETECTION
EAD_fnc_isBridge = {
    params ["_veh"];

    private _pos = getPosATL _veh;
    if !(isOnRoad _pos) exitWith {false};

    private _off = EAD_CFG get "BRIDGE_SIDE_OFFSET";
    private _right = vectorSide _veh;
    private _dir = getDir _veh;
    private _fwd = [sin _dir, cos _dir, 0] vectorMultiply 10;

    // Check 5 points along bridge (more reliable)
    private _checks = [
        _pos vectorAdd (_fwd vectorMultiply -0.5),
        _pos,
        _pos vectorAdd (_fwd vectorMultiply 0.33),
        _pos vectorAdd (_fwd vectorMultiply 0.66),
        _pos vectorAdd _fwd
    ];

    private _hits = 0;

    {
        private _L = _x vectorAdd (_right vectorMultiply _off);
        private _R = _x vectorAdd (_right vectorMultiply -_off);

        if (surfaceIsWater _L && surfaceIsWater _R) then {
            _hits = _hits + 1;
        };
    } forEach _checks;

    // Need at least 3 out of 5 checks to confirm bridge
    (_hits >= 3)
};

// ✅ ADVANCED SCAN with CONE FORWARD
EAD_fnc_scanAdaptive = {
    params ["_veh"];

    private _spd = speed _veh;
    private _dir = getDir _veh;

    private _m = EAD_CFG get "DIST_MAIN";
    private _w = EAD_CFG get "DIST_WIDE";
    private _s = EAD_CFG get "DIST_SIDE";
    private _c = EAD_CFG get "DIST_CORNER";
    private _n = EAD_CFG get "DIST_NEAR";

    // ✅ EXPANDED CONE: 15 rays for maximum coverage
    private _rayDefinitions = [
        // Forward cone (7 rays)
        ["F0",  0,   _m],
        ["FL1", 8,   _m],    // ✅ TIGHTER cone
        ["FR1", -8,  _m],
        ["FL2", 16,  _m],
        ["FR2", -16, _m],
        ["FL3", 25,  _w],
        ["FR3", -25, _w],

        // Side detection (4 rays)
        ["L",   45,  _s],
        ["R",   -45, _s],
        ["CL",  70,  _c],
        ["CR",  -70, _c],

        // Near sides (4 rays)
        ["NL",  90,  _n],
        ["NR",  -90, _n],
        ["NL2", 110, _n],    // ✅ REAR coverage
        ["NR2", -110,_n]
    ];

    // Extract angle/distance pairs for batch raycast
    private _rayDefs = _rayDefinitions apply {[_x#1, _x#2]};

    // ✅ BATCH RAYCAST with 4-HEIGHT detection
    private _distances = [_veh, _rayDefs] call EAD_fnc_rayBatchAdvanced;

    // Build result hashmap
    private _map = createHashMap;
    {
        _x params ["_label", "_angleOffset", "_distance"];
        _map set [_label, _distances select _forEachIndex];
    } forEach _rayDefinitions;

    // ✅ ADD TOP-DOWN CHECK
    private _hasOverhead = [_veh] call EAD_fnc_rayTopDown;
    _map set ["OVERHEAD", _hasOverhead];

    _map
};

/* =====================================================================================
    SECTION 4 — SPEED BRAIN + APEX + SMART CURVES
===================================================================================== */

// ✅ NEW: Detect curve sharpness (gentle vs sharp)
EAD_fnc_detectCurveType = {
    params ["_s"];

    private _leftClear = (_s get "CL") min (_s get "L");
    private _rightClear = (_s get "CR") min (_s get "R");
    private _minSide = _leftClear min _rightClear;
    private _maxSide = _leftClear max _rightClear;

    private _gentleThreshold = EAD_CFG get "CURVE_GENTLE_THRESHOLD";
    private _sharpThreshold = EAD_CFG get "CURVE_SHARP_THRESHOLD";

    // Gentle curve: lots of side clearance
    if (_minSide > _gentleThreshold) exitWith {"GENTLE"};

    // Sharp/90° curve: very little side clearance
    if (_minSide < _sharpThreshold) exitWith {"SHARP"};

    // Medium curve
    "MEDIUM"
};

// ✅ NEW: Apex detection and racing line calculation
EAD_fnc_calculateApex = {
    params ["_veh", "_s", "_curveType"];

    if !(EAD_CFG get "APEX_ENABLED") exitWith {0};
    if (_curveType == "GENTLE") exitWith {0}; // No apex needed on gentle curves

    private _leftClear = (_s get "CL") min (_s get "L");
    private _rightClear = (_s get "CR") min (_s get "R");

    // Determine apex side (cut into the inside of the curve)
    private _apexAngle = 0;

    if (_leftClear < _rightClear) then {
        // Left turn - cut apex to the left
        _apexAngle = EAD_CFG get "APEX_CUT_ANGLE";
    } else {
        // Right turn - cut apex to the right
        _apexAngle = -(EAD_CFG get "APEX_CUT_ANGLE");
    };

    _apexAngle
};

EAD_fnc_speedBrain = {
    params ["_veh","_s","_terrain","_profile"];

    _terrain params ["_isRoad","_slope","_dense","_norm"];

    // ✅ START WITH MAXIMUM BASE SPEED
    private _base = EAD_CFG get "HIGHWAY_BASE";
    if (!_isRoad) then {_base = _base * (_profile get "offroad")};

    // ✅ REDUCED density penalty
    if (_dense) then {_base = _base * 0.92}; // Only 8% reduction (was 15%)

    // ✅ SMART CURVE HANDLING
    private _curveType = [_s] call EAD_fnc_detectCurveType;

    switch (_curveType) do {
        case "GENTLE": {
            _base = _base * (EAD_CFG get "CURVE_GENTLE_MULT"); // 5% slowdown
        };
        case "SHARP": {
            _base = _base * (EAD_CFG get "CURVE_SHARP_MULT"); // 35% slowdown
        };
        case "MEDIUM": {
            _base = _base * 0.82; // 18% slowdown
        };
    };

    // ✅ APEX SPEED BOOST
    if (_curveType != "GENTLE" && (EAD_CFG get "APEX_ENABLED")) then {
        private _onApex = _veh getVariable ["EAD_onApex", false];
        if (_onApex) then {
            _base = _base * (EAD_CFG get "APEX_SPEED_BOOST"); // 15% boost
        };
    };

    // ✅ REDUCED slope penalty (only severe slopes)
    if (_slope > 0.45) then {_base = _base * 0.70}; // Only on very steep slopes

    // ✅ HIGHER minimum speed
    _base max 25 // Was 15
};

EAD_fnc_obstacleLimit = {
    params ["_veh","_s","_cur"];

    // ✅ Check all forward rays for minimum clearance
    private _m = selectMin [
        _s get "F0",
        _s get "FL1",
        _s get "FR1",
        _s get "FL2",
        _s get "FR2",
        _s get "FL3",
        _s get "FR3"
    ];

    // ✅ LESS AGGRESSIVE braking (brake later, less reduction)
    if (_m < 25) then {_cur = _cur * 0.65}; // Was 30m / 0.60
    if (_m < 18) then {_cur = _cur * 0.60}; // Was 25m / 0.55
    if (_m < 10) then {_cur = _cur * 0.40}; // Was 15m / 0.35

    _cur
};

EAD_fnc_altitudeCorrection = {
    params ["_veh","_spd","_terrain"];
    private _slope = _terrain select 1;

    // ✅ ONLY correct on EXTREME slopes
    if (_slope > 0.50) exitWith {_spd * 0.70}; // Was 0.40 / 0.65
    if (_slope > 0.35) exitWith {_spd * 0.85}; // Was 0.25 / 0.80
    _spd
};

// ✅ AGGRESSIVE BRIDGE MODE (no brakes for 4 seconds)
EAD_fnc_applyBridgeMode = {
    params ["_veh","_spd"];

    private _b = [_veh] call EAD_fnc_isBridge;
    private _now = time;

    if (_b) then {
        // Entering bridge
        private _bridgeEnterTime = _veh getVariable ["EAD_bridgeEnterTime", 0];

        if (_bridgeEnterTime == 0) then {
            // Just entered bridge - record time and speed
            _veh setVariable ["EAD_bridgeEnterTime", _now];
            _veh setVariable ["EAD_bridgeSpeed", speed _veh max _spd];
        };

        private _timeSinceEnter = _now - _bridgeEnterTime;
        private _noBrakeTime = EAD_CFG get "BRIDGE_NO_BRAKE_TIME";

        // ✅ MAINTAIN SPEED and DISABLE BRAKES for 4 seconds
        if (_timeSinceEnter < _noBrakeTime) then {
            private _maintainSpeed = _veh getVariable ["EAD_bridgeSpeed", _spd];
            _spd = _maintainSpeed max _spd; // Use higher of current or maintained speed
            _veh setVariable ["EAD_onBridge", true];
            _veh setVariable ["EAD_bridgeNoBrake", true]; // Flag to prevent braking
        } else {
            _veh setVariable ["EAD_bridgeNoBrake", false];
        };

    } else {
        // Exited bridge
        _veh setVariable ["EAD_bridgeEnterTime", 0];
        _veh setVariable ["EAD_onBridge", false];
        _veh setVariable ["EAD_bridgeNoBrake", false];
    };

    _spd
};

EAD_fnc_emergencyBrake = {
    params ["_veh","_s","_profile"];

    // ✅ DISABLE emergency brake if on bridge in no-brake period
    if (_veh getVariable ["EAD_bridgeNoBrake", false]) exitWith {false};

    private _spd = speed _veh;
    private _f0 = _s get "F0";
    private _t = EAD_CFG get "EMERGENCY_BRAKE_DIST";

    if (_profile get "brute") then {_t = _t * 0.6};

    if (_f0 < _t && _spd > 40) then { // ✅ Only brake at higher speeds
        _veh setVelocity [0,0,0];
        true
    } else {
        false
    }
};

/* =====================================================================================
    SECTION 5 — PATH SELECTION with APEX
===================================================================================== */

EAD_fnc_pathBias = {
    params ["_s","_dir","_veh"];

    private _cand = [
        ["F0",0,_s get "F0"],
        ["FL1",8,_s get "FL1"],
        ["FR1",-8,_s get "FR1"],
        ["FL2",16,_s get "FL2"],
        ["FR2",-16,_s get "FR2"],
        ["FL3",25,_s get "FL3"],
        ["FR3",-25,_s get "FR3"]
    ];

    // ✅ Strong preference for straight ahead
    {
        if ((_x#0) == "F0") then {_x set [2, (_x#2)*1.2]}; // Was 1.15
    } forEach _cand;

    _cand sort false;
    private _best = _cand#0;

    private _ang = _best#1;
    private _dist = _best#2;

    // ✅ APEX ADJUSTMENT
    private _curveType = [_s] call EAD_fnc_detectCurveType;
    private _apexAngle = [_veh, _s, _curveType] call EAD_fnc_calculateApex;

    if (_apexAngle != 0) then {
        _ang = _ang + _apexAngle;
        _veh setVariable ["EAD_onApex", true];
    } else {
        _veh setVariable ["EAD_onApex", false];
    };

    private _urg = 1 - (_dist / (EAD_CFG get "DIST_MAIN"));
    _urg = _urg max 0;

    -_ang * (0.8 + _urg * 1.2)
};

EAD_fnc_driftBias = {
    params ["_veh"];

    private _vel = velocity _veh;
    private _spd = speed _veh;
    if (_spd < 5) exitWith {0};

    private _dir = getDir _veh;
    private _dirVec = [sin _dir, cos _dir, 0];
    private _velN = vectorNormalized _vel;

    private _dot = _dirVec vectorDotProduct _velN;
    private _dotClamped = _dot max -1 min 1;
    private _ang = acos _dotClamped;

    if (_ang < 0.25) exitWith {0};

    private _right = vectorSide _veh;
    private _lat = _velN vectorDotProduct _right;

    -_lat * 0.11
};

EAD_fnc_convoySpeed = {
    params ["_veh","_spd"];

    private _drv = driver _veh;
    if (isNull _drv) exitWith {_spd};

    private _grp = group _drv;
    private _units = units _grp;
    if (count _units < 2) exitWith {_spd};

    private _now = time;
    private _last = _veh getVariable ["EAD_convoyListTime",0];
    private _list = _veh getVariable ["EAD_convoyList",[]];

    if ((_now - _last) > 1) then {
        _list = [];

        {
            private _v = vehicle _x;
            if (_v != _x && alive _v && !isNull driver _v) then {
                _list pushBackUnique _v;
            };
        } forEach _units;

        _veh setVariable ["EAD_convoyList",_list];
        _veh setVariable ["EAD_convoyListTime",_now];
    };

    if (count _list < 2) exitWith {_spd};

    private _idx = _list find _veh;
    if (_idx < 0) exitWith {_spd};
    if (_idx == 0) exitWith {_spd};

    private _lead = _list select (_idx - 1);
    if (isNull _lead) exitWith {_spd};

    private _dist = _veh distance2D _lead;
    private _ls = speed _lead;

    if (_dist > 80) exitWith {_ls * 1.25}; // ✅ Faster catch-up
    if (_dist < 30) exitWith {_spd * 0.75};

    if (_dist >= 40 && _dist <= 60) exitWith {_ls max 20}; // ✅ Higher minimum

    _spd
};

/* =====================================================================================
    SECTION 6 — STUCK LOGIC (FASTER)
===================================================================================== */

EAD_fnc_stuck = {
    params ["_veh","_s","_spd"];

    private _now = time;
    private _st = _veh getVariable ["EAD_stuckTime",0];
    private _revUntil = _veh getVariable ["EAD_reverseUntil",0];
    private _lastEnd = _veh getVariable ["EAD_lastReverseEnd",0];

    if (_now < _revUntil) exitWith {
        private _dir = getDir _veh + 180;
        private _revMS = -((EAD_CFG get "REVERSE_SPEED_KMH")/3.6);
        private _vec = [sin _dir, cos _dir, 0] vectorMultiply _revMS;
        _veh setVelocity _vec;
        30
    };

    if (_revUntil > 0) then {
        _veh setVariable ["EAD_reverseUntil",0];
        _veh setVariable ["EAD_stuckTime",0];
        _veh setVariable ["EAD_lastReverseEnd",_now];
    };

    if ((_now - _lastEnd) < 2.5) exitWith {_spd}; // ✅ Shorter cooldown

    private _fv = _s get "F0";
    private _v = speed _veh;

    if (_v < (EAD_CFG get "STUCK_SPEED") && _fv < 12 && _spd > 40) then {
        if (_st == 0) then {
            _veh setVariable ["EAD_stuckTime",_now];
        } else {
            if ((_now - _st) > (EAD_CFG get "STUCK_TIME")) then {
                _veh setVariable ["EAD_reverseUntil", _now + (EAD_CFG get "REVERSE_TIME")];
            };
        };
    } else {
        _veh setVariable ["EAD_stuckTime",0];
    };

    _spd
};

/* =====================================================================================
    SECTION 7 — VECTOR DRIVE
===================================================================================== */

EAD_fnc_vectorDrive = {
    params ["_veh","_s","_tSpd","_profile"];

    private _dir = getDir _veh;

    private _center = ((_s get "L") - (_s get "R")) * 0.004;
    _center = _center + (((_s get "CL") - (_s get "CR")) * 0.0015);

    private _path = [_s,_dir,_veh] call EAD_fnc_pathBias;
    private _pathAdj = _path * 0.018;

    private _drift = [_veh] call EAD_fnc_driftBias;

    private _near = 0;
    if ((_s get "NL") < 8) then {_near = _near + 0.03};
    if ((_s get "NR") < 8) then {_near = _near - 0.03};

    private _bias = _center + _pathAdj + _drift + _near;
    _bias = _bias max -0.25 min 0.25;

    private _newDir = _dir + (_bias * 55);
    _veh setDir _newDir;

    private _ms = _tSpd / 3.6;
    private _vel = velocity _veh;

    private _vert = _vel#2;
    if (abs _vert > 5) then {_vert = _vert * 0.8};

    private _newVel = [sin _newDir, cos _newDir, 0] vectorMultiply _ms;
    _newVel set [2, _vert max -10];

    _veh setVelocity _newVel;
    _veh limitSpeed _tSpd;

    if (EAD_CFG get "DEBUG_ENABLED") then {
        [_veh,_s,_tSpd,_profile] call EAD_fnc_debugDraw;
    };
};

EAD_fnc_debugDraw = {
    params ["_veh","_s","_t","_profile"];

    if !(EAD_CFG get "DEBUG_ENABLED") exitWith {};

    private _pos = getPosASL _veh;
    _pos set [2, (_pos#2)+1.5];

    if (EAD_CFG get "DEBUG_DRAW_TEXT") then {
        private _txtPos = _pos vectorAdd [0,0,1.5];
        private _curveType = [_s] call EAD_fnc_detectCurveType;
        private _onApex = _veh getVariable ["EAD_onApex", false];
        private _onBridge = _veh getVariable ["EAD_onBridge", false];

        private _txt = format [
            "%1 | T:%2 A:%3 | %4%5%6",
            _profile get "role",
            round _t,
            round speed _veh,
            _curveType,
            if (_onApex) then {" APEX"} else {""},
            if (_onBridge) then {" BRIDGE"} else {""}
        ];

        drawIcon3D [
            "",
            [1,1,1,1],
            _txtPos,
            0,0,0,
            _txt,
            1,
            0.03,
            "PuristaMedium",
            "center"
        ];
    };
};

/* =====================================================================================
    SECTION 8 — DRIVER LOOP
===================================================================================== */

EAD_fnc_runDriver = {
    params ["_unit","_veh"];

    private _localEH = _veh addEventHandler ["Local", {
        params ["_veh","_isLocal"];
        if (!_isLocal) then {
            _veh setVariable ["EAD_active",false];
        };
    }];

    private _killedEH = _veh addEventHandler ["Killed", {
        (_this select 0) setVariable ["EAD_active",false];
    }];

    while {
        alive _unit &&
        alive _veh &&
        driver _veh isEqualTo _unit &&
        local _veh &&
        (_veh getVariable ["EAD_active",false])
    } do {

        private _t0 = diag_tickTime;

        private _profile = _veh getVariable "EAD_profile";
        if (isNil "_profile") then {
            _profile = [_veh] call EAD_fnc_getProfile;
            _veh setVariable ["EAD_profile",_profile];
        };

        private _scan = [_veh] call EAD_fnc_scanAdaptive;
        private _terrain = [_veh] call EAD_fnc_terrainInfo;

        private _spd = [_veh,_scan,_terrain,_profile] call EAD_fnc_speedBrain;

        if ([_veh,_scan,_profile] call EAD_fnc_emergencyBrake) then {
            uiSleep (EAD_CFG get "TICK");
            continue;
        };

        _spd = [_veh,_scan,_spd] call EAD_fnc_obstacleLimit;
        _spd = [_veh,_spd] call EAD_fnc_applyBridgeMode;
        _spd = [_veh,_scan,_spd] call EAD_fnc_stuck;
        _spd = [_veh,_spd] call EAD_fnc_convoySpeed;
        _spd = [_veh,_spd,_terrain] call EAD_fnc_altitudeCorrection;

        [_veh,_scan,_spd,_profile] call EAD_fnc_vectorDrive;

        private _dt = diag_tickTime - _t0;

        private _avg = EAD_Stats get "avgTickTime";
        EAD_Stats set ["avgTickTime", (_avg * 0.99) + (_dt * 0.01)];

        private _max = EAD_Stats get "maxTickTime";
        if (_dt > _max) then {EAD_Stats set ["maxTickTime", _dt]};

        uiSleep (EAD_CFG get "TICK");
    };

    _veh removeEventHandler ["Local",_localEH];
    _veh removeEventHandler ["Killed",_killedEH];

    {
        _veh setVariable [_x,nil];
    } forEach [
        "EAD_active","EAD_stuckTime","EAD_reverseUntil","EAD_profile",
        "EAD_onBridge","EAD_bridgeEnterTime","EAD_bridgeSpeed","EAD_bridgeNoBrake",
        "EAD_onApex","EAD_convoyList","EAD_convoyListTime","EAD_treeDense",
        "EAD_treeCheckTime","EAD_lastReverseEnd"
    ];

    private _idx = EAD_TrackedVehicles find _veh;
    if (_idx >= 0) then {
        EAD_TrackedVehicles deleteAt _idx;
        EAD_Stats set ["totalVehicles", count EAD_TrackedVehicles];
    };
};

EAD_fnc_registerDriver = {
    params ["_unit","_veh"];

    if (!alive _veh || isNull _unit) exitWith {};
    if (!(_veh isKindOf "LandVehicle")) exitWith {};
    if (isPlayer _unit) exitWith {};
    if (!local _veh) exitWith {};

    if (_veh getVariable ["EAID_Ignore", false]) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD 9.0] Skipping %1 - EAID_Ignore flag", typeOf _veh];
        };
    };

    if (_veh getVariable ["EAD_active",false]) exitWith {};

    _veh setVariable ["EAD_active",true];

    EAD_TrackedVehicles pushBackUnique _veh;
    EAD_Stats set ["totalVehicles", count EAD_TrackedVehicles];

    private _profile = [_veh] call EAD_fnc_getProfile;
    _veh setVariable ["EAD_profile",_profile];

    private _role = _profile get "role";
    private _c = EAD_VehicleTypes get _role;
    if (isNil "_c") then {_c = 0};
    EAD_VehicleTypes set [_role, _c + 1];

    [_unit,_veh] spawn EAD_fnc_runDriver;
};

/* =====================================================================================
    SECTION 9 — AUTO-DETECTION
===================================================================================== */

[] spawn {
    private _map = createHashMap;
    while {true} do {
        {
            private _veh = _x;
            private _key = netId _veh;
            private _drv = driver _veh;

            if (!isNull _drv && alive _drv && !isPlayer _drv) then {

                private _last = _map get _key;
                if (isNil "_last") then {_last = objNull};

                if (_drv != _last || !(_veh getVariable ["EAD_active",false])) then {
                    _map set [_key, _drv];
                    [_drv, _veh] call EAD_fnc_registerDriver;
                };
            } else {
                _map deleteAt _key;
            };
        } forEach vehicles;

        uiSleep 2.5; // ✅ FASTER polling
    };
};

/* =====================================================================================
    SECTION 10 — PERF LOG
===================================================================================== */

[] spawn {
    while {true} do {
        uiSleep 600;

        private _tot = EAD_Stats get "totalVehicles";
        private _avg = (EAD_Stats get "avgTickTime") * 1000;
        private _max = (EAD_Stats get "maxTickTime") * 1000;

        diag_log format [
            "[EAD 9.0 PERFORMANCE] Vehicles:%1 | Avg:%2ms | Max:%3ms | APEX+4-HEIGHT+TOP-DOWN",
            _tot,
            _avg toFixed 2,
            _max toFixed 2
        ];

        EAD_Stats set ["maxTickTime",0];
    };
};

diag_log "======================================================";
diag_log "[EAD 9.0 PERFORMANCE] INITIALIZED";
diag_log "[EAD 9.0] ✅ Maximum speed optimization";
diag_log "[EAD 9.0] ✅ Apex curve cutting enabled";
diag_log "[EAD 9.0] ✅ 4-height forward raycasting";
diag_log "[EAD 9.0] ✅ Top-down obstacle detection";
diag_log "[EAD 9.0] ✅ Smart curve detection (gentle/sharp)";
diag_log "[EAD 9.0] ✅ Aggressive bridge mode (4s no-brake)";
diag_log "[EAD 9.0] ✅ Expanded cone forward (15 rays)";
diag_log "======================================================";

/* =====================================================================================
    END OF FILE
===================================================================================== */
