/*
    ELITE AI RECRUIT SYSTEM v2.0
    
    Features:
    - AI are RESISTANCE side (same as player in Exile)
    - AI join player's group with full command control
    - TIGHT formation - AI stay close and RUN with player
    - Properly hostile to EAST (A3XAI/mission AI)
    - Clean up on player death
    - Respawn with player after death
    - Godlike combat abilities
    - 3 AI per player: AT, AA, Sniper
*/

if (!isServer) exitWith {};

diag_log "[RECRUIT AI] v2.0 - Starting Elite AI System...";

// ============================================
// GLOBAL TRACKING
// ============================================
RECRUIT_AI_MAP = createHashMap;
RECRUIT_PLAYER_MONITORS = createHashMap;

RECRUIT_AI_TYPES = [
    ["I_Soldier_AT_F", "AT Specialist"],      // Anti-Tank
    ["I_Soldier_AA_F", "AA Specialist"],      // Anti-Air  
    ["I_Sniper_F", "Sniper"]                  // Sniper
];

// ============================================
// FACTION RELATIONS - RESISTANCE hostile to EAST
// ============================================
[] spawn {
    sleep 2;
    
    // Ensure RESISTANCE (player + recruits) is hostile to EAST (mission AI)
    RESISTANCE setFriend [EAST, 0];
    EAST setFriend [RESISTANCE, 0];
    
    // RESISTANCE friendly to itself
    RESISTANCE setFriend [RESISTANCE, 1];
    
    // Keep RESISTANCE friendly to INDEPENDENT and WEST (other friendly AI)
    RESISTANCE setFriend [INDEPENDENT, 1];
    INDEPENDENT setFriend [RESISTANCE, 1];
    RESISTANCE setFriend [WEST, 1];
    WEST setFriend [RESISTANCE, 1];
    
    diag_log "[RECRUIT AI] Factions configured: RESISTANCE hostile to EAST";
};

// ============================================
// CUSTOM LOADOUTS
// ============================================
RECRUIT_fnc_applyLoadout = {
    params ["_unit", "_type"];
    
    // Strip all gear
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeAllMagazines _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    
    // Base items for all
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
    _unit linkItem "ItemWatch";
    _unit linkItem "ItemRadio";
    _unit linkItem "ItemGPS";
    _unit addWeapon "Laserdesignator";  // Rangefinder with laser
    
    switch (_type) do {
        case "I_Soldier_AT_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_Medic_F";
            
            for "_i" from 1 to 8 do { _unit addMagazine "20Rnd_762x51_Mag" };
            for "_i" from 1 to 3 do { _unit addMagazine "Titan_AT" };
            for "_i" from 1 to 5 do { _unit addItem "FirstAidKit" };
            for "_i" from 1 to 2 do { _unit addMagazine "HandGrenade" };
            
            _unit addWeapon "srifle_DMR_03_DMS_snds_F";
            _unit addPrimaryWeaponItem "optic_DMS";
            _unit addPrimaryWeaponItem "muzzle_snds_B";
            _unit addWeapon "launch_I_Titan_short_F";
        };
        
        case "I_Soldier_AA_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_hex_F";
            _unit addHeadgear "H_HelmetO_ViperSP_hex_F";
            _unit addVest "V_PlateCarrierSpec_blk";
            _unit addBackpack "B_ViperHarness_blk_F";
            
            for "_i" from 1 to 10 do { _unit addMagazine "30Rnd_65x39_caseless_khaki_mag" };
            for "_i" from 1 to 3 do { _unit addMagazine "Titan_AA" };
            for "_i" from 1 to 5 do { _unit addItem "FirstAidKit" };
            for "_i" from 1 to 2 do { _unit addMagazine "HandGrenade" };
            
            _unit addWeapon "arifle_MXM_khk_F";
            _unit addPrimaryWeaponItem "optic_Hamr";
            _unit addPrimaryWeaponItem "muzzle_snds_H_khk_F";
            _unit addWeapon "launch_I_Titan_F";
        };
        
        case "I_Sniper_F": {
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_F";
            
            for "_i" from 1 to 10 do { _unit addMagazine "5Rnd_127x108_APDS_Mag" };
            for "_i" from 1 to 3 do { _unit addMagazine "11Rnd_45ACP_Mag" };
            for "_i" from 1 to 5 do { _unit addItem "FirstAidKit" };
            for "_i" from 1 to 2 do { _unit addMagazine "HandGrenade" };
            
            _unit addWeapon "srifle_GM6_camo_F";
            _unit addPrimaryWeaponItem "optic_LRPS";
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "optic_MRD";
        };
    };
};

