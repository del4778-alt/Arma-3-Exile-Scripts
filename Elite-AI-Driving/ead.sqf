/* =====================================================================================
    ELITE AI DRIVING SYSTEM (EAD) – VERSION 8.3
    AUTHOR: YOU + SYSTEM BUILT HERE
    SINGLE-FILE EDITION
    SAFE FOR EXILE + DEDICATED SERVER + HC + ANY FACTION
===================================================================================== */

/* =====================================================================================
    SECTION 1 — GLOBAL STATE & CONFIG
===================================================================================== */

EAD_CFG = createHashMapFromArray [
    ["TICK", 0.10],                     // main frequency

    // Speed profiles
    ["HIGHWAY_BASE", 145],
    ["CITY_BASE", 85],
    ["OFFROAD_MULT", 0.75],

    // Distances
    ["DIST_MAIN", 50],
    ["DIST_WIDE", 35],
    ["DIST_SIDE", 28],
    ["DIST_CORNER", 20],
    ["DIST_NEAR", 14],

    // Behavior multipliers
    ["CURVE_MULT", 0.8],
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
            ["role","CAR"], ["highway",125],["city",70],["offroad",0.70],["brute",false]
        ]
    };

    if (_type isKindOf "MRAP_01_base_F") exitWith {
        createHashMapFromArray [
            ["role","MRAP"],["highway",110],["city",60],["offroad",0.75],["brute",true]
        ]
    };

    if (_type isKindOf "Truck_F") exitWith {
        createHashMapFromArray [
            ["role","TRUCK"],["highway",95],["city",55],["offroad",0.65],["brute",false]
        ]
    };

    if (_type isKindOf "Tank") exitWith {
        createHashMapFromArray [
            ["role","TRACKED"],["highway",70],["city",45],["offroad",0.90],["brute",true]
        ]
    };

    createHashMapFromArray [
        ["role","GENERIC"],["highway",110],["city",65],["offroad",0.70],["brute",false]
    ]
};

/* =====================================================================================
    SECTION 3 — RAYCAST + TERRAIN SYSTEM
===================================================================================== */

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

    private _map = createHashMap;

    private _cast = {
        params ["_label","_off","_dist","_veh","_dir","_map"];
        private _ang = _dir + _off;
        private _vec = [sin _ang, cos _ang, 0];
        private _val = [_veh,_vec,_dist] call EAD_fnc_ray;
        _map set [_label,_val];
    };

    // Full scan - all rays
    ["F0",0,_m,_veh,_dir,_map] call _cast;
    ["FL1",12,_m,_veh,_dir,_map] call _cast;
    ["FR1",-12,_m,_veh,_dir,_map] call _cast;
    ["FL2",25,_w,_veh,_dir,_map] call _cast;
    ["FR2",-25,_w,_veh,_dir,_map] call _cast;
    ["L",45,_s,_veh,_dir,_map] call _cast;
    ["R",-45,_s,_veh,_dir,_map] call _cast;
    ["CL",70,_c,_veh,_dir,_map] call _cast;
    ["CR",-70,_c,_veh,_dir,_map] call _cast;
    ["NL",90,_n,_veh,_dir,_map] call _cast;
    ["NR",-90,_n,_veh,_dir,_map] call _cast;

    _map
};

/* =====================================================================================
    SECTION 4 — SPEED BRAIN + OBSTACLE + ALTITUDE + BRIDGE
===================================================================================== */

EAD_fnc_speedBrain = {
    params ["_veh","_s","_terrain","_profile"];

    _terrain params ["_isRoad","_slope","_dense","_norm"];

    private _base = EAD_CFG get "HIGHWAY_BASE";
    if (!_isRoad) then {_base = _base * (_profile get "offroad")};

    if (_dense) then {_base = _base * 0.85};

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
    SECTION 7 — VECTOR DRIVE + STEERING + DEBUG
===================================================================================== */

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

    {
        _veh setVariable [_x,nil];
    } forEach [
        "EAD_active","EAD_stuckTime","EAD_reverseUntil","EAD_profile",
        "EAD_onBridge","EAD_altT","EAD_altPos","EAD_altLastSpeed",
        "EAD_convoyList","EAD_convoyListTime","EAD_treeDense",
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

    // ✅ RESPECT A3XAI BLOCK FLAG
    if (_veh getVariable ["EAID_Ignore", false]) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD] Skipping %1 - A3XAI settling", typeOf _veh];
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
            "[EAD 8.3]  Total:%1 | Avg:%2 ms | Max:%3 ms (last 10 min)",
            _tot,
            _avg toFixed 2,
            _max toFixed 2
        ];

        EAD_Stats set ["maxTickTime",0];
    };
};

/* =====================================================================================
    END OF FILE
===================================================================================== */
