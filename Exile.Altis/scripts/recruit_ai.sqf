/*
    ═══════════════════════════════════════════════════════════════════════
    ELITE AI RECRUIT SYSTEM v8.3 - CUSTOM LOADOUTS EDITION
    LDF Units with Best-of-Everything Gear
    ═══════════════════════════════════════════════════════════════════════
    
    UNIT ROLES:
    • ENGINEER: Repairs + Mines + Titan Compact AT + DMR
    • MEDIC: Healing + Titan AA + LMG Suppression
    • SOLDIER: Grenadier with UGL + Versatile Rifle
    
    LOADOUT FEATURES:
    • All items stripped and replaced with best gear
    • Suppressed weapons with best optics
    • NVGs, GPS, Rangefinders
    • Role-specific launchers (AT/AA)
    • Maximum ammo capacity
    • Colored smoke for coordination
    
    REQUIRES: Contact DLC for LDF units
*/

if (!isServer) exitWith {};

// ═══════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════

ELITE_AI_TYPES = [
    "I_E_Engineer_F",      // Engineer - Repairs + Mines + AT Launcher
    "I_E_Medic_F",         // Medic - Heals + AA Launcher  
    "I_E_Soldier_AR_F"     // Autorifleman - Gets GL loadout
];

ELITE_MAX_AI = 3;
ELITE_SPAWN_COOLDOWN = 5;

// Global tracking (dual tracking system)
ELITE_PlayerAI = createHashMap;
ELITE_Cooldowns = createHashMap;

diag_log "═══════════════════════════════════════════════════════════════════════";
diag_log "[ELITE AI] v8.3 CUSTOM LOADOUTS - LDF Units with Best Gear";
diag_log "═══════════════════════════════════════════════════════════════════════";

// Validate AI types on startup
diag_log "[ELITE AI] Validating AI types...";
{
    if (!isClass (configFile >> "CfgVehicles" >> _x)) then {
        diag_log format ["[ELITE AI] ERROR: Invalid AI type '%1' - not found! (Need Contact DLC?)", _x];
    } else {
        diag_log format ["[ELITE AI] OK: Validated: %1", _x];
    };
} forEach ELITE_AI_TYPES;

// ═══════════════════════════════════════════════════════════════════════
// FORCE HOSTILITY (Independent vs OPFOR)
// ═══════════════════════════════════════════════════════════════════════

resistance setFriend [east, 0];
east setFriend [resistance, 0];
diag_log "[ELITE AI] OK: Forced RESISTANCE vs EAST hostility";

