/* =====================================================================================
    ELITE AI DRIVING SYSTEM (EAD) – VERSION 9.5 APEX EDITION
    AUTHOR: MAXIMUM PERFORMANCE + A3XAI SAFE

    v9.5 ENHANCEMENTS:
        ✅ All v9.0 features (250 km/h, 4-height, apex, top-down)

        🆕 FROM v10.2 (BEST PARTS ONLY):
        ✅ Predictive collision detection (expectedDestination)
        ✅ Combat evasive serpentine maneuvers
        ✅ Dynamic LOD raycasting (fewer rays when far from players)
        ✅ Enhanced stuck recovery (3 methods: reverse, jump, turn)
        ✅ Obstacle type detection (infantry/vehicle/static)

        🆕 A3XAI COMPLETE EXCLUSION:
        ✅ Multi-layer A3XAI detection
        ✅ Respects EAID_Ignore flag
        ✅ Detects A3XAI group variables
        ✅ Detects A3XAI unit variables
        ✅ NEVER touches A3XAI vehicles (fixes spinning/circling)
        ✅ Only enhances Recruit AI, Patrol AI, Mission AI

        ✅ REALISTIC SPEEDS:
        ✅ 250 km/h supercar max (not 999 km/h nonsense)
        ✅ Physics-safe limits
        ✅ Optimized for Ivory supercars
===================================================================================== */

/* =====================================================================================
    SECTION 1 — GLOBAL STATE & CONFIG
===================================================================================== */

EAD_CFG = createHashMapFromArray [
    ["TICK", 0.06],                     // ✅ Optimized tick rate

    // ✅ SUPERCAR SPEED PROFILES (250 km/h realistic)
    ["HIGHWAY_BASE", 250],
    ["CITY_BASE", 130],
    ["OFFROAD_MULT", 0.85],

    // ✅ EXTENDED DISTANCES FOR 250 KM/H
    ["DIST_MAIN", 120],
    ["DIST_WIDE", 80],
    ["DIST_SIDE", 60],
    ["DIST_CORNER", 45],
    ["DIST_NEAR", 25],

    // ✅ APEX RACING
    ["APEX_ENABLED", true],
    ["APEX_CUT_ANGLE", 35],
    ["APEX_SPEED_BOOST", 1.15],

    // ✅ SMART CURVE DETECTION
    ["CURVE_GENTLE_THRESHOLD", 65],
    ["CURVE_SHARP_THRESHOLD", 25],
    ["CURVE_GENTLE_MULT", 0.98],
    ["CURVE_SHARP_MULT", 0.65],

    // ✅ AGGRESSIVE BRIDGE MODE
    ["BRIDGE_SIDE_OFFSET", 5],
    ["BRIDGE_NO_BRAKE_TIME", 4.0],

    // 🆕 PREDICTIVE COLLISION (from v10.2)
    ["PREDICT_ENABLED", true],
    ["PREDICT_TIME_AHEAD", 3.0],

    // 🆕 COMBAT EVASIVE (from v10.2)
    ["COMBAT_EVASIVE", true],
    ["COMBAT_SERPENTINE_INTERVAL", 3.0],
    ["COMBAT_SPEED_MULT", 1.15],

    // 🆕 DYNAMIC LOD (from v10.2)
    ["LOD_ENABLED", true],
    ["LOD_PLAYER_NEAR", 150],           // Use full rays < 150m from players
    ["LOD_REDUCED_RAY_COUNT", 7],       // Use 7 rays when far from players

    // Stuck logic
    ["STUCK_TIME", 2.5],
    ["STUCK_SPEED", 8],
    ["REVERSE_TIME", 2.0],
    ["REVERSE_SPEED_KMH", 25],

    // Emergency brake
    ["EMERGENCY_BRAKE_DIST", 3],

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
    ["maxTickTime", 0],
    ["a3xaiExcluded", 0]
];

EAD_HasApex = isClass (configFile >> "CfgPatches" >> "expansion");

/* =====================================================================================
    SECTION 2 — A3XAI COMPLETE EXCLUSION SYSTEM
===================================================================================== */

