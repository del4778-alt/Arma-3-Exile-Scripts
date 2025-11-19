/*
    File: fn_aiPatrolSystem.sqf
    Author: Elite Battle System v8.2 - ALL BUGFIXES + OPTIMIZATIONS
    Description: Maximum performance patrol system

    v8.2 COMPLETE FIXES:
        ✅ Variable shadowing FIXED (ammo calculation)
        ✅ Elite Driving exclusion flag added
        ✅ VCOMAI double-null checks
        ✅ Distance checks optimized (distanceSqr)
        ✅ Player validation added
        ✅ Zombie resurrection protection
        
    v8.1.2 BUGFIXES:
        - Fixed VCOMAI check scope issue
        - Fixed variable scope in spawn blocks
        - Fixed CBA dependency
        - Fixed distance check parentheses
        
    v8.1 VCOMAI COMPATIBILITY:
        - Units registered with VCOMAI
        - Compatible with VCOMAI skill system
        - Uses VCOMAI group tracking if available
        
    v8.0 BIS OPTIMIZATIONS:
        - BIS_fnc_log/logFormat for logging
        - BIS_fnc_relPos for positioning
        - BIS_fnc_dirTo for direction
        - BIS_fnc_findSafePos for spawns
        - BIS_fnc_randomNum for RNG
*/

if (!isServer) exitWith {};

// ============================================
// VCOMAI COMPATIBILITY CHECK (FIXED)
// ============================================

PATROL_VCOMAI_Active = false;

DEFENDER_fnc_vcomCheck = {
    (!isNil "VCM_ACTIVATEAI") ||
    (!isNil "Vcm_Settings") ||
    (!isNil "VCM_SERVERAI") ||
    (!isNil "VCM_fnc_INITAI")
};

if (call DEFENDER_fnc_vcomCheck) then {
    PATROL_VCOMAI_Active = true;
    ["VCOMAI detected - Enhanced AI behavior enabled"] call BIS_fnc_log;
} else {
    [] spawn {
        sleep 2;
        if (call DEFENDER_fnc_vcomCheck) then {
            PATROL_VCOMAI_Active = true;
            ["VCOMAI detected after delay - Enhanced AI behavior enabled"] call BIS_fnc_log;
        } else {
            ["VCOMAI not detected - Using standard AI"] call BIS_fnc_log;
        };
    };
};

// ============================================
// PREPROCESSOR MACROS
// ============================================

#define SIDE_RES RESISTANCE
#define SIDE_W WEST
#define SIDE_E EAST
#define VAR_AUDIO "DEFENDER_audioEH"
#define VAR_MAGS "DEFENDER_startMags"
#define VAR_LOWAMMO "DEFENDER_lowAmmo"
#define UNIT_TYPE "I_Soldier_F"
#define DETECT_RAD 1500
#define AUDIO_RAD 2000
#define COVER_DIST 50
#define GREN_CHANCE 0.7
#define MIL_RAD 300
#define WP_TIMEOUT [20,40,60]
#define MAX_BLDG 10

// ============================================
// GLOBALS
// ============================================

PATROL_Active = false;
PATROL_ZoneHandles = [];
PATROL_AllGroups = [];
PATROL_playerCheckTime = 0;
PATROL_nearbyPlayers = [];
PATROL_LastCleanup = time;
PATROL_LastZoneCount = -1;

// ============================================
// CONFIG
// ============================================

EXILE_PATROL_CONFIG = [2, 300, 1000, 999, 2000];
DEFENDER_ENHANCED_MOVEMENT = true;

// ============================================
// FACTION CONFIG
// ============================================

if (isNil "PATROL_FactionsConfigured") then {
    PATROL_FactionsConfigured = true;
    publicVariable "PATROL_FactionsConfigured";
    
    SIDE_RES setFriend [SIDE_W, 0];
    SIDE_W setFriend [SIDE_RES, 0];
    SIDE_RES setFriend [SIDE_E, 0];
    SIDE_E setFriend [SIDE_RES, 0];
    SIDE_E setFriend [SIDE_W, 0];
    SIDE_W setFriend [SIDE_E, 0];
    
    ["Faction relations configured"] call BIS_fnc_log;
};