ELITE_fnc_CustomLoadout = {
    params ["_unit", "_role"];
    
    diag_log format ["[ELITE AI] Applying custom loadout for role: %1", _role];
    
    // ═══════════════════════════════════════════════════════════════════
    // STRIP ALL EXISTING GEAR
    // ═══════════════════════════════════════════════════════════════════
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    
    // ═══════════════════════════════════════════════════════════════════
    // COMMON GEAR (All Roles)
    // ═══════════════════════════════════════════════════════════════════
    
    // Best NVGs (ENVG-II - thermal + night vision)
    _unit linkItem "NVGogglesB_grn_F";
    
    // GPS + Map + Compass + Watch + Radio
    _unit linkItem "ItemGPS";
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    _unit linkItem "ItemRadio";
    
    // Tactical Glasses (anti-flashbang)
    _unit addGoggles "G_Tactical_Clear";
    
    // ═══════════════════════════════════════════════════════════════════
    // ROLE-SPECIFIC LOADOUTS
    // ═══════════════════════════════════════════════════════════════════
    
    switch (_role) do {
        
        // ═══════════════════════════════════════════════════════════════
        // ENGINEER - Repairs, Mines, AT Launcher, DMR
        // ═══════════════════════════════════════════════════════════════
        case "I_E_Engineer_F": {
            diag_log "[ELITE AI] Configuring ENGINEER loadout...";
            
            // UNIFORM - LDF Combat (woodland pattern)
            _unit forceAddUniform "U_I_E_Uniform_01_F";
            
            // VEST - Plate Carrier (maximum armor)
            _unit addVest "V_PlateCarrier2_rgr";
            
            // HELMET - Enhanced Combat Helmet (best protection)
            _unit addHeadgear "H_HelmetSpecB_blk";
            
            // BACKPACK - Carryall (80 slots - room for toolkit + AT rounds)
            _unit addBackpack "B_Carryall_oli";
            
            // PRIMARY - SPAR-17 7.62mm DMR (accurate, hard-hitting)
            _unit addWeapon "arifle_SPAR_03_blk_F";
            // Attachments: DMS Scope + Suppressor + Bipod
            _unit addPrimaryWeaponItem "optic_DMS";
            _unit addPrimaryWeaponItem "muzzle_snds_B";
            _unit addPrimaryWeaponItem "bipod_01_F_blk";
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            // PRE-LOAD magazine into weapon first
            _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
            // Ammo - 19 more mags in inventory
            for "_i" from 1 to 19 do {
                _unit addMagazine "20Rnd_762x51_Mag";
            };
            
            // SECONDARY - 4-Five .45 Suppressed
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "muzzle_snds_acp";
            _unit addHandgunItem "optic_MRD";
            // PRE-LOAD pistol magazine
            _unit addHandgunItem "11Rnd_45ACP_Mag";
            for "_i" from 1 to 7 do {
                _unit addMagazine "11Rnd_45ACP_Mag";
            };
            
            // LAUNCHER - Titan Compact AT (vehicle killer) - 6 ROCKETS
            _unit addWeapon "launch_I_Titan_short_F";
            // PRE-LOAD launcher
            _unit addSecondaryWeaponItem "Titan_AT";
            _unit addMagazine "Titan_AT";
            _unit addMagazine "Titan_AT";
            _unit addMagazine "Titan_AT";
            _unit addMagazine "Titan_AP";
            _unit addMagazine "Titan_AP";
            
            // BINOCULARS - Rangefinder (for AT targeting)
            _unit addWeapon "Rangefinder";
            
            // ITEMS - TOOLKIT IS CRITICAL (must go in backpack - it's a large item)
            (unitBackpack _unit) addItemCargoGlobal ["ToolKit", 1];
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            (unitBackpack _unit) addItemCargoGlobal ["MineDetector", 1];
            
            // GRENADES
            _unit addMagazine "HandGrenade";
            _unit addMagazine "HandGrenade";
            _unit addMagazine "MiniGrenade";
            _unit addMagazine "MiniGrenade";
            _unit addMagazine "SmokeShell";
            _unit addMagazine "SmokeShellGreen";
            _unit addMagazine "SmokeShellRed";
            _unit addMagazine "B_IR_Grenade";
            
            diag_log "[ELITE AI] OK: ENGINEER loadout complete - ToolKit + Titan AT";
        };
        
        // ═══════════════════════════════════════════════════════════════
        // MEDIC - Heals, AA Launcher, LMG Suppression
        // ═══════════════════════════════════════════════════════════════
        case "I_E_Medic_F": {
            diag_log "[ELITE AI] Configuring MEDIC loadout...";
            
            // UNIFORM - LDF Combat
            _unit forceAddUniform "U_I_E_Uniform_01_shortsleeve_F";
            
            // VEST - Carrier Rig (good armor + capacity)
            _unit addVest "V_PlateCarrier1_rgr";
            
            // HELMET - Combat Helmet
            _unit addHeadgear "H_HelmetB_light_grass";
            
            // BACKPACK - Carryall (medkits + AA missiles)
            _unit addBackpack "B_Carryall_oli";
            
            // PRIMARY - SPMG .338 (best LMG in game - devastating)
            _unit addWeapon "MMG_02_black_F";
            // Attachments: ARCO scope + Suppressor + Bipod
            _unit addPrimaryWeaponItem "optic_ARCO_blk_F";
            _unit addPrimaryWeaponItem "muzzle_snds_338_black";
            _unit addPrimaryWeaponItem "bipod_01_F_blk";
            // PRE-LOAD magazine
            _unit addPrimaryWeaponItem "130Rnd_338_Mag";
            // Ammo - 9 more belts
            for "_i" from 1 to 9 do {
                _unit addMagazine "130Rnd_338_Mag";
            };
            
            // SECONDARY - 4-Five .45 Suppressed
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "muzzle_snds_acp";
            _unit addHandgunItem "optic_MRD";
            // PRE-LOAD pistol
            _unit addHandgunItem "11Rnd_45ACP_Mag";
            for "_i" from 1 to 7 do {
                _unit addMagazine "11Rnd_45ACP_Mag";
            };
            
            // LAUNCHER - Titan AA (anti-aircraft) - 5 MISSILES
            _unit addWeapon "launch_I_Titan_F";
            // PRE-LOAD launcher
            _unit addSecondaryWeaponItem "Titan_AA";
            _unit addMagazine "Titan_AA";
            _unit addMagazine "Titan_AA";
            _unit addMagazine "Titan_AA";
            _unit addMagazine "Titan_AA";
            
            // BINOCULARS - Laser Designator (can lase targets)
            _unit addWeapon "Laserdesignator_03";
            _unit addMagazine "Laserbatteries";
            
            // ITEMS - MEDIKIT IS CRITICAL (must go in backpack - it's a large item)
            (unitBackpack _unit) addItemCargoGlobal ["Medikit", 1];
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            
            // GRENADES - Medical smokes for marking
            _unit addMagazine "SmokeShell";
            _unit addMagazine "SmokeShellBlue";
            _unit addMagazine "SmokeShellPurple";
            _unit addMagazine "SmokeShellGreen";
            _unit addMagazine "HandGrenade";
            _unit addMagazine "MiniGrenade";
            
            diag_log "[ELITE AI] OK: MEDIC loadout complete - Medikit + Titan AA + SPMG";
        };
        
        // ═══════════════════════════════════════════════════════════════
        // SOLDIER/GRENADIER - UGL, Versatile Combat
        // ═══════════════════════════════════════════════════════════════
        case "I_E_Soldier_AR_F": {
            diag_log "[ELITE AI] Configuring GRENADIER loadout...";
            
            // UNIFORM - LDF Combat
            _unit forceAddUniform "U_I_E_Uniform_01_F";
            
            // VEST - GL Carrier (extra grenade storage)
            _unit addVest "V_PlateCarrierGL_rgr";
            
            // HELMET - Spec Ops Helmet
            _unit addHeadgear "H_HelmetSpecB_paint2";
            
            // BACKPACK - Assault Pack (lighter for mobility)
            _unit addBackpack "B_AssaultPack_rgr";
            
            // PRIMARY - SPAR-16 GL (5.56mm + Grenade Launcher)
            _unit addWeapon "arifle_SPAR_01_GL_blk_F";
            // Attachments: ARCO + Suppressor + Laser
            _unit addPrimaryWeaponItem "optic_ARCO_blk_F";
            _unit addPrimaryWeaponItem "muzzle_snds_M";
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            // PRE-LOAD rifle magazine
            _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag";
            // Rifle Ammo - 19 more mags
            for "_i" from 1 to 19 do {
                _unit addMagazine "30Rnd_556x45_Stanag";
            };
            // UGL Ammo - 20 HE rounds (PRE-LOADED via addPrimaryWeaponItem)
            _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
            for "_i" from 1 to 19 do {
                _unit addMagazine "1Rnd_HE_Grenade_shell";
            };
            _unit addMagazine "1Rnd_Smoke_Grenade_shell";
            _unit addMagazine "1Rnd_Smoke_Grenade_shell";
            _unit addMagazine "1Rnd_SmokeRed_Grenade_shell";
            _unit addMagazine "1Rnd_SmokeGreen_Grenade_shell";
            _unit addMagazine "UGL_FlareWhite_F";
            _unit addMagazine "UGL_FlareRed_F";
            
            // SECONDARY - 4-Five .45 Suppressed
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "muzzle_snds_acp";
            _unit addHandgunItem "optic_MRD";
            // PRE-LOAD pistol
            _unit addHandgunItem "11Rnd_45ACP_Mag";
            for "_i" from 1 to 7 do {
                _unit addMagazine "11Rnd_45ACP_Mag";
            };
            
            // BINOCULARS - Standard binos
            _unit addWeapon "Binocular";
            
            // ITEMS
            _unit addItem "FirstAidKit";
            _unit addItem "FirstAidKit";
            
            // GRENADES - Full loadout
            _unit addMagazine "HandGrenade";
            _unit addMagazine "HandGrenade";
            _unit addMagazine "HandGrenade";
            _unit addMagazine "MiniGrenade";
            _unit addMagazine "MiniGrenade";
            _unit addMagazine "SmokeShell";
            _unit addMagazine "SmokeShellGreen";
            _unit addMagazine "SmokeShellRed";
            _unit addMagazine "B_IR_Grenade";
            
            diag_log "[ELITE AI] OK: GRENADIER loadout complete - SPAR GL + 20 HE rounds";
        };
        
        // ═══════════════════════════════════════════════════════════════
        // DEFAULT - Basic good loadout
        // ═══════════════════════════════════════════════════════════════
        default {
            diag_log format ["[ELITE AI] Unknown role %1 - applying default loadout", _role];
            
            _unit forceAddUniform "U_I_E_Uniform_01_F";
            _unit addVest "V_PlateCarrier1_rgr";
            _unit addHeadgear "H_HelmetB";
            _unit addBackpack "B_AssaultPack_rgr";
            
            // Basic rifle
            _unit addWeapon "arifle_SPAR_01_blk_F";
            _unit addPrimaryWeaponItem "optic_ARCO";
            _unit addPrimaryWeaponItem "muzzle_snds_M";
            for "_i" from 1 to 8 do {
                _unit addMagazine "30Rnd_556x45_Stanag";
            };
            
            _unit addItem "FirstAidKit";
            _unit addMagazine "HandGrenade";
            _unit addMagazine "SmokeShell";
        };
    };
    
    // ═══════════════════════════════════════════════════════════════════
    // VERIFY CRITICAL ITEMS
    // ═══════════════════════════════════════════════════════════════════
    
    private _hasCriticalItem = false;
    private _backpackItems = backpackItems _unit;
    
    switch (_role) do {
        case "I_E_Engineer_F": {
            _hasCriticalItem = "ToolKit" in _backpackItems || "ToolKit" in items _unit;
            if (!_hasCriticalItem) then {
                diag_log "[ELITE AI] WARNING: Engineer missing ToolKit - adding to backpack...";
                (unitBackpack _unit) addItemCargoGlobal ["ToolKit", 1];
            };
        };
        case "I_E_Medic_F": {
            _hasCriticalItem = "Medikit" in _backpackItems || "Medikit" in items _unit;
            if (!_hasCriticalItem) then {
                diag_log "[ELITE AI] WARNING: Medic missing Medikit - adding to backpack...";
                (unitBackpack _unit) addItemCargoGlobal ["Medikit", 1];
            };
        };
    };
    
    // Select primary weapon
    _unit selectWeapon (primaryWeapon _unit);
    
    diag_log format ["[ELITE AI] Custom loadout applied for %1", _role];
    diag_log format ["[ELITE AI]   Primary: %1", primaryWeapon _unit];
    diag_log format ["[ELITE AI]   Secondary: %1", handgunWeapon _unit];
    diag_log format ["[ELITE AI]   Launcher: %1", secondaryWeapon _unit];
    diag_log format ["[ELITE AI]   Backpack: %1", backpackItems _unit];
    diag_log format ["[ELITE AI]   Items: %1", items _unit];
};

