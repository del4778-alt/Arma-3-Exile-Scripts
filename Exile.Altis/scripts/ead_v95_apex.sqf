/* =====================================================================================
    ELITE AI DRIVING SYSTEM (EAD) – VERSION 9.7 APEX EDITION
    RECRUIT_AI EXCLUSIVE - MAXIMUM PERFORMANCE

    ✅ v9.7 FIXES:
        🆕 AI FULL SPEED MODE - forceSpeed on AI, EAD only handles steering/braking
        🆕 AGGRESSIVE BRIDGE MODE - Force velocity forward, no braking, no steering
        🆕 ROADKILL MODE - Speed up to hit EAST AI on roads
        🆕 CITY/TOWN SPEED - Adjusted speeds for urban areas
        🆕 RECRUIT AI SYNC - Works with recruit AI commands

    ✅ RECRUIT_AI EXCLUSIVE MODE:
        ✅ Only works with vehicles flagged by recruit_ai.sqf
        ✅ Auto-detection DISABLED to prevent conflicts
        ✅ No interference with A3XAI, mission AI, or other AI systems
        ✅ Activated via RECRUIT_fnc_ForceEADReregister only

    ✅ COMPREHENSIVE RAY COVERAGE - 41 RAYS
    ✅ HIGH-SPEED PERFORMANCE - Full vehicle top speed on straights
===================================================================================== */

/* =====================================================================================
    SECTION 1 — GLOBAL STATE & CONFIG
===================================================================================== */