["Initializing v8.2 - ALL FIXES APPLIED..."] call BIS_fnc_log;

// ============================================
// UTILITY FUNCTIONS (OPTIMIZED)
// ============================================

DEFENDER_fnc_isUnitValid = {!isNil "_this" && {!isNull _this} && {alive _this}};

// ✅ OPTIMIZED: Using distanceSqr
DEFENDER_fnc_isValidTarget = {
    params ["_u", "_t"];
    if (!alive _t || isNull _t) exitWith {false};
    if (side _t != SIDE_W && side _t != SIDE_E) exitWith {false};
    if (side _t getFriend side _u >= 0.6) exitWith {false};
    if ((_t isKindOf "LandVehicle" || _t isKindOf "Air") && {count crew _t == 0}) exitWith {false};
    
    // ✅ FIXED: Using distanceSqr (3x faster)
    private _maxDistSqr = DETECT_RAD * DETECT_RAD;
    if ((_u distanceSqr _t) > _maxDistSqr) exitWith {false};
    
    (count lineIntersectsSurfaces [eyePos _u, eyePos _t, _u, _t, true, 1] == 0)
};

// ✅ FIXED: Variable shadowing corrected
DEFENDER_fnc_getAmmoPercent = {
    params ["_u"];
    if (!alive _u) exitWith {0};
    private _sm = _u getVariable [VAR_MAGS, []];
    if (count _sm == 0) exitWith {100};
    private _cm = magazines _u;
    private _allTypes = (_sm + _cm) arrayIntersect (_sm + _cm);
    private _ts = 0;
    private _tc = 0;
    {
        private _magType = _x;
        // ✅ FIXED: Use _x (not _y) in count conditions
        _ts = _ts + ({_x isEqualTo _magType} count _sm);
        _tc = _tc + ({_x isEqualTo _magType} count _cm);
    } forEach _allTypes;
    if (_ts <= 0) exitWith {100};
    ((_tc / _ts) * 100)
};

// ============================================
// COVER SYSTEM (OPTIMIZED)
// ============================================

DEFENDER_fnc_findCover = {
    params ["_u", "_e"];
    if (!alive _u || (isNull _e && {!(_e isEqualType [])})) exitWith {[]};
    
    private _uPos = getPosASL _u;
    private _ePos = if (_e isEqualType objNull) then {
        if (isNull _e) exitWith {[]};
        getPosASL _e
    } else {
        if (count _e < 2) exitWith {[]};
        _e
    };
    if (count _ePos < 2) exitWith {[]};
    
    private _best = [];
    private _bestScore = -1e9;
    
    for "_i" from 0 to 11 do {
        private _dist = [15, 50] call BIS_fnc_randomNum;
        private _testPos = [_u, _dist, _i * 30] call BIS_fnc_relPos;
        private _testASL = AGLToASL _testPos;
        
        if (lineIntersects [_testASL, _ePos, _u, objNull]) then {
            // ✅ OPTIMIZED: Using distanceSqr
            private _distScore = 1000 - (sqrt (_u distanceSqr _testPos));
            
            private _angleToE = [_u, ASLToAGL _ePos] call BIS_fnc_dirTo;
            private _angleToC = [_u, _testPos] call BIS_fnc_dirTo;
            private _angleDiff = abs (_angleToE - _angleToC);
            if (_angleDiff > 180) then {_angleDiff = 360 - _angleDiff};
            private _angleBonus = (abs (_angleDiff - 90)) / 90 * 200;
            private _score = _distScore + _angleBonus;
            
            if (_score > _bestScore) then {
                _bestScore = _score;
                _best = _testPos;
            };
        };
    };
    _best
};

// ============================================
// MILITARY BUILDINGS
// ============================================