ELITE_fnc_ConfigureAI = {
    params ["_unit", "_player"];
    
    // Perfect skills
    {
        _unit setSkill [_x, 1.0];
    } forEach [
        "aimingAccuracy",
        "aimingShake",
        "aimingSpeed",
        "spotDistance",
        "spotTime",
        "courage",
        "reloadSpeed",
        "commanding",
        "general"
    ];
    
    // Superhuman movement
    _unit setAnimSpeedCoef 1.5;
    _unit forceWalk false;
    _unit setUnitRecoilCoefficient 0;
    _unit allowFleeing 0;
    
    // Stealth & detection
    _unit setUnitTrait ["camouflageCoef", 0.3];
    _unit setUnitTrait ["audibleCoef", 0.2];
    _unit setUnitTrait ["loadCoef", 0.5];
    _unit setUnitTrait ["UAVHacker", true];
    
    // IMPORTANT: Set medic/engineer traits based on class
    private _type = typeOf _unit;
    if (_type == "I_E_Medic_F") then {
        _unit setUnitTrait ["Medic", true];
        diag_log "[ELITE AI] Set Medic trait = true";
    };
    if (_type == "I_E_Engineer_F") then {
        _unit setUnitTrait ["Engineer", true];
        _unit setUnitTrait ["explosiveSpecialist", true];
        diag_log "[ELITE AI] Set Engineer + ExplosiveSpecialist traits = true";
    };
    
    // Combat behavior - NEVER PRONE, ALWAYS FOLLOW
    _unit setBehaviour "AWARE";
    _unit setCombatMode "YELLOW";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    
    // FORCE STANDING - disable prone entirely
    _unit setUnitPos "UP";
    _unit disableAI "AUTOCOMBAT";
    
    // Lock unit position to standing
    [_unit] spawn {
        params ["_unit"];
        while {alive _unit} do {
            _unit setUnitPos "UP";
            sleep 1;
        };
    };
    
    // Enable all AI systems
    {
        _unit enableAI _x;
    } forEach [
        "TARGET",
        "AUTOTARGET",
        "MOVE",
        "ANIM",
        "FSM",
        "AIMINGERROR",
        "SUPPRESSION",
        "COVER",
        "TEAMSWITCH"
    ];
    
    // Advanced features
    _unit enableGunLights "AUTO";
    _unit enableIRLasers true;
    _unit enableStamina false;
    
    // Immunity & protections
    _unit setVariable ["NoRessurect", true, true];
    _unit setVariable ["RVG_ZedIgnore", true, true];
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["OwnerUID", getPlayerUID _player, true];
    _unit setVariable ["OwnerName", name _player, true];
    
    // A3XAI Blacklist
    if (!isNil "A3XAI_NOAI") then {
        A3XAI_NOAI pushBackUnique _unit;
        _unit setVariable ["A3XAI_Ignore", true, true];
    };
    
    // VCOMAI Integration
    if (!isNil "VCM_ACTIVATEAI") then {
        if (!isNil "VCM_NOAI") then {
            VCM_NOAI pushBackUnique _unit;
        };
        _unit setVariable ["VCM_CUSTOMAI", true, true];
        _unit setVariable ["VCM_RECRUIT", true, true];
        
        if (!isNil "VCM_fnc_INITAI") then {
            [_unit] call VCM_fnc_INITAI;
        };
    };
    
    // LAMBS Danger Integration
    _unit setVariable ["LAMBS_RECRUIT", true, true];
    _unit setVariable ["LAMBS_dangerRadius", 150, true];
    _unit setVariable ["LAMBS_dangerCausesCreep", true, true];
    
    // Follow player
    _unit doFollow _player;
    
    // Custom ballistics (faster projectiles)
    _unit addEventHandler ["Fired", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
        
        if (!isNull _projectile) then {
            _projectile setVelocity (velocity _projectile vectorMultiply 1.2);
        };
    }];
    
    // SMART RELOAD SYSTEM - Never caught empty
    [_unit] spawn {
        params ["_unit"];
        
        while {alive _unit} do {
            sleep 2;
            
            if (alive _unit) then {
                private _primary = primaryWeapon _unit;
                private _launcher = secondaryWeapon _unit;
                
                // Check primary weapon ammo
                if (_primary != "" && currentMagazine _unit != "") then {
                    private _ammoCount = _unit ammo _primary;
                    private _magazineSize = getNumber (configFile >> "CfgMagazines" >> (currentMagazine _unit) >> "count");
                    
                    // Reload if below 30% magazine capacity
                    if (_ammoCount < (_magazineSize * 0.3)) then {
                        _unit action ["RELOADMAGAZINE", _unit, _unit, 0, currentMuzzle _unit];
                    };
                };
                
                // Check launcher ammo
                if (_launcher != "") then {
                    private _launcherAmmo = _unit ammo _launcher;
                    
                    // Reload launcher if empty
                    if (_launcherAmmo == 0) then {
                        _unit action ["RELOADMAGAZINE", _unit, _unit, 1, _launcher];
                    };
                };
            };
        };
    };
    
    // Auto-healing loop (uses Medikit/FirstAidKit from loadout)
    [_unit] spawn {
        params ["_unit"];
        
        while {alive _unit} do {
            sleep 10;
            
            if (damage _unit > 0.3 && alive _unit) then {
                if ("FirstAidKit" in items _unit || "Medikit" in items _unit) then {
                    _unit action ["HealSoldierSelf", _unit];
                };
            };
        };
    };
    
    // SMOOTH FOLLOW LOOP (No teleporting, no jitter, NEVER PRONE)