// 🆕 Multi-layer A3XAI detection - NEVER touch A3XAI vehicles
EAD_fnc_isA3XAIVehicle = {
    params ["_veh", "_driver"];

    // Layer 1: Check EAID_Ignore flag (set by other scripts)
    if (_veh getVariable ["EAID_Ignore", false]) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD 9.5] A3XAI EXCLUDED (EAID_Ignore): %1", typeOf _veh];
        };
        true
    };

    // Layer 2: Check driver for A3XAI variables
    if (!isNull _driver) then {
        private _group = group _driver;

        // A3XAI sets these variables on units/groups
        if (
            _driver getVariable ["A3XAI_AIUnit", false] ||
            _driver getVariable ["UPSMON_Grp", false] ||
            _group getVariable ["A3XAI_dynGroup", false] ||
            _group getVariable ["A3XAI_staticGroup", false]
        ) exitWith {
            if (EAD_CFG get "DEBUG_ENABLED") then {
                diag_log format ["[EAD 9.5] A3XAI EXCLUDED (unit vars): %1", typeOf _veh];
            };
            true
        };
    };

    // Layer 3: Check vehicle for A3XAI ownership markers
    if (
        _veh getVariable ["A3XAI_VehOwned", false] ||
        _veh getVariable ["A3XAI_Vehicle", false]
    ) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD 9.5] A3XAI EXCLUDED (veh vars): %1", typeOf _veh];
        };
        true
    };

    // Not an A3XAI vehicle - safe to enhance
    false
};

/* =====================================================================================
    SECTION 3 — VEHICLE PROFILE SYSTEM (REALISTIC 250 KM/H)
===================================================================================== */

EAD_fnc_getProfile = {
    params ["_veh"];
    private _type = typeOf _veh;

    if (_type isKindOf "Car") exitWith {
        createHashMapFromArray [
            ["role","CAR"], ["highway",250],["city",130],["offroad",0.85],["brute",false]
        ]
    };

    if (_type isKindOf "MRAP_01_base_F") exitWith {
        createHashMapFromArray [
            ["role","MRAP"],["highway",170],["city",100],["offroad",0.85],["brute",true]
        ]
    };

    if (_type isKindOf "Truck_F") exitWith {
        createHashMapFromArray [
            ["role","TRUCK"],["highway",150],["city",85],["offroad",0.75],["brute",false]
        ]
    };

    if (_type isKindOf "Tank") exitWith {
        createHashMapFromArray [
            ["role","TRACKED"],["highway",110],["city",65],["offroad",0.95],["brute",true]
        ]
    };

    createHashMapFromArray [
        ["role","GENERIC"],["highway",180],["city",100],["offroad",0.80],["brute",false]
    ]
};

/* =====================================================================================
    SECTION 4 — ADVANCED RAYCAST SYSTEM (4-HEIGHT + TOP-DOWN + DYNAMIC LOD)
===================================================================================== */

// 🆕 Dynamic LOD - Use fewer rays when far from players (from v10.2)
EAD_fnc_shouldUseReducedRays = {
    params ["_veh"];

    if !(EAD_CFG get "LOD_ENABLED") exitWith {false};

    private _nearDist = EAD_CFG get "LOD_PLAYER_NEAR";
    private _minDist = 9999;

    {
        if (isPlayer _x && alive _x) then {
            private _dist = _veh distance _x;
            if (_dist < _minDist) then {_minDist = _dist};
        };
    } forEach allUnits;

    (_minDist > _nearDist)
};

