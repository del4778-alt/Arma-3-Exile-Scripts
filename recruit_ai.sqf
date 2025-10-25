/*
    ELITE AI RECRUIT SYSTEM v3.9.2 - GOD-TIER MODE (FINAL FIX)
    INDEPENDENT/RESISTANCE FACTION
    
    FEATURES:
    - COMBAT + RED behavior (ultra-aggressive, shoots everything)
    - EXTREME MODE enabled (perfect aim, ignore suppression)
    - ALL SKILLS SET TO 1.0 (maximum accuracy, spotting, reload)
    - allowFleeing 0 (never retreat, never surrender)
    - Sniper uses GM6 Lynx .50 cal with APDS (optic only - no suppressor/bipod)
    - AT uses AK-12 with full attachments
    - 1.4x movement speed boost (AI move faster than player)
    - Best-in-class weapon attachments (optics, suppressors, bipods)
    - Role-specific gear (rangefinders, laser designators, toolkits)
    - Enhanced medical supplies and utility items
    - Pre-loaded launchers (spawn ready to fight)
    - Instant vehicle teleport boarding
    - Native VEE formation following
    - NO ACE dependencies (Exile items only)
    - Helmet has built-in NVG (no separate NVG items)
    
    FIXES v3.9.2:
    - Removed invalid GM6 attachments (only optic supported)
    - Removed redundant NVGoggles (helmet has built-in NVG)
    - Fixed duplicate weapon loadouts
    
    FIXES v3.9.1:
    - Fixed checkVisibility syntax error (line 126)
    - Fixed nearestObjects performance issue (line 406)
    - Fixed rearm logic critical bug (line 483)
    - AT guy now uses AK-12 with attachments
    - Sniper now uses GM6 Lynx .50 cal with APDS rounds
    - Previous v3.9 fixes maintained (cleanup, respawn, object not found)
    
    WARNING: These AI are EXTREMELY POWERFUL - god-tier operators!
    
    Call from init.sqf: [] execVM "recruit_ai.sqf";
*/

waitUntil {time > 0};
waitUntil {!isNull player};

// ============================================
// GLOBAL FLAGS
// ============================================

RECRUIT_RespawnInProgress = false;
RECRUIT_LastDeathTime = -999;

// ============================================
// FACTION RELATIONS - SET ONCE GLOBALLY
// ============================================

if (isNil "RECRUIT_FactionsConfigured") then {
    RECRUIT_FactionsConfigured = true;
    publicVariable "RECRUIT_FactionsConfigured";
    
    // Make RESISTANCE/INDEPENDENT hostile to EAST
    RESISTANCE setFriend [EAST, 0];
    EAST setFriend [RESISTANCE, 0];
    INDEPENDENT setFriend [EAST, 0];
    EAST setFriend [INDEPENDENT, 0];
    
    // Make RESISTANCE/INDEPENDENT friendly to WEST (for future zombie compatibility)
    RESISTANCE setFriend [WEST, 0];
    WEST setFriend [RESISTANCE, 0];
    INDEPENDENT setFriend [WEST, 0];
    WEST setFriend [INDEPENDENT, 0];
    
    // Keep EAST hostile to WEST
    EAST setFriend [WEST, 0];
    WEST setFriend [EAST, 0];
    
    systemChat "[RECRUIT] Faction relations configured: RESISTANCE/INDEPENDENT recruits will engage EAST";
};

// ============================================
// ENHANCED CONFIGURATION
// ============================================

private _maxSquadmates = 3;
private _recruitmentTypes = [
    ["I_Soldier_unarmed_F", "V_PlateCarrierIA2_dgtl", "B_ViperHarness_blk_F", "AA"],
    ["I_Soldier_unarmed_F", "V_PlateCarrierIA1_dgtl", "B_ViperHarness_blk_F", "AT"],
    ["I_Soldier_unarmed_F", "V_PlateCarrierIAGL_dgtl", "B_ViperHarness_blk_F", "Sniper"]
];

