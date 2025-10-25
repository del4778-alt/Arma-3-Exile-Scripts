/*
    File: fn_aiPatrolSystem_Enhanced.sqf
    Author: Elite Battle System v4.0 - GOD-TIER PATROL EDITION
    Description:
        Elite GM6 Sniper + AA patrol system with EXTREME MODE enhancements
        - Automatically finds all ExileSpawnZone markers
        - Creates god-tier patrols for each spawn city
        - EXTREME MODE: Perfect aim, 1.4x speed, never flee, ultra-aggressive
        - GM6 Lynx .50 cal with APDS rounds
        - AK-12 with full attachments
        - Pre-loaded launchers
        - Enhanced target validation
        - Smart rearm system
        
    v4.0 ENHANCEMENTS (from recruit script):
        ✓ All AI skills set to 1.0 (perfect aim, spotting, reload)
        ✓ COMBAT + RED behavior (ultra-aggressive)
        ✓ allowFleeing 0 (never retreat)
        ✓ 1.4x movement speed boost
        ✓ Enhanced weapon loadouts (GM6 + APDS, AK-12)
        ✓ Pre-loaded launchers (spawn ready to fight)
        ✓ Enhanced target validation
        ✓ Smart rearm system
        ✓ Better utility functions
        
    CONFIGURATION:
        - Edit EXILE_PATROL_CONFIG below to set units per city, respawn delay, etc.
*/

if (!isServer) exitWith {};

// ============================================
// GLOBAL VARS
// ============================================

PATROL_Active = false;
PATROL_ZoneHandles = [];
PATROL_AllGroups = [];
PATROL_playerCheckTime = 0;
PATROL_nearbyPlayers = [];

// ============================================
// EXILE SPAWN ZONE PATROL CONFIGURATION
// ============================================

EXILE_PATROL_CONFIG = [
    4,      // Units per patrol group
    300,    // Respawn delay (seconds) after all units killed
    2000,   // Cache distance (meters) - patrols despawn if no players within this range
    999     // Max respawn attempts (999 = unlimited)
];

// ============================================
// ENHANCED CONFIGURATION (GOD-TIER MODE)
// ============================================

DEFENDER_DETECTION_RADIUS = 1500;
DEFENDER_AUDIO_DETECTION_RADIUS = 2000;
DEFENDER_ENHANCED_MOVEMENT = true;
DEFENDER_COVER_DISTANCE = 50;
DEFENDER_REARM_CHECK_INTERVAL = 30;
DEFENDER_GRENADE_USAGE_CHANCE = 0.7;
DEFENDER_STATIC_WEAPON_DISTANCE = 100;
DEFENDER_CALLOUT_INTERVAL = 8;
DEFENDER_PATROL_RADIUS = 80;

// ============================================
// FACTION RELATIONS - SET ONCE GLOBALLY
// ============================================

if (isNil "PATROL_FactionsConfigured") then {
    PATROL_FactionsConfigured = true;
    publicVariable "PATROL_FactionsConfigured";
    
    // Make RESISTANCE hostile to both WEST and EAST
    RESISTANCE setFriend [WEST, 0];
    WEST setFriend [RESISTANCE, 0];
    RESISTANCE setFriend [EAST, 0];
    EAST setFriend [RESISTANCE, 0];
    
    // Keep EAST hostile to WEST
    EAST setFriend [WEST, 0];
    WEST setFriend [EAST, 0];
    
    diag_log "[AI] Faction relations configured: RESISTANCE patrols will engage WEST & EAST";
};

diag_log "[AI] Starting GOD-TIER Elite Patrol System v4.0 - EXTREME MODE...";

// ============================================
// UTILITY FUNCTIONS
// ============================================

