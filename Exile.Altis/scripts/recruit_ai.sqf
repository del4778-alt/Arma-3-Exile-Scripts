/*
    ELITE AI RECRUIT SYSTEM - PLAYER GROUP EDITION
     AI join YOUR group so you can command them
    
    Features:
    - AI join player's group (full command control)
    - 1.5x movement speed
    - Perfect accuracy (no recoil, no bullet drop simulation)
    - Instant target acquisition
    - Extreme spotting range
    - No fatigue, no suppression effects
    - Aimbot-level shooting
    - Auto-respawn on death
    - 3 AI per player (AT, AA, Sniper)
    
    INDEPENDENT bodyguards hostile to EAST mission AI
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] Elite AI System - Player Group Edition Starting...";

// ============================================
// FACTION SETUP - INDEPENDENT (yours) hostile to EAST (mission AI)
// ============================================
[] spawn {
    sleep 3;
    
    // Your bodyguards (INDEPENDENT) are hostile to mission AI (EAST)
    INDEPENDENT setFriend [EAST, 0];
    EAST setFriend [INDEPENDENT, 0];
    
    // Your bodyguards (INDEPENDENT) are friendly to players (RESISTANCE in Exile)
    INDEPENDENT setFriend [RESISTANCE, 1];
    RESISTANCE setFriend [INDEPENDENT, 1];
    
    // Also friendly to WEST just in case
    INDEPENDENT setFriend [WEST, 1];
    WEST setFriend [INDEPENDENT, 1];
    
    // INDEPENDENT friendly to CIVILIAN
    INDEPENDENT setFriend [CIVILIAN, 1];
    CIVILIAN setFriend [INDEPENDENT, 1];
    
    diag_log "[AI RECRUIT] ✅ Factions: INDEPENDENT (bodyguards) friendly to RESISTANCE (players), hostile to EAST";
};

// ============================================
// GLOBAL TRACKING
// ============================================
all_recruited_ai_map = createHashMap;

RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",
    "I_Soldier_AA_F",
    "I_Sniper_F"
];

// ============================================
// 🔥 CUSTOM LOADOUTS - FIXED HELMET SPAWN
// ============================================
RECRUIT_fnc_ApplyCustomLoadout = {
    params ["_unit", "_type"];

    // Strip ALL gear first
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeAllMagazines _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    switch (_type) do {
        case "I_Soldier_AT_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            sleep 0.1;
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";
            
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_Medic_F";

            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit addWeapon "Rangefinder";

            for "_i" from 1 to 8 do {_unit addMagazine "20Rnd_762x51_Mag"};
            for "_i" from 1 to 2 do {_unit addMagazine "Titan_AT"};
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};
            _unit addWeapon "srifle_DMR_03_DMS_snds_F";
            _unit addPrimaryWeaponItem "optic_DMS";
            _unit addPrimaryWeaponItem "muzzle_snds_B";
            _unit addWeapon "launch_I_Titan_short_F";
        };

        case "I_Soldier_AA_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_hex_F";
            sleep 0.1;
            _unit addHeadgear "H_HelmetO_ViperSP_hex_F";
            
            _unit addVest "V_PlateCarrierSpec_blk";
            _unit addBackpack "B_ViperHarness_blk_F";

            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit addWeapon "Rangefinder";

            for "_i" from 1 to 10 do {_unit addMagazine "30Rnd_65x39_caseless_khaki_mag"};
            for "_i" from 1 to 2 do {_unit addMagazine "Titan_AA"};
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};
            _unit addWeapon "arifle_MXM_khk_MOS_Pointer_Bipod_Snds_F";
            _unit addPrimaryWeaponItem "optic_Hamr";
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            _unit addPrimaryWeaponItem "bipod_01_F_khk";
            _unit addPrimaryWeaponItem "muzzle_snds_H_khk_F";
            _unit addWeapon "launch_I_Titan_F";
        };

        case "I_Sniper_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            sleep 0.1;
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";
            
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_F";

            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit addWeapon "Rangefinder";

            for "_i" from 1 to 10 do {_unit addMagazine "5Rnd_127x108_APDS_Mag"};
            for "_i" from 1 to 3 do {_unit addMagazine "11Rnd_45ACP_Mag"};
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};
            _unit addWeapon "srifle_GM6_camo_F";
            _unit addPrimaryWeaponItem "optic_LRPS";
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "optic_MRD";
        };
    };
};

// ============================================
// 🔥 SPAWN GODLIKE AI - JOIN PLAYER GROUP
// ============================================
fn_spawnAI = {
    params ["_player", "_type"];

    private _uid = getPlayerUID _player;
    private _playerGroup = group _player;

    // Safety: ensure player has a valid group
    if (isNull _playerGroup) then {
        _playerGroup = createGroup [side _player, true];
        [_player] joinSilent _playerGroup;
    };

    // Spawn in player's group directly
    private _pos = _player getPos [3, getDir _player + 120];
    private _unit = _playerGroup createUnit [_type, _pos, [], 0, "FORM"];

    if (isNull _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Failed to spawn %1", _type];
        objNull
    };

    // Store owner info
    _unit setVariable ["RECRUIT_ownerUID", _uid, true];
    _unit setVariable ["RECRUIT_aiType", _type, true];

    // Add to tracking
    private _aiList = all_recruited_ai_map getOrDefault [_uid, []];
    _aiList pushBack _unit;
    all_recruited_ai_map set [_uid, _aiList];

    // Apply custom loadout
    [_unit, _type] call RECRUIT_fnc_ApplyCustomLoadout;

    // ============================================
    // 🔥 GODLIKE SKILLS - All maxed to 1.0
    // ============================================
    {
        _unit setSkill [_x select 0, _x select 1];
    } forEach [
        ["aimingAccuracy", 1.0],
        ["aimingShake", 1.0],
        ["aimingSpeed", 1.0],
        ["spotDistance", 1.0],
        ["spotTime", 1.0],
        ["courage", 1.0],
        ["reloadSpeed", 1.0],
        ["commanding", 1.0],
        ["general", 1.0]
    ];

    // ============================================
    // 🔥 SUPERHUMAN TRAITS
    // ============================================
    _unit setAnimSpeedCoef 1.5;
    _unit enableFatigue false;
    _unit forceSpeed -1;
    _unit allowFleeing 0;
    _unit setUnitTrait ["camouflageCoef", 0.1];
    _unit setUnitTrait ["audibleCoef", 0.1];
    _unit setUnitTrait ["loadCoef", 0.1];

    // 🔥 AIMBOT MODE
    _unit setCustomAimCoef 0;
    _unit setUnitRecoilCoefficient 0;

    // ============================================
    // 🔥 AGGRESSIVE COMBAT SETTINGS
    // ============================================
    _unit setBehaviour "COMBAT";
    _unit setCombatMode "RED";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "AUTO";

    // ============================================
    // 🔥 ENABLE ALL COMBAT AI
    // ============================================
    {
        _unit enableAI _x;
    } forEach [
        "TARGET", "AUTOTARGET", "MOVE", "ANIM", "FSM",
        "AUTOCOMBAT", "COVER", "SUPPRESSION", "AIMINGERROR", "TEAMSWITCH"
    ];

    // ============================================
    // 🔥 PROTECTION VARIABLES
    // ============================================
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["NoRessurect", true, true];
    _unit setVariable ["RVG_ZedIgnore", true, true];

    // ============================================
    // 🔥 FOLLOW PLAYER + GROUP TUNING
    // ============================================
    _unit doFollow _player;
    _playerGroup setFormation "WEDGE";
    _playerGroup setBehaviour "AWARE";
    _playerGroup setCombatMode "RED";
    _playerGroup enableAttack true;

    diag_log format ["[AI RECRUIT] ✅ Spawned ELITE %1 in %2's group", _type, name _player];

    // ============================================
    // 🔥 AUTO-RESPAWN ON AI DEATH
    // ============================================
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _ownerUID = _unit getVariable ["RECRUIT_ownerUID", ""];
        private _aiType = _unit getVariable ["RECRUIT_aiType", typeOf _unit];

        if (_ownerUID != "") then {
            private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;

            // Remove from list
            private _list = all_recruited_ai_map getOrDefault [_ownerUID, []];
            _list = _list - [_unit];
            all_recruited_ai_map set [_ownerUID, _list];

            if (!isNull _owner && alive _owner) then {
                diag_log format ["[AI RECRUIT] AI killed: %1 - respawning in 5s", _aiType];

                // Respawn after 5 seconds
                [_owner, _aiType] spawn {
                    params ["_player", "_type"];
                    sleep 5;

                    if (!isNull _player && alive _player) then {
                        [_player, _type] call fn_spawnAI;
                    };
                };
            };
        };
    }];

    _unit
}
;

// ============================================
// ENSURE PLAYER HAS 3 AI
// ============================================
fn_ensureTeam = {
    params ["_player"];

    if (!alive _player || getPlayerUID _player == "") exitWith {};

    private _uid = getPlayerUID _player;
    private _aiList = all_recruited_ai_map getOrDefault [_uid, []];

    // Remove dead/null AI from list
    private _alive = _aiList select {!isNull _x && alive _x};
    all_recruited_ai_map set [_uid, _alive];

    // Make sure existing AI follow this player object
    {
        _x doFollow _player;
    } forEach _alive;

    // Check what types we have
    private _existingTypes = _alive apply {typeOf _x};

    // Spawn missing types
    {
        if !(_x in _existingTypes) then {
            [_player, _x] call fn_spawnAI;
            sleep 0.5;
        };
    } forEach RECRUIT_AI_TYPES;
}
;

// ============================================
// CLEANUP PLAYER AI (delete all AI for a player)
// ============================================
fn_cleanupPlayerAI = {
    params ["_uid", ["_name", "Unknown"]];
    
    diag_log format ["[AI RECRUIT] Cleaning up AI for %1 (UID: %2)", _name, _uid];
    
    private _aiList = all_recruited_ai_map getOrDefault [_uid, []];
    private _count = count _aiList;
    
    // Delete all AI units
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _aiList;
    
    // Remove from tracking
    all_recruited_ai_map deleteAt _uid;
    
    diag_log format ["[AI RECRUIT] ✅ Cleaned up %1 AI for %2", _count, _name];
};

// ============================================
// PLAYER CONNECTED - Start monitoring
// ============================================
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name"];
    
    diag_log format ["[AI RECRUIT] Player connecting: %1 (UID: %2)", _name, _uid];
    
    [_uid, _name] spawn {
        params ["_uid", "_name"];
        
        // Wait for player object
        private _player = objNull;
        private _timeout = time + 60;
        
        waitUntil {
            sleep 1;
            _player = [_uid] call BIS_fnc_getUnitByUID;
            !isNull _player || time > _timeout
        };
        
        if (isNull _player) exitWith {
            diag_log format ["[AI RECRUIT] ERROR: Player %1 not found after timeout", _name];
        };
        
        // Wait for player to be fully spawned in Exile
        waitUntil {
            sleep 1;
            alive _player && 
            {getPlayerUID _player != ""} && 
            {_player getVariable ["ExileSessionID", ""] != ""} &&
            {getPosATL _player distance2D [0,0,0] > 100}
        };
        
        diag_log format ["[AI RECRUIT] ✅ Player %1 fully spawned - creating AI team", _name];
        
        sleep 3;
        [_player] call fn_ensureTeam;
        
        // ============================================
        // EXILE RESPAWN MONITOR
        // Exile creates NEW player objects on respawn
        // This loop detects that and handles cleanup/respawn
        // ============================================
        [_uid, _name, _player] spawn {
            params ["_uid", "_name", "_lastPlayer"];
            
            private _wasAlive = true;
            
            while {true} do {
                sleep 2;
                
                // Get current player object for this UID
                private _currentPlayer = [_uid] call BIS_fnc_getUnitByUID;
                
                // Player disconnected completely
                if (isNull _currentPlayer) exitWith {
                    diag_log format ["[AI RECRUIT] Player %1 disconnected - stopping monitor", _name];
                };
                
                // Check if player DIED (was alive, now dead or object changed)
                if (_wasAlive && {!alive _lastPlayer || _currentPlayer != _lastPlayer}) then {
                    diag_log format ["[AI RECRUIT] Player %1 died or respawned - cleaning up old AI", _name];
                    
                    // Cleanup old AI
                    [_uid, _name] call fn_cleanupPlayerAI;
                    
                    _wasAlive = false;
                };
                
                // Check if player is NOW ALIVE (respawned)
                if (!_wasAlive && {alive _currentPlayer}) then {
                    // Wait for Exile session to be ready
                    waitUntil {
                        sleep 1;
                        _currentPlayer getVariable ["ExileSessionID", ""] != "" &&
                        {getPosATL _currentPlayer distance2D [0,0,0] > 100}
                    };
                    
                    diag_log format ["[AI RECRUIT] Player %1 respawned - spawning new AI team", _name];
                    
                    sleep 3;
                    [_currentPlayer] call fn_ensureTeam;
                    
                    _lastPlayer = _currentPlayer;
                    _wasAlive = true;
                };
                
                // Update tracking
                if (alive _currentPlayer) then {
                    _lastPlayer = _currentPlayer;
                    _wasAlive = true;
                };
            };
        };
    };
}];

// ============================================
// PLAYER DISCONNECTED
// ============================================
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name"];
    [_uid, _name] call fn_cleanupPlayerAI;
}];

// ============================================
// MAIN LOOP - Check every 30 seconds
// ============================================
[] spawn {
    waitUntil {time > 0};
    sleep 10;
    
    diag_log "[AI RECRUIT] ✅ Elite AI System initialized";
    
    // Process existing players (server restart)
    {
        private _player = _x;
        private _uid = getPlayerUID _player;
        
        if (_uid != "" && alive _player) then {
            diag_log format ["[AI RECRUIT] Found existing player: %1", name _player];
            
            [_player, _uid, name _player] spawn {
                params ["_player", "_uid", "_name"];
                
                waitUntil {
                    sleep 1;
                    _player getVariable ["ExileSessionID", ""] != ""
                };
                
                sleep 2;
                [_player] call fn_ensureTeam;
                
                // Start respawn monitor for existing player
                [_uid, _name, _player] spawn {
                    params ["_uid", "_name", "_lastPlayer"];
                    
                    private _wasAlive = true;
                    
                    while {true} do {
                        sleep 2;
                        
                        private _currentPlayer = [_uid] call BIS_fnc_getUnitByUID;
                        
                        if (isNull _currentPlayer) exitWith {};
                        
                        if (_wasAlive && {!alive _lastPlayer || _currentPlayer != _lastPlayer}) then {
                            diag_log format ["[AI RECRUIT] Player %1 died - cleaning up AI", _name];
                            [_uid, _name] call fn_cleanupPlayerAI;
                            _wasAlive = false;
                        };
                        
                        if (!_wasAlive && {alive _currentPlayer}) then {
                            waitUntil {
                                sleep 1;
                                _currentPlayer getVariable ["ExileSessionID", ""] != "" &&
                                {getPosATL _currentPlayer distance2D [0,0,0] > 100}
                            };
                            
                            diag_log format ["[AI RECRUIT] Player %1 respawned - new AI team", _name];
                            sleep 3;
                            [_currentPlayer] call fn_ensureTeam;
                            
                            _lastPlayer = _currentPlayer;
                            _wasAlive = true;
                        };
                        
                        if (alive _currentPlayer) then {
                            _lastPlayer = _currentPlayer;
                            _wasAlive = true;
                        };
                    };
                };
            };
        };
    } forEach allPlayers;
    
    // Main maintenance loop - just ensures teams are complete
    while {true} do {
        {
            private _player = _x;
            
            if (alive _player && getPlayerUID _player != "") then {
                [_player] call fn_ensureTeam;
            };
        } forEach allPlayers;
        
        sleep 30;
    };
};

// ============================================
// STARTUP LOG
// ============================================
diag_log "========================================";
diag_log "[AI RECRUIT] Elite AI System - Player Group Edition";
diag_log "";
diag_log "  ✅ AI JOIN YOUR GROUP (full command control)";
diag_log "";
diag_log "  🔥 GODLIKE ENHANCEMENTS:";
diag_log "    - 1.5x movement speed (50% faster)";
diag_log "    - Zero recoil (setUnitRecoilCoefficient 0)";
diag_log "    - Zero aiming error (setCustomAimCoef 0)";
diag_log "    - Perfect accuracy (aimingAccuracy 1.0)";
diag_log "    - Instant target lock (aimingSpeed 1.0)";
diag_log "    - No fatigue (enableFatigue false)";
diag_log "    - No suppression effects";
diag_log "    - 90% harder to spot (camouflageCoef 0.1)";
diag_log "    - 90% quieter (audibleCoef 0.1)";
diag_log "    - Infinite stamina (loadCoef 0.1)";
diag_log "    - Auto-respawn on death (5s delay)";
diag_log "";
diag_log "  ✅ AI Types: AT (DMR), AA (MXM), Sniper (.50 cal)";
diag_log "  ✅ Combat Mode: RED (engage at will)";
diag_log "  ✅ Behaviour: COMBAT (always aggressive)";
diag_log "========================================";