EAD_CFG = createHashMapFromArray [
    ["TICK", 0.06],                     // ✅ Optimized tick rate

    // ✅ v9.7: AI FULL SPEED MODE
    // AI driver uses forceSpeed to reach max, EAD only brakes for corners/obstacles
    ["AI_FULL_SPEED", true],            // 🆕 Let AI use full throttle
    ["TOPSPEED_MULTIPLIER", 1.00],      // 🆕 100% of vehicle top speed (was 90%)
    ["HIGHWAY_BASE", 250],              // Fallback speed
    ["USE_VEHICLE_TOPSPEED", true],     // Use vehicle's actual maxSpeed

    // ✅ v9.7: URBAN SPEED LIMITS
    ["CITY_SPEED", 60],                 // 60 km/h in cities (tight streets)
    ["TOWN_SPEED", 80],                 // 80 km/h in towns
    ["VILLAGE_SPEED", 100],             // 100 km/h in villages
    ["OFFROAD_MULT", 0.70],             // 70% speed off-road

    // ✅ v9.7: ROADKILL MODE
    ["ROADKILL_ENABLED", true],         // 🆕 Speed up to hit EAST AI
    ["ROADKILL_SPEED_BOOST", 1.30],     // 🆕 30% speed boost when targeting
    ["ROADKILL_DETECT_RANGE", 50],      // 🆕 Detect enemies within 50m

    // ✅ WAYPOINT FOLLOWING
    ["WAYPOINT_ENABLED", true],
    ["WAYPOINT_ARRIVE_DIST", 15],

    // ✅ SCAN DISTANCES
    ["DIST_MAIN", 50],
    ["DIST_WIDE", 35],
    ["DIST_SIDE", 15],
    ["DIST_CORNER", 15],
    ["DIST_NEAR", 8],

    // ✅ APEX RACING
    ["APEX_ENABLED", true],
    ["APEX_CUT_ANGLE", 35],
    ["APEX_SPEED_BOOST", 1.10],

    // ✅ CURVE DETECTION - Only slow for SHARP turns
    ["CURVE_GENTLE_THRESHOLD", 70],
    ["CURVE_SHARP_THRESHOLD", 25],
    ["CURVE_GENTLE_MULT", 1.00],        // No slowdown on gentle curves
    ["CURVE_SHARP_MULT", 0.40],         // 40% speed on 90° turns only

    // ✅ v9.7: AGGRESSIVE BRIDGE MODE
    ["BRIDGE_SIDE_OFFSET", 5],
    ["BRIDGE_NO_BRAKE_TIME", 8.0],      // 🆕 8 seconds no braking (was 5)
    ["BRIDGE_SPEED_BOOST", 1.40],       // 🆕 40% speed boost on bridges (was 25%)
    ["BRIDGE_FORCE_FORWARD", true],     // 🆕 Force velocity straight ahead

    // 🆕 PREDICTIVE COLLISION
    ["PREDICT_ENABLED", true],
    ["PREDICT_TIME_AHEAD", 3.0],

    // 🆕 COMBAT EVASIVE
    ["COMBAT_EVASIVE", true],
    ["COMBAT_SERPENTINE_INTERVAL", 3.0],
    ["COMBAT_SPEED_MULT", 1.15],

    // Stuck logic
    ["STUCK_TIME", 2.5],
    ["STUCK_SPEED", 8],
    ["REVERSE_TIME", 2.0],
    ["REVERSE_SPEED_KMH", 25],

    // Emergency brake - only for imminent collisions
    ["EMERGENCY_BRAKE_DIST", 2],        // 🆕 Reduced from 3 (less braking)

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

// 🆕 Multi-layer exclusion system - EXCLUDES old A3XAI, ENHANCES new A3XAI Elite
EAD_fnc_isA3XAIVehicle = {
    params ["_veh", "_driver"];

    // Layer 1: Check EAID_Ignore flag (manual exclusions)
    if (_veh getVariable ["EAID_Ignore", false]) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD 9.7] EXCLUDED (EAID_Ignore): %1", typeOf _veh];
        };
        true
    };

    // Layer 2: Check driver for OLD A3XAI variables (exclude old A3XAI only)
    // NOTE: A3XAI Elite Edition uses different variables and is NOT excluded here
    if (!isNull _driver) then {
        private _group = group _driver;

        // OLD A3XAI detection (still exclude these for backwards compatibility)
        if (
            _driver getVariable ["A3XAI_AIUnit", false] ||        // Old A3XAI
            _driver getVariable ["UPSMON_Grp", false] ||          // UPSMON AI
            _group getVariable ["A3XAI_dynGroup", false] ||       // Old A3XAI
            _group getVariable ["A3XAI_staticGroup", false]       // Old A3XAI
        ) exitWith {
            if (EAD_CFG get "DEBUG_ENABLED") then {
                diag_log format ["[EAD 9.7] OLD A3XAI EXCLUDED (unit vars): %1", typeOf _veh];
            };
            true
        };
    };

    // Layer 3: Check vehicle for OLD A3XAI ownership markers
    // NOTE: A3XAI Elite uses lowercase "A3XAI_vehicle" which is NOT checked here
    if (
        _veh getVariable ["A3XAI_VehOwned", false] ||            // Old A3XAI
        _veh getVariable ["A3XAI_Vehicle", false]                // Old A3XAI (capital V)
    ) exitWith {
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD 9.7] OLD A3XAI EXCLUDED (veh vars): %1", typeOf _veh];
        };
        true
    };

    // NOT excluded - safe to enhance (includes A3XAI Elite Edition!)
    false
};

/* =====================================================================================
    SECTION 3A — VEHICLE TOP SPEED DETECTION (v9.6)
===================================================================================== */

// 🆕 v9.6: Get vehicle's actual top speed from config
EAD_fnc_getVehicleTopSpeed = {
    params ["_veh"];

    private _type = typeOf _veh;
    private _cached = _veh getVariable ["EAD_cachedTopSpeed", -1];

    if (_cached > 0) exitWith {_cached};

    // Read maxSpeed from vehicle config
    private _maxSpeed = getNumber (configFile >> "CfgVehicles" >> _type >> "maxSpeed");

    // Fallback if config read fails
    if (_maxSpeed <= 0) then {
        _maxSpeed = EAD_CFG get "HIGHWAY_BASE";
        diag_log format ["[EAD] WARNING: Could not read maxSpeed for %1, using fallback %2", _type, _maxSpeed];
    } else {
        diag_log format ["[EAD] Vehicle %1 maxSpeed: %2 km/h", _type, _maxSpeed];
    };

    _veh setVariable ["EAD_cachedTopSpeed", _maxSpeed];
    _maxSpeed
};