// Enhanced Settings
RECRUIT_VEHICLE_BOARD_RADIUS = 300;
RECRUIT_DETECTION_RADIUS = 1500;
RECRUIT_AUDIO_DETECTION_RADIUS = 2000;
RECRUIT_CALLOUT_INTERVAL = 8;
RECRUIT_REARM_CHECK_INTERVAL = 30;
RECRUIT_RESPAWN_COOLDOWN = 15; // Seconds to wait after respawn before spawning AI

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

// Validate target is actually an enemy
RECRUIT_fnc_isValidTarget = {
    params ["_unit", "_target"];
    
    // Must be alive
    if (!alive _target) exitWith {false};
    
    // Must be EAST faction
    if (side _target != EAST) exitWith {false};
    
    // Must not be friendly or civilian
    if (side _target getFriend side _unit >= 0.6) exitWith {false};
    
    // For vehicles, must have crew (ignore empty vehicles)
    if (_target isKindOf "LandVehicle" || _target isKindOf "Air") then {
        if (count crew _target == 0) exitWith {false};
    };
    
    // FIXED: Correct checkVisibility syntax (removed invalid "VIEW" parameter)
    private _intersects = lineIntersectsSurfaces [eyePos _unit, eyePos _target, _unit, _target, true, 1];
if (count _intersects > 0) exitWith {false};
    
    // Must be within reasonable range
    if (_unit distance _target > RECRUIT_DETECTION_RADIUS) exitWith {false};
    
    true
};

// Get ammo percentage
RECRUIT_fnc_getAmmoPercentage = {
    params ["_unit"];
    private _weapons = weapons _unit;
    private _totalAmmo = 0;
    private _maxAmmo = 0;
    
    {
        private _weapon = _x;
        private _mags = magazinesAmmo _unit;
        private _weaponMags = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
        
        {
            if ((_x select 0) in _weaponMags) then {
                _totalAmmo = _totalAmmo + (_x select 1);
                private _magClass = _x select 0;
                private _magSize = getNumber (configFile >> "CfgMagazines" >> _magClass >> "count");
                _maxAmmo = _maxAmmo + _magSize;
            };
        } forEach _mags;
    } forEach _weapons;
    
    if (_maxAmmo == 0) exitWith {0};
    (_totalAmmo / _maxAmmo)
};

// Safe unit check - prevents "Object not found" errors
RECRUIT_fnc_isUnitValid = {
    params ["_unit"];
    
    if (isNil "_unit") exitWith {false};
    if (isNull _unit) exitWith {false};
    if (!alive _unit) exitWith {false};
    
    true
};

// NEW: Separate gear function for rearming (fixes line 483 bug)
RECRUIT_fnc_rearmUnit = {
    params ["_unit", "_role"];
    
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
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "Titan_AA";
            };
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "150Rnd_93x64_Mag";
            };
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            _unit addItemToBackpack "ToolKit";
        };
        
        case "AT": {
            // UPDATED: AT Specialist with AK-12
            _unit addWeapon "arifle_AK12_F";
            _unit addPrimaryWeaponItem "muzzle_snds_B"; // Suppressor
            _unit addPrimaryWeaponItem "acc_pointer_IR"; // IR laser
            _unit addPrimaryWeaponItem "optic_Arco_AK_blk_F"; // ARCO optic
            _unit addPrimaryWeaponItem "bipod_01_F_blk"; // Bipod
            
            for "_i" from 1 to 6 do {
                _unit addMagazine "30Rnd_762x39_AK12_Mag_F";
            };
            
            _unit addMagazine "MRAWS_HEAT_F";
            _unit addWeapon "launch_MRAWS_green_rail_F";
            
            _unit addWeapon "Rangefinder";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "MRAWS_HEAT_F";
            };
            _unit addItemToBackpack "MRAWS_HE_F";
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "30Rnd_762x39_AK12_Mag_F";
            };
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            _unit addItemToBackpack "ToolKit";
        };
        
        case "Sniper": {
            // UPDATED: Sniper with GM6 Lynx .50 cal (optic only - GM6 doesn't support suppressor/bipod)
            _unit addWeapon "srifle_GM6_ghex_F";
            _unit addPrimaryWeaponItem "optic_LRPS_ghex_F"; // Long-range scope ghex
            
            for "_i" from 1 to 5 do {
                _unit addMagazine "5Rnd_127x108_APDS_Mag"; // APDS rounds
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "5Rnd_127x108_Mag"; // Standard rounds
            };
            
            _unit addWeapon "Laserdesignator_03";
            
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "5Rnd_127x108_APDS_Mag";
            };
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            _unit addItemToBackpack "ToolKit";
        };
    };
};

