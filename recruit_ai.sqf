/*
    ELITE AI RECRUIT SYSTEM v7.6 - DEATH = DISCONNECT METHOD
    ✅ Death cleanup uses same code as disconnect (PROVEN TO WORK)
    ✅ Server-side death monitoring
    ✅ Strict 3 AI maximum
    ✅ Extensive logging
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] ========================================";
diag_log "[AI RECRUIT] Starting initialization v7.6...";
diag_log "[AI RECRUIT] ========================================";

// Make Independent hostile to West (zombies)
independent setFriend [west, 0];
west setFriend [independent, 0];

// ============================================
// VCOMAI COMPATIBILITY CHECK
// ============================================

RECRUIT_VCOMAI_Active = false;
if (!isNil "VCM_ACTIVATEAI") then {
    RECRUIT_VCOMAI_Active = true;
    diag_log "[AI RECRUIT] VCOMAI detected - Enhanced AI behavior enabled";
} else {
    diag_log "[AI RECRUIT] VCOMAI not detected - Using standard AI";
};

// Map to track all recruited AI per player's UID
all_recruited_ai_map = createHashMap;

// Track player last alive state
player_alive_state = createHashMap;

RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",
    "I_Soldier_AA_F",
    "I_Sniper_F"
];

// ====================================================================================
// Function: Check if player is fully initialized and ready
// ====================================================================================
fn_isPlayerReady = {
    params ["_player"];
    
    if (isNull _player) exitWith { false };
    if (!alive _player) exitWith { false };
    if (!isPlayer _player) exitWith { false };
    
    private _uid = getPlayerUID _player;
    if (_uid isEqualTo "") exitWith { false };
    if (isNull group _player) exitWith { false };
    if ((getPosATL _player) isEqualTo [0,0,0]) exitWith { false };
    
    true
};

// ====================================================================================
// Function: Spawn missing AI teammate
// ====================================================================================
fn_spawnAI = {
    params ["_player", "_type", "_spawnIndex"];
    
    private _playerGroup = group _player;
    if (isNull _playerGroup) exitWith {
        diag_log "[AI RECRUIT] ERROR: Player has null group";
        objNull
    };
    
    // Transfer group ownership to server BEFORE creating units
    if (groupOwner _playerGroup != 2) then {
        _playerGroup setGroupOwner 2;
        
        // Wait for ownership transfer to complete
        private _timeout = time + 2;
        waitUntil {sleep 0.1; groupOwner _playerGroup == 2 || time > _timeout};
        
        if (groupOwner _playerGroup != 2) then {
            diag_log format ["[AI RECRUIT] WARNING: Failed to transfer group ownership for %1", name _player];
        };
    };
    
    private _offset = 3 + (_spawnIndex * 0.5);
    private _angle = 120 * _spawnIndex;
    private _pos = [_player, _offset, _angle] call BIS_fnc_relPos;
    
    private _unit = _playerGroup createUnit [_type, _pos, [], 0, "FORM"];
    
    if (isNull _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Failed to create %1", _type];
        objNull
    };
    
    if (!alive _unit) exitWith {
        deleteVehicle _unit;
        objNull
    };
    
    _unit setDir ([_player, _pos] call BIS_fnc_dirTo);
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["OwnerUID", getPlayerUID _player, true];
    _unit setVariable ["OwnerName", name _player, true];
    _unit setVariable ["AIType", _type, true];
    
    // Add to global map IMMEDIATELY
    private _uid = getPlayerUID _player;
    private _globalList = all_recruited_ai_map getOrDefault [_uid, []];
    _globalList pushBack _unit;
    all_recruited_ai_map set [_uid, _globalList];
    
    diag_log format ["[AI RECRUIT] Spawned %1 for %2 - Global map now has %3 AI", typeOf _unit, name _player, count _globalList];
    
    // Blacklist from A3XAI
    if (!isNil "A3XAI_NOAI") then {
        A3XAI_NOAI pushBackUnique _unit;
        publicVariable "A3XAI_NOAI";
    };
    _unit setVariable ["A3XAI_Ignore", true, true];
    _playerGroup setVariable ["A3XAI_Ignore", true, true];
    
    // VCOMAI or standard skills
    if (RECRUIT_VCOMAI_Active) then {
        _unit setUnitPos "AUTO";
        _unit forceSpeed 1.4;
        _unit setAnimSpeedCoef 1.4;
        _unit setBehaviour "COMBAT";
        _unit setCombatMode "RED";
        _unit allowFleeing 0;
        
        if (!isNil "VCM_NOAI") then {
            VCM_NOAI pushBackUnique _unit;
            publicVariable "VCM_NOAI";
        };
        
        _unit setVariable ["VCM_CUSTOMAI", true, true];
        _unit setVariable ["VCM_RECRUIT", true, true];
        
        if (!isNil "VCM_fnc_INITAI") then {
            [_unit] call VCM_fnc_INITAI;
        };
    } else {
        {
            _unit setSkill [_x, 1.0];
        } forEach [
            "aimingAccuracy", "aimingShake", "aimingSpeed", 
            "spotDistance", "spotTime", "courage", 
            "reloadSpeed", "commanding", "general"
        ];
        
        _unit forceSpeed 1.4;
        _unit setUnitPos "AUTO";
        _unit setAnimSpeedCoef 1.4;
        _unit setBehaviour "COMBAT";
        _unit setCombatMode "RED";
        _unit allowFleeing 0;
        _unit disableAI "SUPPRESSION";
        
        {
            _unit enableAI _x;
        } forEach [
            "TARGET", "AUTOTARGET", "MOVE", "ANIM", 
            "FSM", "AIMINGERROR", "COVER", "AUTOCOMBAT"
        ];
    };
    
    _playerGroup setCombatMode "RED";
    _playerGroup setBehaviour "COMBAT";
    _playerGroup enableAttack true;
    
    if (RECRUIT_VCOMAI_Active && !isNil "VCM_SERVERAI") then {
        VCM_SERVERAI pushBackUnique _playerGroup;
        publicVariable "VCM_SERVERAI";
        _playerGroup setVariable ["VCM_RECRUITGROUP", true, true];
    };
    
    // AI death handler - triggers respawn check
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _ownerUID = _unit getVariable ["OwnerUID", ""];
        
        if (_ownerUID isEqualTo "") exitWith {};
        
        private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;
        
        if (!isNull _owner && alive _owner) then {
            private _assigned = _owner getVariable ["AssignedAI", []];
            _assigned = _assigned - [_unit];
            _owner setVariable ["AssignedAI", _assigned, true];
            
            // Remove from global tracking
            private _globalList = all_recruited_ai_map getOrDefault [_ownerUID, []];
            _globalList = _globalList - [_unit];
            all_recruited_ai_map set [_ownerUID, _globalList];
            
            // Trigger respawn check after delay
            [_owner] spawn {
                params ["_owner"];
                sleep 3;
                if (!isNull _owner && alive _owner) then {
                    [_owner] call fn_ensureTeam;
                };
            };
        };
    }];
    
    _unit
};

// ====================================================================================
// Function: Ensure player has correct AI teammates (MAX 3)
// ====================================================================================
fn_ensureTeam = {
    params ["_player"];
    
    if (!([_player] call fn_isPlayerReady)) exitWith {};
    
    private _uid = getPlayerUID _player;
    if (_uid isEqualTo "") exitWith {};
    
    private _isSpawning = _player getVariable ["_aiSpawning", false];
    if (_isSpawning) exitWith {};
    
    _player setVariable ["_aiSpawning", true];
    
    // Get AI from global map
    private _globalAI = all_recruited_ai_map getOrDefault [_uid, []];
    private _globalValid = _globalAI select { !isNull _x && alive _x };
    
    // Get AI from player variable
    private _assigned = _player getVariable ["AssignedAI", []];
    private _assignedValid = _assigned select { !isNull _x && alive _x };
    
    // Combine both sources (remove duplicates)
    private _validAI = (_globalValid + _assignedValid) arrayIntersect (_globalValid + _assignedValid);
    
    // STRICT LIMIT: If we somehow have more than 3, delete the extras
    if (count _validAI > 3) then {
        diag_log format ["[AI RECRUIT] WARNING: Player %1 has %2 AI! Removing extras...", name _player, count _validAI];
        
        private _toKeep = _validAI select [0, 3];
        private _toDelete = _validAI - _toKeep;
        
        {
            if (!isNull _x) then {
                _x setDamage 1;
                deleteVehicle _x;
            };
        } forEach _toDelete;
        
        _validAI = _toKeep;
    };
    
    private _currentCount = count _validAI;
    
    if (_currentCount >= 3) exitWith {
        _player setVariable ["AssignedAI", _validAI, true];
        all_recruited_ai_map set [_uid, _validAI];
        _player setVariable ["_aiSpawning", false];
    };
    
    private _existingTypes = _validAI apply { typeOf _x };
    private _missing = RECRUIT_AI_TYPES select { !(_x in _existingTypes) };
    
    if (_missing isEqualTo []) exitWith {
        _player setVariable ["AssignedAI", _validAI, true];
        all_recruited_ai_map set [_uid, _validAI];
        _player setVariable ["_aiSpawning", false];
    };
    
    diag_log format ["[AI RECRUIT] Player %1 needs %2 AI", name _player, count _missing];
    
    // Spawn missing AI (up to 3 total)
    private _spawnIndex = count _validAI;
    {
        if (count _validAI < 3) then {
            private _ai = [_player, _x, _spawnIndex] call fn_spawnAI;
            if (!isNull _ai) then {
                _validAI pushBack _ai;
                _spawnIndex = _spawnIndex + 1;
            };
            sleep 0.5;
        };
    } forEach _missing;
    
    _player setVariable ["AssignedAI", _validAI, true];
    all_recruited_ai_map set [_uid, _validAI];
    _player setVariable ["_aiSpawning", false];
};

// ====================================================================================
// Function: CLEANUP (Same as disconnect - PROVEN TO WORK)
// ====================================================================================
fn_cleanupPlayerAI = {
    params ["_uid", "_name"];
    
    diag_log format ["[AI RECRUIT] CLEANUP START: %1 (UID: %2)", _name, _uid];
    
    if (_uid isEqualTo "") exitWith {
        diag_log "[AI RECRUIT] ERROR: Empty UID";
    };
    
    // Get player object if available
    private _player = [_uid] call BIS_fnc_getUnitByUID;
    
    // SOURCE 1: Global map
    private _ai_from_map = all_recruited_ai_map getOrDefault [_uid, []];
    
    // SOURCE 2: Player variable (if player object exists)
    private _ai_from_var = [];
    if (!isNull _player) then {
        _ai_from_var = _player getVariable ["AssignedAI", []];
    };
    
    // SOURCE 3: Player's group (if player object exists and has group)
    private _ai_from_group = [];
    if (!isNull _player && !isNull group _player) then {
        _ai_from_group = (units group _player) select {
            !isPlayer _x && 
            {_x getVariable ["ExileRecruited", false]}
        };
    };
    
    // Combine ALL sources
    private _ai_to_delete = _ai_from_map + _ai_from_var + _ai_from_group;
    _ai_to_delete = _ai_to_delete arrayIntersect _ai_to_delete;
    
    diag_log format ["[AI RECRUIT] CLEANUP: Deleting %1 AI for %2", count _ai_to_delete, _name];
    diag_log format ["[AI RECRUIT]   From map: %1, From var: %2, From group: %3", count _ai_from_map, count _ai_from_var, count _ai_from_group];
    
    if (_ai_to_delete isEqualTo []) exitWith {
        diag_log format ["[AI RECRUIT] No AI to cleanup for %1", _name];
    };

    // DELETE THEM ALL
    {
        if (!isNull _x) then {
            // Remove from VCOMAI
            if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
                VCM_NOAI = VCM_NOAI - [_x];
            };
            
            // Remove from A3XAI
            if (!isNil "A3XAI_NOAI") then {
                A3XAI_NOAI = A3XAI_NOAI - [_x];
            };
            
            // Kill if alive
            if (alive _x) then {
                _x setDamage 1;
            };
            
            // Remove event handlers
            _x removeAllEventHandlers "Killed";
            
            // Delete
            deleteVehicle _x;
            
            diag_log format ["[AI RECRUIT]   Deleted: %1", typeOf _x];
            
            // Clean up empty groups
            private _aiGroup = group _x;
            if (!isNull _aiGroup && {count units _aiGroup == 0}) then {
                deleteGroup _aiGroup;
            };
        };
    } forEach _ai_to_delete;
    
    if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
        publicVariable "VCM_NOAI";
    };
    
    if (!isNil "A3XAI_NOAI") then {
        publicVariable "A3XAI_NOAI";
    };

    // Clear from global map
    all_recruited_ai_map deleteAt _uid;
    
    // Clear player variables if player object exists
    if (!isNull _player) then {
        _player setVariable ["AssignedAI", [], true];
        _player setVariable ["_aiSpawning", false, true];
        _player setVariable ["_prevVeh", objNull, true];
    };
    
    diag_log format ["[AI RECRUIT] Cleanup complete for %1 - %2 AI removed", _name, count _ai_to_delete];
};

// ====================================================================================
// Function: Assign seats
// ====================================================================================
fn_assignSeats = {
    params ["_player"];
    
    private _veh = vehicle _player;
    
    if (isNull _veh || _veh isEqualTo _player) exitWith {};
    if (locked _veh > 1) exitWith {};
    
    private _assigned = (_player getVariable ["AssignedAI", []]) select { 
        !isNull _x && alive _x && {vehicle _x != _veh}
    };
    
    if (_assigned isEqualTo []) exitWith {};
    
    private _emptyPositions = _veh emptyPositions "cargo";
    private _hasDriver = isNull driver _veh;
    private _hasGunner = isNull gunner _veh;
    
    private _playerIsDriver = (driver _veh isEqualTo _player);
    private _playerIsGunner = (gunner _veh isEqualTo _player);
    
    private _aiIndex = 0;
    
    private _fnc_moveNextAI = {
        params ["_seatType", "_veh", "_assigned", "_aiIndex"];
        if (_aiIndex < count _assigned) then {
            private _ai = _assigned select _aiIndex;
            if (!isNull _ai && alive _ai) then {
                switch (_seatType) do {
                    case "driver": { _ai moveInDriver _veh };
                    case "gunner": { _ai moveInGunner _veh };
                    case "cargo": { _ai moveInCargo _veh };
                };
                _aiIndex = _aiIndex + 1;
            };
        };
        _aiIndex
    };
    
    if (!_playerIsDriver && _hasDriver) then {
        _aiIndex = ["driver", _veh, _assigned, _aiIndex] call _fnc_moveNextAI;
    };
    
    if (!_playerIsGunner && _hasGunner) then {
        _aiIndex = ["gunner", _veh, _assigned, _aiIndex] call _fnc_moveNextAI;
    };
    
    for "_i" from _aiIndex to ((count _assigned) - 1) do {
        if (_emptyPositions > 0) then {
            _aiIndex = ["cargo", _veh, _assigned, _aiIndex] call _fnc_moveNextAI;
            _emptyPositions = _emptyPositions - 1;
        };
    };

    _player setVariable ["_prevVeh", _veh, true];
};

// ====================================================================================
// Setup event handlers for a player
// ====================================================================================
fn_setupPlayerHandlers = {
    params ["_player"];
    
    private _uid = getPlayerUID _player;
    
    diag_log format ["[AI RECRUIT] Setting up handlers for %1 (UID: %2)", name _player, _uid];
    
    // Track this player's alive state
    player_alive_state set [_uid, true];
    
    // GetInMan
    _player addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        
        [_unit] spawn {
            params ["_player"];
            sleep 0.5;
            if (!isNull _player && alive _player) then {
                [_player] call fn_assignSeats;
            };
        };
    }];
    
    // GetOutMan
    _player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        
        [_unit, _vehicle] spawn {
            params ["_player", "_vehicle"];
            sleep 0.3;
            if (!isNull _player && alive _player) then {
                private _assigned = _player getVariable ["AssignedAI", []];
                {
                    if (!isNull _x && {vehicle _x isEqualTo _vehicle}) then {
                        unassignVehicle _x;
                        moveOut _x;
                    };
                } forEach _assigned;
                
                _player setVariable ["_prevVeh", objNull, true];
            };
        };
    }];
    
    // Respawn - spawn NEW AI after delay
    _player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        
        private _uid = getPlayerUID _unit;
        diag_log format ["[AI RECRUIT] Player %1 RESPAWNED (UID: %2)", name _unit, _uid];
        
        // Update alive state
        player_alive_state set [_uid, true];
        
        // Clean up any existing AI for this UID
        private _existingAI = all_recruited_ai_map getOrDefault [_uid, []];
        if (count _existingAI > 0) then {
            diag_log format ["[AI RECRUIT] Found %1 existing AI on respawn - cleaning up", count _existingAI];
            [_uid, name _unit] call fn_cleanupPlayerAI;
        };
        
        // Clear variables
        _unit setVariable ["AssignedAI", [], true];
        _unit setVariable ["_prevVeh", objNull, true];
        _unit setVariable ["_aiSpawning", false, true];
        _unit setVariable ["_lastCheckTime", 0, true];
        
        // Spawn new AI after delay
        [_unit] spawn {
            params ["_player"];
            sleep 5;
            
            if (!isNull _player && alive _player) then {
                diag_log format ["[AI RECRUIT] Spawning fresh AI for %1", name _player];
                [_player] call fn_ensureTeam;
            };
        };
    }];
    
    diag_log format ["[AI RECRUIT] Handlers setup complete for %1", name _player];
};

// ====================================================================================
// Player disconnect cleanup (USES EXACT SAME FUNCTION)
// ====================================================================================
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip"];
    
    diag_log format ["[AI RECRUIT] Player disconnected: %1", _name];
    
    // Use the SAME cleanup function that works for disconnect
    [_uid, _name] call fn_cleanupPlayerAI;
    
    // Remove from alive state tracking
    player_alive_state deleteAt _uid;
}];

// ====================================================================================
// Player Connected
// ====================================================================================
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];
    
    diag_log format ["[AI RECRUIT] Player connecting: %1", _name];
    
    [_uid, _name] spawn {
        params ["_uid", "_name"];
        sleep 10;
        
        private _player = [_uid] call BIS_fnc_getUnitByUID;
        
        if (!isNull _player && [_player] call fn_isPlayerReady) then {
            [_player] call fn_setupPlayerHandlers;
            
            [_player] spawn {
                params ["_player"];
                sleep 3;
                if ([_player] call fn_isPlayerReady) then {
                    [_player] call fn_ensureTeam;
                };
            };
        };
    };
}];

// ====================================================================================
// Main server loop - MONITORS PLAYER DEATHS
// ====================================================================================
[] spawn {
    diag_log "[AI RECRUIT] Waiting for mission start...";
    
    waitUntil {time > 0};
    sleep 5;
    
    {
        if ([_x] call fn_isPlayerReady) then {
            [_x] call fn_setupPlayerHandlers;
            
            [_x] spawn {
                params ["_player"];
                sleep 5;
                if ([_player] call fn_isPlayerReady) then {
                    [_player] call fn_ensureTeam;
                };
            };
        };
    } forEach allPlayers;
    
    diag_log "[AI RECRUIT] System initialized";
    
    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;
            
            if (_uid != "" && isPlayer _player) then {
                private _wasAlive = player_alive_state getOrDefault [_uid, true];
                private _isAlive = alive _player;
                
                // DEATH DETECTION - Player went from alive to dead
                if (_wasAlive && !_isAlive) then {
                    diag_log format ["[AI RECRUIT] !!!!! DEATH DETECTED: %1 !!!!!", name _player];
                    
                    // Update state
                    player_alive_state set [_uid, false];
                    
                    // USE THE SAME CLEANUP AS DISCONNECT (PROVEN TO WORK)
                    [_uid, name _player] call fn_cleanupPlayerAI;
                };
                
                // Update alive state
                if (_isAlive && !_wasAlive) then {
                    player_alive_state set [_uid, true];
                };
                
                // Regular AI check (only if alive)
                if (_isAlive && [_player] call fn_isPlayerReady) then {
                    private _lastCheck = _player getVariable ["_lastCheckTime", 0];
                    
                    if (time - _lastCheck > 30) then {
                        [_player] call fn_ensureTeam;
                        _player setVariable ["_lastCheckTime", time];
                    };
                };
            };
        } forEach allPlayers;

        sleep 5; // Check every 5 seconds for deaths
    };
};

// ====================================================================================
// STARTUP LOG
// ====================================================================================
diag_log "========================================";
diag_log "[AI RECRUIT] Elite AI Recruit System v7.6";
diag_log "  • Death cleanup = Disconnect cleanup";
diag_log "  • Server-side death monitoring";
diag_log "  • STRICT 3 AI maximum";
diag_log "  • Proven cleanup method";
if (RECRUIT_VCOMAI_Active) then {
    diag_log "  • VCOMAI Integration: ENABLED";
} else {
    diag_log "  • VCOMAI Integration: DISABLED";
};
diag_log "========================================";
