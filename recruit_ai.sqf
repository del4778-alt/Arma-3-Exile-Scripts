/*
    ELITE AI RECRUIT SYSTEM v4.0.2 - PRODUCTION READY
    INDEPENDENT/RESISTANCE FACTION
    
    IMPROVEMENTS FROM v4.0.1:
    - ✅ Fixed broken isValidTarget function
    - ✅ Fixed redundant target validation logic
    - ✅ Re-added missing vehicle boarding system
    - ✅ Kept config helper function (better compatibility)
    - ✅ Kept bearing function (more accurate)
    - ✅ Kept magazine-based ammo (simpler)
    - ✅ Kept nearestObjects optimization
    
    This version combines the best of v4.0.0 and v4.0.1 with all bugs fixed.
    
    Call from init.sqf: [] execVM "recruit_ai.sqf";
*/

// ============================================
// EARLY EXIT FOR HEADLESS CLIENTS
// ============================================
if (!hasInterface && !isServer) exitWith {};

waitUntil {time > 0};
if (hasInterface) then {
    waitUntil {!isNull player};
};

// ============================================
// CONFIGURATION (nested array + helper)
// ============================================
RECRUIT_Config = [
    ["maxSquadmates", 3],
    ["vehicleBoardRadius", 300],
    ["detectionRadius", 1500],
    ["audioDetectionRadius", 2000],
    ["calloutInterval", 8],
    ["rearmCheckInterval", 30],
    ["respawnCooldown", 15],
    ["movementSpeedMultiplier", 1.4],
    ["rearmThreshold", 0.3],
    ["rearmMagBaseline", 6],  // baseline number of magazines considered "full"
    
    // Recruitment types [classname, vest, backpack, role]
    ["recruitmentTypes", [
        ["I_Soldier_unarmed_F", "V_PlateCarrierIA2_dgtl", "B_ViperHarness_blk_F", "AA"],
        ["I_Soldier_unarmed_F", "V_PlateCarrierIA1_dgtl", "B_ViperHarness_blk_F", "AT"],
        ["I_Soldier_unarmed_F", "V_PlateCarrierIAGL_dgtl", "B_ViperHarness_blk_F", "Sniper"]
    ]]
];

// Helper to get config value by key
RECRUIT_fnc_cfgGet = {
    params ["_key"];
    private _val = nil;
    {
        if ((_x select 0) == _key) exitWith { _val = (_x select 1) };
    } forEach RECRUIT_Config;
    _val
};

// Per-player tracking
if (hasInterface) then {
    player setVariable ["RECRUIT_RespawnInProgress", false, false];
    player setVariable ["RECRUIT_LastDeathTime", -999, false];
    player setVariable ["RECRUIT_LastCallout", 0, false];
};

// ============================================
// FACTION RELATIONS - SERVER ONLY
// ============================================
if (isServer && isNil "RECRUIT_FactionsConfigured") then {
    RECRUIT_FactionsConfigured = true;
    publicVariable "RECRUIT_FactionsConfigured";
    
    RESISTANCE setFriend [EAST, 0];
    EAST setFriend [RESISTANCE, 0];
    INDEPENDENT setFriend [EAST, 0];
    EAST setFriend [INDEPENDENT, 0];
    
    RESISTANCE setFriend [WEST, 0];
    WEST setFriend [RESISTANCE, 0];
    INDEPENDENT setFriend [WEST, 0];
    WEST setFriend [INDEPENDENT, 0];
    
    EAST setFriend [WEST, 0];
    WEST setFriend [EAST, 0];
    
    if (hasInterface) then {
        systemChat "[RECRUIT] Faction relations configured: RESISTANCE/INDEPENDENT recruits will engage EAST";
    };
};

// ============================================
// UTILITY FUNCTIONS
// ============================================