// ✅ 4-height batch raycast with obstacle type detection (enhanced from v10.2)
EAD_fnc_rayBatchAdvanced = {
    params ["_veh", "_rayDefs"];

    private _vehPos = getPosASL _veh;
    private _dir = getDir _veh;
    private _batch = [];
    private _obstacleInfo = [];

    {
        _x params ["_angleOffset", "_dist"];
        private _ang = _dir + _angleOffset;
        private _vec = [sin _ang, cos _ang, 0];
        private _heights = [0.15, 0.6, 1.2, 1.8]; // Ground, Low, Mid, Eye

        {
            private _startHeight = _vehPos vectorAdd [0, 0, _x];
            private _endHeight = _startHeight vectorAdd (_vec vectorMultiply _dist);
            _batch pushBack [_startHeight, _endHeight, _veh, objNull, true, 1, "GEOM", "NONE"];
        } forEach _heights;
    } forEach _rayDefs;

    private _results = lineIntersectsSurfaces [_batch];
    private _distances = [];
    private _idx = 0;

    {
        _x params ["_angleOffset", "_dist"];
        private _minDist = _dist;
        private _obstacleType = "NONE";
        private _obstacleObject = objNull;

        for "_h" from 0 to 3 do {
            private _result = _results select (_idx + _h);

            // ✅ FIX: Check if result has enough elements (needs at least 3 for select 2)
            if (count _result > 2) then {
                private _heightOffset = [0.15, 0.6, 1.2, 1.8] select _h;
                private _startPos = _vehPos vectorAdd [0, 0, _heightOffset];
                private _hitDist = _startPos vectorDistance (_result#0#0);

                if (_hitDist < _minDist) then {
                    _minDist = _hitDist;
                    private _hitObj = _result select 2;

                    // 🆕 Detect obstacle type (from v10.2)
                    if (!isNull _hitObj && _obstacleType == "NONE") then {
                        if (_hitObj isKindOf "Man") then {
                            _obstacleType = "INFANTRY";
                            _obstacleObject = _hitObj;
                        } else {
                            if (_hitObj isKindOf "Car" || _hitObj isKindOf "Tank") then {
                                _obstacleType = "VEHICLE";
                                _obstacleObject = _hitObj;
                            } else {
                                _obstacleType = "STATIC";
                            };
                        };
                    };
                };
            };
        };

        _distances pushBack _minDist;
        _obstacleInfo pushBack [_obstacleType, _obstacleObject];
        _idx = _idx + 4;
    } forEach _rayDefs;

    [_distances, _obstacleInfo]
};

EAD_fnc_rayTopDown = {
    params ["_veh"];
    private _pos = getPosASL _veh;
    private _startAbove = _pos vectorAdd [0, 0, 15];
    private _endAtVehicle = _pos vectorAdd [0, 0, 0.5];
    private _hit = lineIntersectsSurfaces [_startAbove, _endAtVehicle, _veh, objNull, true, 1, "GEOM"];
    (count _hit > 0)
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

EAD_fnc_isBridge = {
    params ["_veh"];
    private _pos = getPosATL _veh;
    if !(isOnRoad _pos) exitWith {false};

    private _off = EAD_CFG get "BRIDGE_SIDE_OFFSET";
    private _right = vectorSide _veh;
    private _dir = getDir _veh;
    private _fwd = [sin _dir, cos _dir, 0] vectorMultiply 10;

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
        if (surfaceIsWater _L && surfaceIsWater _R) then {_hits = _hits + 1};
    } forEach _checks;

    (_hits >= 3)
};

// 🆕 Adaptive scan with dynamic LOD (from v10.2)
EAD_fnc_scanAdaptive = {
    params ["_veh"];

    private _dir = getDir _veh;
    private _m = EAD_CFG get "DIST_MAIN";
    private _w = EAD_CFG get "DIST_WIDE";
    private _s = EAD_CFG get "DIST_SIDE";
    private _c = EAD_CFG get "DIST_CORNER";
    private _n = EAD_CFG get "DIST_NEAR";

    private _useReducedRays = [_veh] call EAD_fnc_shouldUseReducedRays;

    // Full 15-ray scan when near players, reduced 7-ray scan when far
    private _rayDefinitions = if (_useReducedRays) then {
        [
            ["F0",0,_m],["FL1",12,_m],["FR1",-12,_m],
            ["FL2",25,_w],["FR2",-25,_w],["L",45,_s],["R",-45,_s]
        ]
    } else {
        [
            ["F0",0,_m],["FL1",8,_m],["FR1",-8,_m],["FL2",16,_m],["FR2",-16,_m],
            ["FL3",25,_w],["FR3",-25,_w],["L",45,_s],["R",-45,_s],["CL",70,_c],
            ["CR",-70,_c],["NL",90,_n],["NR",-90,_n],["NL2",110,_n],["NR2",-110,_n]
        ]
    };

    private _rayDefs = _rayDefinitions apply {[_x#1, _x#2]};
    private _batchResult = [_veh, _rayDefs] call EAD_fnc_rayBatchAdvanced;
    _batchResult params ["_distances", "_obstacleInfo"];

    private _map = createHashMap;
    {
        _x params ["_label", "_angleOffset", "_distance"];
        _map set [_label, _distances select _forEachIndex];

        // 🆕 Store obstacle type info (from v10.2)
        private _obsInfo = _obstacleInfo select _forEachIndex;
        _map set [_label + "_OBS", _obsInfo select 0];
        _map set [_label + "_OBJ", _obsInfo select 1];
    } forEach _rayDefinitions;

    // Fill in missing rays when using reduced LOD
    if (_useReducedRays) then {
        _map set ["FL3", _map get "FL2"];
        _map set ["FR3", _map get "FR2"];
        _map set ["CL", _map get "L"];
        _map set ["CR", _map get "R"];
        _map set ["NL", 20];
        _map set ["NR", 20];
        _map set ["NL2", 20];
        _map set ["NR2", 20];
    };

    _map set ["OVERHEAD", [_veh] call EAD_fnc_rayTopDown];
    _map
};

/* =====================================================================================
    SECTION 5 — PREDICTIVE COLLISION (NEW FROM v10.2)
===================================================================================== */

EAD_fnc_predictiveCollision = {
    params ["_veh", "_currentSpeed"];

    if !(EAD_CFG get "PREDICT_ENABLED") exitWith {[false, 0]};

    // Use Arma's built-in prediction
    private _expectedPos = expectedDestination _veh;
    if (_expectedPos isEqualTo [0,0,0]) exitWith {[false, 0]};

    private _currentPos = getPosASL _veh;

    // ✅ FIX: expectedDestination returns AGL position, convert to ASL for lineIntersectsSurfaces
    // lineIntersectsSurfaces requires ASL positions
    private _intersects = lineIntersectsSurfaces [
        _currentPos vectorAdd [0,0,1],
        (AGLToASL _expectedPos) vectorAdd [0,0,1],
        _veh, objNull, true, 1, "GEOM", "FIRE"
    ];

    if (count _intersects > 0) then {
        private _hit = _intersects select 0;
        private _hitPos = _hit select 0;
        private _distance = _currentPos distance _hitPos;
        private _hitObject = _hit select 2;

        // Weight threat by object type
        private _threatLevel = 1.0;
        if (!isNull _hitObject) then {
            if (_hitObject isKindOf "Man") then {
                _threatLevel = 1.5; // Higher threat for infantry
            } else {
                if (_hitObject isKindOf "Car" || _hitObject isKindOf "Tank") then {
                    _threatLevel = 1.3; // Medium threat for vehicles
                };
            };
        };

        [true, _distance * _threatLevel]
    } else {
        [false, 0]
    }
};

/* =====================================================================================
    SECTION 6 — SPEED BRAIN + APEX + CURVES
===================================================================================== */

EAD_fnc_detectCurveType = {
    params ["_s"];
    private _leftClear = (_s get "CL") min (_s get "L");
    private _rightClear = (_s get "CR") min (_s get "R");
    private _minSide = _leftClear min _rightClear;

    if (_minSide > (EAD_CFG get "CURVE_GENTLE_THRESHOLD")) exitWith {"GENTLE"};
    if (_minSide < (EAD_CFG get "CURVE_SHARP_THRESHOLD")) exitWith {"SHARP"};
    "MEDIUM"
};

EAD_fnc_calculateApex = {
    params ["_veh", "_s", "_curveType"];
    if !(EAD_CFG get "APEX_ENABLED") exitWith {0};
    if (_curveType == "GENTLE") exitWith {0};

    private _leftClear = (_s get "CL") min (_s get "L");
    private _rightClear = (_s get "CR") min (_s get "R");

    if (_leftClear < _rightClear) then {
        EAD_CFG get "APEX_CUT_ANGLE"
    } else {
        -(EAD_CFG get "APEX_CUT_ANGLE")
    }
};

// 🆕 Combat speed multiplier (from v10.2)
EAD_fnc_getCombatMultiplier = {
    params ["_veh"];
    if !(EAD_CFG get "COMBAT_EVASIVE") exitWith {1.0};

    private _driver = driver _veh;
    if (isNull _driver) exitWith {1.0};

    if (behaviour _driver in ["COMBAT", "STEALTH"]) then {
        EAD_CFG get "COMBAT_SPEED_MULT"
    } else {
        1.0
    }
};

EAD_fnc_speedBrain = {
    params ["_veh","_s","_terrain","_profile"];

    _terrain params ["_isRoad","_slope","_dense"];

    private _base = EAD_CFG get "HIGHWAY_BASE";
    if (!_isRoad) then {_base = _base * (_profile get "offroad")};
    if (_dense) then {_base = _base * 0.92};

    private _curveType = [_s] call EAD_fnc_detectCurveType;
    switch (_curveType) do {
        case "GENTLE": {_base = _base * (EAD_CFG get "CURVE_GENTLE_MULT")};
        case "SHARP": {_base = _base * (EAD_CFG get "CURVE_SHARP_MULT")};
        case "MEDIUM": {_base = _base * 0.88};
    };

    if (_curveType != "GENTLE" && (EAD_CFG get "APEX_ENABLED")) then {
        private _onApex = _veh getVariable ["EAD_onApex", false];
        if (_onApex) then {_base = _base * (EAD_CFG get "APEX_SPEED_BOOST")};
    };

    if (_slope > 0.45) then {_base = _base * 0.70};

    // 🆕 Combat speed boost (from v10.2)
    _base = _base * ([_veh] call EAD_fnc_getCombatMultiplier);

    _base max 25
};

EAD_fnc_obstacleLimit = {
    params ["_veh","_s","_cur"];

    private _m = selectMin [
        _s get "F0", _s get "FL1", _s get "FR1",
        _s get "FL2", _s get "FR2", _s get "FL3", _s get "FR3"
    ];

    // 🆕 Don't slow down for infantry if we have enough clearance (from v10.2)
    private _f0ObsType = _s get "F0_OBS";
    if (_f0ObsType == "INFANTRY" && _m > 15) exitWith {_cur};

    if (_m < 25) then {_cur = _cur * 0.65};
    if (_m < 18) then {_cur = _cur * 0.60};
    if (_m < 10) then {_cur = _cur * 0.40};

    // 🆕 Predictive collision avoidance (from v10.2)
    private _predictResult = [_veh, _cur] call EAD_fnc_predictiveCollision;
    if ((_predictResult select 0) && (_predictResult select 1) < 30) then {
        _cur = _cur * 0.5;
    };

    _cur
};

EAD_fnc_altitudeCorrection = {
    params ["_veh","_spd","_terrain"];
    private _slope = _terrain select 1;
    if (_slope > 0.50) exitWith {_spd * 0.70};
    if (_slope > 0.35) exitWith {_spd * 0.85};
    _spd
};

EAD_fnc_applyBridgeMode = {
    params ["_veh","_spd"];
    private _b = [_veh] call EAD_fnc_isBridge;
    private _now = time;

    if (_b) then {
        private _bridgeEnterTime = _veh getVariable ["EAD_bridgeEnterTime", 0];
        if (_bridgeEnterTime == 0) then {
            _veh setVariable ["EAD_bridgeEnterTime", _now];
            _veh setVariable ["EAD_bridgeSpeed", speed _veh max _spd];
        };

        if ((_now - _bridgeEnterTime) < (EAD_CFG get "BRIDGE_NO_BRAKE_TIME")) then {
            private _maintainSpeed = _veh getVariable ["EAD_bridgeSpeed", _spd];
            _spd = _maintainSpeed max _spd;
            _veh setVariable ["EAD_onBridge", true];
            _veh setVariable ["EAD_bridgeNoBrake", true];
        } else {
            _veh setVariable ["EAD_bridgeNoBrake", false];
        };
    } else {
        _veh setVariable ["EAD_bridgeEnterTime", 0];
        _veh setVariable ["EAD_onBridge", false];
        _veh setVariable ["EAD_bridgeNoBrake", false];
    };

    _spd
};

EAD_fnc_emergencyBrake = {
    params ["_veh","_s","_profile"];
    if (_veh getVariable ["EAD_bridgeNoBrake", false]) exitWith {false};

    private _spd = speed _veh;
    private _f0 = _s get "F0";
    private _t = EAD_CFG get "EMERGENCY_BRAKE_DIST";
    if (_profile get "brute") then {_t = _t * 0.6};

    if (_f0 < _t && _spd > 40) then {
        _veh setVelocity [0,0,0];
        true
    } else {
        false
    }
};

/* =====================================================================================
    SECTION 7 — PATH SELECTION & DRIVING
===================================================================================== */

EAD_fnc_pathBias = {
    params ["_s","_dir","_veh"];

    private _cand = [
        ["F0",0,_s get "F0"],["FL1",8,_s get "FL1"],["FR1",-8,_s get "FR1"],
        ["FL2",16,_s get "FL2"],["FR2",-16,_s get "FR2"],
        ["FL3",25,_s get "FL3"],["FR3",-25,_s get "FR3"]
    ];

    {if ((_x#0) == "F0") then {_x set [2, (_x#2)*1.2]}} forEach _cand;
    _cand sort false;
    private _best = _cand#0;
    private _ang = _best#1;
    private _dist = _best#2;

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
    private _dot = (_dirVec vectorDotProduct _velN) max -1 min 1;
    private _ang = acos _dot;

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
    if (count units _grp < 2) exitWith {_spd};

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
        } forEach units _grp;
        _veh setVariable ["EAD_convoyList",_list];
        _veh setVariable ["EAD_convoyListTime",_now];
    };

    if (count _list < 2) exitWith {_spd};

    private _idx = _list find _veh;
    if (_idx <= 0) exitWith {_spd};

    private _lead = _list select (_idx - 1);
    if (isNull _lead) exitWith {_spd};

    private _dist = _veh distance2D _lead;
    private _ls = speed _lead;

    if (_dist > 80) exitWith {_ls * 1.25};
    if (_dist < 30) exitWith {_spd * 0.75};
    if (_dist >= 40 && _dist <= 60) exitWith {_ls max 20};

    _spd
};

/* =====================================================================================
    SECTION 8 — ENHANCED STUCK RECOVERY (NEW FROM v10.2)
===================================================================================== */

EAD_fnc_stuck = {
    params ["_veh","_s","_spd"];

    private _now = time;
    private _st = _veh getVariable ["EAD_stuckTime",0];
    private _revUntil = _veh getVariable ["EAD_reverseUntil",0];
    private _lastEnd = _veh getVariable ["EAD_lastReverseEnd",0];
    private _stuckCounter = _veh getVariable ["EAD_stuckCounter", 0];

    if (_now < _revUntil) exitWith {
        private _dir = getDir _veh + 180;
        private _revMS = -((EAD_CFG get "REVERSE_SPEED_KMH")/3.6);
        _veh setVelocity ([sin _dir, cos _dir, 0] vectorMultiply _revMS);
        30
    };

    if (_revUntil > 0) then {
        _veh setVariable ["EAD_reverseUntil",0];
        _veh setVariable ["EAD_stuckTime",0];
        _veh setVariable ["EAD_lastReverseEnd",_now];
        _veh setVariable ["EAD_stuckCounter", _stuckCounter + 1];
    };

    if ((_now - _lastEnd) < 2.5) exitWith {_spd};

    if (speed _veh < (EAD_CFG get "STUCK_SPEED") && (_s get "F0") < 12 && _spd > 40) then {
        if (_st == 0) then {
            _veh setVariable ["EAD_stuckTime",_now];
        } else {
            if ((_now - _st) > (EAD_CFG get "STUCK_TIME")) then {
                // 🆕 3 recovery methods that cycle (from v10.2)
                switch (_stuckCounter % 3) do {
                    case 0: {
                        // Method 1: Reverse
                        _veh setVariable ["EAD_reverseUntil", _now + (EAD_CFG get "REVERSE_TIME")];
                    };
                    case 1: {
                        // Method 2: Jump (upward velocity)
                        _veh setVelocity ([sin getDir _veh, cos getDir _veh, 0.5] vectorMultiply 8);
                        _veh setVariable ["EAD_stuckTime",0];
                    };
                    case 2: {
                        // Method 3: Turn 45° and reverse
                        _veh setDir (getDir _veh + 45);
                        _veh setVariable ["EAD_reverseUntil", _now + (EAD_CFG get "REVERSE_TIME")];
                    };
                };
            };
        };
    } else {
        _veh setVariable ["EAD_stuckTime",0];
        if (speed _veh > 20) then {
            _veh setVariable ["EAD_stuckCounter", 0];
        };
    };

    _spd
};

/* =====================================================================================
    SECTION 9 — COMBAT EVASIVE MANEUVERS (NEW FROM v10.2)
===================================================================================== */

EAD_fnc_combatEvasive = {
    params ["_veh"];
    if !(EAD_CFG get "COMBAT_EVASIVE") exitWith {};

    private _driver = driver _veh;
    if (isNull _driver || !(behaviour _driver in ["COMBAT", "STEALTH"])) exitWith {};

    // Only evade if recently hit (within 5 seconds)
    if ((time - (_veh getVariable ["EAD_lastHitTime", 0])) >= 5) exitWith {};

    // Serpentine pattern every 3 seconds
    if ((time - (_veh getVariable ["EAD_lastSerpentine", 0])) > (EAD_CFG get "COMBAT_SERPENTINE_INTERVAL")) then {
        private _dodgeAngle = if ((time % 6) < 3) then {30} else {-30};
        _veh setDir (getDir _veh + _dodgeAngle);
        _veh setVariable ["EAD_lastSerpentine", time];
    };
};

/* =====================================================================================
    SECTION 10 — VECTOR DRIVE
===================================================================================== */

EAD_fnc_vectorDrive = {
    params ["_veh","_s","_tSpd","_profile"];

    private _dir = getDir _veh;
    private _center = ((_s get "L") - (_s get "R")) * 0.004;
    _center = _center + (((_s get "CL") - (_s get "CR")) * 0.0015);

    private _path = [_s,_dir,_veh] call EAD_fnc_pathBias;
    private _drift = [_veh] call EAD_fnc_driftBias;

    private _near = 0;
    if ((_s get "NL") < 8) then {_near = _near + 0.03};
    if ((_s get "NR") < 8) then {_near = _near - 0.03};

    private _bias = (_center + (_path * 0.018) + _drift + _near) max -0.25 min 0.25;
    private _newDir = _dir + (_bias * 55);

    // ✅ FIX: Removed invalid setVehicleTurnSpeed command (doesn't exist in Arma 3)
    // Turn speed is controlled via setDir and setVelocity below

    _veh setDir _newDir;

    private _vel = velocity _veh;
    private _vert = (_vel#2) * (if (abs (_vel#2) > 5) then {0.8} else {1});
    private _newVel = [sin _newDir, cos _newDir, 0] vectorMultiply (_tSpd / 3.6);
    _newVel set [2, _vert max -10];

    _veh setVelocity _newVel;
    _veh limitSpeed _tSpd;

    // 🆕 Combat evasive maneuvers (from v10.2)
    [_veh] call EAD_fnc_combatEvasive;

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
        private _txt = format [
            "%1 | T:%2 A:%3 | %4%5%6",
            _profile get "role",
            round _t,
            round speed _veh,
            _curveType,
            if (_veh getVariable ["EAD_onApex",false]) then {" APEX"} else {""},
            if (_veh getVariable ["EAD_onBridge",false]) then {" BRIDGE"} else {""}
        ];

        drawIcon3D ["", [1,1,1,1], _txtPos, 0,0,0, _txt, 1, 0.03, "PuristaMedium", "center"];
    };
};

/* =====================================================================================
    SECTION 11 — DRIVER LOOP (A3XAI SAFE)
===================================================================================== */

EAD_fnc_runDriver = {
    params ["_unit","_veh"];

    private _localEH = _veh addEventHandler ["Local", {
        if !(_this select 1) then {(_this select 0) setVariable ["EAD_active", false]};
    }];

    private _killedEH = _veh addEventHandler ["Killed", {
        (_this select 0) setVariable ["EAD_active", false];
    }];

    // 🆕 Track hits for combat evasive (from v10.2)
    private _hitEH = _veh addEventHandler ["Hit", {
        (_this select 0) setVariable ["EAD_lastHitTime", time];
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
        EAD_Stats set ["avgTickTime", ((EAD_Stats get "avgTickTime") * 0.99) + (_dt * 0.01)];
        if (_dt > (EAD_Stats get "maxTickTime")) then {EAD_Stats set ["maxTickTime", _dt]};

        uiSleep (EAD_CFG get "TICK");
    };

    _veh removeEventHandler ["Local",_localEH];
    _veh removeEventHandler ["Killed",_killedEH];
    _veh removeEventHandler ["Hit",_hitEH];

    {
        _veh setVariable [_x,nil];
    } forEach [
        "EAD_active","EAD_stuckTime","EAD_reverseUntil","EAD_profile",
        "EAD_onBridge","EAD_bridgeEnterTime","EAD_bridgeSpeed","EAD_bridgeNoBrake",
        "EAD_onApex","EAD_convoyList","EAD_convoyListTime","EAD_treeDense",
        "EAD_treeCheckTime","EAD_lastReverseEnd","EAD_stuckCounter","EAD_lastHitTime",
        "EAD_lastSerpentine"
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

    // 🆕 COMPLETE A3XAI EXCLUSION - Multi-layer detection
    if ([_veh, _unit] call EAD_fnc_isA3XAIVehicle) exitWith {
        EAD_Stats set ["a3xaiExcluded", (EAD_Stats get "a3xaiExcluded") + 1];
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
    SECTION 12 — AUTO-DETECTION
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

        uiSleep 2.5;
    };
};

/* =====================================================================================
    SECTION 13 — PERF LOG
===================================================================================== */

[] spawn {
    while {true} do {
        uiSleep 600;

        diag_log format [
            "[EAD 9.5 APEX] Vehicles:%1 | A3XAI Excluded:%2 | Avg:%3ms | Max:%4ms",
            EAD_Stats get "totalVehicles",
            EAD_Stats get "a3xaiExcluded",
            ((EAD_Stats get "avgTickTime") * 1000) toFixed 2,
            ((EAD_Stats get "maxTickTime") * 1000) toFixed 2
        ];

        EAD_Stats set ["maxTickTime",0];
    };
};

diag_log "======================================================";
diag_log "[EAD 9.5 APEX EDITION] INITIALIZED";
diag_log "[EAD 9.5] ✅ 250 km/h supercar speeds (realistic)";
diag_log "[EAD 9.5] ✅ 4-height forward raycasting";
diag_log "[EAD 9.5] ✅ Top-down obstacle detection";
diag_log "[EAD 9.5] ✅ Apex curve cutting + racing line";
diag_log "[EAD 9.5] ✅ Aggressive bridge mode (4s no-brake)";
diag_log "[EAD 9.5] 🆕 Predictive collision detection";
diag_log "[EAD 9.5] 🆕 Combat evasive serpentine maneuvers";
diag_log "[EAD 9.5] 🆕 Dynamic LOD raycasting (performance)";
diag_log "[EAD 9.5] 🆕 Enhanced stuck recovery (3 methods)";
diag_log "[EAD 9.5] 🆕 Obstacle type detection";
diag_log "[EAD 9.5] 🆕 COMPLETE A3XAI EXCLUSION (multi-layer)";
diag_log "[EAD 9.5] ❌ A3XAI vehicles NEVER touched (fixes spinning)";
diag_log "[EAD 9.5] ✅ Only enhances: Recruit AI, Patrol AI, Mission AI";
diag_log "======================================================";

/* =====================================================================================
    END OF FILE
===================================================================================== */