DEFENDER_fnc_getDirectionName = {
    params ["_dir"];
    
    switch (true) do {
        case (_dir >= 337.5 || _dir < 22.5): {"North"};
        case (_dir >= 22.5 && _dir < 67.5): {"NE"};
        case (_dir >= 67.5 && _dir < 112.5): {"East"};
        case (_dir >= 112.5 && _dir < 157.5): {"SE"};
        case (_dir >= 157.5 && _dir < 202.5): {"South"};
        case (_dir >= 202.5 && _dir < 247.5): {"SW"};
        case (_dir >= 247.5 && _dir < 292.5): {"West"};
        default {"NW"};
    };
};

// Safe unit check - prevents "Object not found" errors
DEFENDER_fnc_isUnitValid = {
    params ["_unit"];
    
    if (isNil "_unit") exitWith {false};
    if (isNull _unit) exitWith {false};
    if (!alive _unit) exitWith {false};
    
    true
};

// Enhanced target validation with proper visibility checking
DEFENDER_fnc_isValidTarget = {
    params ["_unit", "_target"];
    
    // Must be alive
    if (!alive _target) exitWith {false};
    
    // Must be hostile side (WEST or EAST)
    if (side _target != WEST && side _target != EAST) exitWith {false};
    
    // Must not be friendly
    if (side _target getFriend side _unit >= 0.6) exitWith {false};
    
    // For vehicles, must have crew (ignore empty vehicles)
    if (_target isKindOf "LandVehicle" || _target isKindOf "Air") then {
        if (count crew _target == 0) exitWith {false};
    };
    
    // Check visibility using lineIntersectsSurfaces (more reliable than checkVisibility)
    private _intersects = lineIntersectsSurfaces [eyePos _unit, eyePos _target, _unit, _target, true, 1];
    if (count _intersects > 0) exitWith {false};
    
    // Must be within reasonable range
    if (_unit distance _target > DEFENDER_DETECTION_RADIUS) exitWith {false};
    
    true
};

// ============================================
// EXILE SPAWN ZONE DETECTOR
// ============================================

DEFENDER_fnc_findExileSpawnZones = {
    private _exileZones = [];
    
    // Search through all markers
    {
        private _markerName = _x;
        private _markerType = markerType _markerName;
        
        // Check if it's an ExileSpawnZone marker
        if (_markerType == "ExileSpawnZone") then {
            private _markerPos = getMarkerPos _markerName;
            private _markerText = markerText _markerName;
            
            // Only add if it has a valid position
            if ((_markerPos select 0) != 0 || (_markerPos select 1) != 0) then {
                _exileZones pushBack [_markerName, _markerText, _markerPos];
                diag_log format["[AI] Found ExileSpawnZone: %1 (%2) at %3", _markerName, _markerText, _markerPos];
            };
        };
    } forEach allMapMarkers;
    
    diag_log format["[AI] Total ExileSpawnZones detected: %1", count _exileZones];
    _exileZones
};

// ============================================
// ENHANCED AMMO TRACKING
// ============================================

DEFENDER_fnc_getAmmoPercentage = {
    params ["_unit"];
    
    if (!alive _unit) exitWith {0};

    private _startMags = _unit getVariable ["DEFENDER_startMags", []];
    if (count _startMags == 0) exitWith {0};

    private _currentMags = magazines _unit;

    // Get unique magazine types
    private _allMagTypes = (_startMags + _currentMags);
    _allMagTypes = _allMagTypes arrayIntersect _allMagTypes;

    private _totalStart = 0;
    private _totalCurrent = 0;

    {
        private _magType = _x;
        _totalStart = _totalStart + ({_x == _magType} count _startMags);
        _totalCurrent = _totalCurrent + ({_x == _magType} count _currentMags);
    } forEach _allMagTypes;

    if (_totalStart <= 0) exitWith {0};
    (_totalCurrent / _totalStart)
};

// ============================================
// ENHANCED COVER DETECTION
// ============================================