// ============================================
// SPAWN ELITE AI
// ============================================
RECRUIT_fnc_spawnAI = {
    params ["_player", "_typeData"];
    
    _typeData params ["_classname", "_roleName"];
    
    private _uid = getPlayerUID _player;
    private _playerGroup = group _player;
    
    // Create group if needed
    if (isNull _playerGroup) then {
        _playerGroup = createGroup [RESISTANCE, true];
        [_player] joinSilent _playerGroup;
    };
    
    // Spawn position close to player
    private _pos = _player getPos [2 + random 2, random 360];
    
    // Create unit in player's group (RESISTANCE side)
    private _unit = _playerGroup createUnit [_classname, _pos, [], 0, "FORM"];
    
    if (isNull _unit) exitWith {
        diag_log format ["[RECRUIT AI] ERROR: Failed to spawn %1", _classname];
        objNull
    };
    
    // Store owner info
    _unit setVariable ["RECRUIT_ownerUID", _uid, true];
    _unit setVariable ["RECRUIT_classname", _classname, true];
    _unit setVariable ["RECRUIT_roleName", _roleName, true];
    
    // Apply loadout
    [_unit, _classname] call RECRUIT_fnc_applyLoadout;
    
    // ============================================
    // GODLIKE SKILLS
    // ============================================
    {
        _unit setSkill [_x, 1.0];
    } forEach [
        "aimingAccuracy", "aimingShake", "aimingSpeed",
        "spotDistance", "spotTime", "courage",
        "reloadSpeed", "commanding", "general"
    ];
    
    // ============================================
    // SUPERHUMAN TRAITS
    // ============================================
    _unit setAnimSpeedCoef 1.5;           // 50% faster animations
    _unit enableFatigue false;             // No fatigue
    _unit forceSpeed -1;                   // No speed limit
    _unit allowFleeing 0;                  // Never flee
    _unit setUnitTrait ["camouflageCoef", 0.1];  // Hard to spot
    _unit setUnitTrait ["audibleCoef", 0.1];     // Quiet
    _unit setUnitTrait ["loadCoef", 0.1];        // No load penalty
    
    // Aimbot mode
    _unit setCustomAimCoef 0;
    _unit setUnitRecoilCoefficient 0;
    
    // ============================================
    // AGGRESSIVE COMBAT SETTINGS
    // ============================================
    _unit setBehaviour "AWARE";
    _unit setCombatMode "RED";             // Fire at will
    _unit setSpeedMode "FULL";             // Run always
    _unit setUnitPos "AUTO";
    
    // Enable all AI features
    {
        _unit enableAI _x;
    } forEach [
        "TARGET", "AUTOTARGET", "MOVE", "ANIM", "FSM",
        "AUTOCOMBAT", "COVER", "SUPPRESSION", "TEAMSWITCH"
    ];
    
    // Protection variables
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["NoRessurect", true, true];
    _unit setVariable ["RVG_ZedIgnore", true, true];
    
    // ============================================
    // TIGHT FORMATION - Stay close to player
    // ============================================
    _unit doFollow _player;
    
    // Group settings for tight formation
    _playerGroup setFormation "DIAMOND";
    _playerGroup setFormDir (getDir _player);
    _playerGroup enableAttack true;
    
    // Keep formation tight
    _unit setVariable ["RECRUIT_followPlayer", _player, true];
    
    // Add to tracking
    private _aiList = RECRUIT_AI_MAP getOrDefault [_uid, []];
    _aiList pushBack _unit;
    RECRUIT_AI_MAP set [_uid, _aiList];
    
    diag_log format ["[RECRUIT AI] Spawned %1 for %2", _roleName, name _player];
    
    // ============================================
    // AI DEATH HANDLER - Respawn after 5 seconds
    // ============================================
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        
        private _ownerUID = _unit getVariable ["RECRUIT_ownerUID", ""];
        private _classname = _unit getVariable ["RECRUIT_classname", ""];
        private _roleName = _unit getVariable ["RECRUIT_roleName", ""];
        
        if (_ownerUID == "") exitWith {};
        
        // Remove from tracking
        private _list = RECRUIT_AI_MAP getOrDefault [_ownerUID, []];
        _list = _list - [_unit];
        RECRUIT_AI_MAP set [_ownerUID, _list];
        
        // Find owner
        private _owner = objNull;
        {
            if (getPlayerUID _x == _ownerUID) exitWith { _owner = _x };
        } forEach allPlayers;
        
        if (!isNull _owner && alive _owner) then {
            // Notify player
            [format ["Your %1 was killed. Respawning in 5 seconds...", _roleName]] remoteExec ["systemChat", _owner];
            
            // Respawn after 5 seconds
            [_owner, [_classname, _roleName]] spawn {
                params ["_player", "_typeData"];
                sleep 5;
                
                if (!isNull _player && alive _player) then {
                    private _newUnit = [_player, _typeData] call RECRUIT_fnc_spawnAI;
                    if (!isNull _newUnit) then {
                        [format ["%1 has rejoined your squad.", _typeData select 1]] remoteExec ["systemChat", _player];
                    };
                };
            };
        };
    }];
    
    _unit
};