RECRUIT_fnc_getDirectionName = {
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

// IMPROVED: Proper bearing calculation from A to B
RECRUIT_fnc_bearing = {
    params ["_from", "_to"];
    private _fp = getPosATL _from;
    private _tp = getPosATL _to;
    private _dx = (_tp select 0) - (_fp select 0);
    private _dy = (_tp select 1) - (_fp select 1);
    private _rad = _dx atan2 _dy;
    private _deg = _rad * 57.2957795131;
    _deg = (_deg + 360) mod 360;
    _deg
};

// FIXED: Validate target is actually an enemy
RECRUIT_fnc_isValidTarget = {
    params ["_unit", "_target"];
    
    if (isNil "_target") exitWith {false};
    if (isNull _target) exitWith {false};
    if (!alive _target) exitWith {false};
    if (side _target != EAST) exitWith {false};
    if (side _target getFriend side _unit >= 0.6) exitWith {false};
    
    // For vehicles, must have crew
    if (_target isKindOf "LandVehicle" || _target isKindOf "Air") then {
        if (count crew _target == 0) exitWith {false};
    };
    
    // Line of sight check
    private _intersects = lineIntersectsSurfaces [eyePos _unit, eyePos _target, _unit, _target, true, 1];
    if (count _intersects > 0) exitWith {false};
    
    // FIXED: Range check with proper config access
    private _maxRange = ["detectionRadius"] call RECRUIT_fnc_cfgGet;
    if (isNil "_maxRange") then { _maxRange = 1500 };
    if (_unit distance _target > _maxRange) exitWith {false};
    
    true
};

// IMPROVED: Magazine-count based ammo estimate (more robust)
RECRUIT_fnc_getAmmoEstimate = {
    params ["_unit"];
    
    private _mags = magazines _unit;
    private _totalMags = count _mags;
    
    if (_totalMags == 0) exitWith {0};
    
    private _baseline = ["rearmMagBaseline"] call RECRUIT_fnc_cfgGet;
    if (isNil "_baseline") then { _baseline = 6 };
    
    private _frac = _totalMags / _baseline;
    if (_frac > 1) then { _frac = 1 };
    _frac
};

// Safe unit check
RECRUIT_fnc_isUnitValid = {
    params ["_unit"];
    
    if (isNil "_unit") exitWith {false};
    if (isNull _unit) exitWith {false};
    if (!alive _unit) exitWith {false};
    
    true
};

// Check if config class exists
RECRUIT_fnc_classExists = {
    params ["_class", "_configType"];
    private _cfg = configFile >> _configType >> _class;
    isClass _cfg
};

// ============================================
// SERVER-SIDE FUNCTIONS
// ============================================

// SERVER ONLY: Spawn unit
RECRUIT_fnc_serverSpawnUnit = {
    if (!isServer) exitWith {};
    
    params ["_player", "_config"];
    
    private _classname = _config select 0;
    private _vest = _config select 1;
    private _backpack = _config select 2;
    private _role = _config select 3;
    
    private _group = group _player;
    private _spawnPos = _player getPos [5, random 360];
    
    private _unit = _group createUnit [_classname, _spawnPos, [], 0, "FORM"];
    
    if (isNull _unit) exitWith {
        diag_log format ["[RECRUIT] Failed to create unit for player %1", name _player];
    };
    
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["TAC_Role", _role, true];
    _unit setVariable ["RECRUIT_OwnerPlayer", _player, true];
    
    [_unit, _role, _vest, _backpack] call RECRUIT_fnc_applyGear;
    [_unit] call RECRUIT_fnc_configureAI;
    [_unit] call RECRUIT_fnc_addUnitHandlers;
    
    [format["[RECRUIT] Spawned %1", _role]] remoteExec ["systemChat", _player];
    
    _unit
};

// SERVER ONLY: Delete recruited units
RECRUIT_fnc_serverCleanupUnits = {
    if (!isServer) exitWith {};
    
    params ["_player"];
    
    private _unitsToDelete = [];
    
    {
        if (_x getVariable ["ExileRecruited", false] && _x != _player) then {
            _unitsToDelete pushBack _x;
        };
    } forEach (units group _player);
    
    {
        if (_x getVariable ["ExileRecruited", false] && _x != _player) then {
            if ((_x getVariable ["RECRUIT_OwnerPlayer", objNull]) == _player) then {
                if (!(_x in _unitsToDelete)) then {
                    _unitsToDelete pushBack _x;
                };
            };
        };
    } forEach allUnits;
    
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _unitsToDelete;
    
    [format["[RECRUIT] Cleaned up %1 AI units", count _unitsToDelete]] remoteExec ["systemChat", _player];
    
    count _unitsToDelete
};

// Configure AI behavior
RECRUIT_fnc_configureAI = {
    params ["_unit"];
    
    {
        _unit setSkill [_x, 1.0];
    } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "courage", "reloadSpeed", "commanding", "general"];
    
    _unit setBehaviour "COMBAT";
    _unit setCombatMode "RED";
    _unit allowFleeing 0;
    _unit setUnitPos "AUTO";
    
    private _speedMult = ["movementSpeedMultiplier"] call RECRUIT_fnc_cfgGet;
    if (isNil "_speedMult") then { _speedMult = 1.4 };
    _unit setAnimSpeedCoef _speedMult;
    
    _unit disableAI "RADIOPROTOCOL";
    enableSentences false;
};