DEFENDER_fnc_findCover = {
    params ["_unit", "_enemyPos"];
    
    if (!alive _unit) exitWith {[]};
    
    private _bestPos = [];
    private _bestScore = -1e9;
    private _unitPosASL = getPosASL _unit;
    private _enemyPosASL = getPosASL _enemyPos;
    
    for "_i" from 0 to 8 do {
        private _angleDeg = _i * 45;
        private _angleRad = _angleDeg * (pi / 180);
        private _distance = 20 + (random 30);
        
        private _testPos = [
            (_unitPosASL select 0) + (sin _angleRad) * _distance,
            (_unitPosASL select 1) + (cos _angleRad) * _distance,
            (_unitPosASL select 2) + 1.5
        ];
        
        private _blocked = lineIntersects [
            ASLToAGL _testPos, 
            ASLToAGL _enemyPosASL, 
            _unit,
            objNull
        ];
        
        if (_blocked) then {
            private _score = 1000 - (_unit distance2D (ASLToAGL _testPos));
            
            if (_score > _bestScore) then {
                _bestScore = _score;
                _bestPos = ASLToAGL _testPos;
            };
        };
    };
    
    _bestPos
};

// ============================================
// VEHICLE OCCUPANCY CHECK
// ============================================

DEFENDER_fnc_isVehicleOccupied = {
    params ["_vehicle"];
    
    if (isNull _vehicle) exitWith {false};
    if (!(_vehicle isKindOf "LandVehicle" || _vehicle isKindOf "Air" || _vehicle isKindOf "Ship")) exitWith {false};
    
    private _crew = crew _vehicle;
    (count _crew > 0)
};

// ============================================
// ENHANCED REARM SYSTEM
// ============================================

DEFENDER_fnc_rearmUnit = {
    params ["_unit", "_role"];
    
    if (!alive _unit) exitWith {};
    
    // Remove all existing gear
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    
    // Re-add gear based on role
    switch (_role) do {
        case "AA": {
            // Anti-Air Specialist with MMG
            _unit addWeapon "MMG_01_hex_ARCO_LP_F";
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            _unit addPrimaryWeaponItem "bipod_02_F_hex";
            
            for "_i" from 1 to 3 do {
                _unit addMagazine "150Rnd_93x64_Mag";
            };
            
            _unit addMagazine "Titan_AA";
            _unit addWeapon "launch_B_Titan_F";
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItem "FirstAidKit";
            };
        };
        case "AT": {
            // Anti-Tank with AK-12
            _unit addWeapon "arifle_AK12_F";
            _unit addPrimaryWeaponItem "acc_flashlight";
            _unit addPrimaryWeaponItem "optic_Hamr";
            _unit addPrimaryWeaponItem "muzzle_snds_B";
            
            for "_i" from 1 to 8 do {
                _unit addMagazine "30Rnd_762x39_AK12_Mag_F";
            };
            
            _unit addMagazine "RPG32_F";
            _unit addWeapon "launch_RPG32_F";
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItem "FirstAidKit";
            };
        };
        case "Sniper": {
            // Sniper with GM6 Lynx .50 cal + APDS (only optic supported)
            _unit addWeapon "srifle_GM6_F";
            _unit addPrimaryWeaponItem "optic_LRPS";
            
            for "_i" from 1 to 6 do {
                _unit addMagazine "5Rnd_127x108_APDS_Mag";
            };
            
            _unit addWeapon "Laserdesignator";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItem "FirstAidKit";
            };
        };
        default {
            // Rifleman with AK-12
            _unit addWeapon "arifle_AK12_F";
            _unit addPrimaryWeaponItem "acc_flashlight";
            _unit addPrimaryWeaponItem "optic_Hamr";
            _unit addPrimaryWeaponItem "muzzle_snds_B";
            
            for "_i" from 1 to 8 do {
                _unit addMagazine "30Rnd_762x39_AK12_Mag_F";
            };
            
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            for "_i" from 1 to 3 do {
                _unit addMagazine "11Rnd_45ACP_Mag";
            };
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItem "FirstAidKit";
            };
        };
    };
    
    // Snapshot starting magazines for ammo tracking
    _unit setVariable ["DEFENDER_startMags", magazines _unit];
    
    diag_log format["[AI] Rearmed %1 unit: %2", _role, name _unit];
};