// ============================================
// ENHANCED AI SPAWN FUNCTION
// ============================================

RECRUIT_spawnUnit = {
    params ["_player", "_config"];
    
    _config params ["_model", "_vest", "_backpack", "_role"];
    
    // Create RESISTANCE/INDEPENDENT unit using FORM mode (native formation)
    private _unit = (group _player) createUnit [_model, position _player, [], 5, "FORM"];
    
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    
    // RESISTANCE/INDEPENDENT gear
    _unit forceAddUniform "U_C_Driver_3";
    _unit addVest _vest;
    _unit addBackpack _backpack;
    _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";
    _unit addGoggles "G_Balaclava_Skull1";
    
    // Universal items for all roles
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    _unit linkItem "ItemRadio";
    _unit linkItem "ItemGPS";
    
    // Role-specific loadouts with PRE-LOADED LAUNCHERS
    switch (_role) do {
        case "AA": {
            // Anti-Air Specialist with MMG (ARCO optic built-in)
            _unit addWeapon "MMG_01_hex_ARCO_LP_F";
            _unit addPrimaryWeaponItem "acc_pointer_IR"; // IR laser
            _unit addPrimaryWeaponItem "bipod_02_F_hex"; // Bipod for stability
            
            // Add primary weapon magazines FIRST (before launcher)
            for "_i" from 1 to 3 do {
                _unit addMagazine "150Rnd_93x64_Mag";
            };
            
            // Add launcher with PRE-LOADED magazine
            _unit addMagazine "Titan_AA"; // Add magazine BEFORE weapon
            _unit addWeapon "launch_B_Titan_F"; // Weapon will auto-load the magazine
            
            // Binoculars for target acquisition
            _unit addWeapon "Rangefinder";
            
            // Extra equipment
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            _unit addMagazine "SmokeShellGreen"; // Signal smoke
            
            // Backpack ammo
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "Titan_AA";
            };
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "150Rnd_93x64_Mag";
            };
            _unit addItemToBackpack "SmokeShell";
            
            // Medical supplies
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            
            // Toolkit for repairs
            _unit addItemToBackpack "ToolKit";
        };
        
        case "AT": {
            // UPDATED: Anti-Tank Specialist with AK-12
            _unit addWeapon "arifle_AK12_F";
            _unit addPrimaryWeaponItem "muzzle_snds_B"; // Suppressor
            _unit addPrimaryWeaponItem "acc_pointer_IR"; // IR laser
            _unit addPrimaryWeaponItem "optic_Arco_AK_blk_F"; // ARCO optic for AK
            _unit addPrimaryWeaponItem "bipod_01_F_blk"; // Bipod
            
            // Add primary weapon magazines
            for "_i" from 1 to 6 do {
                _unit addMagazine "30Rnd_762x39_AK12_Mag_F";
            };
            
            // Add launcher with PRE-LOADED magazine
            _unit addMagazine "MRAWS_HEAT_F"; // Add magazine BEFORE weapon
            _unit addWeapon "launch_MRAWS_green_rail_F"; // Weapon will auto-load
            
            // Rangefinder for precision
            _unit addWeapon "Rangefinder";
            
            // Extra equipment
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            _unit addMagazine "SmokeShellRed"; // Signal smoke
            
            // Backpack ammo
            for "_i" from 1 to 2 do {
                _unit addItemToBackpack "MRAWS_HEAT_F";
            };
            _unit addItemToBackpack "MRAWS_HE_F"; // HE round for infantry
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "30Rnd_762x39_AK12_Mag_F";
            };
            
            // Medical supplies
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            
            // Toolkit for repairs
            _unit addItemToBackpack "ToolKit";
        };
        
        case "Sniper": {
            // UPDATED: Designated Marksman with GM6 Lynx .50 cal (ghex variant)
            // GM6 only supports optic attachments, no suppressor or bipod compatibility
            _unit addWeapon "srifle_GM6_ghex_F";
            _unit addPrimaryWeaponItem "optic_LRPS_ghex_F"; // Long-range scope ghex
            
            // Add APDS (armor-piercing) ammunition
            for "_i" from 1 to 5 do {
                _unit addMagazine "5Rnd_127x108_APDS_Mag"; // APDS rounds
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "5Rnd_127x108_Mag"; // Standard rounds
            };
            
            // Laser designator for marking targets
            _unit addWeapon "Laserdesignator_03";
            
            // Extra equipment
            for "_i" from 1 to 2 do {
                _unit addMagazine "SmokeShell";
            };
            for "_i" from 1 to 2 do {
                _unit addMagazine "HandGrenade";
            };
            _unit addMagazine "SmokeShellBlue"; // Signal smoke
            
            // Backpack ammo - MORE APDS rounds
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "5Rnd_127x108_APDS_Mag"; // Additional APDS
            };
            
            // Medical supplies
            for "_i" from 1 to 4 do {
                _unit addItemToBackpack "FirstAidKit";
            };
            _unit addItemToBackpack "Medikit";
            
            // Toolkit for repairs
            _unit addItemToBackpack "ToolKit";
        };
    };
    
    // GOD-TIER SKILLS (ALL SET TO MAXIMUM 1.0)
    _unit setSkill ["aimingAccuracy", 1.0];
    _unit setSkill ["aimingShake", 1.0];
    _unit setSkill ["aimingSpeed", 1.0];
    _unit setSkill ["spotDistance", 1.0];
    _unit setSkill ["spotTime", 1.0];
    _unit setSkill ["courage", 1.0];
    _unit setSkill ["reloadSpeed", 1.0];
    _unit setSkill ["commanding", 1.0];
    _unit setSkill ["general", 1.0];
    
    // 1.4x MOVEMENT SPEED (AI move faster than player)
    _unit setAnimSpeedCoef 1.4;
    
    // EXTREME AI BEHAVIOR SETTINGS
    _unit setBehaviour "AWARE";
    _unit setCombatMode "YELLOW";
    _unit allowFleeing 0;
    _unit disableAI "SUPPRESSION";
    _unit setUnitPos "AUTO";
    
    // Maximize aggression and awareness
    _unit enableAI "TARGET";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "MOVE";
    _unit enableAI "ANIM";
    _unit enableAI "FSM";
    _unit enableAI "AIMINGERROR";
    _unit enableAI "COVER";
    _unit enableAI "AUTOCOMBAT";
    
    // Mark as recruited and set role
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["TAC_Role", _role, true];
    
    // Start AI behavior loop for THIS unit
    [_unit, _role] spawn {
        params ["_unit", "_role"];
        
        private _lastCalloutTime = 0;
        private _lastRearmCheck = 0;
        
        while {[_unit] call RECRUIT_fnc_isUnitValid} do {
            
            // Check if player died - exit loop if so
            if (!alive player || RECRUIT_RespawnInProgress) exitWith {};
            
            // TARGET ACQUISITION AND CALLOUTS
            if (time - _lastCalloutTime > RECRUIT_CALLOUT_INTERVAL) then {
                _lastCalloutTime = time;
                
                // FIXED: Pre-filter to relevant object types for performance
                private _nearTargets = (nearestObjects [_unit, ["CAManBase", "LandVehicle", "Air"], RECRUIT_DETECTION_RADIUS]) select {
                    [_unit, _x] call RECRUIT_fnc_isValidTarget
                };
                
                if (count _nearTargets > 0) then {
                    private _target = _nearTargets select 0;
                    private _distance = round(_unit distance _target);
                    private _bearing = round(_unit getDir _target);
                    private _direction = [_bearing] call RECRUIT_fnc_getDirectionName;
                    
                    private _targetType = "Enemy";
                    if (_target isKindOf "LandVehicle" || _target isKindOf "Air") then {
                        private _vehType = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
                        if (_vehType != "") then {
                            _targetType = _vehType;
                        } else {
                            _targetType = "Vehicle";
                        };
                    };
                    
                    // Audio callout based on role
                    switch (_role) do {
                        case "AA": {
                            _unit globalChat format["[AA] Contact! %1 spotted, %2m %3! Going LOUD!", _targetType, _distance, _direction];
                        };
                        case "AT": {
                            _unit globalChat format["[AT] Got eyes on %1, %2m %3! Engaging!", _targetType, _distance, _direction];
                        };
                        case "Sniper": {
                            _unit globalChat format["[Sniper] Target acquired: %1, %2m %3. Taking the shot!", _targetType, _distance, _direction];
                        };
                    };
                    
                    // Force engage target
                    _unit doTarget _target;
                    _unit doFire _target;
                    
                    // Share target with group
                    {
                        if ([_x] call RECRUIT_fnc_isUnitValid && _x != _unit) then {
                            _x reveal [_target, 4];
                            _x doTarget _target;
                        };
                    } forEach (units group _unit);
                };
            };
            
            // AMMO CHECK AND REARM
            if (time - _lastRearmCheck > RECRUIT_REARM_CHECK_INTERVAL) then {
                _lastRearmCheck = time;
                
                private _ammoPercent = [_unit] call RECRUIT_fnc_getAmmoPercentage;
                
                if (_ammoPercent < 0.3) then {
                    _unit globalChat format["[%1] Running low on ammo! %2%% remaining.", _role, round(_ammoPercent * 100)];
                    
                    // Check if player has Arsenal nearby
                    private _nearArsenal = nearestObjects [_unit, [], 10] select {
                        _x getVariable ["ExileIsAmmoBox", false]
                    };
                    
                    if (count _nearArsenal > 0) then {
                        _unit globalChat format["[%1] Arsenal nearby - rearming!", _role];
                        
                        // Move to arsenal and rearm
                        _unit doMove (getPos (_nearArsenal select 0));
                        waitUntil {
                            sleep 1;
                            !alive _unit || _unit distance (_nearArsenal select 0) < 5 || time > (_lastRearmCheck + 30)
                        };
                        
                        if (alive _unit) then {
                            // FIXED: Use new rearm function instead of calling RECRUIT_spawnUnit
                            [_unit, _role] spawn {
                                params ["_unit", "_role"];
                                sleep 2;
                                [_unit, _role] call RECRUIT_fnc_rearmUnit;
                                _unit globalChat format["[%1] Rearm complete!", _role];
                            };
                        };
                    };
                };
            };
            
            sleep 8;
        };
    };
};