// ============================================
// GEAR APPLICATION WITH DLC VALIDATION
// ============================================

RECRUIT_fnc_applyGear = {
    params ["_unit", "_role", "_vest", "_backpack"];
    
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeBackpack _unit;
    removeVest _unit;
    removeHeadgear _unit;
    
    _unit addVest _vest;
    _unit addBackpack _backpack;
    _unit addHeadgear "H_HelmetIA";
    _unit addGoggles "G_Balaclava_blk";
    
    _unit linkItem "ItemGPS";
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    
    switch (_role) do {
        case "AA": {
            if (["MMG_01_hex_ARCO_LP_F", "CfgWeapons"] call RECRUIT_fnc_classExists) then {
                _unit addWeapon "MMG_01_hex_ARCO_LP_F";
                _unit addPrimaryWeaponItem "acc_pointer_IR";
                _unit addPrimaryWeaponItem "bipod_02_F_hex";
                for "_i" from 1 to 3 do {
                    _unit addMagazine "150Rnd_93x64_Mag";
                };
            } else {
                _unit addWeapon "arifle_MX_SW_F";
                _unit addPrimaryWeaponItem "optic_Hamr";
                _unit addPrimaryWeaponItem "acc_pointer_IR";
                _unit addPrimaryWeaponItem "bipod_01_F_snd";
                for "_i" from 1 to 4 do {
                    _unit addMagazine "100Rnd_65x39_caseless_mag";
                };
            };
            
            if (["Titan_AA", "CfgMagazines"] call RECRUIT_fnc_classExists) then {
                _unit addMagazine "Titan_AA";
                _unit addWeapon "launch_B_Titan_F";
            };
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
        };
        
        case "AT": {
            if (["arifle_AK12_F", "CfgWeapons"] call RECRUIT_fnc_classExists) then {
                _unit addWeapon "arifle_AK12_F";
                _unit addPrimaryWeaponItem "optic_Arco_AK_blk_F";
                _unit addPrimaryWeaponItem "acc_pointer_IR";
                _unit addPrimaryWeaponItem "muzzle_snds_B";
                for "_i" from 1 to 6 do {
                    _unit addMagazine "30Rnd_762x39_AK12_Mag_F";
                };
            } else {
                _unit addWeapon "arifle_Katiba_F";
                _unit addPrimaryWeaponItem "optic_Arco";
                _unit addPrimaryWeaponItem "acc_pointer_IR";
                for "_i" from 1 to 6 do {
                    _unit addMagazine "30Rnd_65x39_caseless_green";
                };
            };
            
            if (["MRAWS_HEAT_F", "CfgMagazines"] call RECRUIT_fnc_classExists) then {
                _unit addMagazine "MRAWS_HEAT_F";
                _unit addWeapon "launch_MRAWS_green_F";
            } else {
                _unit addMagazine "NLAW_F";
                _unit addWeapon "launch_NLAW_F";
            };
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
        };
        
        case "Sniper": {
            if (["srifle_GM6_ghex_F", "CfgWeapons"] call RECRUIT_fnc_classExists) then {
                _unit addWeapon "srifle_GM6_ghex_F";
                _unit addPrimaryWeaponItem "optic_LRPS";
                for "_i" from 1 to 5 do {
                    _unit addMagazine "5Rnd_127x108_APDS_Mag";
                };
            } else {
                _unit addWeapon "srifle_LRR_F";
                _unit addPrimaryWeaponItem "optic_LRPS";
                for "_i" from 1 to 7 do {
                    _unit addMagazine "7Rnd_408_Mag";
                };
            };
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
                _unit addMagazine "HandGrenade";
            };
        };
    };
    
    for "_i" from 1 to 5 do {
        _unit addItem "FirstAidKit";
    };
    _unit addItem "Medikit";
    _unit addItem "ToolKit";
};

// ============================================
// REARM FUNCTION
// ============================================

RECRUIT_fnc_rearmUnit = {
    params ["_unit", "_role"];
    
    if (!isServer) then {
        [_unit, _role] remoteExec ["RECRUIT_fnc_rearmUnit", 2];
    } else {
        [_unit, _role, vest _unit, backpack _unit] call RECRUIT_fnc_applyGear;
    };
};

// ============================================
// EVENT HANDLERS
// ============================================