// ============================================
// GOD-TIER AI SKILL CONFIGURATION
// ============================================

DEFENDER_fnc_setGodTierSkills = {
    params ["_unit"];
    
    if (!alive _unit) exitWith {};
    
    // EXTREME MODE: All skills at maximum (1.0)
    _unit setSkill ["aimingAccuracy", 1.0];
    _unit setSkill ["aimingShake", 1.0];
    _unit setSkill ["aimingSpeed", 1.0];
    _unit setSkill ["spotDistance", 1.0];
    _unit setSkill ["spotTime", 1.0];
    _unit setSkill ["courage", 1.0];
    _unit setSkill ["reloadSpeed", 1.0];
    _unit setSkill ["commanding", 1.0];
    _unit setSkill ["general", 1.0];
    
    // COMBAT + RED behavior (ultra-aggressive)
    _unit setBehaviour "COMBAT";
    _unit setCombatMode "RED";
    
    // Never flee, never surrender
    _unit allowFleeing 0;
    
    // 1.4x movement speed boost (god-tier operators move faster)
    _unit setAnimSpeedCoef 1.4;
    
    // Disable auto rearm (we control this)
    _unit setVariable ["BIS_noCoreConversations", true];
    _unit disableAI "AUTOTARGET";
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    
    diag_log format["[AI] God-tier skills applied to: %1", name _unit];
};

// ============================================
// ENHANCED COMBAT AI (CONSOLIDATED)
// ============================================

DEFENDER_fnc_enhancedCombatAI = {
    params ["_unit", "_defensePos"];
    
    while {alive _unit} do {
        sleep 5;
        
        if (!([_unit] call DEFENDER_fnc_isUnitValid)) exitWith {};
        
        private _nearestEnemy = objNull;
        private _minDist = DEFENDER_DETECTION_RADIUS;
        
        // Find nearest valid target
        {
            if ([_unit, _x] call DEFENDER_fnc_isValidTarget) then {
                private _dist = _unit distance _x;
                if (_dist < _minDist) then {
                    _minDist = _dist;
                    _nearestEnemy = _x;
                };
            };
        } forEach (_unit nearEntities [["CAManBase", "LandVehicle", "Air"], DEFENDER_DETECTION_RADIUS]);
        
        // Combat behavior when enemy detected
        if (!isNull _nearestEnemy && alive _nearestEnemy) then {
            private _grp = group _unit;
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
            _grp setSpeedMode "FULL";
            
            // Target callout
            private _dist = floor(_unit distance _nearestEnemy);
            private _dir = _unit getDir _nearestEnemy;
            private _dirName = [_dir] call DEFENDER_fnc_getDirectionName;
            private _enemyType = if (_nearestEnemy isKindOf "CAManBase") then {"Infantry"} else {"Vehicle"};
            
            diag_log format["[AI] %1 engaging %2 - %3m %4", name _unit, _enemyType, _dist, _dirName];
            
            // Use grenade if close
            if (_dist < 40 && random 1 < DEFENDER_GRENADE_USAGE_CHANCE) then {
                if ("HandGrenade" in magazines _unit) then {
                    _unit doTarget _nearestEnemy;
                    sleep 0.5;
                    _unit fire currentMuzzle _unit;
                };
            };
            
            // Move to cover if needed
            if (random 1 < 0.4) then {
                private _coverPos = [_unit, _nearestEnemy] call DEFENDER_fnc_findCover;
                if (count _coverPos > 0) then {
                    _unit doMove _coverPos;
                    _unit setUnitPos "MIDDLE"; // Crouch in combat
                };
            };
            
            // Check ammo and rearm if needed
            private _ammoPercent = [_unit] call DEFENDER_fnc_getAmmoPercentage;
            if (_ammoPercent < 0.2) then {
                private _role = _unit getVariable ["DEFENDER_Role", "Rifleman"];
                [_unit, _role] call DEFENDER_fnc_rearmUnit;
                diag_log format["[AI] %1 rearmed (%2)", name _unit, _role];
            };
        } else {
            // Patrol behavior when no enemy
            _unit setUnitPos "AUTO";
        };
    };
};

