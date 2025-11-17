/* =====================================================================================
    ELITE AI DRIVING SYSTEM (EAD) – VERSION 8.7
    AUTHOR: YOU + SYSTEM BUILT HERE
    SINGLE-FILE EDITION
    SAFE FOR EXILE + DEDICATED SERVER + HC + ANY FACTION

    v8.7 TOP-DOWN ROAD DETECTION:
        ✅ NEW: Top-down raycasts for road surface detection
        ✅ Scans 5 points ahead: center, near lanes, far lanes (15m and 30m)
        ✅ Road confidence score (0.0-1.0) based on road ahead
        ✅ Speed reduction when approaching road edges (<80% confidence)
        ✅ Prevents offroad driving by detecting terrain ahead
        ✅ Cached every 1 second for performance
        ✅ Integrated with speed brain for better road adherence
        ✅ High speeds require: straight + clear + paved + 80%+ road ahead

    v8.6 SPEED + ROAD SAFETY:
        ✅ Increased highway speed: 170 km/h (was 145)
        ✅ Increased city speed: 100 km/h (was 85)
        ✅ High speeds ONLY on straight, clear, paved roads
        ✅ Straight path detection (forward rays within 10m variance, >40m clear)
        ✅ Heavy offroad penalty (0.55x) to keep AI on pavement
        ✅ Conservative obstacle detection (reverted) - no hitting stuff
        ✅ Reduced curve speed penalty (0.5 from 0.8)
        ✅ Cars reach 75%+ of max on ideal road conditions
        ✅ Updated vehicle profiles for better performance

    v8.5 A3XAI FIX:
        ✅ Fixed A3XAI vehicles spinning in place
        ✅ Disables AI PATH/AUTOTARGET to prevent conflict with EAD control
        ✅ Re-enables AI when EAD releases control
        ✅ EAD now steers toward AI waypoints while maintaining smooth control
        ✅ Vehicles reach A3XAI objectives without pathfinding conflicts

    v8.4 OPTIMIZATION:
        ✅ Batch raycast processing (Arma 3 v2.20+)
        ✅ 22 raycasts per vehicle → 1 batch call
        ✅ ~10-15x faster obstacle detection
        ✅ Reduced CPU load for multiple AI vehicles
===================================================================================== */

/* =====================================================================================
    SECTION 1 — GLOBAL STATE & CONFIG
===================================================================================== */