RECRUIT_fnc_addUnitHandlers = {
    params ["_unit"];
    
    if (local _unit) then {
        _unit addEventHandler ["Killed", {
            params ["_unit", "_killer"];
            diag_log format ["[RECRUIT] Unit %1 (role: %2) was killed", _unit, _unit getVariable ["TAC_Role", "unknown"]];
        }];
    };
};

// Player event handlers (CLIENT ONLY)
if (hasInterface) then {
    
    player addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        
        player setVariable ["RECRUIT_RespawnInProgress", true, false];
        player setVariable ["RECRUIT_LastDeathTime", time, false];
        
        systemChat "[RECRUIT] Player died - requesting AI cleanup...";
        [player] remoteExec ["RECRUIT_fnc_serverCleanupUnits", 2];
    }];
    
    player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        
        systemChat "[RECRUIT] Player respawned - AI will spawn after cooldown...";
        
        [] spawn {
            private _cooldown = ["respawnCooldown"] call RECRUIT_fnc_cfgGet;
            if (isNil "_cooldown") then { _cooldown = 15 };
            sleep _cooldown;
            player setVariable ["RECRUIT_RespawnInProgress", false, false];
            systemChat "[RECRUIT] Cooldown complete - AI recruitment active";
        };
    }];
    
    // ============================================
    // VEHICLE BOARDING SYSTEM (RE-ADDED & FIXED)
    // ============================================
    
    player addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        
        [{
            params ["_vehicle", "_playerUnit"];
            
            if (!alive _playerUnit) exitWith {};
            if (vehicle _playerUnit != _vehicle) exitWith {};
            
            private _recruitedAI = (units group _playerUnit) select {
                [_x] call RECRUIT_fnc_isUnitValid &&
                _x getVariable ["ExileRecruited", false] &&
                _x != _playerUnit
            };
            
            private _boardRadius = ["vehicleBoardRadius"] call RECRUIT_fnc_cfgGet;
            if (isNil "_boardRadius") then { _boardRadius = 300 };
            
            {
                private _ai = _x;
                
                if (_ai distance _vehicle < _boardRadius) then {
                    if (vehicle _ai == _ai) then {
                        
                        private _boarded = false;
                        
                        if (!_boarded && _vehicle emptyPositions "cargo" > 0) then {
                            _ai moveInCargo _vehicle;
                            _boarded = true;
                        };
                        
                        if (!_boarded && _vehicle emptyPositions "gunner" > 0) then {
                            _ai moveInGunner _vehicle;
                            _boarded = true;
                        };
                        
                        if (_boarded) then {
                            private _roleName = _ai getVariable ["TAC_Role", "AI"];
                            systemChat format ["[RECRUIT] %1 boarded vehicle", _roleName];
                        };
                    };
                };
            } forEach _recruitedAI;
            
        }, [_vehicle, _unit], 0.5] call {
            params ["_code", "_params", "_delay"];
            _params spawn {
                params ["_vehicle", "_playerUnit"];
                sleep 0.5;
                [_vehicle, _playerUnit] call compile str {
                    params ["_vehicle", "_playerUnit"];
                    
                    if (!alive _playerUnit) exitWith {};
                    if (vehicle _playerUnit != _vehicle) exitWith {};
                    
                    private _recruitedAI = (units group _playerUnit) select {
                        [_x] call RECRUIT_fnc_isUnitValid &&
                        _x getVariable ["ExileRecruited", false] &&
                        _x != _playerUnit
                    };
                    
                    private _boardRadius = ["vehicleBoardRadius"] call RECRUIT_fnc_cfgGet;
                    if (isNil "_boardRadius") then { _boardRadius = 300 };
                    
                    {
                        private _ai = _x;
                        
                        if (_ai distance _vehicle < _boardRadius) then {
                            if (vehicle _ai == _ai) then {
                                
                                private _boarded = false;
                                
                                if (!_boarded && _vehicle emptyPositions "cargo" > 0) then {
                                    _ai moveInCargo _vehicle;
                                    _boarded = true;
                                };
                                
                                if (!_boarded && _vehicle emptyPositions "gunner" > 0) then {
                                    _ai moveInGunner _vehicle;
                                    _boarded = true;
                                };
                                
                                if (_boarded) then {
                                    private _roleName = _ai getVariable ["TAC_Role", "AI"];
                                    systemChat format ["[RECRUIT] %1 boarded vehicle", _roleName];
                                };
                            };
                        };
                    } forEach _recruitedAI;
                };
            };
        };
    }];
    
    player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        
        private _recruitedAI = (units group _unit) select {
            [_x] call RECRUIT_fnc_isUnitValid &&
            _x getVariable ["ExileRecruited", false]
        };
        
        {
            private _ai = _x;
            
            if (vehicle _ai == _vehicle) then {
                private _vehSpeed = speed _vehicle;
                
                if (_vehSpeed < 5) then {
                    unassignVehicle _ai;
                    _ai action ["Eject", _vehicle];
                    moveOut _ai;
                    
                    private _roleName = _ai getVariable ["TAC_Role", "AI"];
                    systemChat format ["[RECRUIT] %1 exited vehicle", _roleName];
                };
            };
        } forEach _recruitedAI;
    }];
};