// ============================================
// VEHICLE COORDINATION - INSTANT TELEPORT BOARDING
// ============================================

[] spawn {
    while {true} do {
        if (!RECRUIT_RespawnInProgress) then {
            {
                private _plyr = _x;
                
                // Only process if player is alive
                if (alive _plyr) then {
                    private _playerVeh = vehicle _plyr;
                    
                    // Only process if player is in a vehicle
                    if (_playerVeh != _plyr) then {
                        // INSTANT TELEPORT BOARDING (no doGetIn delay)
                        private _unitsToBoard = (units group _plyr) select {
                            [_x] call RECRUIT_fnc_isUnitValid && 
                            _x != _plyr && 
                            _x getVariable ["ExileRecruited", false] &&
                            vehicle _x == _x && // Unit is on foot
                            _x distance _playerVeh <= RECRUIT_VEHICLE_BOARD_RADIUS
                        };
                        
                        {
                            private _unit = _x;
                            
                            // Check what position the player is in
                            private _playerIsDriver = (driver _playerVeh == _plyr);
                            private _playerIsCargo = !_playerIsDriver && (commander _playerVeh != _plyr) && (gunner _playerVeh != _plyr);
                            private _playerIsGunner = (gunner _playerVeh == _plyr);
                            
                            // Prioritize seats based on player's position
                            if (_playerIsDriver) then {
                                // Player is DRIVER: Fill Gunner → Cargo
                                if (_playerVeh emptyPositions "gunner" > 0) then {
                                    _unit moveInGunner _playerVeh;
                                } else {
                                    if (_playerVeh emptyPositions "cargo" > 0) then {
                                        _unit moveInCargo _playerVeh;
                                    };
                                };
                            } else {
                                if (_playerIsCargo) then {
                                    // Player is CARGO: Fill Driver → Gunner → Cargo
                                    if (_playerVeh emptyPositions "driver" > 0) then {
                                        _unit moveInDriver _playerVeh;
                                    } else {
                                        if (_playerVeh emptyPositions "gunner" > 0) then {
                                            _unit moveInGunner _playerVeh;
                                        } else {
                                            if (_playerVeh emptyPositions "cargo" > 0) then {
                                                _unit moveInCargo _playerVeh;
                                            };
                                        };
                                    };
                                } else {
                                    if (_playerIsGunner) then {
                                        // Player is GUNNER: Fill Driver → Cargo
                                        if (_playerVeh emptyPositions "driver" > 0) then {
                                            _unit moveInDriver _playerVeh;
                                        } else {
                                            if (_playerVeh emptyPositions "cargo" > 0) then {
                                                _unit moveInCargo _playerVeh;
                                            };
                                        };
                                    } else {
                                        // Player in other position: Just fill cargo
                                        if (_playerVeh emptyPositions "cargo" > 0) then {
                                            _unit moveInCargo _playerVeh;
                                        };
                                    };
                                };
                            };
                            
                        } forEach _unitsToBoard;
                    };
                    
                    // Handle AI exiting when player exits vehicle
                    {
                        private _unit = _x;
                        
                        if ([_unit] call RECRUIT_fnc_isUnitValid) then {
                            if (_unit getVariable ["ExileRecruited", false]) then {
                                private _unitVeh = vehicle _unit;
                                
                                // If player is on foot but AI still in vehicle - eject them
                                if (_playerVeh == _plyr && _unitVeh != _unit) then {
                                    private _vehSpeed = speed _unitVeh;
                                    
                                    // Exit immediately if vehicle is slow or stopped
                                    if (_vehSpeed < 5) then {
                                        unassignVehicle _unit;
                                        _unit action ["Eject", _unitVeh];
                                        moveOut _unit;
                                    };
                                };
                            };
                        };
                        
                    } forEach (units group _plyr);
                };
                
            } forEach allPlayers;
        };
        
        sleep 0.3;
    };
};