[_unit, _player] spawn {
    params ["_unit", "_player"];
    
    while {alive _unit && alive _player} do {
        sleep 2;
        
        // CHECK IF AI IS IN A VEHICLE - IF SO, SKIP FOLLOW COMMANDS
        private _unitVehicle = objectParent _unit;
        
        if (isNull _unitVehicle) then {
            // AI is on foot - apply normal follow behavior
            
            // FORCE STANDING POSITION - CRITICAL
            _unit setUnitPos "UP";
            _unit setBehaviour "AWARE";
            
            private _dist = _unit distance _player;
            
            // Aggressive follow - always stay close
            if (_dist > 50) then {
                _unit doFollow _player;
                _unit doMove (getPos _player);
                _unit setSpeedMode "FULL";
            } else {
                _unit doFollow _player;
                _unit setSpeedMode "NORMAL";
            };
        } else {
            // AI is in a vehicle - just maintain basic behavior, don't force movement
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "NORMAL";
        };
    };
};
    
    diag_log format ["[ELITE AI] OK: Configured ULTRA ELITE stats for %1", typeOf _unit];
};

ELITE_fnc_SpawnAI = {
    params ["_player", "_type", "_spawnIndex"];
    
    diag_log format ["[ELITE AI] SPAWN: Spawning %1 for %2 (index: %3)...", _type, name _player, _spawnIndex];
    
    private _group = group _player;
    
    if (isNull _group) exitWith {
        diag_log format ["[ELITE AI] ERROR: Player %1 has NULL group!", name _player];
        objNull
    };
    
    // Ensure group is server-owned
    if (groupOwner _group != 2) then {
        diag_log "[ELITE AI] Transferring group ownership to server...";
        _group setGroupOwner 2;
        
        private _transferred = false;
        private _attempts = 0;
        private _maxAttempts = 10;
        
        while {!_transferred && _attempts < _maxAttempts} do {
            sleep 0.2;
            _attempts = _attempts + 1;
            
            if (groupOwner _group == 2) then {
                _transferred = true;
                diag_log format ["[ELITE AI] OK: Group ownership transferred (attempt %1)", _attempts];
            };
        };
        
        if (!_transferred) then {
            diag_log format ["[ELITE AI] WARNING: Group transfer timeout (owner: %1)", groupOwner _group];
        };
    };
    
    // Validate AI type
    if (!isClass (configFile >> "CfgVehicles" >> _type)) exitWith {
        diag_log format ["[ELITE AI] ERROR: Invalid AI type: %1", _type];
        objNull
    };
    
    // STAGGERED SPAWN POSITION (prevents jitter)
    private _offset = 3 + (_spawnIndex * 0.5);
    private _angle = 120 * _spawnIndex;
    private _pos = [_player, _offset, _angle] call BIS_fnc_relPos;
    
    diag_log format ["[ELITE AI] Spawn position: %1 (offset: %2, angle: %3)", _pos, _offset, _angle];
    
    // Create unit in player's group
    private _unit = _group createUnit [_type, _pos, [], 0, "FORM"];
    
    if (isNull _unit) exitWith {
        diag_log format ["[ELITE AI] ERROR: createUnit returned NULL for %1", _type];
        objNull
    };
    
    if (!alive _unit) exitWith {
        diag_log format ["[ELITE AI] ERROR: Unit spawned but is DEAD: %1", _type];
        deleteVehicle _unit;
        objNull
    };
    
    // Set direction facing player
    _unit setDir ([_player, _pos] call BIS_fnc_dirTo);
    
    // Store AIType for tracking
    _unit setVariable ["AIType", _type, true];
    
    diag_log format ["[ELITE AI] OK: Unit created: %1", typeOf _unit];
    
    // Apply custom loadout
    [_unit, _type] call ELITE_fnc_CustomLoadout;
    
    // Configure elite stats
    [_unit, _player] call ELITE_fnc_ConfigureAI;
    
    // ═══════════════════════════════════════════════════════════════════
    // DEATH HANDLER
    // ═══════════════════════════════════════════════════════════════════
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        
        private _ownerUID = _unit getVariable ["OwnerUID", ""];
        if (_ownerUID == "") exitWith {};
        
        private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;
    if (!isNull _owner && {!(_owner isKindOf "CAManBase")}) then {
        _owner = effectiveCommander _owner;
    };
    
    if (isNull _owner || !alive _owner) exitWith {};
    
    // Remove from BOTH tracking systems
    private _globalList = ELITE_PlayerAI getOrDefault [_ownerUID, []];
    _globalList = _globalList - [_unit];
    ELITE_PlayerAI set [_ownerUID, _globalList];
    
    private _assigned = _owner getVariable ["AssignedAI", []];
    _assigned = _assigned - [_unit];
    _owner setVariable ["AssignedAI", _assigned, true];
    
    diag_log format ["[ELITE AI] AI killed: %1 - %2 AI remaining", 
        typeOf _unit, count _globalList];
    
    // Auto-respawn after delay
    [_owner, _ownerUID] spawn {
        params ["_owner", "_ownerUID"];
        sleep 3;
        
        if (!isNull _owner && alive _owner) then {
            private _cooldown = ELITE_Cooldowns getOrDefault [_ownerUID, 0];
            if (time > _cooldown) then {
                ELITE_Cooldowns set [_ownerUID, time + ELITE_SPAWN_COOLDOWN];
                [_owner] call ELITE_fnc_EnsureTeam;
            };
        };
    };
}];