// ============================================
// ENSURE PLAYER HAS FULL TEAM
// ============================================
RECRUIT_fnc_ensureTeam = {
    params ["_player"];
    
    if (!alive _player) exitWith {};
    
    private _uid = getPlayerUID _player;
    if (_uid == "") exitWith {};
    
    // Get current AI list
    private _aiList = RECRUIT_AI_MAP getOrDefault [_uid, []];
    
    // Remove dead/null AI
    _aiList = _aiList select { !isNull _x && alive _x };
    RECRUIT_AI_MAP set [_uid, _aiList];
    
    // Get existing types
    private _existingTypes = _aiList apply { _x getVariable ["RECRUIT_classname", ""] };
    
    // Spawn missing types
    {
        _x params ["_classname", "_roleName"];
        
        if !(_classname in _existingTypes) then {
            [_player, _x] call RECRUIT_fnc_spawnAI;
            sleep 0.3;
        };
    } forEach RECRUIT_AI_TYPES;
    
    // Update formation for existing AI
    {
        _x doFollow _player;
        _x setSpeedMode "FULL";
    } forEach _aiList;
    
    // Set tight formation
    private _grp = group _player;
    if (!isNull _grp) then {
        _grp setFormation "DIAMOND";
        _grp setSpeedMode "FULL";
        _grp setCombatMode "RED";
        _grp enableAttack true;
    };
};

// ============================================
// CLEANUP ALL AI FOR A PLAYER
// ============================================
RECRUIT_fnc_cleanupAI = {
    params ["_uid"];
    
    private _aiList = RECRUIT_AI_MAP getOrDefault [_uid, []];
    
    diag_log format ["[RECRUIT AI] Cleaning up %1 AI for UID %2", count _aiList, _uid];
    
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _aiList;
    
    RECRUIT_AI_MAP set [_uid, []];
};

// ============================================
// PLAYER MONITOR - Handles death/respawn/disconnect
// ============================================
RECRUIT_fnc_startMonitor = {
    params ["_uid", "_name"];
    
    // Don't start duplicate monitors
    if (RECRUIT_PLAYER_MONITORS getOrDefault [_uid, false]) exitWith {};
    RECRUIT_PLAYER_MONITORS set [_uid, true];
    
    [_uid, _name] spawn {
        params ["_uid", "_name"];
        
        private _lastPlayer = objNull;
        private _wasAlive = false;
        private _disconnectCounter = 0;
        
        // Wait for player object to exist (up to 60 seconds)
        diag_log format ["[RECRUIT AI] Waiting for player object: %1", _name];
        private _waitStart = time;
        waitUntil {
            sleep 1;
            private _found = false;
            {
                if (getPlayerUID _x == _uid) exitWith { _found = true };
            } forEach allPlayers;
            _found || (time - _waitStart > 60)
        };
        
        diag_log format ["[RECRUIT AI] Player object found for: %1", _name];
        
        while {true} do {
            sleep 1;
            
            // Find current player object
            private _currentPlayer = objNull;
            {
                if (getPlayerUID _x == _uid) exitWith { _currentPlayer = _x };
            } forEach allPlayers;
            
            // Player not found - might be disconnected or loading
            if (isNull _currentPlayer) then {
                _disconnectCounter = _disconnectCounter + 1;
                
                // Only consider disconnected after 10 consecutive checks (10 seconds)
                if (_disconnectCounter >= 10) exitWith {
                    diag_log format ["[RECRUIT AI] %1 confirmed disconnected - cleaning up", _name];
                    [_uid] call RECRUIT_fnc_cleanupAI;
                    RECRUIT_PLAYER_MONITORS set [_uid, false];
                };
            } else {
                // Player found, reset counter
                _disconnectCounter = 0;
                
                // Player died (was alive, now dead OR new player object)
                if (_wasAlive && (!alive _currentPlayer || _currentPlayer != _lastPlayer)) then {
                    diag_log format ["[RECRUIT AI] %1 died - cleaning up AI", _name];
                    [_uid] call RECRUIT_fnc_cleanupAI;
                    _wasAlive = false;
                };
                
                // Player alive (newly spawned or respawned)
                if (!_wasAlive && alive _currentPlayer) then {
                    // Wait for Exile session
                    private _ready = false;
                    for "_i" from 1 to 30 do {
                        if (_currentPlayer getVariable ["ExileSessionID", ""] != "" &&
                            getPosATL _currentPlayer distance2D [0,0,0] > 100) exitWith {
                            _ready = true;
                        };
                        sleep 1;
                    };
                    
                    if (_ready) then {
                        diag_log format ["[RECRUIT AI] %1 spawned/respawned - creating team", _name];
                        sleep 2;
                        [_currentPlayer] call RECRUIT_fnc_ensureTeam;
                        _wasAlive = true;
                        _lastPlayer = _currentPlayer;
                    };
                };
                
                // Update tracking
                if (alive _currentPlayer) then {
                    _lastPlayer = _currentPlayer;
                    _wasAlive = true;
                };
            };
        };
    };
};