/* =====================================================================================
    SECTION 3B — WAYPOINT DETECTION (v9.6)
===================================================================================== */

// 🆕 v9.6: Get current waypoint position for driver's group
EAD_fnc_getWaypointTarget = {
    params ["_veh"];

    if !(EAD_CFG get "WAYPOINT_ENABLED") exitWith {[]};

    private _driver = driver _veh;
    if (isNull _driver) exitWith {[]};

    private _grp = group _driver;
    if (isNull _grp) exitWith {[]};

    // Check for player command via group waypoints
    private _wpCount = count waypoints _grp;
    if (_wpCount == 0) exitWith {[]};

    private _currentWP = currentWaypoint _grp;
    if (_currentWP >= _wpCount) exitWith {[]};

    private _wpPos = waypointPosition [_grp, _currentWP];

    // Skip if waypoint is at origin (invalid)
    if (_wpPos isEqualTo [0,0,0]) exitWith {[]};

    // Check distance to waypoint
    private _distToWP = _veh distance2D _wpPos;

    // If arrived at waypoint, skip
    if (_distToWP < (EAD_CFG get "WAYPOINT_ARRIVE_DIST")) exitWith {
        // Complete waypoint
        [_grp, _currentWP] setWaypointPosition [getPos _veh, 0];
        diag_log format ["[EAD] Arrived at waypoint, distance: %1m", round _distToWP];
        []
    };

    _wpPos
};