// ═══════════════════════════════════════════════════════════════════
// AUTO-REPAIR SYSTEM (Engineer only)
// ═══════════════════════════════════════════════════════════════════
if (_type == "I_E_Engineer_F") then {
    [_unit, _player] spawn {
        params ["_engineer", "_player"];
        
        while {alive _engineer && alive _player} do {
            sleep 2;
            
            // Check if player just got out of a vehicle
            private _playerVehicle = objectParent _player;
            
            // If player is on foot
            if (isNull _playerVehicle) then {
                // Find nearby damaged vehicles (within 50m)
                private _nearVehicles = nearestObjects [_player, ["Car", "Tank", "Air", "Ship"], 50];
                
                {
                    private _vehicle = _x;
                    
                    // Check if vehicle is damaged
                    if (damage _vehicle > 0.05 || {count (getAllHitPointsDamage _vehicle select 2) > 0}) then {
                        private _hitPointDamages = getAllHitPointsDamage _vehicle select 2;
                        private _needsRepair = false;
                        
                        // Check if any part is damaged
                        {
                            if (_x > 0.05) exitWith {_needsRepair = true;};
                        } forEach _hitPointDamages;
                        
                        // Start repair if needed
                        if (_needsRepair || damage _vehicle > 0.05) then {
                            diag_log format ["[ELITE AI] Engineer auto-repairing vehicle: %1", typeOf _vehicle];
                            
                            // Move engineer to vehicle
                            _engineer doMove (getPos _vehicle);
                            
                            // Wait until engineer is close
                            waitUntil {
                                sleep 0.5;
                                _engineer distance _vehicle < 10 || !alive _engineer || !alive _player
                            };
                            
                            if (alive _engineer) then {
                                // Stop movement
                                _engineer doMove (getPos _engineer);
                                
                                // Face the vehicle
                                _engineer doWatch _vehicle;
                                
                                sleep 1;
                                
                                // Perform repair action
                                _engineer action ["Repair", _vehicle];
                                
                                // Visual feedback
                                private _playerName = name _player;
                                diag_log format ["[ELITE AI] Engineer repairing %1's vehicle (%2)", _playerName, typeOf _vehicle];
                                
                                // Wait for repair to complete
                                sleep 8;
                                
                                // Force full repair if still damaged
                                if (damage _vehicle > 0 || {count ((getAllHitPointsDamage _vehicle select 2) select {_x > 0}) > 0}) then {
                                    _vehicle setDamage 0;
                                    
                                    // Repair all hit points
                                    private _hitPoints = getAllHitPointsDamage _vehicle select 0;
                                    {
                                        _vehicle setHitPointDamage [_x, 0];
                                    } forEach _hitPoints;
                                    
                                    diag_log format ["[ELITE AI] Engineer completed full repair on %1", typeOf _vehicle];
                                };
                                
                                // Return to following player
                                sleep 1;
                                _engineer doFollow _player;
                            };
                            
                            // Only repair one vehicle at a time
                            sleep 5;
                        };
                    };
                } forEach _nearVehicles;
            };
        };
    };
};