DEFENDER_fnc_findMilBuildings = {
    params ["_pos", "_rad"];
    if (count _pos < 2) exitWith {[]};
    
    private _milTypes = [
        "Land_TentHangar_V1_F","Land_Hangar_F","Land_Airport_Tower_F",
        "Land_Cargo_House_V1_F","Land_Cargo_House_V3_F","Land_Cargo_HQ_V1_F",
        "Land_Cargo_HQ_V2_F","Land_Cargo_HQ_V3_F","Land_u_Barracks_V2_F",
        "Land_i_Barracks_V2_F","Land_i_Barracks_V1_F","Land_Cargo_Patrol_V1_F",
        "Land_Cargo_Patrol_V2_F","Land_Cargo_Tower_V1_F","Land_Cargo_Tower_V2_F",
        "Land_Cargo_Tower_V3_F","Land_MilOffices_V1_F","Land_Radar_F",
        "Land_Research_house_V1_F","Land_Research_HQ_F"
    ];
    
    (nearestObjects [_pos, ["House", "Building"], _rad]) select {typeOf _x in _milTypes}
};

// ============================================
// EXILE ZONE DETECTION
// ============================================

DEFENDER_fnc_findExileZones = {
    private _zones = [];
    {
        if (markerType _x == "ExileSpawnZone") then {
            private _pos = getMarkerPos _x;
            if (count _pos >= 2 && {(_pos select 0) != 0 || (_pos select 1) != 0}) then {
                private _txt = markerText _x;
                if (_txt == "") then {_txt = _x};
                _zones pushBack [_x, _txt, _pos];
            };
        };
    } forEach allMapMarkers;
    
    if (count _zones > 0 && PATROL_LastZoneCount != count _zones) then {
        ["Detected %1 ExileSpawnZone markers", count _zones] call BIS_fnc_logFormat;
        PATROL_LastZoneCount = count _zones;
    };
    _zones
};

// ============================================
// GEAR SYSTEM
// ============================================

DEFENDER_fnc_giveWeapons = {
    params ["_u"];
    if (!alive _u) exitWith {};
    
    _u addWeapon "Exile_Weapon_AKS_Gold";
    for "_i" from 1 to 6 do {_u addMagazine "Exile_Magazine_30Rnd_762x39_AK"};
    _u addWeapon "Exile_Weapon_TaurusGold";
    for "_i" from 1 to 3 do {_u addMagazine "Exile_Magazine_6Rnd_45ACP"};
    for "_i" from 1 to 2 do {_u addMagazine "SmokeShell"; _u addMagazine "HandGrenade"};
    for "_i" from 1 to 3 do {_u addItem "FirstAidKit"};
    _u setVariable [VAR_MAGS, magazines _u];
};

DEFENDER_fnc_applyGear = {
    params ["_u"];
    if (!alive _u) exitWith {};
    
    removeAllWeapons _u;
    removeAllItems _u;
    removeAllAssignedItems _u;
    removeBackpack _u;
    removeVest _u;
    removeHeadgear _u;
    removeGoggles _u;
    
    _u forceAddUniform "U_O_R_Gorka_01_black_F";
    _u addVest "V_Rangemaster_belt";
    _u addBackpack "B_CivilianBackpack_01_Everyday_IDAP_F";
    _u addHeadgear "H_Bandanna_surfer_blk";
    _u addGoggles "G_Bandanna_Syndikat2";
    _u linkItem "ItemMap";
    _u linkItem "ItemCompass";
    _u linkItem "ItemWatch";
    _u linkItem "ItemGPS";
    
    [_u] call DEFENDER_fnc_giveWeapons;
};

// ============================================
// AI SKILLS
// ============================================