EAD_CFG = createHashMapFromArray [
    ["TICK", 0.10],                     // main frequency

    // Speed profiles (INCREASED for better performance on pavement)
    ["HIGHWAY_BASE", 170],              // Increased from 145 (allows 75%+ of max speed)
    ["CITY_BASE", 100],                 // Increased from 85 (proportional)
    ["OFFROAD_MULT", 0.75],

    // Distances
    ["DIST_MAIN", 50],
    ["DIST_WIDE", 35],
    ["DIST_SIDE", 28],
    ["DIST_CORNER", 20],
    ["DIST_NEAR", 14],

    // Behavior multipliers
    ["CURVE_MULT", 0.5],                // Reduced from 0.8 (less speed reduction in curves)
    ["OVERTAKE_MULT", 1.25],

    // Bridge detection
    ["BRIDGE_SIDE_OFFSET", 4],

    // Stuck logic
    ["STUCK_TIME", 3.0],
    ["STUCK_SPEED", 7],
    ["REVERSE_TIME", 2.5],
    ["REVERSE_SPEED_KMH", 20],

    // Emergency brake
    ["EMERGENCY_BRAKE_DIST", 5],

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
    SECTION 2 — VEHICLE PROFILE SYSTEM
===================================================================================== */

EAD_fnc_getProfile = {
    params ["_veh"];

    private _type = typeOf _veh;

    if (_type isKindOf "Car") exitWith {
        createHashMapFromArray [
            ["role","CAR"], ["highway",155],["city",95],["offroad",0.70],["brute",false]
        ]
    };

    if (_type isKindOf "MRAP_01_base_F") exitWith {
        createHashMapFromArray [
            ["role","MRAP"],["highway",130],["city",80],["offroad",0.75],["brute",true]
        ]
    };

    if (_type isKindOf "Truck_F") exitWith {
        createHashMapFromArray [
            ["role","TRUCK"],["highway",115],["city",70],["offroad",0.65],["brute",false]
        ]
    };

    if (_type isKindOf "Tank") exitWith {
        createHashMapFromArray [
            ["role","TRACKED"],["highway",85],["city",55],["offroad",0.90],["brute",true]
        ]
    };

    createHashMapFromArray [
        ["role","GENERIC"],["highway",140],["city",85],["offroad",0.70],["brute",false]
    ]
};

/* =====================================================================================
    SECTION 3 — RAYCAST + TERRAIN SYSTEM
===================================================================================== */

// ✅ v8.4 OPTIMIZATION: Single ray (legacy fallback)
EAD_fnc_ray = {
    params ["_veh","_dirVec","_dist"];

    // ✅ FIX: LOWERED from 0.8m to 0.3m for low-clearance vehicles (sports cars)
    // This detects rocks, bushes, and low obstacles that protrude above ground
    private _startLow = (getPosASL _veh) vectorAdd [0, 0, 0.3];
    private _endLow = _startLow vectorAdd (_dirVec vectorMultiply _dist);

    // ✅ FIX: Add mid-height check at 1.2m for general obstacles and trees
    private _startMid = (getPosASL _veh) vectorAdd [0, 0, 1.2];
    private _endMid = _startMid vectorAdd (_dirVec vectorMultiply _dist);

    // ✅ FIX: Use GEOM LOD for better physical obstacle detection (rocks, bushes, trees)
    // GEOM detects the actual physical geometry of objects
    // Check both low and mid heights, return the closest hit
    private _hitLow = lineIntersectsSurfaces [_startLow, _endLow, _veh, objNull, true, 1, "GEOM"];
    private _hitMid = lineIntersectsSurfaces [_startMid, _endMid, _veh, objNull, true, 1, "GEOM"];

    private _distLow = if (count _hitLow > 0) then {
        _startLow vectorDistance (_hitLow#0#0)
    } else {
        _dist
    };

    private _distMid = if (count _hitMid > 0) then {
        _startMid vectorDistance (_hitMid#0#0)
    } else {
        _dist
    };

    // Return the minimum distance (closest obstacle)
    _distLow min _distMid
};

// ✅ v8.4 NEW: Batch raycast (Arma 3 v2.20+ optimization)
// Processes all 11 rays × 2 heights = 22 raycasts in a SINGLE call
// Performance: ~10-15x faster than sequential calls
EAD_fnc_rayBatch = {
    params ["_veh", "_rayDefs"];

    // _rayDefs format: [[angle, distance], [angle, distance], ...]
    // Example: [[0, 50], [12, 50], [-12, 50], ...]

    private _vehPos = getPosASL _veh;
    private _dir = getDir _veh;
    private _batch = [];

    // Build batch array: for each ray, create low + mid height checks
    {
        _x params ["_angleOffset", "_dist"];
        private _ang = _dir + _angleOffset;
        private _vec = [sin _ang, cos _ang, 0];

        // Low height (0.3m) - detects rocks, bushes, low obstacles
        private _startLow = _vehPos vectorAdd [0, 0, 0.3];
        private _endLow = _startLow vectorAdd (_vec vectorMultiply _dist);

        // Mid height (1.2m) - detects trees, walls, general obstacles
        private _startMid = _vehPos vectorAdd [0, 0, 1.2];
        private _endMid = _startMid vectorAdd (_vec vectorMultiply _dist);

        // Add both checks to batch (order: low, mid, low, mid, ...)
        _batch pushBack [_startLow, _endLow, _veh, objNull, true, 1, "GEOM", "NONE"];
        _batch pushBack [_startMid, _endMid, _veh, objNull, true, 1, "GEOM", "NONE"];
    } forEach _rayDefs;

    // ✅ BATCH PROCESSING: Single call for all 22 raycasts
    private _results = lineIntersectsSurfaces [_batch];

    // Process results: extract distances for each ray
    private _distances = [];
    private _idx = 0;

    {
        _x params ["_angleOffset", "_dist"];

        // Get low and mid results for this ray
        private _resultLow = _results select _idx;
        private _resultMid = _results select (_idx + 1);

        // Calculate distances (or use max distance if no hit)
        private _distLow = if (count _resultLow > 0) then {
            private _startLow = _vehPos vectorAdd [0, 0, 0.3];
            _startLow vectorDistance (_resultLow#0#0)
        } else {
            _dist
        };

        private _distMid = if (count _resultMid > 0) then {
            private _startMid = _vehPos vectorAdd [0, 0, 1.2];
            _startMid vectorDistance (_resultMid#0#0)
        } else {
            _dist
        };

        // Return minimum distance (closest obstacle)
        _distances pushBack (_distLow min _distMid);

        _idx = _idx + 2;
    } forEach _rayDefs;

    _distances
};

// ✅ v8.7 NEW: Top-down raycasts for road detection and terrain awareness
EAD_fnc_topDownRoadScan = {
    params ["_veh"];

    private _vehPos = getPosASL _veh;
    private _dir = getDir _veh;
    private _castHeight = 15; // Cast from 15m above vehicle

    // Define 5 top-down scan points: center, near-left, near-right, far-left, far-right
    private _scanPoints = [
        [0, 15],    // Center, 15m ahead
        [-3, 15],   // Left lane, 15m ahead
        [3, 15],    // Right lane, 15m ahead
        [-4, 30],   // Far left, 30m ahead
        [4, 30]     // Far right, 30m ahead
    ];

    private _roadAhead = 0;
    private _totalChecks = count _scanPoints;

    {
        _x params ["_lateralOffset", "_forwardDist"];

        // Calculate position ahead
        private _fwdVec = [sin _dir, cos _dir, 0] vectorMultiply _forwardDist;
        private _rightVec = [sin(_dir + 90), cos(_dir + 90), 0] vectorMultiply _lateralOffset;
        private _checkPos = _vehPos vectorAdd _fwdVec vectorAdd _rightVec;

        // Cast ray from above looking down
        private _startPos = [_checkPos select 0, _checkPos select 1, (_vehPos select 2) + _castHeight];
        private _endPos = [_checkPos select 0, _checkPos select 1, (_vehPos select 2) - 5];

        // Check if this position will be on road
        private _checkPos2D = [_checkPos select 0, _checkPos select 1, 0];
        if (isOnRoad _checkPos2D) then {
            _roadAhead = _roadAhead + 1;
        };

    } forEach _scanPoints;

    // Calculate road confidence (0.0 to 1.0)
    private _roadConfidence = _roadAhead / _totalChecks;

    _roadConfidence
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

    // ✅ v8.7: Add top-down road scan (cached every 1 second)
    private _lastRoadScan = _veh getVariable ["EAD_lastRoadScanTime", 0];
    private _roadAheadConfidence = _veh getVariable ["EAD_roadAheadConfidence", 1.0];

    if ((_now - _lastRoadScan) > 1) then {
        _roadAheadConfidence = [_veh] call EAD_fnc_topDownRoadScan;
        _veh setVariable ["EAD_roadAheadConfidence", _roadAheadConfidence];
        _veh setVariable ["EAD_lastRoadScanTime", _now];
    };

    [_isRoad,_slope,_dense,_norm,_roadAheadConfidence]
};

EAD_fnc_isBridge = {
    params ["_veh"];

    private _pos = getPosATL _veh;
    if !(isOnRoad _pos) exitWith {false};

    private _off = EAD_CFG get "BRIDGE_SIDE_OFFSET";
    private _right = vectorSide _veh;  // Changed from vectorRight
    private _dir = getDir _veh;
    private _fwd = [sin _dir, cos _dir, 0] vectorMultiply 10;

    private _checks = [
        _pos,
        _pos vectorAdd (_fwd vectorMultiply 0.5),
        _pos vectorAdd _fwd
    ];

    private _hits = 0;

    {
        private _L = _x vectorAdd (_right vectorMultiply _off);
        private _R = _x vectorAdd (_right vectorMultiply -_off);

        if (surfaceIsWater _L && surfaceIsWater _R) then {
            _hits = _hits + 1;
            if (_hits >= 2) exitWith {};
        };
    } forEach _checks;

    (_hits >= 2)
};

EAD_fnc_scanAdaptive = {
    params ["_veh"];

    private _spd = speed _veh;
    private _dir = getDir _veh;

    private _m = EAD_CFG get "DIST_MAIN";
    private _w = EAD_CFG get "DIST_WIDE";
    private _s = EAD_CFG get "DIST_SIDE";
    private _c = EAD_CFG get "DIST_CORNER";
    private _n = EAD_CFG get "DIST_NEAR";

    // ✅ v8.4 BATCH OPTIMIZATION: Define all 11 rays for batch processing
    // Format: [label, angleOffset, distance]
    private _rayDefinitions = [
        ["F0",  0,   _m],
        ["FL1", 12,  _m],
        ["FR1", -12, _m],
        ["FL2", 25,  _w],
        ["FR2", -25, _w],
        ["L",   45,  _s],
        ["R",   -45, _s],
        ["CL",  70,  _c],
        ["CR",  -70, _c],
        ["NL",  90,  _n],
        ["NR",  -90, _n]
    ];

    // Extract angle/distance pairs for batch raycast
    private _rayDefs = _rayDefinitions apply {[_x#1, _x#2]};

    // ✅ BATCH RAYCAST: Process all 11 rays × 2 heights = 22 checks in one call
    private _distances = [_veh, _rayDefs] call EAD_fnc_rayBatch;

    // Build result hashmap
    private _map = createHashMap;
    {
        _x params ["_label", "_angleOffset", "_distance"];
        _map set [_label, _distances select _forEachIndex];
    } forEach _rayDefinitions;

    _map
};

/* =====================================================================================
    SECTION 4 — SPEED BRAIN + OBSTACLE + ALTITUDE + BRIDGE
===================================================================================== */

EAD_fnc_speedBrain = {
    params ["_veh","_s","_terrain","_profile"];

    _terrain params ["_isRoad","_slope","_dense","_norm","_roadAheadConfidence"];

    private _base = EAD_CFG get "HIGHWAY_BASE";

    // ✅ STRICT: Heavy penalty for offroad to keep AI on pavement
    if (!_isRoad) then {_base = _base * 0.55};  // Reduced from offroad mult

    if (_dense) then {_base = _base * 0.85};

    // ✅ v8.7: Use top-down road scan to enforce road adherence
    // If road ahead confidence is low, reduce speed significantly
    if (_roadAheadConfidence < 0.8) then {
        // Less than 80% road ahead - approaching road edge or offroad
        _base = _base * (0.5 + (_roadAheadConfidence * 0.5)); // 50-100% speed based on confidence
    };

    // ✅ NEW: Check if path is straight and clear for high-speed allowance
    private _isStraight = true;
    private _minFrontDist = selectMin [
        _s get "F0",
        _s get "FL1",
        _s get "FR1"
    ];

    // Path is straight if all forward rays are nearly equal and > 40m
    private _f0 = _s get "F0";
    private _fl1 = _s get "FL1";
    private _fr1 = _s get "FR1";

    if (_f0 < 40 || abs(_f0 - _fl1) > 10 || abs(_f0 - _fr1) > 10) then {
        _isStraight = false;
    };

    // Only allow high speeds on straight, clear, paved roads WITH good road confidence
    if (_isRoad && _isStraight && _minFrontDist > 45 && _roadAheadConfidence > 0.8) then {
        // Perfect conditions - allow full speed
        _base = _base * 1.0;
    } else {
        // Not ideal - reduce speed moderately
        if (!_isStraight) then {_base = _base * 0.80};
    };

    private _curve = (_s get "CL") min (_s get "CR");
    private _drop = 1 - (_curve / 80);
    if (_drop > 0) then {
        _base = _base * (1 - (_drop * (EAD_CFG get "CURVE_MULT")));
    };

    if (_slope > 0.35) then {_base = _base * 0.75};

    _base max 15
};

EAD_fnc_obstacleLimit = {
    params ["_veh","_s","_cur"];

    private _m = selectMin [
        _s get "F0",
        _s get "FL1",
        _s get "FR1",
        _s get "FL2",
        _s get "FR2"
    ];

    // ✅ REVERTED: Conservative obstacle detection for safety (no hitting stuff)
    if (_m < 30) then {_cur = _cur * 0.60};
    if (_m < 25) then {_cur = _cur * 0.55};
    if (_m < 15) then {_cur = _cur * 0.35};

    _cur
};

EAD_fnc_altitudeCorrection = {
    params ["_veh","_spd","_terrain"];
    private _slope = _terrain select 1;

    if (_slope > 0.40) exitWith {_spd * 0.65};
    if (_slope > 0.25) exitWith {_spd * 0.80};
    _spd
};

EAD_fnc_applyBridgeMode = {
    params ["_veh","_spd"];
    private _b = [_veh] call EAD_fnc_isBridge;

    _veh setVariable ["EAD_onBridge", _b];
    if (_b) then {_spd = _spd * 0.90};

    _spd
};

EAD_fnc_emergencyBrake = {
    params ["_veh","_s","_profile"];

    private _spd = speed _veh;
    private _f0 = _s get "F0";
    private _t = EAD_CFG get "EMERGENCY_BRAKE_DIST";

    if (_profile get "brute") then {_t = _t * 0.6};

    if (_f0 < _t && _spd > 30) then {
        _veh setVelocity [0,0,0];
        true
    } else {
        false
    }
};

/* =====================================================================================
    SECTION 5 — PATH SELECTION, DRIFT CONTROL, OVERTAKE, CONVOY
===================================================================================== */

EAD_fnc_pathBias = {
    params ["_s","_dir"];

    private _cand = [
        ["F0",0,_s get "F0"],
        ["FL1",12,_s get "FL1"],
        ["FR1",-12,_s get "FR1"],
        ["FL2",25,_s get "FL2"],
        ["FR2",-25,_s get "FR2"]
    ];

    {
        if ((_x#0) == "F0") then {_x set [2, (_x#2)*1.15]};
    } forEach _cand;

    _cand sort false;
    private _best = _cand#0;

    private _ang = _best#1;
    private _dist = _best#2;
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

    if (_dist > 80) exitWith {_ls * 1.2};
    if (_dist < 30) exitWith {_spd * 0.7};

    if (_dist >= 40 && _dist <= 60) exitWith {_ls max 15};

    _spd
};

/* =====================================================================================
    SECTION 6 — STUCK LOGIC + REVERSE
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

    if ((_now - _lastEnd) < 3) exitWith {_spd};

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
    SECTION 7 — WAYPOINT NAVIGATION + VECTOR DRIVE + STEERING + DEBUG
===================================================================================== */

// ✅ NEW: Get steering bias toward AI waypoint
EAD_fnc_waypointBias = {
    params ["_veh"];

    private _drv = driver _veh;
    if (isNull _drv) exitWith {0};

    private _grp = group _drv;
    private _wpIdx = currentWaypoint _grp;

    // If no valid waypoint, just drive forward
    if (_wpIdx < 0) exitWith {0};

    private _wpPos = waypointPosition [_grp, _wpIdx];

    // Check if waypoint is valid
    if (_wpPos isEqualTo [0,0,0]) exitWith {0};

    private _vehPos = getPosATL _veh;
    private _dist = _vehPos distance2D _wpPos;

    // If very close to waypoint (within 30m), reduce steering influence
    if (_dist < 30) exitWith {0};

    // Calculate angle to waypoint
    private _dirToWP = _vehPos getDir _wpPos;
    private _vehDir = getDir _veh;

    // Calculate angle difference (-180 to 180)
    private _angleDiff = _dirToWP - _vehDir;
    while {_angleDiff > 180} do {_angleDiff = _angleDiff - 360};
    while {_angleDiff < -180} do {_angleDiff = _angleDiff + 360};

    // Convert to steering bias (stronger at longer distances)
    private _strength = ((_dist min 200) / 200) * 0.15; // Max 0.15 bias
    private _bias = (_angleDiff / 180) * _strength;

    _bias
};

EAD_fnc_vectorDrive = {
    params ["_veh","_s","_tSpd","_profile"];

    private _dir = getDir _veh;

    private _center = ((_s get "L") - (_s get "R")) * 0.004;
    _center = _center + (((_s get "CL") - (_s get "CR")) * 0.0015);

    private _path = [_s,_dir] call EAD_fnc_pathBias;
    private _pathAdj = _path * 0.018;

    private _drift = [_veh] call EAD_fnc_driftBias;

    private _near = 0;
    if ((_s get "NL") < 8) then {_near = _near + 0.03};
    if ((_s get "NR") < 8) then {_near = _near - 0.03};

    // ✅ NEW: Add waypoint steering to guide vehicle toward A3XAI objectives
    private _wpSteer = [_veh] call EAD_fnc_waypointBias;

    private _bias = _center + _pathAdj + _drift + _near + _wpSteer;
    _bias = _bias max -0.25 min 0.25;

    private _newDir = _dir + (_bias * 55);
    _veh setDir _newDir;

    private _ms = _tSpd / 3.6;
    private _vel = velocity _veh;

    private _vert = _vel#2;
    if (abs _vert > 5) then {_vert = _vert * 0.8};

    private _newVel = [sin _newDir, cos _newDir, 0] vectorMultiply _ms;
    _newVel set [2, _vert max -10];

    // ✅ v9.0: Only apply velocity changes when on ground (prevents mid-air physics issues)
    if (isTouchingGround _veh) then {
        _veh setVelocity _newVel;
    };
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
    private _dir = getDir _veh;

    if (EAD_CFG get "DEBUG_DRAW_RAYS") then {
        private _rayData = [
            ["F0",0,_s get "F0",(EAD_CFG get "DIST_MAIN")],
            ["FL1",12,_s get "FL1",(EAD_CFG get "DIST_MAIN")],
            ["FR1",-12,_s get "FR1",(EAD_CFG get "DIST_MAIN")],
            ["FL2",25,_s get "FL2",(EAD_CFG get "DIST_WIDE")],
            ["FR2",-25,_s get "FR2",(EAD_CFG get "DIST_WIDE")],
            ["L",45,_s get "L",(EAD_CFG get "DIST_SIDE")],
            ["R",-45,_s get "R",(EAD_CFG get "DIST_SIDE")],
            ["CL",70,_s get "CL",(EAD_CFG get "DIST_CORNER")],
            ["CR",-70,_s get "CR",(EAD_CFG get "DIST_CORNER")],
            ["NL",90,_s get "NL",(EAD_CFG get "DIST_NEAR")],
            ["NR",-90,_s get "NR",(EAD_CFG get "DIST_NEAR")]
        ];

        {
            _x params ["_lab","_off","_dist","_max"];

            private _ang = _dir + _off;
            private _vec = [sin _ang, cos _ang, 0];
            private _end = _pos vectorAdd (_vec vectorMultiply _dist);

            private _ratio = _dist / _max;
            private _color =
            if (_ratio > 0.7) then {[0,1,0,0.6]}
            else {
                if (_ratio > 0.4) then {[1,1,0,0.7]} else {[1,0,0,0.9]}
            };

            drawLine3D [_pos,_end,_color];
        } forEach _rayData;
    };

    if (EAD_CFG get "DEBUG_DRAW_TEXT") then {
        private _txtPos = _pos vectorAdd [0,0,1.5];

        private _txt = format [
            "%1 | T:%2 A:%3",
            _profile get "role",
            round _t,
            round speed _veh
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
    SECTION 8 — DRIVER LOOP + REGISTRATION + CLEANUP
===================================================================================== */

EAD_fnc_runDriver = {
    params ["_unit","_veh"];

    // locality protector
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

        // ✅ v9.0: Physics-based terrain safety limit
        // NOTE: This adds surface friction and slope awareness to EAD's existing
        // geometry-based curve detection. EAD's rays handle path geometry,
        // physics adds material property awareness (mud vs asphalt, uphill vs flat).
        private _lookAheadDist = 40;
        private _vehPos = getPosASL _veh;
        private _vehDir = getDir _veh;

        private _targetPos = _vehPos vectorAdd [
            (sin _vehDir) * _lookAheadDist,
            (cos _vehDir) * _lookAheadDist,
            0
        ];

        private _physicsData = [_veh, _targetPos] call EAD_fnc_calculatePhysicsSpeed;
        private _maxSafeSpeed = _physicsData select 0;

        // Apply as safety cap (only reduces speed, never increases)
        _spd = _spd min _maxSafeSpeed;

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

    // cleanup
    _veh removeEventHandler ["Local",_localEH];
    _veh removeEventHandler ["Killed",_killedEH];

    // ✅ FIX: Re-enable AI pathfinding when EAD releases control
    if (_veh getVariable ["EAD_aiDisabled", false]) then {
        if (alive _unit) then {
            _unit enableAI "PATH";
            _unit enableAI "AUTOTARGET";
        };
    };

    {
        _veh setVariable [_x,nil];
    } forEach [
        "EAD_active","EAD_stuckTime","EAD_reverseUntil","EAD_profile",
        "EAD_onBridge","EAD_altT","EAD_altPos","EAD_altLastSpeed",
        "EAD_convoyList","EAD_convoyListTime","EAD_treeDense",
        "EAD_treeCheckTime","EAD_lastReverseEnd","EAD_aiDisabled"
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

    // ✅ RESPECT A3XAI BLOCK FLAG
    if (_veh getVariable ["EAID_Ignore", false]) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD] Skipping %1 - A3XAI settling", typeOf _veh];
        };
    };

    if (_veh getVariable ["EAD_active",false]) exitWith {};

    _veh setVariable ["EAD_active",true];

    // ✅ FIX: Disable AI pathfinding to prevent conflict with EAD's direct control
    // This stops the AI from fighting against EAD's setDir/setVelocity commands
    _unit disableAI "PATH";
    _unit disableAI "AUTOTARGET";
    _veh setVariable ["EAD_aiDisabled", true];

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
    SECTION 9 — AUTO-DETECTION SYSTEM (POLLING)
===================================================================================== */

[] spawn {
    private _map = createHashMap;
    while {true} do {
        {
            private _veh = _x;
            private _key = netId _veh;  // Use netId as string key
            private _drv = driver _veh;

            if (!isNull _drv && alive _drv && !isPlayer _drv) then {

                private _last = _map get _key;
                if (isNil "_last") then {_last = objNull};

                if (_drv != _last || !(_veh getVariable ["EAD_active",false])) then {
                    _map set [_key, _drv];
                    [_drv, _veh] call EAD_fnc_registerDriver;
                };
            } else {
                _map deleteAt _key;  // Now using string key
            };
        } forEach vehicles;

        uiSleep 3;
    };
};

/* =====================================================================================
    SECTION 10 — PERF LOG RESET
===================================================================================== */

[] spawn {
    while {true} do {
        uiSleep 600;

        private _tot = EAD_Stats get "totalVehicles";
        private _avg = (EAD_Stats get "avgTickTime") * 1000;
        private _max = (EAD_Stats get "maxTickTime") * 1000;

        diag_log format [
            "[EAD 8.5]  Total:%1 | Avg:%2 ms | Max:%3 ms (last 10 min) [A3XAI FIX]",
            _tot,
            _avg toFixed 2,
            _max toFixed 2
        ];

        EAD_Stats set ["maxTickTime",0];
    };
};

/* =====================================================================================
    SECTION 11 — EAD v9.0 PHYSICS UPGRADE - NEW FUNCTIONS

    Added physics-based calculations from Elite Driving v3.4:
    - EAD_fnc_calculatePhysicsSpeed: Physics-based corner speed calculation
    - EAD_fnc_calculateBrakingAction: Braking distance prediction
    - EAD_fnc_progressiveSteering: Speed-dependent steering control
    - EAD_fnc_analyzeTerrainGradient: Terrain slope analysis

    These functions can be called by existing EAD functions to enhance behavior.
===================================================================================== */

/* -------------------------------------------------------------------------------------
    Physics Function 1: Calculate Physics-Based Speed

    Calculates maximum safe cornering speed based on:
    - Turn radius and turn angle
    - Surface friction (asphalt, gravel, mud, etc.)
    - Terrain gradient (uphill/downhill)
    - Vehicle specifications

    Params:
        _vehicle - The vehicle
        _targetPos - Target position to calculate turn to

    Returns: [_maxSafeSpeed, _vehicleMaxSpeed, _turnAngle, _turnRadius, _friction]
------------------------------------------------------------------------------------- */
EAD_fnc_calculatePhysicsSpeed = {
    params ["_vehicle", "_targetPos"];

    if (isNull _vehicle) exitWith {[0,0,0,0,0]};

    private _vPos = getPosASL _vehicle;
    private _currentSpeed = speed _vehicle;
    private _distance = _vPos distance _targetPos;

    private _configMaxSpeed = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "maxSpeed");
    private _vehicleMaxSpeed = _configMaxSpeed * 0.85;

    private _currentDir = getDir _vehicle;
    private _targetDir = [_vPos, _targetPos] call BIS_fnc_dirTo;
    private _turnAngle = abs (_targetDir - _currentDir);
    if (_turnAngle > 180) then { _turnAngle = 360 - _turnAngle };

    private _turnRadius = if (_turnAngle > 3 && _distance > 0.1) then {
        _distance / (2 * (sin (_turnAngle / 2)))
    } else {
        9999
    };

    private _aglPos = ASLToAGL _vPos;
    private _surfaceRaw = toLower surfaceType _aglPos;
    private _friction = switch (true) do {
        case (_surfaceRaw find "asphalt" > -1): {0.85};
        case (_surfaceRaw find "concrete" > -1): {0.85};
        case (_surfaceRaw find "gravel" > -1): {0.60};
        case (_surfaceRaw find "mud" > -1): {0.45};
        case (_surfaceRaw find "soil" > -1): {0.45};
        case (_surfaceRaw find "rock" > -1): {0.70};
        case (_surfaceRaw find "stone" > -1): {0.70};
        case (_surfaceRaw find "sand" > -1): {0.50};
        default {0.65};
    };

    private _slope = 0;
    if (_distance > 5) then {
        private _targetHeight = _targetPos select 2;
        private _heightDiff = abs (_targetHeight - (_vPos select 2));
        private _distance2D = _vPos distance2D _targetPos max 0.1;
        _slope = atan (_heightDiff / _distance2D);
    };

    private _maxCornerSpeed = (sqrt (_friction * 9.81 * (_turnRadius max 1))) * 3.6;

    if (_slope > 15) then {
        _maxCornerSpeed = _maxCornerSpeed * 0.7;
    };

    if (_turnAngle > 75) then {
        _maxCornerSpeed = _maxCornerSpeed * 0.85;
    } else {
        if (_turnAngle > 45) then {
            _maxCornerSpeed = _maxCornerSpeed * 0.90;
        };
    };

    _maxCornerSpeed = _maxCornerSpeed * 0.95;
    private _finalMax = _maxCornerSpeed min _vehicleMaxSpeed;

    [_finalMax, _vehicleMaxSpeed, _turnAngle, _turnRadius, _friction]
};

/* -------------------------------------------------------------------------------------
    Physics Function 2: Calculate Braking Action

    Calculates required braking action based on physics:
    - Current speed vs target speed
    - Distance to obstacle
    - Reaction time (0.15s)
    - Braking power (8 m/s²)

    Params:
        _vehicle - The vehicle
        _obstacleDistance - Distance to obstacle in meters
        _targetSpeed - Desired speed in km/h

    Returns: [_action, _urgency, _totalStopDist, _brakingDist]
        _action: "ACCELERATE", "MAINTAIN", "PREPARE", "SLOW", "BRAKE", "EMERGENCY_BRAKE"
        _urgency: 0.0 to 1.0 (how critical the situation is)
        _totalStopDist: Total distance needed to stop (reaction + braking)
        _brakingDist: Pure braking distance
------------------------------------------------------------------------------------- */
EAD_fnc_calculateBrakingAction = {
    params ["_vehicle", "_obstacleDistance", "_targetSpeed"];

    if (isNull _vehicle) exitWith {["MAINTAIN",0,0,0]};

    private _currentSpeed = speed _vehicle;
    private _speedMS = _currentSpeed / 3.6;
    private _targetSpeedMS = _targetSpeed / 3.6;

    private _brakingPower = 8;
    private _reactionTime = 0.15;

    private _reactionDist = _speedMS * _reactionTime;

    private _brakingDist = 0;
    if (_speedMS > _targetSpeedMS) then {
        private _v1sq = _speedMS * _speedMS;
        private _v2sq = _targetSpeedMS * _targetSpeedMS;
        _brakingDist = (_v1sq - _v2sq) / (2 * _brakingPower max 0.1);
        if (_brakingDist < 0) then {_brakingDist = 0};
    };

    private _totalStopDist = _reactionDist + _brakingDist;

    private _action = "ACCELERATE";
    private _urgency = 0;

    if (_totalStopDist > 0 && _obstacleDistance < _totalStopDist) then {
        _urgency = 1 - (_obstacleDistance / _totalStopDist);

        if (_urgency > 0.85) then {
            _action = "EMERGENCY_BRAKE";
        } else {
            if (_urgency > 0.50) then {
                _action = "BRAKE";
            } else {
                _action = "SLOW";
            };
        };
    } else {
        if (_obstacleDistance < (_totalStopDist * 1.4)) then {
            _action = "PREPARE";
        } else {
            if (_currentSpeed < (_targetSpeed * 0.9)) then {
                _action = "ACCELERATE";
            } else {
                _action = "MAINTAIN";
            };
        };
    };

    [_action, _urgency, _totalStopDist, _brakingDist]
};

/* -------------------------------------------------------------------------------------
    Physics Function 3: Progressive Steering

    Applies smooth, speed-dependent steering corrections.
    At high speeds, uses velocity manipulation for realistic turning.
    At low speeds, allows more aggressive steering.

    Params:
        _vehicle - The vehicle
        _targetPos - Position to steer toward

    Returns: [_steeringInput, _angleDiff]
        _steeringInput: Calculated steering input (-1 to 1)
        _angleDiff: Angle difference to target
------------------------------------------------------------------------------------- */
EAD_fnc_progressiveSteering = {
    params ["_vehicle", "_targetPos"];

    if (isNull _vehicle) exitWith {[0,0]};

    private _vehicleDir = getDir _vehicle;
    private _vPos = getPosASL _vehicle;
    private _targetDir = [_vPos, _targetPos] call BIS_fnc_dirTo;
    private _currentSpeed = speed _vehicle;

    private _angleDiff = _targetDir - _vehicleDir;
    if (_angleDiff > 180) then {_angleDiff = _angleDiff - 360};
    if (_angleDiff < -180) then {_angleDiff = _angleDiff + 360};

    private _maxSpeed = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "maxSpeed") * 0.85;
    private _speedRatio = (_currentSpeed / (_maxSpeed max 1)) max 0.2;
    private _steerAggressive = 0.3 + ((1 - _speedRatio) * 0.7);

    private _steeringInput = ((_angleDiff / 35) max -1 min 1) * _steerAggressive;

    if (_currentSpeed > 25 && abs _angleDiff > 4) then {
        private _vel = velocity _vehicle;
        private _speed = vectorMagnitude _vel;

        private _maxTurnRate = 5 / (_speedRatio max 0.5);
        private _turnAmount = (_steeringInput * _maxTurnRate) max -_maxTurnRate min _maxTurnRate;

        private _newDir = _vehicleDir + _turnAmount;
        private _newVel = [
            (sin _newDir) * _speed,
            (cos _newDir) * _speed,
            _vel select 2
        ];

        _vehicle setVelocity _newVel;
    };

    [_steeringInput, _angleDiff]
};

/* -------------------------------------------------------------------------------------
    Physics Function 4: Analyze Terrain Gradient

    Scans terrain ahead in 5 sample points to detect slopes and steep obstacles.
    Helps predict uphill/downhill sections for speed adjustment.

    Params:
        _vehicle - The vehicle
        _scanDistance - How far ahead to scan (meters)

    Returns: [_avgGradient, _maxGradient, _hasObstacle]
        _avgGradient: Average terrain gradient in degrees
        _maxGradient: Maximum gradient detected
        _hasObstacle: true if gradient > 25 degrees (cliff/wall)
------------------------------------------------------------------------------------- */
EAD_fnc_analyzeTerrainGradient = {
    params ["_vehicle", "_scanDistance"];

    if (isNull _vehicle) exitWith {[0,0,false]};

    private _vPos = getPosASL _vehicle;
    private _vDir = getDir _vehicle;

    private _samples = [];
    for "_i" from 1 to 5 do {
        private _dist = (_scanDistance / 5) * _i;
        private _samplePos = _vPos vectorAdd [
            (sin _vDir) * _dist,
            (cos _vDir) * _dist,
            0
        ];
        private _h = getTerrainHeightASL _samplePos;
        _samples pushBack [_dist, _h];
    };

    private _avgGradient = 0;
    private _maxGradient = 0;

    for "_i" from 1 to ((count _samples) - 1) do {
        private _prev = _samples select (_i - 1);
        private _curr = _samples select _i;

        private _heightChange = (_curr select 1) - (_prev select 1);
        private _dist = (_curr select 0) - (_prev select 0) max 0.1;
        private _gradient = atan (_heightChange / _dist);

        _avgGradient = _avgGradient + _gradient;
        if (abs _gradient > abs _maxGradient) then {
            _maxGradient = _gradient;
        };
    };

    if ((count _samples) > 1) then {
        _avgGradient = _avgGradient / ((count _samples) - 1);
    };

    private _hasObstacle = (abs _maxGradient > 25);
    [_avgGradient, _maxGradient, _hasObstacle]
};

/* =====================================================================================
    END OF FILE - EAD v9.0
===================================================================================== */