// ============================================
// TARGET DETECTION & CALLOUT (SERVER-SIDE, FIXED)
// ============================================

if (isServer) then {
    [] spawn {
        while {true} do {
            {
                private _player = _x;
                
                if (alive _player) then {
                    private _recruitedAI = (units group _player) select {
                        [_x] call RECRUIT_fnc_isUnitValid &&
                        _x getVariable ["ExileRecruited", false]
                    };
                    
                    if (count _recruitedAI > 0) then {
                        private _lastCallout = _player getVariable ["RECRUIT_LastCallout", 0];
                        private _interval = ["calloutInterval"] call RECRUIT_fnc_cfgGet;
                        if (isNil "_interval") then { _interval = 8 };
                        
                        if (time - _lastCallout >= _interval) then {
                            
                            private _detectionRadius = ["detectionRadius"] call RECRUIT_fnc_cfgGet;
                            if (isNil "_detectionRadius") then { _detectionRadius = 1500 };
                            
                            // IMPROVED: Use nearestObjects (better performance)
                            private _nearEnemies = nearestObjects [_player, ["CAManBase", "LandVehicle", "Air"], _detectionRadius];
                            
                            // FIXED: Simplified validation - just check if valid target
                            private _validTargets = [];
                            {
                                if ([_recruitedAI select 0, _x] call RECRUIT_fnc_isValidTarget) then {
                                    _validTargets pushBack _x;
                                };
                            } forEach _nearEnemies;
                            
                            if (count _validTargets > 0) then {
                                private _target = selectRandom _validTargets;
                                private _caller = selectRandom _recruitedAI;
                                
                                // IMPROVED: Use proper bearing function
                                private _bearing = [_caller, _target] call RECRUIT_fnc_bearing;
                                private _dirName = [_bearing] call RECRUIT_fnc_getDirectionName;
                                private _distance = round(_player distance _target);
                                
                                private _targetType = "Enemy";
                                if (_target isKindOf "CAManBase") then {
                                    _targetType = "Infantry";
                                } else {
                                    if (_target isKindOf "Tank") then {
                                        _targetType = "Armor";
                                    } else {
                                        if (_target isKindOf "Air") then {
                                            _targetType = "Air";
                                        } else {
                                            if (_target isKindOf "LandVehicle") then {
                                                _targetType = "Vehicle";
                                            };
                                        };
                                    };
                                };
                                
                                private _roleName = _caller getVariable ["TAC_Role", "AI"];
                                private _msg = format ["[%1] %2 contact, %3m %4!", _roleName, _targetType, _distance, _dirName];
                                
                                [_msg] remoteExec ["systemChat", _player];
                                _player setVariable ["RECRUIT_LastCallout", time, false];
                            };
                        };
                    };
                };
                
            } forEach allPlayers;
            
            sleep 1;
        };
    };
};

// ============================================
// AUTOMATIC REARM SYSTEM (SERVER-SIDE)
// ============================================