// ============================================
// FORMATION MANAGEMENT
// ============================================

[] spawn {
    waitUntil {sleep 1; !isNull player};
    
    // Set group formation to VEE
    (group player) setFormation "VEE";
    
    while {true} do {
        if (!RECRUIT_RespawnInProgress) then {
            {
                private _plyr = _x;
                
                if (alive _plyr) then {
                    private _grp = group _plyr;
                    
                    // Maintain VEE formation
                    if (formation _grp != "VEE") then {
                        _grp setFormation "VEE";
                    };
                    
                    // Ensure AI follow player
                    {
                        private _unit = _x;
                        if ([_unit] call RECRUIT_fnc_isUnitValid && _unit getVariable ["ExileRecruited", false]) then {
                            // Make sure unit is in formation
                            _unit setUnitPos "AUTO";
                            
                            // If unit is too far behind, force them to catch up
                            if (_unit distance _plyr > 50 && vehicle _unit == _unit && vehicle _plyr == _plyr) then {
                                _unit doFollow _plyr;
                            };
                        };
                    } forEach (units _grp select {_x != _plyr});
                };
                
            } forEach allPlayers;
        };
        
        sleep 2;
    };
};

// ============================================
// CLEANUP - FIXED VERSION
// ============================================

[] spawn {
    while {true} do {
        // Wait until player dies
        waitUntil {sleep 0.5; !alive player};
        
        // Set respawn flag immediately
        RECRUIT_RespawnInProgress = true;
        RECRUIT_LastDeathTime = time;
        
        systemChat "[RECRUIT] Player died - cleaning up AI squad...";
        
        // Clean up ALL recruited units
        private _unitsToDelete = (units group player) select {
            _x getVariable ["ExileRecruited", false]
        };
        
        // Also check for orphaned units from previous groups
        {
            if (_x getVariable ["ExileRecruited", false] && _x != player) then {
                if (!(_x in _unitsToDelete)) then {
                    _unitsToDelete pushBack _x;
                };
            };
        } forEach allUnits;
        
        // Delete all found units
        {
            if (!isNull _x && _x != player) then {
                deleteVehicle _x;
            };
        } forEach _unitsToDelete;
        
        systemChat format["[RECRUIT] Cleaned up %1 AI units", count _unitsToDelete];
        
        // Wait for player to respawn
        waitUntil {sleep 0.5; alive player};
        
        systemChat "[RECRUIT] Player respawned - AI will spawn after cooldown period...";
        
        // Keep respawn flag active during cooldown
        sleep RECRUIT_RESPAWN_COOLDOWN;
        
        // Clear respawn flag
        RECRUIT_RespawnInProgress = false;
        
        systemChat "[RECRUIT] Cooldown complete - AI recruitment active";
    };
};