// 🆕 v9.6: Calculate steering bias toward waypoint
EAD_fnc_waypointSteeringBias = {
    params ["_veh", "_wpPos"];

    if (count _wpPos < 2) exitWith {0};

    private _vehPos = getPos _veh;
    private _vehDir = getDir _veh;

    // Calculate angle to waypoint
    private _dx = (_wpPos select 0) - (_vehPos select 0);
    private _dy = (_wpPos select 1) - (_vehPos select 1);
    private _targetAngle = (_dx atan2 _dy);

    // Normalize to 0-360
    if (_targetAngle < 0) then {_targetAngle = _targetAngle + 360};

    // Calculate angle difference
    private _angleDiff = _targetAngle - _vehDir;

    // Normalize to -180 to 180
    while {_angleDiff > 180} do {_angleDiff = _angleDiff - 360};
    while {_angleDiff < -180} do {_angleDiff = _angleDiff + 360};

    // Return steering bias (-1 to 1 range, scaled for smooth steering)
    // Positive = turn right, Negative = turn left
    private _steerBias = _angleDiff / 90;  // Full steering at 90 degree offset
    _steerBias = _steerBias max -1 min 1;

    _steerBias
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

// ✅ OPTIMIZED RAYCAST v9.9 - Think like a driver at 150km/h
// At high speed you need: forward vision, steering info, that's it
// Old: 41 rays × 4 heights = 164 calls per tick (insane)
// New: Smart rays with selective heights = ~25 calls per tick
EAD_fnc_rayBatchAdvanced = {
    params ["_veh", "_rayDefs"];

    private _vehPos = getPosASL _veh;
    private _dir = getDir _veh;
    private _distances = [];
    private _obstacleInfo = [];

    {
        _x params ["_angleOffset", "_dist"];
        private _ang = _dir + _angleOffset;
        private _vec = [sin _ang, cos _ang, 0];
        private _absAngle = abs _angleOffset;

        private _minDist = _dist;
        private _obstacleType = "NONE";
        private _obstacleObject = objNull;

        // Smart height selection based on ray angle:
        // - Forward (0-15°): Check ground + bumper height (cars, rocks, barriers)
        // - Steering (15-45°): Ground only (walls, trees)
        // - Peripheral (45°+): Ground only, shorter range
        private _heights = if (_absAngle <= 15) then {
            [0.3, 0.8]  // Bumper + hood height - catch cars, barriers, rocks
        } else {
            [0.4]       // Single mid-height ray for walls/trees
        };

        {
            private _startPos = _vehPos vectorAdd [0, 0, _x];
            private _endPos = _startPos vectorAdd (_vec vectorMultiply _dist);

            private _hits = lineIntersectsSurfaces [_startPos, _endPos, _veh, objNull, true, 1, "GEOM", "NONE"];

            if (count _hits > 0) then {
                private _hit = _hits select 0;
                private _hitPos = _hit select 0;
                private _hitDist = _startPos vectorDistance _hitPos;

                if (_hitDist < _minDist) then {
                    _minDist = _hitDist;

                    if (count _hit > 2) then {
                        private _hitObj = _hit select 2;
                        if (!isNull _hitObj && _obstacleType == "NONE") then {
                            _obstacleType = if (_hitObj isKindOf "Man") then {"INFANTRY"}
                                else {if (_hitObj isKindOf "LandVehicle") then {"VEHICLE"} else {"STATIC"}};
                            _obstacleObject = _hitObj;
                        };
                    };
                };
            };
        } forEach _heights;

        _distances pushBack _minDist;
        _obstacleInfo pushBack [_obstacleType, _obstacleObject];
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

// ✅ OPTIMIZED SCAN v9.9 - Quality over quantity
// Think like a driver: you look ahead, glance sides, that's it
// Old: 41 rays (overkill, CPU heavy)
// New: 15 rays (focused, fast, effective)
EAD_fnc_scanAdaptive = {
    params ["_veh"];

    private _far = EAD_CFG get "DIST_MAIN";    // 50m - forward scan
    private _mid = EAD_CFG get "DIST_WIDE";    // 35m - steering scan
    private _near = EAD_CFG get "DIST_SIDE";   // 15m - side scan

    // 15 RAYS - All you need at 150km/h:
    // Forward cone (where you're going)
    // Steering zone (where you might turn)
    // Side glance (am I about to sideswipe something)
    private _rayDefinitions = [
        // FORWARD CONE - Your main focus (5 rays, long range)
        ["F0", 0, _far],            // Dead ahead - most important
        ["FL1", -8, _far],          // Slight left
        ["FR1", 8, _far],           // Slight right
        ["FL2", -16, _mid],         // Left quarter
        ["FR2", 16, _mid],          // Right quarter

        // STEERING ZONE - Where you'll turn into (4 rays)
        ["L", -30, _mid],           // Left turn zone
        ["R", 30, _mid],            // Right turn zone
        ["CL", -50, _near],         // Sharp left (tight corners)
        ["CR", 50, _near],          // Sharp right (tight corners)

        // SIDE AWARENESS - Don't sideswipe (4 rays)
        ["NL", -75, _near],         // Left side
        ["NR", 75, _near],          // Right side
        ["L2", -45, _near],         // Left-forward diagonal
        ["R2", 45, _near],          // Right-forward diagonal

        // WIDE CORNERS - For 90° turns only (2 rays)
        ["CL2", -70, _near],        // Hard left
        ["CR2", 70, _near]          // Hard right
    ];

    private _rayDefs = _rayDefinitions apply {[_x#1, _x#2]};
    private _batchResult = [_veh, _rayDefs] call EAD_fnc_rayBatchAdvanced;
    _batchResult params ["_distances", "_obstacleInfo"];

    private _map = createHashMap;
    {
        _x params ["_label", "_angleOffset", "_distance"];
        _map set [_label, _distances select _forEachIndex];
        private _obsInfo = _obstacleInfo select _forEachIndex;
        _map set [_label + "_OBS", _obsInfo select 0];
        _map set [_label + "_OBJ", _obsInfo select 1];
    } forEach _rayDefinitions;

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
    // ✅ FIX: expectedDestination returns [position, time] - extract just the position
    private _expectedData = expectedDestination _veh;
    if (count _expectedData < 1) exitWith {[false, 0]};

    private _expectedPos = _expectedData select 0;  // Extract position from [position, time]
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

    // 🆕 v9.7: Get vehicle's FULL top speed
    private _base = if (EAD_CFG get "USE_VEHICLE_TOPSPEED") then {
        private _topSpeed = [_veh] call EAD_fnc_getVehicleTopSpeed;
        _topSpeed * (EAD_CFG get "TOPSPEED_MULTIPLIER")  // 100% of top speed
    } else {
        EAD_CFG get "HIGHWAY_BASE"
    };

    // 🆕 v9.7: Check for urban speed limits
    private _urbanSpeed = [_veh] call EAD_fnc_getUrbanSpeed;
    if (_urbanSpeed > 0) then {
        // In urban area - use urban speed limit as base
        _base = _urbanSpeed;
    };

    // Off-road penalty
    if (!_isRoad) then {_base = _base * (_profile get "offroad")};
    if (_dense) then {_base = _base * 0.95};  // Less penalty in forest

    // 🆕 v9.7: ROADKILL MODE - Speed up when EAST AI ahead
    private _hasRoadkillTarget = [_veh] call EAD_fnc_detectRoadkillTarget;
    if (_hasRoadkillTarget) then {
        _base = _base * (EAD_CFG get "ROADKILL_SPEED_BOOST");
        _veh setVariable ["EAD_roadkillMode", true];
    } else {
        _veh setVariable ["EAD_roadkillMode", false];
    };

    // Curve detection - only slow for SHARP turns
    private _curveType = [_s] call EAD_fnc_detectCurveType;
    switch (_curveType) do {
        case "GENTLE": {_base = _base * (EAD_CFG get "CURVE_GENTLE_MULT")};  // 100% - no slowdown
        case "SHARP": {_base = _base * (EAD_CFG get "CURVE_SHARP_MULT")};    // 40% - 90° turns only
        case "MEDIUM": {_base = _base * 0.90};  // 90% - slight slowdown
    };

    // Apex racing boost
    if (_curveType != "GENTLE" && (EAD_CFG get "APEX_ENABLED")) then {
        private _onApex = _veh getVariable ["EAD_onApex", false];
        if (_onApex) then {_base = _base * (EAD_CFG get "APEX_SPEED_BOOST")};
    };

    // Steep slope penalty
    if (_slope > 0.45) then {_base = _base * 0.75};

    // Combat speed boost
    _base = _base * ([_veh] call EAD_fnc_getCombatMultiplier);

    // 🆕 v9.7: Minimum speed 30 km/h (prevent crawling)
    _base max 30
};

EAD_fnc_obstacleLimit = {
    params ["_veh","_s","_cur"];

    // Check forward cone rays (the ones that matter for braking)
    private _m = selectMin [
        _s get "F0",   // Dead ahead
        _s get "FL1",  // Slight left
        _s get "FR1",  // Slight right
        _s get "FL2",  // Quarter left
        _s get "FR2"   // Quarter right
    ];

    // Don't slow for infantry if plenty of room
    private _f0ObsType = _s get "F0_OBS";
    if (_f0ObsType == "INFANTRY" && _m > 15) exitWith {_cur};

    // Progressive braking - smooth slowdown based on distance
    if (_m < 12) then {_cur = _cur * 0.75};   // Start slowing at 12m
    if (_m < 7) then {_cur = _cur * 0.50};    // Moderate brake at 7m
    if (_m < 4) then {_cur = _cur * 0.25};    // Hard brake at 4m

    _cur
};

EAD_fnc_altitudeCorrection = {
    params ["_veh","_spd","_terrain"];
    private _slope = _terrain select 1;
    if (_slope > 0.50) exitWith {_spd * 0.70};
    if (_slope > 0.35) exitWith {_spd * 0.85};
    _spd
};

// 🆕 v9.7: Check if in urban area (city/town/village)
EAD_fnc_getUrbanSpeed = {
    params ["_veh"];
    private _pos = getPosATL _veh;

    // Check nearby locations
    private _locations = nearestLocations [_pos, ["NameCityCapital", "NameCity", "NameVillage", "NameLocal"], 500];

    if (count _locations == 0) exitWith {-1};  // Not in urban area

    private _loc = _locations select 0;
    private _type = type _loc;
    private _dist = _pos distance2D (locationPosition _loc);
    private _size = size _loc;
    private _radius = ((_size select 0) max (_size select 1)) max 50;

    // Only apply urban speed if actually inside the location
    if (_dist > _radius) exitWith {-1};

    switch (_type) do {
        case "NameCityCapital": {EAD_CFG get "CITY_SPEED"};
        case "NameCity": {EAD_CFG get "CITY_SPEED"};
        case "NameVillage": {EAD_CFG get "VILLAGE_SPEED"};
        case "NameLocal": {EAD_CFG get "TOWN_SPEED"};
        default {-1};
    }
};

// 🆕 v9.7: Detect EAST AI on road for roadkill
EAD_fnc_detectRoadkillTarget = {
    params ["_veh"];

    if !(EAD_CFG get "ROADKILL_ENABLED") exitWith {false};

    private _dir = getDir _veh;
    private _pos = getPosATL _veh;
    private _range = EAD_CFG get "ROADKILL_DETECT_RANGE";

    // Look for EAST AI ahead on road
    private _targets = _pos nearEntities [["Man"], _range];
    private _foundTarget = false;

    {
        if (side _x == EAST && alive _x) then {
            private _targetPos = getPosATL _x;
            private _targetDir = _pos getDir _targetPos;
            private _angleDiff = abs(_targetDir - _dir);
            if (_angleDiff > 180) then {_angleDiff = 360 - _angleDiff};

            // Target must be ahead (within 45 degrees)
            if (_angleDiff < 45 && isOnRoad _targetPos) then {
                _foundTarget = true;
                _veh setVariable ["EAD_roadkillTarget", _x];
            };
        };
    } forEach _targets;

    _foundTarget
};

EAD_fnc_applyBridgeMode = {
    params ["_veh","_spd"];
    private _b = [_veh] call EAD_fnc_isBridge;
    private _now = time;

    if (_b) then {
        private _bridgeEnterTime = _veh getVariable ["EAD_bridgeEnterTime", 0];
        if (_bridgeEnterTime == 0) then {
            _veh setVariable ["EAD_bridgeEnterTime", _now];
            private _boostMult = EAD_CFG get "BRIDGE_SPEED_BOOST";
            private _entrySpeed = (speed _veh) max 60;  // Minimum 60 km/h on bridge
            _veh setVariable ["EAD_bridgeSpeed", _entrySpeed * _boostMult];
            diag_log format ["[EAD 9.7] BRIDGE MODE: %1x boost, %2 km/h target", _boostMult, _entrySpeed * _boostMult];
        };

        private _bridgeTime = _now - _bridgeEnterTime;
        private _noBrakeTime = EAD_CFG get "BRIDGE_NO_BRAKE_TIME";

        if (_bridgeTime < _noBrakeTime) then {
            _veh setVariable ["EAD_onBridge", true];
            _veh setVariable ["EAD_bridgeNoBrake", true];

            // 🆕 v9.7: FORCE VEHICLE FORWARD - No steering, full throttle
            if (EAD_CFG get "BRIDGE_FORCE_FORWARD") then {
                private _driver = driver _veh;
                if (!isNull _driver && !isPlayer _driver) then {
                    private _dir = getDir _veh;
                    private _targetSpeed = _veh getVariable ["EAD_bridgeSpeed", 100];
                    private _targetSpeedMS = _targetSpeed / 3.6;  // Convert km/h to m/s

                    // Get current velocity
                    private _vel = velocity _veh;
                    private _currentSpeed = vectorMagnitude [_vel select 0, _vel select 1, 0];

                    // If too slow, accelerate hard
                    if (_currentSpeed < _targetSpeedMS) then {
                        private _accel = (_targetSpeedMS - _currentSpeed) min 5;  // Max 5 m/s acceleration
                        _targetSpeedMS = _currentSpeed + _accel;
                    };

                    // Force velocity straight ahead at target speed
                    private _newVel = [
                        sin _dir * _targetSpeedMS,
                        cos _dir * _targetSpeedMS,
                        (_vel select 2) max -2  // Prevent diving
                    ];
                    _veh setVelocity _newVel;

                    // Force AI to keep throttle
                    _driver action ["YOURSPEED", _veh, _targetSpeed];
                };
            };

            // Return boosted speed
            _spd = _veh getVariable ["EAD_bridgeSpeed", _spd];
        } else {
            _veh setVariable ["EAD_bridgeNoBrake", false];
        };
    } else {
        if (_veh getVariable ["EAD_onBridge", false]) then {
            diag_log "[EAD 9.7] BRIDGE MODE: Exited bridge";
        };
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

    // Simple: find clearest path in forward cone
    private _cand = [
        ["F0", 0, _s get "F0"],       // Straight ahead (prefer)
        ["FL1", -8, _s get "FL1"],    // Slight left
        ["FR1", 8, _s get "FR1"],     // Slight right
        ["FL2", -16, _s get "FL2"],   // Quarter left
        ["FR2", 16, _s get "FR2"],    // Quarter right
        ["L", -30, _s get "L"],       // Turn left
        ["R", 30, _s get "R"]         // Turn right
    ];

    // Prefer going straight - boost center ray
    {if ((_x#0) == "F0") then {_x set [2, (_x#2) * 1.3]}} forEach _cand;

    // Pick clearest direction
    _cand sort false;
    private _best = _cand#0;
    private _ang = _best#1;
    private _dist = _best#2;

    // Apex cutting on curves
    private _curveType = [_s] call EAD_fnc_detectCurveType;
    private _apexAngle = [_veh, _s, _curveType] call EAD_fnc_calculateApex;
    if (_apexAngle != 0) then {
        _ang = _ang + _apexAngle;
        _veh setVariable ["EAD_onApex", true];
    } else {
        _veh setVariable ["EAD_onApex", false];
    };

    // Urgency: closer obstacles = sharper steering
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

    // 🆕 v9.6: WAYPOINT STEERING - Drive toward player waypoint if set
    private _wpPos = [_veh] call EAD_fnc_getWaypointTarget;
    private _wpBias = 0;
    private _hasWaypoint = count _wpPos > 0;

    if (_hasWaypoint) then {
        _wpBias = [_veh, _wpPos] call EAD_fnc_waypointSteeringBias;
        // Log waypoint following (once per 5 seconds to avoid spam)
        private _lastWPLog = _veh getVariable ["EAD_lastWPLog", 0];
        if (time - _lastWPLog > 5) then {
            private _distToWP = _veh distance2D _wpPos;
            diag_log format ["[EAD] Following waypoint: %1m away, steering bias: %2", round _distToWP, _wpBias toFixed 2];
            _veh setVariable ["EAD_lastWPLog", time];
        };
    };

    // Simple steering: use side rays to stay centered, path to find clear direction
    private _center = ((_s get "L") - (_s get "R")) * 0.004;           // Turn toward clear side
    _center = _center + (((_s get "CL") - (_s get "CR")) * 0.002);    // Corner awareness

    private _path = [_s,_dir,_veh] call EAD_fnc_pathBias;
    private _drift = [_veh] call EAD_fnc_driftBias;

    // Side obstacle avoidance
    private _near = 0;
    if ((_s get "NL") < 8) then {_near = _near + 0.03};  // Something close on left, steer right
    if ((_s get "NR") < 8) then {_near = _near - 0.03};  // Something close on right, steer left

    // Steering intensity based on turn sharpness
    private _turnSharpness = abs((_s get "L") - (_s get "R"));
    private _steeringMultiplier = if (_turnSharpness > 50) then {70} else {
        if (_turnSharpness > 30) then {60} else {50}
    };

    // Combine all inputs: obstacles + waypoint + drift correction
    private _waypointWeight = if (_hasWaypoint) then {0.4} else {0};
    private _baseBias = _center + (_path * 0.02) + _drift + _near;
    private _bias = (_baseBias + (_wpBias * _waypointWeight)) max -0.4 min 0.4;
    private _newDir = _dir + (_bias * _steeringMultiplier);

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

    // ✅ RECRUIT_AI EXCLUSIVE - Only accept vehicles flagged by recruit_ai.sqf
    if !(_veh getVariable ["RECRUIT_AI_VEHICLE", false]) exitWith {
        // Not a recruit_ai vehicle - skip registration
        if (EAD_CFG get "DEBUG_ENABLED") then {
            diag_log format ["[EAD] Skipping %1 - not a RECRUIT_AI_VEHICLE", typeOf _veh];
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

    // Track driving session in performance monitor
    if (!isNil "PERFMON_fnc_recordDrivingSession") then {
        [] call PERFMON_fnc_recordDrivingSession;
    };

    [_unit,_veh] spawn EAD_fnc_runDriver;
};

/* =====================================================================================
    SECTION 12 — AUTO-DETECTION (DISABLED - RECRUIT_AI EXCLUSIVE)
===================================================================================== */

// ✅ AUTO-DETECTION DISABLED
// EAD is now RECRUIT_AI EXCLUSIVE
// Only recruit_ai.sqf can register vehicles via RECRUIT_fnc_ForceEADReregister
// This prevents conflicts with A3XAI, mission AI, and other AI systems

/* ORIGINAL AUTO-DETECTION LOOP - NOW DISABLED
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
*/

/* =====================================================================================
    SECTION 13 — PERF LOG
===================================================================================== */

[] spawn {
    while {true} do {
        uiSleep 600;

        diag_log format [
            "[EAD 9.7 APEX] Vehicles:%1 | A3XAI Excluded:%2 | Avg:%3ms | Max:%4ms",
            EAD_Stats get "totalVehicles",
            EAD_Stats get "a3xaiExcluded",
            ((EAD_Stats get "avgTickTime") * 1000) toFixed 2,
            ((EAD_Stats get "maxTickTime") * 1000) toFixed 2
        ];

        EAD_Stats set ["maxTickTime",0];
    };
};

diag_log "======================================================";
diag_log "[EAD 9.9 APEX EDITION] INITIALIZED - OPTIMIZED";
diag_log "[EAD 9.9] 🔥 CRITICAL FIX: Raycast system actually works now!";
diag_log "[EAD 9.9] 🔥 OPTIMIZED: 15 smart rays vs 164 wasteful ones";
diag_log "[EAD 9.9] 🔥 OPTIMIZED: Height-adaptive raycasting";
diag_log "[EAD 9.9] ✅ Forward + steering + side awareness";
diag_log "[EAD 9.9] ✅ Waypoint following + apex racing";
diag_log "[EAD 9.9] ✅ Performance monitoring enabled";
diag_log "======================================================";

/* =====================================================================================
    END OF FILE
===================================================================================== */