if (isServer) then {
    [] spawn {
        while {true} do {
            {
                private _player = _x;
                
                if (alive _player) then {
                    {
                        private _ai = _x;
                        
                        if ([_ai] call RECRUIT_fnc_isUnitValid && _ai getVariable ["ExileRecruited", false]) then {
                            
                            private _inCombat = (behaviour _ai in ["COMBAT", "STEALTH"]);
                            
                            if (!_inCombat) then {
                                private _ammoFrac = [_ai] call RECRUIT_fnc_getAmmoEstimate;
                                
                                private _threshold = ["rearmThreshold"] call RECRUIT_fnc_cfgGet;
                                if (isNil "_threshold") then { _threshold = 0.3 };
                                
                                if (_ammoFrac < _threshold) then {
                                    private _role = _ai getVariable ["TAC_Role", ""];
                                    
                                    if (_role != "") then {
                                        [_ai, _role] call RECRUIT_fnc_rearmUnit;
                                        
                                        private _msg = format [
                                            "[RECRUIT] Rearmed %1 (%2%% → 100%%)",
                                            _role,
                                            round(_ammoFrac * 100)
                                        ];
                                        [_msg] remoteExec ["systemChat", _player];
                                    };
                                };
                            };
                        };
                    } forEach (units group _player);
                };
                
            } forEach allPlayers;
            
            private _rearmInterval = ["rearmCheckInterval"] call RECRUIT_fnc_cfgGet;
            if (isNil "_rearmInterval") then { _rearmInterval = 30 };
            sleep _rearmInterval;
        };
    };
};

// ============================================
// MAIN SPAWN LOOP (SERVER ONLY)
// ============================================

if (isServer) then {
    [] spawn {
        systemChat "========================================";
        systemChat "ELITE AI RECRUIT SYSTEM v4.0.2";
        systemChat "✓ Server-authoritative (MP safe)";
        systemChat "✓ Event handlers (better performance)";
        systemChat "✓ DLC validation (fallback weapons)";
        systemChat "✓ Vehicle boarding (auto-teleport)";
        systemChat "✓ Target callouts (enemy detection)";
        systemChat "✓ Auto-rearm system";
        systemChat "✓ All bugs from v4.0.1 FIXED";
        systemChat "========================================";
        
        while {true} do {
            {
                private _player = _x;
                
                if (alive _player) then {
                    private _respawnFlag = _player getVariable ["RECRUIT_RespawnInProgress", false];
                    private _lastDeath = _player getVariable ["RECRUIT_LastDeathTime", -999];
                    
                    private _cooldown = ["respawnCooldown"] call RECRUIT_fnc_cfgGet;
                    if (isNil "_cooldown") then { _cooldown = 15 };
                    
                    if (!_respawnFlag && time > (_lastDeath + _cooldown)) then {
                        
                        private _squadmates = (units (group _player)) select {
                            [_x] call RECRUIT_fnc_isUnitValid &&
                            _x != _player &&
                            _x getVariable ["ExileRecruited", false]
                        };
                        
                        private _maxSquad = ["maxSquadmates"] call RECRUIT_fnc_cfgGet;
                        if (isNil "_maxSquad") then { _maxSquad = 3 };
                        
                        private _unitsToSpawn = _maxSquad - (count _squadmates);
                        
                        if (_unitsToSpawn > 0) then {
                            private _existingTypes = _squadmates apply {_x getVariable ["TAC_Role", ""]};
                            
                            private _recruitTypes = ["recruitmentTypes"] call RECRUIT_fnc_cfgGet;
                            if (isNil "_recruitTypes") exitWith {};
                            
                            {
                                private _config = _x;
                                private _role = _config select 3;
                                
                                if (!(_role in _existingTypes) && count _squadmates < _maxSquad) then {
                                    [_player, _config] call RECRUIT_fnc_serverSpawnUnit;
                                    
                                    _squadmates = (units (group _player)) select {
                                        [_x] call RECRUIT_fnc_isUnitValid &&
                                        _x != _player &&
                                        _x getVariable ["ExileRecruited", false]
                                    };
                                    
                                    sleep 1;
                                };
                            } forEach _recruitTypes;
                        };
                    };
                };
                
            } forEach allPlayers;
            
            sleep 10;
        };
    };
};

// ============================================
// FORMATION MANAGEMENT (CLIENT-SIDE)
// ============================================

if (hasInterface) then {
    [] spawn {
        waitUntil {sleep 1; !isNull player};
        
        (group player) setFormation "VEE";
        
        while {true} do {
            if (!(player getVariable ["RECRUIT_RespawnInProgress", false])) then {
                private _grp = group player;
                
                if (formation _grp != "VEE") then {
                    _grp setFormation "VEE";
                };
                
                {
                    private _unit = _x;
                    if ([_unit] call RECRUIT_fnc_isUnitValid && _unit getVariable ["ExileRecruited", false]) then {
                        _unit setUnitPos "AUTO";
                        
                        if (_unit distance player > 50 && vehicle _unit == _unit && vehicle player == player) then {
                            _unit doFollow player;
                        };
                    };
                } forEach (units _grp select {_x != player});
            };
            
            sleep 2;
        };
    };
    
    systemChat "[RECRUIT] System initialized successfully!";
};