// ============================================
// ENHANCED SPAWN FUNCTION WITH GOD-TIER FEATURES
// ============================================

DEFENDER_fnc_spawnPatrolZones = {
    params ["_spawnZones"];
    
    PATROL_Active = true;
    
    {
        _x params ["_zoneMarker", "_defendersPerGroup", "_respawnDelay", "_cacheDistance", "_maxRespawnAttempts"];
        
        private _markerPos = getMarkerPos _zoneMarker;
        private _cityName = markerText _zoneMarker;
        
        if (_cityName == "") then {
            _cityName = _zoneMarker;
        };
        
        diag_log format["[AI] Initializing GOD-TIER patrol zone: %1 at %2", _cityName, _markerPos];
        
        if ((_markerPos select 0) != 0 || (_markerPos select 1) != 0) then {
            private _handle = [_zoneMarker, _cityName, _markerPos, _defendersPerGroup, _respawnDelay, _cacheDistance, _maxRespawnAttempts] spawn {
                params ["_zoneMarker", "_cityName", "_markerPos", "_defendersPerGroup", "_respawnDelay", "_cacheDistance", "_maxRespawnAttempts"];
                
                private _respawnAttempts = 0;
                
                while {_respawnAttempts < _maxRespawnAttempts && PATROL_Active} do {
                    private _defenderGrp = createGroup RESISTANCE;
                    PATROL_AllGroups pushBack _defenderGrp;
                    
                    private _roles = ["AA", "AT", "Sniper", "Rifleman"];
                    
                    for "_i" from 1 to _defendersPerGroup do {
                        private _role = _roles select ((_i - 1) mod (count _roles));
                        
                        private _spawnPos = [_markerPos, 5, 30, 5, 0, 60, 0] call BIS_fnc_findSafePos;
                        private _defender = _defenderGrp createUnit ["I_Soldier_F", _spawnPos, [], 0, "FORM"];
                        
                        // Remove default gear
                        removeAllWeapons _defender;
                        removeAllItems _defender;
                        removeAllAssignedItems _defender;
                        removeBackpack _defender;
                        removeVest _defender;
                        removeHeadgear _defender;
                        removeGoggles _defender;
                        
                        // Add uniform and gear
                        _defender forceAddUniform "U_I_CombatUniform";
                        _defender addVest "V_PlateCarrierIA2_dgtl";
                        _defender addBackpack "B_ViperHarness_blk_F";
                        _defender addHeadgear "H_HelmetIA";
                        
                        // Add NVG capability (built into helmet)
                        _defender linkItem "NVGoggles_INDEP";
                        
                        // Add GPS and other items
                        _defender linkItem "ItemMap";
                        _defender linkItem "ItemCompass";
                        _defender linkItem "ItemWatch";
                        _defender linkItem "ItemGPS";
                        
                        // Store role
                        _defender setVariable ["DEFENDER_Role", _role];
                        
                        // Load role-specific gear
                        [_defender, _role] call DEFENDER_fnc_rearmUnit;
                        
                        // Apply GOD-TIER skills and behavior
                        [_defender] call DEFENDER_fnc_setGodTierSkills;
                        
                        // Audio detection event handler
                        private _audioEH = _defender addEventHandler ["FiredNear", {
                            params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];
                            
                            if (side _firer != side _unit && _distance < DEFENDER_AUDIO_DETECTION_RADIUS) then {
                                if ([_unit, _firer] call DEFENDER_fnc_isValidTarget) then {
                                    _unit doTarget _firer;
                                    _unit doFire _firer;
                                    
                                    private _dist = floor(_unit distance _firer);
                                    private _dir = _unit getDir _firer;
                                    private _dirName = [_dir] call DEFENDER_fnc_getDirectionName;
                                    
                                    diag_log format["[AI] %1 responding to shots from %2 - %3m %4", 
                                        name _unit, name _firer, _dist, _dirName];
                                };
                            };
                        }];
                        
                        _defender setVariable ["DEFENDER_audioEH", _audioEH];
                        
                        // Start combat AI thread
                        [_defender, _markerPos] spawn DEFENDER_fnc_enhancedCombatAI;
                    };
                    
                    // Configure group
                    _defenderGrp setFormation "LINE";
                    _defenderGrp setSpeedMode "LIMITED";
                    
                    // 80m RADIUS PATROL - 8 waypoints in circle
                    for "_i" from 0 to 7 do {
                        private _angle = _i * 45;
                        private _dist = DEFENDER_PATROL_RADIUS;
                        private _patrolPos = [
                            (_markerPos select 0) + (_dist * sin _angle), 
                            (_markerPos select 1) + (_dist * cos _angle), 
                            0
                        ];
                        _patrolPos = [_patrolPos, 0, 50, 5, 0, 60, 0] call BIS_fnc_findSafePos;
                        
                        private _wp = _defenderGrp addWaypoint [_patrolPos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "LIMITED";
                        _wp setWaypointBehaviour "SAFE";
                        _wp setWaypointCombatMode "YELLOW";
                        _wp setWaypointCompletionRadius 30;
                        _wp setWaypointTimeout [15, 30, 45];
                    };
                    
                    private _cycleWp = _defenderGrp addWaypoint [_markerPos, 0];
                    _cycleWp setWaypointType "CYCLE";
                    
                    diag_log format["[AI] Spawned %1 GOD-TIER patrol at %2 (%3) - v4.0 EXTREME MODE", _defendersPerGroup, _cityName, _zoneMarker];
                    
                    _respawnAttempts = _respawnAttempts + 1;
                    
                    // === MONITORING LOOP ===
                    private _deathTime = -1;
                    
                    while {PATROL_Active} do {
                        sleep 30;
                        
                        if (isNull _defenderGrp || {count units _defenderGrp == 0}) exitWith {
                            diag_log format["[AI] Patrol group at %1 was deleted externally", _cityName];
                        };
                        
                        private _defendersAlive = {alive _x} count units _defenderGrp;
                        
                        if (_defendersAlive == 0) then {
                            if (_deathTime < 0) then {
                                _deathTime = time;
                                diag_log format["[AI] %1: All patrol units eliminated!", _cityName];
                            };
                            if (time - _deathTime > _respawnDelay) exitWith {
                                {
                                    if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                        _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                        _x setVariable ["DEFENDER_audioEH", nil];
                                    };
                                    deleteVehicle _x;
                                } forEach units _defenderGrp;
                                deleteGroup _defenderGrp;
                                PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                                diag_log format["[AI] Patrol cleanup complete at %1", _cityName];
                            };
                        } else {
                            _deathTime = -1;
                        };
                        
                        if (time > PATROL_playerCheckTime) then {
                            PATROL_nearbyPlayers = allPlayers;
                            PATROL_playerCheckTime = time + 15;
                        };
                        
                        private _players = PATROL_nearbyPlayers select {(_x distance2D _markerPos) < _cacheDistance};
                        if (count _players == 0) exitWith {
                            {
                                if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                    _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                    _x setVariable ["DEFENDER_audioEH", nil];
                                };
                                deleteVehicle _x;
                            } forEach units _defenderGrp;
                            deleteGroup _defenderGrp;
                            PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                            diag_log format["[AI] Patrol cached at %1 (no nearby players)", _cityName];
                        };
                    };
                    
                    if (!PATROL_Active) exitWith {
                        {
                            if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                                _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                                _x setVariable ["DEFENDER_audioEH", nil];
                            };
                            deleteVehicle _x;
                        } forEach units _defenderGrp;
                        deleteGroup _defenderGrp;
                        PATROL_AllGroups = PATROL_AllGroups - [_defenderGrp];
                    };
                    
                    sleep _respawnDelay;
                };
                
                if (_respawnAttempts >= _maxRespawnAttempts) then {
                    diag_log format["[AI] ERROR: Patrol zone %1 exceeded respawn limit, disabling", _cityName];
                };
            };
            
            PATROL_ZoneHandles pushBack _handle;
        };
    } forEach _spawnZones;
    
    diag_log format["[AI] GOD-TIER Patrol System v4.0 Active - %1 zones initialized", count PATROL_ZoneHandles];
};