// ============================================
// FORMATION KEEPER - Keeps AI close and running
// ============================================
[] spawn {
    sleep 15;
    
    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;
            
            if (_uid != "" && alive _player) then {
                private _aiList = RECRUIT_AI_MAP getOrDefault [_uid, []];
                
                {
                    if (!isNull _x && alive _x) then {
                        private _dist = _x distance _player;
                        
                        // If AI is too far, teleport them closer
                        if (_dist > 50) then {
                            private _newPos = _player getPos [5 + random 5, random 360];
                            _x setPos _newPos;
                            diag_log format ["[RECRUIT AI] Teleported AI to player (was %1m away)", round _dist];
                        };
                        
                        // Always follow player
                        _x doFollow _player;
                        _x setSpeedMode "FULL";
                        
                        // Keep combat mode aggressive
                        _x setCombatMode "RED";
                        _x setBehaviour "AWARE";
                    };
                } forEach _aiList;
            };
        } forEach allPlayers;
        
        sleep 5;
    };
};

// ============================================
// TARGET ENFORCER - Make sure AI engage EAST enemies
// ============================================
[] spawn {
    sleep 20;
    
    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;
            private _aiList = RECRUIT_AI_MAP getOrDefault [_uid, []];
            
            // Find nearby EAST enemies
            private _enemies = _player nearEntities ["Man", 500];
            _enemies = _enemies select { side group _x == EAST && alive _x };
            
            if (count _enemies > 0 && count _aiList > 0) then {
                private _target = _enemies select 0;
                
                {
                    if (!isNull _x && alive _x) then {
                        // Reveal enemy to AI
                        _x reveal [_target, 4];
                        
                        // Order to engage if not already
                        if (isNull (assignedTarget _x)) then {
                            _x doTarget _target;
                            _x doFire _target;
                        };
                    };
                } forEach _aiList;
            };
        } forEach allPlayers;
        
        sleep 3;
    };
};

// ============================================
// EVENT HANDLERS
// ============================================
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name"];
    
    if (_uid == "" || _uid == "0") exitWith {};  // Invalid UID
    
    diag_log format ["[RECRUIT AI] Player connected: %1 (UID: %2)", _name, _uid];
    [_uid, _name] call RECRUIT_fnc_startMonitor;
}];

addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name"];
    
    if (_uid == "" || _uid == "0") exitWith {};  // Invalid UID
    
    // Just log - the monitor will handle cleanup after confirming disconnect
    diag_log format ["[RECRUIT AI] PlayerDisconnected event for: %1", _name];
    // Don't cleanup here - monitor does it after 10s confirmation
}];

// ============================================
// INITIALIZE FOR EXISTING PLAYERS
// ============================================
[] spawn {
    sleep 10;
    
    diag_log "[RECRUIT AI] Initializing for existing players...";
    
    {
        private _uid = getPlayerUID _x;
        private _name = name _x;
        
        if (_uid != "" && alive _x) then {
            diag_log format ["[RECRUIT AI] Found existing player: %1", _name];
            [_uid, _name] call RECRUIT_fnc_startMonitor;
        };
    } forEach allPlayers;
    
    diag_log "[RECRUIT AI] v2.0 - System Ready";
};

// ============================================
// STARTUP LOG
// ============================================
diag_log "========================================";
diag_log "[RECRUIT AI] v2.0 - Elite AI System";
diag_log "  - RESISTANCE side (same as player)";
diag_log "  - Hostile to EAST (mission AI)";
diag_log "  - Tight DIAMOND formation";
diag_log "  - Auto-respawn on AI death";
diag_log "  - Cleanup on player death";
diag_log "  - Respawn with player";
diag_log "  - 50% faster movement";
diag_log "  - Godlike accuracy";
diag_log "========================================";