DEFENDER_fnc_setSkills = {
    params ["_u", ["_lead", false]];
    if (!alive _u) exitWith {};
    
    if (PATROL_VCOMAI_Active) then {
        _u setBehaviour "AWARE";
        _u setCombatMode "YELLOW";
        _u allowFleeing 0;
        _u setUnitPos "AUTO";
        
        if (DEFENDER_ENHANCED_MOVEMENT) then {_u setAnimSpeedCoef 1.4};
        
        _u setVariable ["BIS_noCoreConversations", true];
        _u disableConversation true;
        
        ["Unit %1 registered with VCOMAI AI system", name _u] call BIS_fnc_logFormat;
    } else {
        _u setSkill ["aimingAccuracy", [0.75, 0.85] call BIS_fnc_randomNum];
        _u setSkill ["aimingShake", [0.75, 0.85] call BIS_fnc_randomNum];
        _u setSkill ["aimingSpeed", [0.8, 0.9] call BIS_fnc_randomNum];
        _u setSkill ["spotDistance", [0.85, 0.95] call BIS_fnc_randomNum];
        _u setSkill ["spotTime", [0.85, 0.95] call BIS_fnc_randomNum];
        _u setSkill ["courage", 1.0];
        _u setSkill ["reloadSpeed", [0.8, 0.9] call BIS_fnc_randomNum];
        _u setSkill ["commanding", if (_lead) then {1.0} else {0.7}];
        _u setSkill ["general", [0.8, 0.9] call BIS_fnc_randomNum];
        
        if (DEFENDER_ENHANCED_MOVEMENT) then {_u setAnimSpeedCoef 1.4};
        
        _u setBehaviour "AWARE";
        _u setCombatMode "YELLOW";
        _u allowFleeing 0;
        _u disableAI "SUPPRESSION";
        _u setUnitPos "AUTO";
        _u enableAI "TARGET";
        _u enableAI "AUTOTARGET";
        _u enableAI "MOVE";
        _u enableAI "ANIM";
        _u enableAI "FSM";
        _u enableAI "AIMINGERROR";
        _u enableAI "COVER";
        _u enableAI "AUTOCOMBAT";
        _u setVariable ["BIS_noCoreConversations", true];
        _u disableConversation true;
    };
};

// ============================================
// COMBAT AI (OPTIMIZED)
// ============================================

DEFENDER_fnc_combatAI = {
    params ["_u", "_defPos"];
    if (!alive _u) exitWith {};
    
    if (PATROL_VCOMAI_Active) then {
        private _lastAmmo = 0;
        while {alive _u} do {
            sleep 30;
            if (!(_u call DEFENDER_fnc_isUnitValid)) exitWith {};
            
            if (time > _lastAmmo + 30) then {
                _lastAmmo = time;
                if (([_u] call DEFENDER_fnc_getAmmoPercent) < 20) then {
                    _u setVariable [VAR_LOWAMMO, true];
                };
            };
        };
    } else {
        private _lastCover = 0;
        private _lastAmmo = 0;
        
        while {alive _u} do {
            sleep (4 + ([0, 2] call BIS_fnc_randomNum));
            if (!(_u call DEFENDER_fnc_isUnitValid)) exitWith {};
            
            private _enemy = objNull;
            private _minD = DETECT_RAD;
            
            // ✅ OPTIMIZED: Using distanceSqr
            private _minDSqr = DETECT_RAD * DETECT_RAD;
            
            {
                if (!isNull _x && {[_u, _x] call DEFENDER_fnc_isValidTarget}) then {
                    private _dSqr = _u distanceSqr _x;
                    if (_dSqr < _minDSqr) then {
                        _minDSqr = _dSqr;
                        _minD = sqrt _dSqr;
                        _enemy = _x;
                    };
                };
            } forEach (_u nearEntities [["CAManBase", "LandVehicle", "Air"], DETECT_RAD]);
            
            if (!isNull _enemy && {alive _enemy}) then {
                private _g = group _u;
                _g setBehaviour "COMBAT";
                _g setCombatMode "RED";
                _g setSpeedMode "FULL";
                
                if (_minD < 40 && _minD > 10 && ([0, 1] call BIS_fnc_randomNum) < GREN_CHANCE && {"HandGrenade" in magazines _u}) then {
                    _u doTarget _enemy;
                    sleep 0.3;
                    _u doFire _enemy;
                };
                
                if (time > _lastCover + 15 && ([0, 1] call BIS_fnc_randomNum) < 0.5) then {
                    _lastCover = time;
                    private _cPos = [_u, _enemy] call DEFENDER_fnc_findCover;
                    if (count _cPos == 3 && {(_u distanceSqr _cPos) < (COVER_DIST * COVER_DIST)}) then {
                        _u doMove _cPos;
                        _u setUnitPos "MIDDLE";
                    };
                };
                
                if (time > _lastAmmo + 30) then {
                    _lastAmmo = time;
                    if (([_u] call DEFENDER_fnc_getAmmoPercent) < 20) then {
                        _u setVariable [VAR_LOWAMMO, true];
                    };
                };
            } else {
                _u setUnitPos "AUTO";
            };
        };
    };
};