diag_log format ["[ELITE AI] OK: AI fully configured: %1 for %2", typeOf _unit, name _player];

_unit
};
ELITE_fnc_CleanupAI = {
params ["_uid", "_name"];
diag_log format ["[ELITE AI] CLEANUP: Starting cleanup for %1 (UID: %2)", _name, _uid];
// SOURCE 1: Global hashmap
private _fromMap = ELITE_PlayerAI getOrDefault [_uid, []];
diag_log format ["[ELITE AI]   Source 1 (Global Map): %1 AI", count _fromMap];

// SOURCE 2: Try to find player and check variable
private _player = [_uid] call BIS_fnc_getUnitByUID;
private _fromVar = [];
if (!isNull _player) then {
    _fromVar = _player getVariable ["AssignedAI", []];
    diag_log format ["[ELITE AI]   Source 2 (Player Var): %1 AI", count _fromVar];
} else {
    diag_log "[ELITE AI]   Source 2 (Player Var): Player not found";
};

// SOURCE 3: Scan all groups for AI owned by this player
private _fromGroups = [];
{
    private _unit = _x;
    if (!isPlayer _unit && {_unit getVariable ["OwnerUID", ""] == _uid}) then {
        _fromGroups pushBack _unit;
    };
} forEach allUnits;
diag_log format ["[ELITE AI]   Source 3 (Group Scan): %1 AI", count _fromGroups];

// Combine all sources and deduplicate
private _allAI = _fromMap + _fromVar + _fromGroups;
_allAI = _allAI arrayIntersect _allAI;

diag_log format ["[ELITE AI] Total unique AI to cleanup: %1", count _allAI];

// Collect groups that might need deletion
private _groupsToCheck = [];

// Delete all AI
{
    private _unit = _x;
    if (!isNull _unit) then {
        private _grp = group _unit;
        if (!isNull _grp && {!(_grp in _groupsToCheck)}) then {
            _groupsToCheck pushBack _grp;
        };
        
        // Remove all event handlers
        _unit removeAllEventHandlers "Killed";
        _unit removeAllEventHandlers "Fired";
        
        diag_log format ["[ELITE AI]   Deleting: %1", typeOf _unit];
        deleteVehicle _unit;
    };
} forEach _allAI;

// Clean up empty groups (but NEVER delete player's group)
{
    private _grp = _x;
    if (!isNull _grp) then {
        // SAFETY CHECK: Only delete if not player's group and empty
        private _isPlayerGroup = false;
        {
            if (isPlayer _x) exitWith { _isPlayerGroup = true; };
        } forEach (units _grp);
        
        if (!_isPlayerGroup && {count (units _grp) == 0}) then {
            diag_log format ["[ELITE AI]   Deleting empty group: %1", _grp];
            deleteGroup _grp;
        };
    };
} forEach _groupsToCheck;

// Clear tracking data
ELITE_PlayerAI set [_uid, []];

if (!isNull _player) then {
    _player setVariable ["AssignedAI", [], true];
    _player setVariable ["ELITE_AI_Spawning", false, true];
    _player setVariable ["ELITE_AI_SpawnLockTime", 0, true];
};

diag_log format ["[ELITE AI] OK: Cleanup complete for %1", _name];
};
ELITE_fnc_EnsureTeam = {
params ["_player"];
private _uid = getPlayerUID _player;
if (_uid == "") exitWith {
diag_log "[ELITE AI] WARNING: EnsureTeam called with invalid player";
};
// Check spawn lock
private _isSpawning = _player getVariable ["ELITE_AI_Spawning", false];
private _lockTime = _player getVariable ["ELITE_AI_SpawnLockTime", 0];

// Timeout after 30 seconds (prevents permanent lock)
if (_isSpawning && (time - _lockTime) < 30) exitWith {
    diag_log format ["[ELITE AI] Spawn in progress for %1 - skipping", name _player];
};

// Set spawn lock
_player setVariable ["ELITE_AI_Spawning", true, true];
_player setVariable ["ELITE_AI_SpawnLockTime", time, true];

// Get current AI count
private _currentAI = ELITE_PlayerAI getOrDefault [_uid, []];
_currentAI = _currentAI select {!isNull _x && alive _x};
ELITE_PlayerAI set [_uid, _currentAI];

private _aiNeeded = ELITE_MAX_AI - (count _currentAI);

if (_aiNeeded <= 0) exitWith {
    _player setVariable ["ELITE_AI_Spawning", false, true];
    diag_log format ["[ELITE AI] %1 already has full team (%2 AI)", name _player, count _currentAI];
};

diag_log format ["[ELITE AI] %1 needs %2 AI (has %3)", name _player, _aiNeeded, count _currentAI];

// Determine which types to spawn
private _existingTypes = _currentAI apply {_x getVariable ["AIType", ""]};
private _typesToSpawn = [];

{
    if !(_x in _existingTypes) then {
        _typesToSpawn pushBack _x;
    };
} forEach ELITE_AI_TYPES;

// Spawn AI with staggered delays
private _spawnIndex = count _currentAI;
{
    private _type = _x;
    
    diag_log format ["[ELITE AI] Spawning %1 (index %2)...", _type, _spawnIndex];
    
    private _newAI = [_player, _type, _spawnIndex] call ELITE_fnc_SpawnAI;
    
    if (!isNull _newAI && alive _newAI) then {
        // Add to BOTH tracking systems
        private _list = ELITE_PlayerAI getOrDefault [_uid, []];
        _list pushBack _newAI;
        ELITE_PlayerAI set [_uid, _list];
        
        private _assigned = _player getVariable ["AssignedAI", []];
        _assigned pushBack _newAI;
        _player setVariable ["AssignedAI", _assigned, true];
        
        diag_log format ["[ELITE AI] OK: %1 spawned successfully", _type];
    } else {
        diag_log format ["[ELITE AI] ERROR: Failed to spawn %1", _type];
    };
    
    _spawnIndex = _spawnIndex + 1;
    
    // Staggered spawn delay
    sleep 0.5;
    
} forEach (_typesToSpawn select [0, _aiNeeded]);

// Release spawn lock
_player setVariable ["ELITE_AI_Spawning", false, true];

private _finalCount = count (ELITE_PlayerAI getOrDefault [_uid, []]);
diag_log format ["[ELITE AI] OK: Team complete for %1: %2 AI", name _player, _finalCount];
};
ELITE_fnc_IsPlayerReady = {
params ["_player"];
// Basic null/alive checks
if (isNull _player) exitWith {false};
if (!alive _player) exitWith {false};
if (!isPlayer _player) exitWith {false};

// Check for valid Exile session
private _sessionID = _player getVariable ["ExileSessionID", -1];
if (_sessionID isEqualTo -1) exitWith {false};

// Check position (not in lobby/loading)
private _pos = getPosATL _player;
private _altitude = _pos select 2;
if (_altitude > 1000) exitWith {false};
if (_pos isEqualTo [0,0,0]) exitWith {false};

// Player is ready
true
};
ELITE_fnc_SetupPlayer = {
params ["_player"];
private _uid = getPlayerUID _player;
if (_uid == "") exitWith {};
// Initialize player variables
_player setVariable ["AssignedAI", [], true];
_player setVariable ["ELITE_AI_Spawning", false, true];

// Death handler
_player addEventHandler ["Killed", {
    params ["_unit", "_killer"];
    private _uid = getPlayerUID _unit;
    
    diag_log "═══════════════════════════════════════════════════════════════════════";
    diag_log format ["[ELITE AI] *** PLAYER DIED: %1 (UID: %2) ***", name _unit, _uid];
    diag_log "═══════════════════════════════════════════════════════════════════════";
    
    [_uid, name _unit] call ELITE_fnc_CleanupAI;
}];

// Respawn handler
_player addEventHandler ["Respawn", {
    params ["_unit", "_corpse"];
    private _uid = getPlayerUID _unit;
    
    diag_log "═══════════════════════════════════════════════════════════════════════";
    diag_log format ["[ELITE AI] *** PLAYER RESPAWNED: %1 (UID: %2) ***", name _unit, _uid];
    diag_log "═══════════════════════════════════════════════════════════════════════";
    
    // Check for orphaned AI
    private _existingAI = ELITE_PlayerAI getOrDefault [_uid, []];
    if (count _existingAI > 0) then {
        diag_log format ["[ELITE AI] WARNING: Found %1 orphaned AI - cleaning", count _existingAI];
        [_uid, name _unit] call ELITE_fnc_CleanupAI;
    };
    
    // Reset player variables
    _unit setVariable ["AssignedAI", [], true];
    _unit setVariable ["ELITE_AI_Spawning", false, true];
    _unit setVariable ["ELITE_AI_SpawnLockTime", 0, true];
    _unit setVariable ["ELITE_LastCheck", 0, true];
    
    // Spawn new team
    [_unit, _uid] spawn {
        params ["_player", "_uid"];
        
        // Wait for player to be fully in-game
        waitUntil {
            sleep 1;
            [_player] call ELITE_fnc_IsPlayerReady
        };
        
        diag_log format ["[ELITE AI] OK: Player %1 in-game after respawn - waiting for server to settle...", name _player];
        
        // Extra delay - let Exile fully settle before spawning AI
        sleep 5;
        
        diag_log format ["[ELITE AI] OK: Spawning AI for %1 now", name _player];
        
        private _cooldown = ELITE_Cooldowns getOrDefault [_uid, 0];
        if (time > _cooldown) then {
            ELITE_Cooldowns set [_uid, time + ELITE_SPAWN_COOLDOWN];
            [_player] call ELITE_fnc_EnsureTeam;
        };
    };
}];

diag_log format ["[ELITE AI] OK: Death/Respawn handlers ready for %1", name _player];
};
addMissionEventHandler ["PlayerDisconnected", {
params ["_id", "_uid", "_name", "_jip"];
diag_log "═══════════════════════════════════════════════════════════════════════";
diag_log format ["[ELITE AI] DISCONNECT: Player disconnected: %1 (UID: %2)", _name, _uid];
diag_log "═══════════════════════════════════════════════════════════════════════";

[_uid, _name] call ELITE_fnc_CleanupAI;
}];
addMissionEventHandler ["PlayerConnected", {
params ["_id", "_uid", "_name", "_jip", "_owner"];
diag_log format ["[ELITE AI] Player connecting: %1 (UID: %2)", _name, _uid];

[_uid, _name] spawn {
    params ["_uid", "_name"];
    
    private _player = objNull;
    private _timeout = time + 30;
    
    while {isNull _player && time < _timeout} do {
        sleep 1;
        _player = [_uid] call BIS_fnc_getUnitByUID;
    };
    
    if (isNull _player) exitWith {
        diag_log format ["[ELITE AI] ERROR: Could not find player object for %1 after 30s", _name];
    };
    
    diag_log format ["[ELITE AI] Player object found for %1, waiting for in-game spawn...", _name];
    
    // Wait for player to be fully in-game
    waitUntil {
        sleep 1;
        [_player] call ELITE_fnc_IsPlayerReady
    };
    
    diag_log format ["[ELITE AI] OK: Player %1 is in-game - waiting for server to settle...", _name];
    
    // Setup handlers first
    [_player] call ELITE_fnc_SetupPlayer;
    
    // Extra delay - let Exile fully settle before spawning AI
    sleep 5;
    
    diag_log format ["[ELITE AI] OK: Spawning AI for %1 now", _name];
    
    private _cooldown = ELITE_Cooldowns getOrDefault [_uid, 0];
    if (time > _cooldown) then {
        ELITE_Cooldowns set [_uid, time + ELITE_SPAWN_COOLDOWN];
        [_player] call ELITE_fnc_EnsureTeam;
    };
};
}];
[] spawn {
diag_log "[ELITE AI] Waiting for mission start...";
waitUntil {time > 0};
sleep 5;
diag_log "[ELITE AI] Checking for existing players...";

{
    private _player = _x;
    private _uid = getPlayerUID _player;
    
    if (_uid != "") then {
        diag_log format ["[ELITE AI] Found existing player: %1", name _player];
        
        [_player, _uid] spawn {
            params ["_player", "_uid"];
            
            // Wait for player to be fully in-game
            waitUntil {sleep 1; [_player] call ELITE_fnc_IsPlayerReady};
            
            diag_log format ["[ELITE AI] OK: Existing player %1 is in-game - waiting for server to settle...", name _player];
            
            [_player] call ELITE_fnc_SetupPlayer;
            
            // Extra delay - let Exile fully settle before spawning AI
            sleep 5;
            
            diag_log format ["[ELITE AI] OK: Spawning AI for %1 now", name _player];
            
            private _cooldown = ELITE_Cooldowns getOrDefault [_uid, 0];
            if (time > _cooldown) then {
                ELITE_Cooldowns set [_uid, time + ELITE_SPAWN_COOLDOWN];
                [_player] call ELITE_fnc_EnsureTeam;
            };
        };
    };
} forEach allPlayers;

diag_log "[ELITE AI] OK: System initialized";

private _playerAliveStates = createHashMap;

// Maintenance loop
while {true} do {
    {
        private _player = _x;
        private _uid = getPlayerUID _player;
        
        if (_uid != "" && isPlayer _player) then {
            private _isAlive = alive _player;
            private _wasAlive = _playerAliveStates getOrDefault [_uid, true];
            
            // Backup death detection
            if (_wasAlive && !_isAlive) then {
                diag_log format ["[ELITE AI] !!!!! DEATH DETECTED (BACKUP): %1 !!!!!", name _player];
                [_uid, name _player] call ELITE_fnc_CleanupAI;
                _playerAliveStates set [_uid, false];
            };
            
            if (_isAlive && !_wasAlive) then {
                diag_log format ["[ELITE AI] Player %1 alive again (respawned)", name _player];
                _playerAliveStates set [_uid, true];
            };
            
            if (_isAlive && [_player] call ELITE_fnc_IsPlayerReady) then {
                private _lastCheck = _player getVariable ["ELITE_LastCheck", 0];
                
                if (time - _lastCheck > 30) then {
                    _player setVariable ["ELITE_LastCheck", time];
                    
                    private _cooldown = ELITE_Cooldowns getOrDefault [_uid, 0];
                    if (time > _cooldown) then {
                        ELITE_Cooldowns set [_uid, time + ELITE_SPAWN_COOLDOWN];
                        [_player] call ELITE_fnc_EnsureTeam;
                    };
                };
            };
        };
    } forEach allPlayers;
    
    sleep 5;
};
};
diag_log "═══════════════════════════════════════════════════════════════════════";
diag_log "[ELITE AI] v8.3 CUSTOM LOADOUTS EDITION - READY";
diag_log "";
diag_log "  UNITS: UNIT ROSTER (LDF - Contact DLC):";
diag_log "    1. ENGINEER - ToolKit + Titan AT + SPAR-17 DMR";
diag_log "    2. MEDIC    - Medikit + Titan AA + SPMG .338 LMG";
diag_log "    3. SOLDIER  - SPAR-16 GL + 20 HE grenades";
diag_log "";
diag_log "  STATS: ELITE STATS:";
diag_log "    - 1.5x Movement Speed";
diag_log "    - ZERO Recoil";
diag_log "    - 20% Faster Projectiles";
diag_log "    - Perfect Skills (1.0)";
diag_log "    - Infinite Stamina";
diag_log "    - Auto-Healing";
diag_log "    - NEVER PRONE (forced standing)";
diag_log "";
diag_log "  LOADOUT: LOADOUT FEATURES:";
diag_log "    - All weapons PRE-LOADED";
diag_log "    - All weapons suppressed";
diag_log "    - Best optics (DMS/ARCO)";
diag_log "    - ENVG-II night vision";
diag_log "    - GPS + Rangefinders";
diag_log "    - 20 mags primary + 6 rockets";
diag_log "";
diag_log "  OK: FIXES:";
diag_log "    - 3-Source Cleanup";
diag_log "    - Safe Group Deletion";
diag_log "    - Spawn Locking";
diag_log "    - Staggered Positions";
diag_log "    - Smart Auto-Reload";
diag_log "    - FORCED STANDING";
diag_log "    - Auto-Repair (Engineers)";
diag_log "    - Native Vehicle Handling";
diag_log "";
diag_log "═══════════════════════════════════════════════════════════════════════";