// ============================================
// MAIN LOOP
// ============================================

[] spawn {
    while {true} do {
        sleep 5;
        
        if (PATROL_Active) then {
            // System is running
        } else {
            if (count allPlayers > 0) then {
                // AUTO-DETECT ALL EXILE SPAWN ZONES
                private _exileZones = [] call DEFENDER_fnc_findExileSpawnZones;
                
                if (count _exileZones > 0) then {
                    // Create patrol configuration for each zone
                    private _spawnZones = [];
                    
                    {
                        _x params ["_markerName", "_markerText", "_markerPos"];
                        
                        // Format: [markerName, unitsPerGroup, respawnDelay, cacheDistance, maxRespawnAttempts]
                        _spawnZones pushBack [
                            _markerName,
                            EXILE_PATROL_CONFIG select 0,  // Units per group
                            EXILE_PATROL_CONFIG select 1,  // Respawn delay
                            EXILE_PATROL_CONFIG select 2,  // Cache distance
                            EXILE_PATROL_CONFIG select 3   // Max respawns
                        ];
                    } forEach _exileZones;
                    
                    diag_log format["[AI] Creating GOD-TIER patrols for %1 ExileSpawnZones", count _spawnZones];
                    [_spawnZones] call DEFENDER_fnc_spawnPatrolZones;
                } else {
                    diag_log "[AI] WARNING: No ExileSpawnZone markers found on map!";
                    sleep 60; // Wait before checking again
                };
            };
        };
        
        sleep 30;
        if (count allPlayers == 0 && PATROL_Active) then {
            diag_log "[AI] No players online - Shutting down Patrol System";
            PATROL_Active = false;
            
            {terminate _x} forEach PATROL_ZoneHandles;
            PATROL_ZoneHandles = [];
            
            private _cleanupCount = 0;
            {
                if (!isNull _x) then {
                    {
                        if (!isNil {_x getVariable "DEFENDER_audioEH"}) then {
                            _x removeEventHandler ["FiredNear", _x getVariable "DEFENDER_audioEH"];
                            _x setVariable ["DEFENDER_audioEH", nil];
                        };
                        deleteVehicle _x;
                    } forEach units _x;
                    deleteGroup _x;
                    _cleanupCount = _cleanupCount + 1;
                };
            } forEach PATROL_AllGroups;
            PATROL_AllGroups = [];
            
            diag_log format["[AI] Patrol System Stopped - Removed %1 patrol groups", _cleanupCount];
        };
    };
};

// ============================================
// MONITORING THREAD
// ============================================

[] spawn {
    while {true} do {
        sleep 300;
        if (PATROL_Active) then {
            private _resistanceCount = {side _x == RESISTANCE} count allUnits;
            private _activeGroups = {!isNull _x && {count units _x > 0}} count PATROL_AllGroups;
            diag_log format["[AI] Patrol Health Check: %1 GOD-TIER patrol units | %2 active groups | v4.0 EXTREME MODE", 
                _resistanceCount, _activeGroups];
        };
    };
};

// ============================================
// STARTUP MESSAGE
// ============================================

diag_log "========================================";
diag_log "ELITE AI PATROL SYSTEM v4.0 - GOD-TIER MODE";
diag_log "⚠️  EXTREME MODE: COMBAT+RED+PERFECT AIM";
diag_log "Ultra-aggressive! 100% accuracy! Fearless!";
diag_log "1.4x speed, GM6+APDS, AK-12, never flees!";
diag_log "Auto-detects ExileSpawnZone markers";
diag_log "✓ Enhanced from recruit script features";
diag_log "========================================";