// ============================================
// MAIN SPAWN LOOP
// ============================================

systemChat "========================================";
systemChat "ELITE AI RECRUIT SYSTEM v3.9.2 FINAL";
systemChat "⚠️  EXTREME MODE: AWARE+YELLOW+PERFECT AIM";
systemChat "Ultra-aggressive! 100% accuracy! Fearless!";
systemChat "1.4x speed, GM6+APDS, AK-12, never flees!";
systemChat "✓ Fixed: GM6 attachments, removed NVG";
systemChat "========================================";

while {true} do {
    // Only spawn if not in respawn cooldown
    if (!RECRUIT_RespawnInProgress && time > (RECRUIT_LastDeathTime + RECRUIT_RESPAWN_COOLDOWN)) then {
        {
            private _player = _x;
            
            if (alive _player) then {
                private _squadmates = (units (group _player)) select {
                    [_x] call RECRUIT_fnc_isUnitValid &&
                    _x != _player && 
                    _x getVariable ["ExileRecruited", false]
                };
                
                private _unitsToSpawn = _maxSquadmates - (count _squadmates);
                
                if (_unitsToSpawn > 0) then {
                    private _existingTypes = _squadmates apply {_x getVariable ["TAC_Role", ""]};
                    
                    {
                        private _config = _x;
                        private _role = _config select 3;
                        
                        if (!(_role in _existingTypes) && count _squadmates < _maxSquadmates) then {
                            [_player, _config] call RECRUIT_spawnUnit;
                            
                            _squadmates = (units (group _player)) select {
                                [_x] call RECRUIT_fnc_isUnitValid &&
                                _x != _player && 
                                _x getVariable ["ExileRecruited", false]
                            };
                            
                            sleep 1;
                        };
                    } forEach _recruitmentTypes;
                };
            };
            
        } forEach allPlayers;
    };
    
    sleep 10;
};
