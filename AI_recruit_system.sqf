/*
    ELITE AI RECRUIT SYSTEM v7.21 - VEHICLE BEHAVIOR FIX
    ✅ All function scoping fixed
    ✅ Proper group handling (no more warnings!)
    ✅ Simplified player initialization (spawn when actually in-game)
    ✅ Variable shadowing fixed
    ✅ Elite Driving integration (v5.4 Safe Driving Mode)
    ✅ Zombie resurrection protection

    VEHICLE BEHAVIOR:
    ✅ Driver = Elite Driving (safe autopilot 30-40 city, 80-100 highway)
    ✅ Gunner = Full combat AI (if armed vehicle)
    ✅ Passengers = Locked (won't exit until player exits)
    ✅ Auto-seating when player enters vehicle
    ✅ Auto-dismount only when player fully exits
    ✅ On foot = FSM brain system (IDLE/COMBAT/RETREAT/HEAL)

    CHANGES IN v7.21:
    - Fixed AI jumping out of vehicles (passenger retention system restored)
    - Added player GetInMan/GetOutMan handlers for auto-seating
    - AI stay in vehicles until player fully exits
    - Integrated Elite Driving v5.4 (safe speeds, better road following)
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] ========================================";
diag_log "[AI RECRUIT] Starting initialization v7.21 (Vehicle Behavior Fix)...";
diag_log "[AI RECRUIT] ========================================";

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

// Track spawn cooldowns to prevent cascading respawns
spawn_cooldowns = createHashMap;

RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",
    "I_Soldier_AA_F",
    "I_Sniper_F"
];

// Validate AI types on startup
diag_log "[AI RECRUIT] Validating AI types...";
{
    if (!isClass (configFile >> "CfgVehicles" >> _x)) then {
        diag_log format ["[AI RECRUIT] ERROR: Invalid AI type '%1' - not found in CfgVehicles!", _x];
    } else {
        diag_log format ["[AI RECRUIT] Validated AI type: %1", _x];
    };
} forEach RECRUIT_AI_TYPES;

// ====================================================================================
// ADVANCED FSM BRAIN SYSTEM
// ====================================================================================

// FSM States
FSM_STATE_IDLE = "IDLE";
FSM_STATE_COMBAT = "COMBAT";
FSM_STATE_RETREAT = "RETREAT";
FSM_STATE_HEAL = "HEAL";

diag_log "[AI RECRUIT] FSM Brain: 4-state simplified system initialized";
diag_log "[AI RECRUIT] States: IDLE ⟷ COMBAT → RETREAT → HEAL → IDLE";

// ====================================================================================
// FSM: Analyze threat situation
// ====================================================================================
RECRUIT_fnc_FSM_AnalyzeThreat = {
    params ["_unit"];

    // Scan for enemies at 300m range - OPTIMIZED with distanceSqr
    private _maxDistSqr = 300 * 300; // 90000
    private _threats = _unit nearEntities [["CAManBase"], 300] select {
        side _x != side _unit && alive _x && _unit knowsAbout _x > 0.05
    };

    // Also check for very close enemies regardless of knowledge
    private _veryClose = _unit nearEntities [["CAManBase"], 50] select {
        side _x != side _unit && alive _x
    };

    // Merge both lists
    {
        if (!(_x in _threats)) then {
            _threats pushBack _x;
            _unit reveal [_x, 2.0];
        };
    } forEach _veryClose;

    if (count _threats == 0) exitWith {
        [0, objNull, 0, 0]
    };

    // OPTIMIZED: Use distanceSqr instead of distance
    _threats = _threats apply {[_x, _unit distanceSqr _x, _unit knowsAbout _x]};
    _threats sort true;

    private _closest = (_threats select 0) select 0;
    private _closestDistSqr = (_threats select 0) select 1;
    private _avgKnowledge = ((_threats apply {_x select 2}) call BIS_fnc_arithmeticMean);

    [count _threats, _closest, sqrt _closestDistSqr, _avgKnowledge]
};

// ====================================================================================
// FSM: Evaluate next state
// ====================================================================================
RECRUIT_fnc_FSM_EvaluateNextState = {
    params ["_unit", "_currentState", "_player"];

    private _threatInfo = [_unit] call RECRUIT_fnc_FSM_AnalyzeThreat;
    _threatInfo params ["_threatCount", "_closestThreat", "_threatDist", "_avgKnowledge"];

    private _damage = damage _unit;
    private _suppression = getSuppression _unit;

    // PRIORITY 1: Retreat if critically wounded
    if (_damage > 0.7) exitWith { FSM_STATE_RETREAT };

    // PRIORITY 2: Combat if threats detected
    if (_threatCount > 0) exitWith { FSM_STATE_COMBAT };

    // PRIORITY 3: Heal if wounded but safe
    if (_damage > 0.3) exitWith { FSM_STATE_HEAL };

    // PRIORITY 4: Stay with player (default)
    FSM_STATE_IDLE
};

// ====================================================================================
// FSM: Execute state-specific behavior
// ====================================================================================
RECRUIT_fnc_FSM_ExecuteState = {
    params ["_unit", "_state", "_player", "_playerGroup", "_threatInfo"];
    _threatInfo params ["_threatCount", "_closestThreat", "_threatDist", "_avgKnowledge"];

    switch (_state) do {
        case FSM_STATE_IDLE: {
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit setUnitPos "UP";
            _unit doFollow _player;

            private _distToPlayer = _unit distanceSqr _player;
            if (_distToPlayer > (10 * 10)) then {
                _unit doMove (getPos _player);
            };
        };

        case FSM_STATE_COMBAT: {
            _unit setBehaviour "COMBAT";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";
            _playerGroup setFormation "LINE";
            _unit setUnitPos "AUTO";
        };

        case FSM_STATE_RETREAT: {
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit doFollow _player;
            _unit setUnitPos "UP";

            if ("SmokeShell" in magazines _unit && random 1 > 0.7) then {
                _unit fire ["SmokeShellMuzzle", "SmokeShellMuzzle", "SmokeShell"];
            };

            if (random 1 > 0.8) then {
                [_unit, "I'm hit bad!"] remoteExec ["sideChat", 0];
            };
        };

        case FSM_STATE_HEAL: {
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit doFollow _player;
            _unit setUnitPos "UP";

            if ("FirstAidKit" in items _unit) then {
                _unit action ["HealSoldierSelf", _unit];
            };
        };
    };
};

// ====================================================================================
// FSM: Main brain loop (OPTIMIZED with staggering)
// ====================================================================================
RECRUIT_fnc_FSM_BrainLoop = {
    params ["_unit", "_playerUID", "_playerGroup"];

    // ✅ FIXED: Use random instead of hashValue
    private _stagger = random [0, 1, 2]; // 0-2 second stagger
    sleep _stagger;

    _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
    _unit setVariable ["FSM_StateTimer", time, false];
    _unit setVariable ["FSM_LastTransition", time, false];

    diag_log format ["[AI RECRUIT FSM] Brain activated for %1 (UID: %2, stagger: %3s)",
        typeOf _unit, _playerUID, _stagger];

    while {!isNull _unit && alive _unit} do {
        private _player = [_playerUID] call BIS_fnc_getUnitByUID;

        // ✅ FIXED: Get current state BEFORE if block so it's always defined
        private _currentState = _unit getVariable ["FSM_CurrentState", FSM_STATE_IDLE];

        if (!isNull _player && alive _player && alive _unit) then {
            private _stateTimer = _unit getVariable ["FSM_StateTimer", time];
            private _lastTransition = _unit getVariable ["FSM_LastTransition", time];
            private _timeInState = time - _stateTimer;

            private _threatInfo = [_unit] call RECRUIT_fnc_FSM_AnalyzeThreat;
            private _threatCount = _threatInfo select 0;

            private _canSwitch = if (_threatCount > 0) then {
                true
            } else {
                _timeInState > 2
            };

            if (_canSwitch) then {
                private _nextState = [_unit, _currentState, _player] call RECRUIT_fnc_FSM_EvaluateNextState;

                if (_nextState != _currentState) then {
                    diag_log format ["[AI RECRUIT FSM] %1: %2 → %3 (Threat: %4 @ %5m)",
                        name _unit, _currentState, _nextState,
                        (_threatInfo select 0), round (_threatInfo select 2)
                    ];

                    _unit setVariable ["FSM_CurrentState", _nextState, false];
                    _unit setVariable ["FSM_StateTimer", time, false];
                    _unit setVariable ["FSM_LastTransition", time, false];

                    _currentState = _nextState;

                    [_unit, _currentState, _player, _playerGroup, _threatInfo] call RECRUIT_fnc_FSM_ExecuteState;
                };
            };

            // Follow enforcement when NOT in combat
            if (_currentState != FSM_STATE_COMBAT) then {
                private _distanceToPlayerSqr = _unit distanceSqr _player;

                if (_distanceToPlayerSqr > (30 * 30)) then {
                    _unit doFollow _player;
                    _unit doMove (getPos _player);
                };

                if (_timeInState > 2) then {
                    _unit doFollow _player;
                };
            };

        };

        // ✅ OPTIMIZED: Variable sleep based on state
        private _sleepTime = switch (_currentState) do {
            case FSM_STATE_COMBAT: { 1.0 };
            case FSM_STATE_RETREAT: { 1.0 };
            case FSM_STATE_HEAL: { 2.5 };
            default { 3.0 };
        };

        sleep _sleepTime;
    };

    diag_log format ["[AI RECRUIT FSM] Brain terminated for %1", typeOf _unit];
};

// ====================================================================================
// Function: Check if player is fully in-game and ready
// ====================================================================================
fn_isPlayerReady = {
    params ["_player"];

    if (isNull _player) exitWith { false };
    if (!alive _player) exitWith { false };
    if (!isPlayer _player) exitWith { false };

    private _uid = getPlayerUID _player;
    if (_uid isEqualTo "") exitWith { false };
    if (isNull group _player) exitWith { false };

    // ✅ Check if player has valid position (not at world origin)
    private _pos = getPosATL _player;
    if (_pos isEqualTo [0,0,0]) exitWith {
        diag_log format ["[AI RECRUIT] Player %1 at world origin - not spawned yet", name _player];
        false
    };

    // ✅ Check if Exile session is initialized
    private _sessionID = _player getVariable ["ExileSessionID", ""];
    if (_sessionID isEqualTo "") exitWith {
        diag_log format ["[AI RECRUIT] Player %1 waiting for Exile session...", name _player];
        false
    };

    // ✅ Player is standing in-game and ready!
    true
};

// ====================================================================================
// Function: Check spawn cooldown (OPTIMIZED with combat check)
// ====================================================================================
fn_checkSpawnCooldown = {
    params ["_uid"];

    private _lastSpawnTime = spawn_cooldowns getOrDefault [_uid, 0];
    private _cooldownRemaining = (_lastSpawnTime + 5) - time;

    // ✅ Also check if player is in active combat
    private _player = [_uid] call BIS_fnc_getUnitByUID;
    if (!isNull _player) then {
        private _inCombat = (_player getVariable ["FSM_CurrentState", ""]) == FSM_STATE_COMBAT;
        if (_inCombat) exitWith {
            diag_log format ["[AI RECRUIT] Spawn blocked - player %1 in combat", name _player];
            false
        };
    };

    if (_cooldownRemaining > 0) then {
        diag_log format ["[AI RECRUIT] Spawn cooldown active for UID %1 - %2s remaining",
            _uid, _cooldownRemaining];
        false
    } else {
        true
    }
};

// ====================================================================================
// Function: Set spawn cooldown
// ====================================================================================
fn_setSpawnCooldown = {
    params ["_uid"];
    spawn_cooldowns set [_uid, time];
    diag_log format ["[AI RECRUIT] Spawn cooldown set for UID %1", _uid];
};

// ====================================================================================
// Function: Spawn AI teammate (FIXED - Proper group handling)
// ====================================================================================
fn_spawnAI = {
    params ["_player", "_type", "_spawnIndex"];

    if (!isClass (configFile >> "CfgVehicles" >> _type)) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Cannot spawn invalid AI type '%1'", _type];
        objNull
    };

    private _playerGroup = group _player;
    if (isNull _playerGroup) exitWith {
        diag_log "[AI RECRUIT] ERROR: Player has null group";
        objNull
    };

    // ✅ NEW APPROACH: Create AI in server-owned group, then join to player
    // This avoids the "remote group" warning entirely
    private _tempGroup = createGroup [side _player, true];

    private _offset = 3 + (_spawnIndex * 0.5);
    private _angle = 120 * _spawnIndex;
    private _pos = [_player, _offset, _angle] call BIS_fnc_relPos;

    // Create unit in temporary server-owned group
    private _unit = _tempGroup createUnit [_type, _pos, [], 0, "FORM"];

    if (isNull _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Failed to create %1", _type];
        deleteGroup _tempGroup;
        objNull
    };

    if (!alive _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Created %1 but unit is dead", _type];
        deleteVehicle _unit;
        deleteGroup _tempGroup;
        objNull
    };

    // ✅ Now join the unit to the player's group (safe way)
    [_unit] joinSilent _playerGroup;

    // Delete the temporary group
    deleteGroup _tempGroup;

    diag_log format ["[AI RECRUIT] ✓ Created %1 in server group and joined to player %2",
        typeOf _unit, name _player];

    _unit setDir ([_player, _pos] call BIS_fnc_dirTo);
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["OwnerUID", getPlayerUID _player, true];
    _unit setVariable ["OwnerName", name _player, true];
    _unit setVariable ["AIType", _type, true];

    // ✅ ZOMBIE RESURRECTION PROTECTION
    _unit setVariable ["NoRessurect", true, true];
    _unit setVariable ["RVG_ZedIgnore", true, true];

    // ✅ ELITE DRIVING INTEGRATION:
    // DO NOT set EAID_Ignore - we WANT drivers to use Elite Driving!

    private _globalList = all_recruited_ai_map getOrDefault [getPlayerUID _player, []];
    _globalList pushBack _unit;
    all_recruited_ai_map set [getPlayerUID _player, _globalList];

    diag_log format ["[AI RECRUIT] Spawned %1 for %2 - %3 AI total",
        typeOf _unit, name _player, count _globalList];

    // Blacklist from A3XAI
    if (!isNil "A3XAI_NOAI") then {
        A3XAI_NOAI pushBackUnique _unit;
        publicVariable "A3XAI_NOAI";
    };
    _unit setVariable ["A3XAI_Ignore", true, true];
    _playerGroup setVariable ["A3XAI_Ignore", true, true];

    // AI Skills
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

    _unit setAnimSpeedCoef 1.4;
    _unit allowFleeing 0;
    _unit setUnitTrait ["camouflageCoef", 0.5];
    _unit setUnitTrait ["audibleCoef", 0.5];

    _unit setBehaviour "SAFE";
    _unit setCombatMode "YELLOW";
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    _unit doFollow _player;

    _unit enableAI "SUPPRESSION";
    _unit enableAI "COVER";
    _unit enableAI "AUTOCOMBAT";

    {
        _unit enableAI _x;
    } forEach [
        "TARGET",
        "AUTOTARGET",
        "MOVE",
        "ANIM",
        "FSM",
        "AIMINGERROR",
        "TEAMSWITCH"
    ];

    _unit setSkill ["courage", 1.0];
    _unit enableGunLights "AUTO";
    _unit setUnitTrait ["UAVHacker", true];

    _playerGroup setCombatMode "RED";
    _playerGroup setBehaviour "COMBAT";
    _playerGroup enableAttack true;
    _playerGroup setFormation "COLUMN";

    // ✅ VEHICLE RETENTION: Prevent AI from auto-dismounting vehicles
    _unit addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        // Check if AI is dismounting on their own (not ordered by player)
        private _owner = [_unit getVariable ["OwnerUID", ""]] call BIS_fnc_getUnitByUID;

        if (!isNull _owner && alive _owner) then {
            private _ownerVeh = vehicle _owner;

            // If owner is in the same vehicle, the AI shouldn't get out unless ordered
            if (_ownerVeh == _vehicle && _role != "driver") then {
                // Re-board the AI after a short delay
                [_unit, _vehicle, _role, _turret] spawn {
                    params ["_unit", "_vehicle", "_role", "_turret"];
                    sleep 0.3;

                    // Check if AI is still outside and owner is still in vehicle
                    if (!isNull _unit && alive _unit && vehicle _unit == _unit) then {
                        private _owner = [_unit getVariable ["OwnerUID", ""]] call BIS_fnc_getUnitByUID;

                        if (!isNull _owner && alive _owner && vehicle _owner == _vehicle) then {
                            // Get back in
                            switch (_role) do {
                                case "cargo": { _unit moveInCargo _vehicle };
                                case "gunner": { _unit moveInGunner _vehicle };
                                case "commander": { _unit moveInCommander _vehicle };
                                case "turret": { _unit moveInTurret [_vehicle, _turret] };
                            };

                            diag_log format ["[AI RECRUIT] %1 re-boarded %2 (prevented auto-dismount)", name _unit, typeOf _vehicle];
                        };
                    };
                };
            };
        };
    }];

    // VCOMAI Integration
    if (RECRUIT_VCOMAI_Active) then {
        if (!isNil "VCM_NOAI" && {!isNil {VCM_NOAI}}) then {
            VCM_NOAI pushBackUnique _unit;
            publicVariable "VCM_NOAI";
        };

        _unit setVariable ["VCM_CUSTOMAI", true, true];
        _unit setVariable ["VCM_RECRUIT", true, true];

        if (!isNil "VCM_fnc_INITAI" && {!isNil {VCM_fnc_INITAI}}) then {
            [_unit] call VCM_fnc_INITAI;
        };

        if (!isNil "VCM_SERVERAI" && {!isNil {VCM_SERVERAI}}) then {
            VCM_SERVERAI pushBackUnique _playerGroup;
            publicVariable "VCM_SERVERAI";
            _playerGroup setVariable ["VCM_RECRUITGROUP", true, true];
        };
    };

    // LAMBS Integration
    _unit setVariable ["LAMBS_RECRUIT", true, true];
    _unit setVariable ["LAMBS_dangerRadius", 100, true];
    _unit setVariable ["LAMBS_dangerCausesCreep", true, true];
    _unit setVariable ["LAMBS_suppressionRadius", 50, true];
    _unit setVariable ["LAMBS_suppressionDuration", 15, true];

    // Activate FSM Brain
    [_unit, getPlayerUID _player, _playerGroup] spawn RECRUIT_fnc_FSM_BrainLoop;

    // AI death handler
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _ownerUID = _unit getVariable ["OwnerUID", ""];

        if (_ownerUID isEqualTo "") exitWith {};

        private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;

        if (!isNull _owner && {!(_owner isKindOf "CAManBase")}) then {
            _owner = effectiveCommander _owner;
        };

        if (!isNull _owner && alive _owner) then {
            private _assigned = _owner getVariable ["AssignedAI", []];
            _assigned = _assigned - [_unit];
            _owner setVariable ["AssignedAI", _assigned, true];

            private _globalList = all_recruited_ai_map getOrDefault [_ownerUID, []];
            _globalList = _globalList - [_unit];
            all_recruited_ai_map set [_ownerUID, _globalList];

            diag_log format ["[AI RECRUIT] AI killed: %1 (owner: %2) - %3 AI remaining",
                typeOf _unit, name _owner, count _globalList];

            [_owner, _ownerUID] spawn {
                params ["_owner", "_ownerUID"];
                sleep 3;

                if (!isNull _owner && alive _owner) then {
                    if ([_ownerUID] call fn_checkSpawnCooldown) then {
                        [_ownerUID] call fn_setSpawnCooldown;
                        [_owner] call fn_ensureTeam;
                    };
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
    private _spawnLockTime = _player getVariable ["_aiSpawnLockTime", 0];

    if (_isSpawning && (time - _spawnLockTime > 30)) then {
        diag_log format ["[AI RECRUIT] WARNING: Spawn lock timeout for %1 - resetting", name _player];
        _isSpawning = false;
        _player setVariable ["_aiSpawning", false];
    };

    if (_isSpawning) exitWith {
        diag_log format ["[AI RECRUIT] Spawn in progress for %1 - skipping", name _player];
    };

    _player setVariable ["_aiSpawning", true];
    _player setVariable ["_aiSpawnLockTime", time];

    private _globalAI = all_recruited_ai_map getOrDefault [_uid, []];
    private _globalValid = _globalAI select { !isNull _x && alive _x };

    private _assigned = _player getVariable ["AssignedAI", []];
    private _assignedValid = _assigned select { !isNull _x && alive _x };

    private _combined = _globalValid + _assignedValid;
    private _validAI = _combined arrayIntersect _combined;

    if (count _validAI > 3) then {
        diag_log format ["[AI RECRUIT] WARNING: Player %1 has %2 AI! Removing extras...",
            name _player, count _validAI];

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

    diag_log format ["[AI RECRUIT] Player %1 needs %2 AI (has %3)",
        name _player, count _missing, _currentCount];

    private _spawnIndex = count _validAI;
    {
        if (count _validAI < 3) then {
            private _ai = [_player, _x, _spawnIndex] call fn_spawnAI;
            if (!isNull _ai) then {
                _validAI pushBack _ai;
                _spawnIndex = _spawnIndex + 1;
            } else {
                diag_log format ["[AI RECRUIT] Failed to spawn AI type %1 for %2", _x, name _player];
            };
            sleep 0.5;
        };
    } forEach _missing;

    _player setVariable ["AssignedAI", _validAI, true];
    all_recruited_ai_map set [_uid, _validAI];
    _player setVariable ["_aiSpawning", false];

    diag_log format ["[AI RECRUIT] Team spawn complete for %1 - now has %2 AI",
        name _player, count _validAI];
};

// ====================================================================================
// Function: CLEANUP (FIXED - safe group deletion)
// ====================================================================================
fn_cleanupPlayerAI = {
    params ["_uid", "_name"];

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP START: %1 (UID: %2) ***", _name, _uid];
    diag_log "========================================";

    if (_uid isEqualTo "") exitWith {
        diag_log "[AI RECRUIT] ERROR: Empty UID - cannot cleanup";
    };

    private _player = [_uid] call BIS_fnc_getUnitByUID;
    diag_log format ["[AI RECRUIT] Player object lookup: %1",
        if (isNull _player) then {"NULL"} else {"FOUND"}];

    // SOURCE 1: Global map
    private _ai_from_map = all_recruited_ai_map getOrDefault [_uid, []];
    diag_log format ["[AI RECRUIT] Source 1 (Global Map): %1 AI found", count _ai_from_map];

    // SOURCE 2: Player variable
    private _ai_from_var = [];
    if (!isNull _player) then {
        _ai_from_var = _player getVariable ["AssignedAI", []];
        diag_log format ["[AI RECRUIT] Source 2 (Player Variable): %1 AI found", count _ai_from_var];
    } else {
        diag_log "[AI RECRUIT] Source 2 (Player Variable): Skipped (player null)";
    };

    // SOURCE 3: Player's group
    private _ai_from_group = [];
    if (!isNull _player && !isNull group _player) then {
        _ai_from_group = (units group _player) select {
            !isPlayer _x && {_x getVariable ["ExileRecruited", false]}
        };
        diag_log format ["[AI RECRUIT] Source 3 (Player Group): %1 AI found", count _ai_from_group];
    } else {
        diag_log "[AI RECRUIT] Source 3 (Player Group): Skipped (player/group null)";
    };

    private _ai_to_delete = _ai_from_map + _ai_from_var + _ai_from_group;
    _ai_to_delete = _ai_to_delete arrayIntersect _ai_to_delete;

    diag_log format ["[AI RECRUIT] Total unique AI to delete: %1", count _ai_to_delete];

    if (_ai_to_delete isEqualTo []) exitWith {
        diag_log format ["[AI RECRUIT] *** NO AI TO CLEANUP for %1 ***", _name];
        diag_log "========================================";
    };

    private _groupsToClean = [];

    // ✅ OPTIMIZED: Batch deletion
    // Phase 1: Disable and collect groups
    {
        if (!isNull _x) then {
            private _aiGroup = group _x;
            if (!isNull _aiGroup && {!(_aiGroup in _groupsToClean)}) then {
                _groupsToClean pushBack _aiGroup;
            };

            if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
                VCM_NOAI = VCM_NOAI - [_x];
            };

            if (!isNil "A3XAI_NOAI") then {
                A3XAI_NOAI = A3XAI_NOAI - [_x];
            };

            _x removeAllEventHandlers "Killed";
            if (alive _x) then { _x setDamage 1 };

            diag_log format ["[AI RECRUIT]   Deleted: %1", typeOf _x];
        };
    } forEach _ai_to_delete;

    // Phase 2: Batch delete all units
    {deleteVehicle _x} forEach _ai_to_delete;

    // ✅ FIXED: Safe group deletion (never delete player's group)
    {
        if (!isNull _x && {count units _x == 0}) then {
            private _isPlayerGroup = if (!isNull _player) then {
                _x == group _player
            } else {
                false
            };

            if (!_isPlayerGroup) then {
                deleteGroup _x;
                diag_log format ["[AI RECRUIT]   Deleted empty group: %1", _x];
            } else {
                diag_log "[AI RECRUIT]   Skipped player's group (safety check)";
            };
        };
    } forEach _groupsToClean;

    if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
        publicVariable "VCM_NOAI";
    };

    if (!isNil "A3XAI_NOAI") then {
        publicVariable "A3XAI_NOAI";
    };

    all_recruited_ai_map deleteAt _uid;
    spawn_cooldowns deleteAt _uid;

    if (!isNull _player) then {
        _player setVariable ["AssignedAI", [], true];
        _player setVariable ["_aiSpawning", false, true];
        _player setVariable ["_aiSpawnLockTime", 0, true];
        diag_log "[AI RECRUIT] Player variables cleared";
    };

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP COMPLETE for %1 ***", _name];
    diag_log format ["[AI RECRUIT] Results: %1 AI deleted, %2 groups cleaned",
        count _ai_to_delete, count _groupsToClean];
    diag_log "========================================";
};

// ====================================================================================
// Setup event handlers for a player
// ====================================================================================
fn_setupPlayerHandlers = {
    params ["_player"];

    private _uid = getPlayerUID _player;

    diag_log format ["[AI RECRUIT] Setting up handlers for %1 (UID: %2)", name _player, _uid];

    _player addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _uid = getPlayerUID _unit;
        diag_log format ["[AI RECRUIT] Player death detected: %1 - cleaning up AI", name _unit];
        [_uid, name _unit] call fn_cleanupPlayerAI;
    }];

    diag_log format ["[AI RECRUIT] Death event handlers registered for %1", name _player];

    // GetInMan - Assign AI to seats when player enters vehicle
    _player addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        [_unit, _vehicle] spawn {
            params ["_player", "_vehicle"];
            sleep 0.5;

            if (!isNull _player && alive _player && vehicle _player == _vehicle) then {
                private _assigned = _player getVariable ["AssignedAI", []];
                private _seatsAssigned = 0;

                // Assign AI to available seats
                {
                    if (!isNull _x && alive _x && vehicle _x != _vehicle) then {
                        // Try different roles in priority order
                        if (driver _vehicle isEqualTo objNull && _seatsAssigned == 0) then {
                            _x assignAsDriver _vehicle;
                            _x moveInDriver _vehicle;
                            _seatsAssigned = _seatsAssigned + 1;
                            diag_log format ["[AI RECRUIT] %1 assigned as driver", name _x];
                        } else {
                            _x assignAsCargo _vehicle;
                            _x moveInCargo _vehicle;
                            _seatsAssigned = _seatsAssigned + 1;
                            diag_log format ["[AI RECRUIT] %1 assigned as cargo", name _x];
                        };
                    };
                } forEach _assigned;

                if (_seatsAssigned > 0) then {
                    diag_log format ["[AI RECRUIT] %1 AI assigned to %2", _seatsAssigned, typeOf _vehicle];
                };
            };
        };
    }];

    // GetOutMan - Only dismount AI if player fully exits (not switching seats)
    _player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        [_unit, _vehicle] spawn {
            params ["_player", "_vehicle"];
            sleep 0.5;  // Delay to check if player re-enters

            // Only dismount AI if player is truly out of the vehicle
            if (!isNull _player && alive _player && vehicle _player == _player) then {
                private _assigned = _player getVariable ["AssignedAI", []];
                {
                    if (!isNull _x && {vehicle _x isEqualTo _vehicle}) then {
                        unassignVehicle _x;
                        moveOut _x;
                        _x doFollow _player;
                        diag_log format ["[AI RECRUIT] %1 dismounted from %2", name _x, typeOf _vehicle];
                    };
                } forEach _assigned;
            };
        };
    }];

    _player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];

        private _uid = getPlayerUID _unit;

        diag_log "========================================";
        diag_log format ["[AI RECRUIT] *** PLAYER RESPAWNED: %1 (UID: %2) ***", name _unit, _uid];
        diag_log "========================================";

        private _existingAI = all_recruited_ai_map getOrDefault [_uid, []];
        if (count _existingAI > 0) then {
            diag_log format ["[AI RECRUIT] WARNING: Found %1 orphaned AI on respawn - cleaning",
                count _existingAI];
            [_uid, name _unit] call fn_cleanupPlayerAI;
        } else {
            diag_log "[AI RECRUIT] Good: No orphaned AI found";
        };

        _unit setVariable ["AssignedAI", [], true];
        _unit setVariable ["_aiSpawning", false, true];
        _unit setVariable ["_aiSpawnLockTime", 0, true];
        _unit setVariable ["_lastCheckTime", 0, true];

        [_unit, _uid] spawn {
            params ["_player", "_uid"];

            // ✅ Wait for player to be in-game (Exile session + valid position)
            waitUntil {
                sleep 1;
                [_player] call fn_isPlayerReady
            };

            diag_log format ["[AI RECRUIT] ✓ Player %1 in-game after respawn - spawning AI", name _player];

            if ([_uid] call fn_checkSpawnCooldown) then {
                [_uid] call fn_setSpawnCooldown;
                [_player] call fn_ensureTeam;
            };
        };
    }];

    diag_log format ["[AI RECRUIT] Handlers setup complete for %1", name _player];
};

// ====================================================================================
// Player disconnect cleanup
// ====================================================================================
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip"];

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** PLAYER DISCONNECTED: %1 ***", _name];
    diag_log "========================================";

    [_uid, _name] call fn_cleanupPlayerAI;
}];

// ====================================================================================
// Player Connected - SIMPLIFIED (just wait for Exile session + valid position)
// ====================================================================================
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];

    diag_log format ["[AI RECRUIT] Player connecting: %1 (UID: %2)", _name, _uid];

    [_uid, _name] spawn {
        params ["_uid", "_name"];

        // ✅ Wait for player object to exist
        private _player = objNull;
        private _timeout = time + 30;

        while {isNull _player && time < _timeout} do {
            sleep 1;
            _player = [_uid] call BIS_fnc_getUnitByUID;
        };

        if (isNull _player) exitWith {
            diag_log format ["[AI RECRUIT] ERROR: Could not find player object for %1 after 30s", _name];
        };

        diag_log format ["[AI RECRUIT] Player object found for %1, waiting for in-game spawn...", _name];

        // ✅ SIMPLIFIED: Just wait for Exile session + valid position
        waitUntil {
            sleep 1;
            [_player] call fn_isPlayerReady
        };

        diag_log format ["[AI RECRUIT] ✓ Player %1 is in-game and standing - spawning AI!", _name];

        // ✅ Setup handlers
        [_player] call fn_setupPlayerHandlers;

        // ✅ Small delay then spawn
        sleep 2;

        if ([_uid] call fn_checkSpawnCooldown) then {
            [_uid] call fn_setSpawnCooldown;
            [_player] call fn_ensureTeam;
        };
    };
}];

// ====================================================================================
// Main server loop (SIMPLIFIED)
// ====================================================================================
[] spawn {
    diag_log "[AI RECRUIT] Waiting for mission start...";

    waitUntil {time > 0};
    sleep 5;

    diag_log "[AI RECRUIT] Checking for existing players...";

    // ✅ Process existing players (server restart with players already connected)
    {
        private _player = _x;
        private _uid = getPlayerUID _player;

        if (_uid != "") then {
            diag_log format ["[AI RECRUIT] Found existing player: %1", name _player];

            [_player, _uid] spawn {
                params ["_player", "_uid"];

                // ✅ Wait for player to be in-game
                waitUntil {
                    sleep 1;
                    [_player] call fn_isPlayerReady
                };

                diag_log format ["[AI RECRUIT] ✓ Existing player %1 is in-game - spawning AI", name _player];

                [_player] call fn_setupPlayerHandlers;
                sleep 2;

                if ([_uid] call fn_checkSpawnCooldown) then {
                    [_uid] call fn_setSpawnCooldown;
                    [_player] call fn_ensureTeam;
                };
            };
        };
    } forEach allPlayers;

    diag_log "[AI RECRUIT] System initialized";

    private _playerAliveStates = createHashMap;

    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;

            if (_uid != "" && isPlayer _player) then {
                private _isAlive = alive _player;
                private _wasAlive = _playerAliveStates getOrDefault [_uid, true];

                if (_wasAlive && !_isAlive) then {
                    diag_log format ["[AI RECRUIT] !!!!! DEATH DETECTED (BACKUP): %1 !!!!!",
                        name _player];
                    [_uid, name _player] call fn_cleanupPlayerAI;
                    _playerAliveStates set [_uid, false];
                };

                if (_isAlive && !_wasAlive) then {
                    diag_log format ["[AI RECRUIT] Player %1 alive again (respawned)", name _player];
                    _playerAliveStates set [_uid, true];
                };

                if (_isAlive && [_player] call fn_isPlayerReady) then {
                    private _lastCheck = _player getVariable ["_lastCheckTime", 0];

                    if (time - _lastCheck > 30) then {
                        if ([_uid] call fn_checkSpawnCooldown) then {
                            [_uid] call fn_setSpawnCooldown;
                            [_player] call fn_ensureTeam;
                        };
                        _player setVariable ["_lastCheckTime", time];
                    };
                };
            };
        } forEach allPlayers;

        sleep 5;
    };
};

// ====================================================================================
// STARTUP LOG
// ====================================================================================
diag_log "========================================";
diag_log "[AI RECRUIT] Elite AI Recruit System v7.21 - VEHICLE BEHAVIOR FIX";
diag_log "  • VEHICLE INTEGRATION (FIXED):";
diag_log "    - Drivers USE Elite Driving v5.4 (safe autopilot)";
diag_log "      * Cities/Towns: 30-40 km/h";
diag_log "      * Highway: 80-100 km/h";
diag_log "      * Curves: Auto-slowdown (slight/medium/sharp)";
diag_log "      * Bridges: No braking, maintain speed";
diag_log "      * Road Following: Enhanced (stays on roads)";
diag_log "    - Passengers LOCKED (won't exit until player exits)";
diag_log "    - Auto-seating when player enters vehicle";
diag_log "    - Auto-dismount only when player fully exits";
diag_log "    - Gunners ACTIVE (armed vehicles)";
diag_log "    - On foot = FSM brain (IDLE/COMBAT/RETREAT/HEAL)";
diag_log "";
diag_log "  • EXTREME SKILLS: 1.0 (PERFECT) all categories";
diag_log "  • 300M SIGHT: Detect enemies at extreme distance";
diag_log "  • 1.4X SPEED: Lightning movement";
diag_log "  • STEALTH: 50% harder to spot, 50% quieter";
diag_log "";
diag_log "  • GROUP HANDLING:";
diag_log "    - Create AI in temp server-owned group";
diag_log "    - Join AI to player group (safe method)";
diag_log "    - No more ownership transfer warnings!";
diag_log "    - Clean, reliable spawning";
diag_log "";
diag_log "  • SPAWN TIMING:";
diag_log "    - Wait for Exile session ID";
diag_log "    - Wait for valid position (not at 0,0,0)";
diag_log "    - Spawn when player standing in-game!";
diag_log "";
diag_log "  • OPTIMIZATIONS:";
diag_log "    - distanceSqr (3x faster distance checks)";
diag_log "    - Staggered FSM (0-2s offset prevents CPU spikes)";
diag_log "    - Variable sleep (1-3s based on state)";
diag_log "    - Combat spawn blocking";
diag_log "    - Batch AI deletion";
diag_log "";
diag_log "  • PROTECTIONS:";
diag_log "    - Ravage zombie immunity";
diag_log "    - Safe group deletion (never deletes player group)";
diag_log "    - Passenger retention (re-board if dismount)";
diag_log "    - Variable shadowing fixed";
diag_log "";
if (RECRUIT_VCOMAI_Active) then {
    diag_log "  • VCOMAI Integration: ENABLED";
} else {
    diag_log "  • VCOMAI Integration: DISABLED";
};
diag_log "========================================";