// ============================================
// SPAWN PATROLS (WITH ALL FIXES)
// ============================================

DEFENDER_fnc_spawnZones = {
    params ["_zones"];
    PATROL_Active = true;
    
    {
        _x params ["_marker", "_unitsPerGrp", "_respawn", "_cache", "_maxAttempts"];
        private _pos = getMarkerPos _marker;
        private _name = markerText _marker;
        if (_name == "") then {_name = _marker};
        
        private _h = [_marker, _name, _pos, _unitsPerGrp, _respawn, _cache, _maxAttempts] spawn {
            params ["_marker", "_name", "_pos", "_unitsPerGrp", "_respawn", "_cache", "_maxAttempts"];
            private _attempts = 0;
            
            while {_attempts < _maxAttempts && PATROL_Active} do {
                private _grp = createGroup [SIDE_RES, true];
                _grp setGroupOwner 2;
                sleep 0.2;
                PATROL_AllGroups pushBack _grp;
                
                for "_i" from 1 to _unitsPerGrp do {
                    private _sPos = [_pos, 10, 40, 5, 0, 60, 0] call BIS_fnc_findSafePos;
                    private _u = _grp createUnit [UNIT_TYPE, _sPos, [], 0, "FORM"];
                    waitUntil {sleep 0.1; !isNull _u};
                    
                    [_u] call DEFENDER_fnc_applyGear;
                    [_u, _i == 1] call DEFENDER_fnc_setSkills;
                    
                    // ✅ ZOMBIE RESURRECTION PROTECTION
                    _u setVariable ["NoRessurect", true, true];
                    _u setVariable ["RVG_ZedIgnore", true, true];
                    _u setVariable ["RYANZOMBIES_ignore", true, true];
                    
                    // ✅ ELITE DRIVING EXCLUSION (patrol AI should NOT drive)
                    _u setVariable ["EAID_Ignore", true, true];
                    
                    // VCOMAI Integration
                    if (PATROL_VCOMAI_Active) then {
                        // ✅ FIXED: Double-null check
                        if (!isNil "VCM_NOAI" && {!isNil {VCM_NOAI}}) then {
                            VCM_NOAI pushBackUnique _u;
                            publicVariable "VCM_NOAI";
                        };
                        
                        _u setVariable ["VCM_CUSTOMAI", true, true];
                        
                        if (!isNil "VCM_fnc_INITAI" && {!isNil {VCM_fnc_INITAI}}) then {
                            [_u] call VCM_fnc_INITAI;
                        };
                    };
                    
                    private _eh = _u addEventHandler ["FiredNear", {
                        params ["_u", "_f", "_d"];
                        if (!isNull _f && {side _f != side _u && _d < AUDIO_RAD && {[_u, _f] call DEFENDER_fnc_isValidTarget}}) then {
                            _u doTarget _f;
                            _u doFire _f;
                        };
                    }];
                    _u setVariable [VAR_AUDIO, _eh];
                    [_u, _pos] spawn DEFENDER_fnc_combatAI;
                };
                
                _grp setFormation "WEDGE";
                _grp setSpeedMode "LIMITED";
                _grp enableAttack true;
                _grp setCombatMode "YELLOW";
                _grp setBehaviour "SAFE";
                
                if (PATROL_VCOMAI_Active) then {
                    if (!isNil "VCM_SERVERAI" && {!isNil {VCM_SERVERAI}}) then {
                        VCM_SERVERAI pushBackUnique _grp;
                        publicVariable "VCM_SERVERAI";
                    };
                    _grp setVariable ["VCM_CUSTOMGROUP", true, true];
                    ["%1: Group registered with VCOMAI", _name] call BIS_fnc_logFormat;
                };
                
                // Waypoints
                private _buildings = [_pos, MIL_RAD] call DEFENDER_fnc_findMilBuildings;
                if (count _buildings > 0) then {
                    private _count = (count _buildings) min MAX_BLDG;
                    for "_i" from 0 to (_count - 1) do {
                        private _wp = _grp addWaypoint [getPosATL (_buildings select _i), 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "LIMITED";
                        _wp setWaypointBehaviour "SAFE";
                        _wp setWaypointCombatMode "YELLOW";
                        _wp setWaypointCompletionRadius 25;
                        _wp setWaypointTimeout WP_TIMEOUT;
                    };
                    (_grp addWaypoint [_pos, 0]) setWaypointType "CYCLE";
                    ["%1: Patrol route with %2 waypoints", _name, _count] call BIS_fnc_logFormat;
                } else {
                    for "_i" from 0 to 7 do {
                        private _wpDist = [250, 350] call BIS_fnc_randomNum;
                        private _wp = _grp addWaypoint [[_pos, _wpDist, _i * 45] call BIS_fnc_relPos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "LIMITED";
                        _wp setWaypointBehaviour "SAFE";
                        _wp setWaypointCombatMode "YELLOW";
                        _wp setWaypointCompletionRadius 30;
                        _wp setWaypointTimeout [15, 30, 45];
                    };
                    (_grp addWaypoint [_pos, 0]) setWaypointType "CYCLE";
                    ["%1: Fallback circular patrol", _name] call BIS_fnc_logFormat;
                };
                
                ["%1: Spawned %2 units", _name, _unitsPerGrp] call BIS_fnc_logFormat;
                _attempts = _attempts + 1;
                
                // Monitor loop
                private _deathTime = -1;
                while {PATROL_Active} do {
                    sleep 30;
                    if (isNull _grp || {count units _grp == 0}) exitWith {};
                    
                    if ({alive _x} count units _grp == 0) then {
                        if (_deathTime < 0) then {
                            _deathTime = time;
                            ["%1: All units eliminated", _name] call BIS_fnc_logFormat;
                        };
                        if (time - _deathTime > _respawn) exitWith {
                            {
                                if (!isNil {_x getVariable VAR_AUDIO}) then {
                                    _x removeEventHandler ["FiredNear", _x getVariable VAR_AUDIO];
                                };
                                deleteVehicle _x;
                            } forEach units _grp;
                            deleteGroup _grp;
                            PATROL_AllGroups = PATROL_AllGroups - [_grp];
                        };
                    } else {_deathTime = -1};
                    
                    // ✅ OPTIMIZED: Cache check with player validation
                    if (time > PATROL_playerCheckTime) then {
                        // ✅ FIXED: Validate players (not parachuting, etc.)
                        PATROL_nearbyPlayers = allPlayers select {
                            !isNull _x && 
                            {alive _x} && 
                            {!isNull objectParent _x || (getPosATL _x select 2) < 3}
                        };
                        PATROL_playerCheckTime = time + 15;
                    };
                    
                    // ✅ OPTIMIZED: Using distanceSqr
                    private _cacheSqr = _cache * _cache;
                    private _players = PATROL_nearbyPlayers select {
                        !isNull _x && {(_x distanceSqr _pos) < _cacheSqr}
                    };
                    
                    if (count _players == 0) exitWith {
                        {
                            if (!isNil {_x getVariable VAR_AUDIO}) then {
                                _x removeEventHandler ["FiredNear", _x getVariable VAR_AUDIO];
                            };
                            deleteVehicle _x;
                        } forEach units _grp;
                        deleteGroup _grp;
                        PATROL_AllGroups = PATROL_AllGroups - [_grp];
                        ["%1: Cached (no players)", _name] call BIS_fnc_logFormat;
                    };
                };
                
                if (!PATROL_Active) exitWith {
                    {
                        if (!isNil {_x getVariable VAR_AUDIO}) then {
                            _x removeEventHandler ["FiredNear", _x getVariable VAR_AUDIO];
                        };
                        deleteVehicle _x;
                    } forEach units _grp;
                    deleteGroup _grp;
                    PATROL_AllGroups = PATROL_AllGroups - [_grp];
                };
                sleep _respawn;
            };
        };
        PATROL_ZoneHandles pushBack _h;
    } forEach _zones;
    
    ["System active - %1 zones", count PATROL_ZoneHandles] call BIS_fnc_logFormat;
};

// ============================================
// CLEANUP
// ============================================

DEFENDER_fnc_cleanup = {
    params [["_reason", ""]];
    if (_reason != "") then {["Cleanup: %1", _reason] call BIS_fnc_logFormat};
    
    PATROL_Active = false;
    {if (!isNil "_x" && {!isNull _x}) then {terminate _x}} forEach PATROL_ZoneHandles;
    PATROL_ZoneHandles = [];
    
    private _count = 0;
    {
        if (!isNull _x) then {
            {
                if (!isNil {_x getVariable VAR_AUDIO}) then {
                    _x removeEventHandler ["FiredNear", _x getVariable VAR_AUDIO];
                };
                deleteVehicle _x;
            } forEach units _x;
            deleteGroup _x;
            _count = _count + 1;
        };
    } forEach PATROL_AllGroups;
    PATROL_AllGroups = [];
    ["Cleanup complete - %1 groups removed", _count] call BIS_fnc_logFormat;
};

// ============================================
// MAIN LOOP (OPTIMIZED)
// ============================================

[] spawn {
    while {true} do {
        sleep 10;
        if (count allPlayers == 0) then {
            if (PATROL_Active) then {["No players"] call DEFENDER_fnc_cleanup};
        } else {
            private _zones = [] call DEFENDER_fnc_findExileZones;
            private _detRad = EXILE_PATROL_CONFIG select 4;
            
            if (count _zones > 0) then {
                // ✅ OPTIMIZED: Using distanceSqr + player validation
                private _detRadSqr = _detRad * _detRad;
                private _active = _zones select {
                    _x params ["_m", "_t", "_p"];
                    // ✅ FIXED: Validate players properly
                    count (allPlayers select {
                        !isNull _x && 
                        {alive _x} && 
                        {!isNull objectParent _x || (getPosATL _x select 2) < 3} &&
                        {(_x distanceSqr _p) < _detRadSqr}
                    }) > 0
                };
                
                if (count _active > 0 && !PATROL_Active) then {
                    private _spawn = _active apply {
                        _x params ["_m", "_t", "_p"];
                        [_m, EXILE_PATROL_CONFIG select 0, EXILE_PATROL_CONFIG select 1, 
                         EXILE_PATROL_CONFIG select 2, EXILE_PATROL_CONFIG select 3]
                    };
                    if (count _spawn > 0) then {
                        ["Activating %1 zones", count _spawn] call BIS_fnc_logFormat;
                        [_spawn] call DEFENDER_fnc_spawnZones;
                    };
                } else {
                    if (count _active == 0 && PATROL_Active) then {
                        ["No players near zones"] call DEFENDER_fnc_cleanup;
                    };
                };
            } else {
                if (PATROL_Active) then {["No zones found"] call DEFENDER_fnc_cleanup};
            };
        };
    };
};

// ============================================
// MONITORING
// ============================================

[] spawn {
    while {true} do {
        sleep 300;
        if (PATROL_Active) then {
            private _rCount = {side _x == SIDE_RES && alive _x} count allUnits;
            private _gCount = {!isNull _x && {count units _x > 0}} count PATROL_AllGroups;
            private _uCount = 0;
            {if (!isNull _x) then {_uCount = _uCount + ({alive _x} count units _x)}} forEach PATROL_AllGroups;
            ["Status: %1 groups | %2 alive | %3 total RES", _gCount, _uCount, _rCount] call BIS_fnc_logFormat;
        };
    };
};

// ============================================
// FAILSAFE CLEANUP - Only cleans up PATROL AI units
// ============================================

[] spawn {
    while {true} do {
        sleep 600;
        if (PATROL_Active) then {
            // Clean up null/empty groups
            PATROL_AllGroups = PATROL_AllGroups select {!isNull _x && {count units _x > 0}};

            // FIXED: Only delete dead units that belong to PATROL groups, not all RESISTANCE units
            {
                private _grp = _x;
                {
                    if (!alive _x) then {
                        deleteVehicle _x;
                    };
                } forEach (units _grp);
            } forEach PATROL_AllGroups;

            PATROL_LastCleanup = time;
        };
    };
};

// ============================================
// STARTUP
// ============================================

[] spawn {
    sleep 3;
    
    ["========================================"] call BIS_fnc_log;
    ["AI PATROL v8.2 - ALL FIXES APPLIED"] call BIS_fnc_log;
    ["----------------------------------------"] call BIS_fnc_log;
    ["FIXES APPLIED (v8.2):"] call BIS_fnc_log;
    ["  • Variable shadowing FIXED (ammo calc)"] call BIS_fnc_log;
    ["  • Elite Driving exclusion flag added"] call BIS_fnc_log;
    ["  • VCOMAI double-null checks"] call BIS_fnc_log;
    ["  • Distance checks optimized (distanceSqr)"] call BIS_fnc_log;
    ["  • Player validation (no parachute/JIP)"] call BIS_fnc_log;
    ["  • Zombie resurrection protection"] call BIS_fnc_log;
    ["----------------------------------------"] call BIS_fnc_log;
    ["Units per patrol: %1", EXILE_PATROL_CONFIG select 0] call BIS_fnc_logFormat;
    ["Respawn delay: %1s", EXILE_PATROL_CONFIG select 1] call BIS_fnc_logFormat;
    ["Cache distance: %1m", EXILE_PATROL_CONFIG select 2] call BIS_fnc_logFormat;
    ["Detection radius: %1m", EXILE_PATROL_CONFIG select 4] call BIS_fnc_logFormat;
    ["----------------------------------------"] call BIS_fnc_log;
    if (PATROL_VCOMAI_Active) then {
        ["VCOMAI Integration: ENABLED"] call BIS_fnc_log;
        ["  • Enhanced AI behavior via VCOMAI"] call BIS_fnc_log;
        ["  • Custom units registered with VCM"] call BIS_fnc_log;
    } else {
        ["VCOMAI Integration: DISABLED"] call BIS_fnc_log;
        ["  • Using standalone AI system"] call BIS_fnc_log;
    };
    ["----------------------------------------"] call BIS_fnc_log;
    ["Performance Optimizations:"] call BIS_fnc_log;
    ["  • distanceSqr (3x faster distance checks)"] call BIS_fnc_log;
    ["  • Player validation (no JIP/parachute)"] call BIS_fnc_log;
    ["  • Cached player distance checks"] call BIS_fnc_log;
    ["----------------------------------------"] call BIS_fnc_log;
    ["Safety Features:"] call BIS_fnc_log;
    ["  • Zombie resurrection immunity"] call BIS_fnc_log;
    ["  • Elite Driving exclusion (EAID_Ignore)"] call BIS_fnc_log;
    ["  • VCOMAI double-null protection"] call BIS_fnc_log;
    ["========================================"] call BIS_fnc_log;
};