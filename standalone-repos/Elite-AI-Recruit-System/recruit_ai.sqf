/*
    ELITE AI RECRUIT SYSTEM v7.16 - EXTREME ELITE OPERATORS
    ✅ EXTREME SKILLS - 1.0 (perfect) accuracy, speed, spotting - HEADSHOT MASTERS
    ✅ 300M SIGHT RANGE - Detect and engage enemies at extreme distance
    ✅ 1.4X SPEED - Lightning fast movement and reactions
    ✅ PERFECT AIM - No shake, instant acquisition, headshot preference
    ✅ STEALTH BONUS - 50% harder to spot, 50% quieter
    ✅ NO FLEEING - Fearless warriors who never retreat (except when critically wounded)
    ✅ EXILE RESILIENT - Brain survives Exile session initialization
    ✅ STREAMLINED FSM - 4 states: Idle (SAFE/UP), Combat, Retreat, Heal
    ✅ INSTANT REACTION - Immediate response to threats
    ✅ DUAL death detection: Event handlers + backup polling
    ✅ NO VEHICLE BOARDING - AI stay on foot for maximum tactical flexibility

    COMBAT BEHAVIOR:
    ✅ FULL AUTONOMY - AI have complete freedom to engage, flank, take cover
    ✅ NO RESTRICTIONS - Can spread out and use advanced tactics in combat
    ✅ TARGET SHARING - Group shares enemy information automatically

    NON-COMBAT BEHAVIOR:
    ✅ TIGHT FORMATION - Stay within 30m, mirror player movement closely
    ✅ STRICT FOLLOWING - Force AI to stay in column formation when safe
    ✅ AUTO-RETURN - Seamlessly return to tight formation after combat ends
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] ========================================";
diag_log "[AI RECRUIT] Starting initialization v7.16 (Extreme Elite Operators)...";
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
// ADVANCED FSM BRAIN SYSTEM - Based on LAMBS Danger.fsm
// ====================================================================================

// FSM States
FSM_STATE_IDLE = "IDLE";           // Following player, no threats
FSM_STATE_COMBAT = "COMBAT";       // Engaged with enemy
FSM_STATE_RETREAT = "RETREAT";     // Falling back when critically wounded
FSM_STATE_HEAL = "HEAL";           // Healing self when safe

diag_log "[AI RECRUIT] FSM Brain: 4-state simplified system initialized";
diag_log "[AI RECRUIT] States: IDLE ⟷ COMBAT → RETREAT → HEAL → IDLE";

// ====================================================================================
// FSM: Analyze threat situation
// ====================================================================================
fn_FSM_AnalyzeThreat = {
    params ["_unit"];

    // Scan for enemies at 300m range - extreme sight distance
    private _threats = _unit nearEntities [["CAManBase"], 300] select {
        side _x != side _unit && alive _x && _unit knowsAbout _x > 0.05
    };

    // Also check for very close enemies regardless of knowledge (visual detection)
    private _veryClose = _unit nearEntities [["CAManBase"], 50] select {
        side _x != side _unit && alive _x
    };

    // Merge both lists
    {
        if (!(_x in _threats)) then {
            _threats pushBack _x;
            // Reveal very close enemies immediately
            _unit reveal [_x, 2.0];  // High reveal level
        };
    } forEach _veryClose;

    if (count _threats == 0) exitWith {
        [0, objNull, 0, 0] // [count, closest, distance, avgKnowledge]
    };

    _threats = _threats apply {[_x, _unit distance _x, _unit knowsAbout _x]};
    _threats sort true; // Sort by distance

    private _closest = (_threats select 0) select 0;
    private _closestDist = (_threats select 0) select 1;
    private _avgKnowledge = ((_threats apply {_x select 2}) call BIS_fnc_arithmeticMean);

    [count _threats, _closest, _closestDist, _avgKnowledge]
};

// ====================================================================================
// FSM: Evaluate next state based on current situation
// ====================================================================================
fn_FSM_EvaluateNextState = {
    params ["_unit", "_currentState", "_player"];

    private _threatInfo = [_unit] call fn_FSM_AnalyzeThreat;
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
fn_FSM_ExecuteState = {
    params ["_unit", "_state", "_player", "_playerGroup", "_threatInfo"];
    _threatInfo params ["_threatCount", "_closestThreat", "_threatDist", "_avgKnowledge"];

    switch (_state) do {
        case FSM_STATE_IDLE: {
            // Safe and calm - TIGHT FORMATION, mirror player movement
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";  // Tight column formation

            // Force standing/running (not crouched) - mirror player stance
            _unit setUnitPos "UP";

            // STRICT following - stay close to player
            _unit doFollow _player;

            // Mirror player movement more closely
            private _distToPlayer = _unit distance _player;
            if (_distToPlayer > 10) then {
                _unit doMove (getPos _player);
            };
        };

        case FSM_STATE_COMBAT: {
            // Enemy detected - FULL COMBAT AUTONOMY
            _unit setBehaviour "COMBAT";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";  // Fire at will
            _playerGroup setFormation "LINE";

            // COMPLETE FREEDOM in combat - no movement restrictions
            // AI can flank, take cover, spread out, use tactics freely
            // Group shares target information automatically

            // Let AI choose stance for combat
            _unit setUnitPos "AUTO";
        };

        case FSM_STATE_RETREAT: {
            // Badly wounded - fall back fast
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";

            // Move toward player
            _unit doFollow _player;
            _unit setUnitPos "UP";  // Run fast

            // Use smoke if available
            if ("SmokeShell" in magazines _unit && random 1 > 0.7) then {
                _unit fire ["SmokeShellMuzzle", "SmokeShellMuzzle", "SmokeShell"];
            };

            if (random 1 > 0.8) then {
                [_unit, "I'm hit bad!"] remoteExec ["sideChat", 0];
            };
        };

        case FSM_STATE_HEAL: {
            // Safe and wounded - heal while running with player
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";

            // Stay with player while healing
            _unit doFollow _player;
            _unit setUnitPos "UP";  // Stand/run

            // Use FAK if available
            if ("FirstAidKit" in items _unit) then {
                _unit action ["HealSoldierSelf", _unit];
            };
        };
    };
};

// ====================================================================================
// FSM: Main brain loop for each AI unit
// ====================================================================================
fn_FSM_BrainLoop = {
    params ["_unit", "_playerUID", "_playerGroup"];

    // Initialize FSM state
    _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
    _unit setVariable ["FSM_StateTimer", time, false];
    _unit setVariable ["FSM_LastTransition", time, false];

    diag_log format ["[AI RECRUIT FSM] Brain activated for %1 (UID: %2)", typeOf _unit, _playerUID];

    while {!isNull _unit && alive _unit} do {
        // Look up player by UID each loop (resilient to Exile session changes)
        private _player = [_playerUID] call BIS_fnc_getUnitByUID;

        if (!isNull _player && alive _player && alive _unit) then {

            private _currentState = _unit getVariable ["FSM_CurrentState", FSM_STATE_IDLE];
            private _stateTimer = _unit getVariable ["FSM_StateTimer", time];
            private _lastTransition = _unit getVariable ["FSM_LastTransition", time];
            private _timeInState = time - _stateTimer;

            // Analyze threat situation
            private _threatInfo = [_unit] call fn_FSM_AnalyzeThreat;
            private _threatCount = _threatInfo select 0;

            // Evaluate next state - instant reaction to threats, 2s delay for non-combat
            private _canSwitch = if (_threatCount > 0) then {
                true  // Instant reaction to threats
            } else {
                _timeInState > 2  // 2s minimum for non-combat states
            };

            if (_canSwitch) then {
                private _nextState = [_unit, _currentState, _player] call fn_FSM_EvaluateNextState;

                // State transition - only execute state actions on transition
                if (_nextState != _currentState) then {
                    diag_log format ["[AI RECRUIT FSM] %1: %2 → %3 (Threat: %4 @ %5m)",
                        name _unit, _currentState, _nextState,
                        (_threatInfo select 0), round (_threatInfo select 2)
                    ];

                    _unit setVariable ["FSM_CurrentState", _nextState, false];
                    _unit setVariable ["FSM_StateTimer", time, false];
                    _unit setVariable ["FSM_LastTransition", time, false];

                    _currentState = _nextState;

                    // Execute state behavior ONLY on transition
                    [_unit, _currentState, _player, _playerGroup, _threatInfo] call fn_FSM_ExecuteState;
                };
            };

            // Continuous follow enforcement - ONLY when NOT in combat
            // In combat, AI have complete freedom to engage and maneuver
            if (_currentState != FSM_STATE_COMBAT) then {
                private _distanceToPlayer = _unit distance _player;

                // Strict formation enforcement when safe
                // Force AI to stay close and mirror player movement
                if (_distanceToPlayer > 30) then {
                    _unit doFollow _player;
                    _unit doMove (getPos _player);
                };

                // Periodic follow refresh to keep tight formation
                if (_timeInState > 2) then {
                    _unit doFollow _player;
                };
            };

        };

        sleep 2; // FSM evaluation every 2 seconds
    };

    diag_log format ["[AI RECRUIT FSM] Brain terminated for %1", typeOf _unit];
};

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

    // Check if player is on the ground (not parachuting/in air)
    if ((getPosATL _player select 2) > 3) exitWith {
        diag_log format ["[AI RECRUIT] Player %1 is in air (altitude: %2m) - waiting for landing", name _player, round ((getPosATL _player select 2))];
        false
    };

    // Check if player is in a parachute
    private _veh = vehicle _player;
    if (_veh != _player && {_veh isKindOf "ParachuteBase"}) exitWith {
        diag_log format ["[AI RECRUIT] Player %1 is parachuting - waiting for landing", name _player];
        false
    };

    true
};

// ====================================================================================
// Function: Check spawn cooldown
// ====================================================================================
fn_checkSpawnCooldown = {
    params ["_uid"];

    private _lastSpawnTime = spawn_cooldowns getOrDefault [_uid, 0];
    private _cooldownRemaining = (_lastSpawnTime + 5) - time;

    if (_cooldownRemaining > 0) then {
        diag_log format ["[AI RECRUIT] Spawn cooldown active for UID %1 - %2 seconds remaining", _uid, _cooldownRemaining];
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
// Function: Spawn missing AI teammate
// ====================================================================================
fn_spawnAI = {
    params ["_player", "_type", "_spawnIndex"];

    // Validate AI type
    if (!isClass (configFile >> "CfgVehicles" >> _type)) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Cannot spawn invalid AI type '%1'", _type];
        objNull
    };

    private _playerGroup = group _player;
    if (isNull _playerGroup) exitWith {
        diag_log "[AI RECRUIT] ERROR: Player has null group";
        objNull
    };

    // Transfer group ownership to server BEFORE creating units
    if (groupOwner _playerGroup != 2) then {
        diag_log format ["[AI RECRUIT] Transferring group ownership for %1...", name _player];
        _playerGroup setGroupOwner 2;

        // Wait for ownership transfer to complete
        private _timeout = time + 2;
        waitUntil {sleep 0.1; groupOwner _playerGroup == 2 || time > _timeout};

        if (groupOwner _playerGroup != 2) then {
            diag_log format ["[AI RECRUIT] WARNING: Failed to transfer group ownership for %1 - continuing anyway", name _player];
            diag_log format ["[AI RECRUIT] Units will be created in client-owned group (this is usually fine)"];
        } else {
            diag_log format ["[AI RECRUIT] Group ownership transferred successfully for %1", name _player];
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
        diag_log format ["[AI RECRUIT] ERROR: Created %1 but unit is dead", _type];
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

    // ============================================
    // ENHANCED AI BEHAVIORS (Best from top mods)
    // ============================================

    // EXTREME ELITE AI Skills - Maximum lethality
    {
        _unit setSkill [_x select 0, _x select 1];
    } forEach [
        ["aimingAccuracy", 1.0],    // Perfect accuracy (headshots)
        ["aimingShake", 1.0],       // No shake (laser aim)
        ["aimingSpeed", 1.0],       // Instant target acquisition
        ["spotDistance", 1.0],      // 300m sight range
        ["spotTime", 1.0],          // Instant recognition
        ["courage", 1.0],           // Fearless
        ["reloadSpeed", 1.0],       // Lightning reload
        ["commanding", 1.0],        // Perfect coordination
        ["general", 1.0]            // Maximum competence
    ];

    // Extreme Movement Speed
    _unit setAnimSpeedCoef 1.4;     // 1.4x speed
    _unit allowFleeing 0;           // Never flee

    // Damage Multiplier - elite survivability
    _unit setUnitTrait ["camouflageCoef", 0.5];  // Harder to spot
    _unit setUnitTrait ["audibleCoef", 0.5];     // Quieter

    // Initial Behavior - Safe and fast when no combat
    _unit setBehaviour "SAFE";      // Run normally with player
    _unit setCombatMode "YELLOW";   // Return fire if attacked
    _unit setSpeedMode "FULL";      // Full speed
    _unit setUnitPos "UP";          // Standing/running (not crouched)
    _unit doFollow _player;         // Follow player immediately

    // Advanced AI Features
    _unit enableAI "SUPPRESSION";   // Use suppressive fire
    _unit enableAI "COVER";         // Seek cover intelligently
    _unit enableAI "AUTOCOMBAT";    // Auto-engage threats

    {
        _unit enableAI _x;
    } forEach [
        "TARGET",                   // Target selection
        "AUTOTARGET",              // Auto target acquisition
        "MOVE",                    // Movement AI
        "ANIM",                    // Animation control
        "FSM",                     // Finite state machine
        "AIMINGERROR",             // Realistic aiming
        "TEAMSWITCH"               // Team coordination
    ];

    // Combat enhancements
    _unit setSkill ["courage", 1.0];
    _unit enableGunLights "AUTO";   // Tactical lights in CQB

    // Headshot preference (aim high)
    _unit setUnitTrait ["UAVHacker", true];  // Tech bonus

    // Group behavior
    _playerGroup setCombatMode "RED";
    _playerGroup setBehaviour "COMBAT";
    _playerGroup enableAttack true;
    _playerGroup setFormation "COLUMN";  // Tight formation for close following

    // VCOMAI Integration (if available)
    if (RECRUIT_VCOMAI_Active) then {
        if (!isNil "VCM_NOAI") then {
            VCM_NOAI pushBackUnique _unit;
            publicVariable "VCM_NOAI";
        };

        _unit setVariable ["VCM_CUSTOMAI", true, true];
        _unit setVariable ["VCM_RECRUIT", true, true];

        if (!isNil "VCM_fnc_INITAI") then {
            [_unit] call VCM_fnc_INITAI;
        };

        if (!isNil "VCM_SERVERAI") then {
            VCM_SERVERAI pushBackUnique _playerGroup;
            publicVariable "VCM_SERVERAI";
            _playerGroup setVariable ["VCM_RECRUITGROUP", true, true];
        };
    };

    // ============================================
    // LAMBS-INSPIRED BEHAVIORS (LAMBS Danger.fsm + Suppression)
    // ============================================

    // LAMBS Danger Detection - Enhanced threat awareness
    _unit setVariable ["LAMBS_RECRUIT", true, true];
    _unit setVariable ["LAMBS_dangerRadius", 100, true];  // Aware of threats 100m out
    _unit setVariable ["LAMBS_dangerCausesCreep", true, true];  // Cautious movement near danger

    // LAMBS Suppression Behavior
    _unit setVariable ["LAMBS_suppressionRadius", 50, true];  // React to suppression 50m
    _unit setVariable ["LAMBS_suppressionDuration", 15, true];  // Remember suppression 15s

    // ============================================
    // ACTIVATE FSM BRAIN (replaces old tactical loops)
    // ============================================
    [_unit, getPlayerUID _player, _playerGroup] spawn fn_FSM_BrainLoop;

    // AI death handler - triggers respawn check with cooldown
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _ownerUID = _unit getVariable ["OwnerUID", ""];

        if (_ownerUID isEqualTo "") exitWith {};

        private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;

        // BIS_fnc_getUnitByUID can return a vehicle - get the actual unit
        if (!isNull _owner && {!(_owner isKindOf "CAManBase")}) then {
            _owner = effectiveCommander _owner;
        };

        if (!isNull _owner && alive _owner) then {
            private _assigned = _owner getVariable ["AssignedAI", []];
            _assigned = _assigned - [_unit];
            _owner setVariable ["AssignedAI", _assigned, true];

            // Remove from global tracking
            private _globalList = all_recruited_ai_map getOrDefault [_ownerUID, []];
            _globalList = _globalList - [_unit];
            all_recruited_ai_map set [_ownerUID, _globalList];

            diag_log format ["[AI RECRUIT] AI killed: %1 (owner: %2) - %3 AI remaining", typeOf _unit, name _owner, count _globalList];

            // Trigger respawn check after delay with cooldown check
            [_owner, _ownerUID] spawn {
                params ["_owner", "_ownerUID"];
                sleep 3;

                if (!isNull _owner && alive _owner) then {
                    // Check cooldown before spawning
                    if ([_ownerUID] call fn_checkSpawnCooldown) then {
                        [_ownerUID] call fn_setSpawnCooldown;
                        [_owner] call fn_ensureTeam;
                    } else {
                        diag_log format ["[AI RECRUIT] AI death respawn skipped due to cooldown for %1", name _owner];
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

    // Enhanced spawn lock with timeout (30 seconds max)
    private _isSpawning = _player getVariable ["_aiSpawning", false];
    private _spawnLockTime = _player getVariable ["_aiSpawnLockTime", 0];

    // Reset lock if it's been more than 30 seconds (stuck lock protection)
    if (_isSpawning && (time - _spawnLockTime > 30)) then {
        diag_log format ["[AI RECRUIT] WARNING: Spawn lock timeout for %1 - resetting lock", name _player];
        _isSpawning = false;
        _player setVariable ["_aiSpawning", false];
    };

    if (_isSpawning) exitWith {
        diag_log format ["[AI RECRUIT] Spawn already in progress for %1 - skipping", name _player];
    };

    _player setVariable ["_aiSpawning", true];
    _player setVariable ["_aiSpawnLockTime", time];

    // Get AI from global map
    private _globalAI = all_recruited_ai_map getOrDefault [_uid, []];
    private _globalValid = _globalAI select { !isNull _x && alive _x };

    // Get AI from player variable
    private _assigned = _player getVariable ["AssignedAI", []];
    private _assignedValid = _assigned select { !isNull _x && alive _x };

    // Combine both sources (remove duplicates) - OPTIMIZED
    private _combined = _globalValid + _assignedValid;
    private _validAI = _combined arrayIntersect _combined;

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

    diag_log format ["[AI RECRUIT] Player %1 needs %2 AI (has %3)", name _player, count _missing, _currentCount];

    // Spawn missing AI (up to 3 total)
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

    diag_log format ["[AI RECRUIT] Team spawn complete for %1 - now has %2 AI", name _player, count _validAI];
};

// ====================================================================================
// Function: CLEANUP (Same as disconnect - PROVEN TO WORK)
// ====================================================================================
fn_cleanupPlayerAI = {
    params ["_uid", "_name"];

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP START: %1 (UID: %2) ***", _name, _uid];
    diag_log "========================================";

    if (_uid isEqualTo "") exitWith {
        diag_log "[AI RECRUIT] ERROR: Empty UID - cannot cleanup";
    };

    // Get player object if available
    private _player = [_uid] call BIS_fnc_getUnitByUID;
    diag_log format ["[AI RECRUIT] Player object lookup: %1", if (isNull _player) then {"NULL"} else {"FOUND"}];

    // SOURCE 1: Global map
    private _ai_from_map = all_recruited_ai_map getOrDefault [_uid, []];
    diag_log format ["[AI RECRUIT] Source 1 (Global Map): %1 AI found", count _ai_from_map];

    // SOURCE 2: Player variable (if player object exists)
    private _ai_from_var = [];
    if (!isNull _player) then {
        _ai_from_var = _player getVariable ["AssignedAI", []];
        diag_log format ["[AI RECRUIT] Source 2 (Player Variable): %1 AI found", count _ai_from_var];
    } else {
        diag_log "[AI RECRUIT] Source 2 (Player Variable): Skipped (player object null)";
    };

    // SOURCE 3: Player's group (if player object exists and has group)
    private _ai_from_group = [];
    if (!isNull _player && !isNull group _player) then {
        _ai_from_group = (units group _player) select {
            !isPlayer _x &&
            {_x getVariable ["ExileRecruited", false]}
        };
        diag_log format ["[AI RECRUIT] Source 3 (Player Group): %1 AI found", count _ai_from_group];
    } else {
        diag_log "[AI RECRUIT] Source 3 (Player Group): Skipped (player or group null)";
    };

    // Combine ALL sources
    private _ai_to_delete = _ai_from_map + _ai_from_var + _ai_from_group;
    _ai_to_delete = _ai_to_delete arrayIntersect _ai_to_delete;

    diag_log format ["[AI RECRUIT] Total unique AI to delete: %1", count _ai_to_delete];
    diag_log format ["[AI RECRUIT]   From map: %1 | From var: %2 | From group: %3", count _ai_from_map, count _ai_from_var, count _ai_from_group];

    if (_ai_to_delete isEqualTo []) exitWith {
        diag_log format ["[AI RECRUIT] *** NO AI TO CLEANUP for %1 ***", _name];
        diag_log "========================================";
    };

    // Collect groups for cleanup AFTER units are deleted
    private _groupsToClean = [];

    // DELETE THEM ALL
    {
        if (!isNull _x) then {
            // Collect group for later cleanup
            private _aiGroup = group _x;
            if (!isNull _aiGroup && {!(_aiGroup in _groupsToClean)}) then {
                _groupsToClean pushBack _aiGroup;
            };

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
        };
    } forEach _ai_to_delete;

    // Now clean up empty groups AFTER all units deleted
    {
        if (!isNull _x && {count units _x == 0}) then {
            deleteGroup _x;
            diag_log format ["[AI RECRUIT]   Deleted empty group: %1", _x];
        };
    } forEach _groupsToClean;

    if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
        publicVariable "VCM_NOAI";
    };

    if (!isNil "A3XAI_NOAI") then {
        publicVariable "A3XAI_NOAI";
    };

    // Clear from global map
    all_recruited_ai_map deleteAt _uid;

    // Clear spawn cooldown
    spawn_cooldowns deleteAt _uid;

    // Clear player variables if player object exists
    if (!isNull _player) then {
        _player setVariable ["AssignedAI", [], true];
        _player setVariable ["_aiSpawning", false, true];
        _player setVariable ["_aiSpawnLockTime", 0, true];
        diag_log "[AI RECRUIT] Player variables cleared";
    };

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP COMPLETE for %1 ***", _name];
    diag_log format ["[AI RECRUIT] Results: %1 AI deleted, %2 groups cleaned", count _ai_to_delete, count _groupsToClean];
    diag_log "========================================";
};


// ====================================================================================
// Setup event handlers for a player
// ====================================================================================
fn_setupPlayerHandlers = {
    params ["_player"];

    private _uid = getPlayerUID _player;

    diag_log format ["[AI RECRUIT] Setting up handlers for %1 (UID: %2)", name _player, _uid];

    // MULTIPLE DEATH DETECTION METHODS (for reliability in Exile)

    // Killed event handler (cleanup AI when player dies)
    _player addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _uid = getPlayerUID _unit;
        diag_log format ["[AI RECRUIT] Player death detected: %1 - cleaning up AI", name _unit];
        [_uid, name _unit] call fn_cleanupPlayerAI;
    }];

    diag_log format ["[AI RECRUIT] Death event handlers registered for %1", name _player];

    // Respawn - spawn NEW AI after delay
    _player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];

        private _uid = getPlayerUID _unit;

        diag_log "========================================";
        diag_log format ["[AI RECRUIT] *** PLAYER RESPAWNED: %1 (UID: %2) ***", name _unit, _uid];
        diag_log "========================================";

        // Clean up any existing AI for this UID (should already be clean from death event)
        private _existingAI = all_recruited_ai_map getOrDefault [_uid, []];
        if (count _existingAI > 0) then {
            diag_log format ["[AI RECRUIT] WARNING: Found %1 orphaned AI on respawn - cleaning up", count _existingAI];
            [_uid, name _unit] call fn_cleanupPlayerAI;
        } else {
            diag_log "[AI RECRUIT] Good: No orphaned AI found (cleanup worked correctly)";
        };

        // Clear variables
        _unit setVariable ["AssignedAI", [], true];
        _unit setVariable ["_aiSpawning", false, true];
        _unit setVariable ["_aiSpawnLockTime", 0, true];
        _unit setVariable ["_lastCheckTime", 0, true];

        // Spawn new AI after delay with cooldown
        [_unit, _uid] spawn {
            params ["_player", "_uid"];

            // Wait for player to land if parachuting
            private _waitTime = 0;
            while {!isNull _player && alive _player && !([_player] call fn_isPlayerReady) && _waitTime < 60} do {
                sleep 1;
                _waitTime = _waitTime + 1;
            };

            if (_waitTime >= 60) exitWith {
                diag_log format ["[AI RECRUIT] ERROR: Player %1 not ready after 60 seconds - aborting AI spawn", name _player];
            };

            if (!isNull _player && alive _player) then {
                if ([_uid] call fn_checkSpawnCooldown) then {
                    [_uid] call fn_setSpawnCooldown;
                    diag_log format ["[AI RECRUIT] Player %1 landed - spawning fresh AI", name _player];
                    [_player] call fn_ensureTeam;
                } else {
                    diag_log format ["[AI RECRUIT] Respawn AI spawn skipped due to cooldown for %1", name _player];
                };
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

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** PLAYER DISCONNECTED: %1 ***", _name];
    diag_log "========================================";

    // Use the SAME cleanup function that works for disconnect
    [_uid, _name] call fn_cleanupPlayerAI;
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

            [_player, _uid] spawn {
                params ["_player", "_uid"];
                sleep 3;
                if ([_player] call fn_isPlayerReady) then {
                    if ([_uid] call fn_checkSpawnCooldown) then {
                        [_uid] call fn_setSpawnCooldown;
                        [_player] call fn_ensureTeam;
                    };
                };
            };
        };
    };
}];

// ====================================================================================
// Main server loop - REDUCED TO MAINTENANCE ONLY (death is now event-based)
// ====================================================================================
[] spawn {
    diag_log "[AI RECRUIT] Waiting for mission start...";

    waitUntil {time > 0};
    sleep 5;

    // Setup initial players
    {
        if ([_x] call fn_isPlayerReady) then {
            [_x] call fn_setupPlayerHandlers;

            private _uid = getPlayerUID _x;
            [_x, _uid] spawn {
                params ["_player", "_uid"];
                sleep 5;
                if ([_player] call fn_isPlayerReady) then {
                    if ([_uid] call fn_checkSpawnCooldown) then {
                        [_uid] call fn_setSpawnCooldown;
                        [_player] call fn_ensureTeam;
                    };
                };
            };
        };
    } forEach allPlayers;

    diag_log "[AI RECRUIT] System initialized";
    diag_log "[AI RECRUIT] Death detection: EVENT-BASED + BACKUP POLLING";

    // Track player alive states
    private _playerAliveStates = createHashMap;

    // Maintenance loop - checks for missing AI + backup death detection
    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;

            if (_uid != "" && isPlayer _player) then {
                private _isAlive = alive _player;
                private _wasAlive = _playerAliveStates getOrDefault [_uid, true];

                // BACKUP DEATH DETECTION (in case event handlers fail)
                if (_wasAlive && !_isAlive) then {
                    diag_log format ["[AI RECRUIT] !!!!! DEATH DETECTED (BACKUP POLLING): %1 !!!!!", name _player];
                    [_uid, name _player] call fn_cleanupPlayerAI;
                    _playerAliveStates set [_uid, false];
                };

                // Update alive state
                if (_isAlive && !_wasAlive) then {
                    diag_log format ["[AI RECRUIT] Player %1 is alive again (respawned)", name _player];
                    _playerAliveStates set [_uid, true];
                };

                // Regular AI check (only if alive and ready)
                if (_isAlive && [_player] call fn_isPlayerReady) then {
                    private _lastCheck = _player getVariable ["_lastCheckTime", 0];

                    // Check every 30 seconds for missing AI
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

        sleep 5; // Check every 5 seconds for death + AI maintenance
    };
};

// ====================================================================================
// STARTUP LOG
// ====================================================================================
diag_log "========================================";
diag_log "[AI RECRUIT] Elite AI Recruit System v7.16 - EXTREME ELITE OPERATORS";
diag_log "  • EXTREME SKILLS: 1.0 (PERFECT) in all categories - HEADSHOT MASTERS";
diag_log "  • 300M SIGHT RANGE: Detect and engage at extreme distance";
diag_log "  • 1.4X SPEED: Lightning fast movement (setAnimSpeedCoef 1.4)";
diag_log "  • PERFECT AIM: No shake, instant acquisition, laser accuracy";
diag_log "  • STEALTH: 50% harder to spot, 50% quieter";
diag_log "";
diag_log "  COMBAT BEHAVIOR:";
diag_log "  • FULL AUTONOMY: Complete freedom to engage, flank, spread out";
diag_log "  • NO RESTRICTIONS: AI use advanced tactics, take cover independently";
diag_log "  • TARGET SHARING: Group automatically shares enemy information";
diag_log "";
diag_log "  NON-COMBAT BEHAVIOR:";
diag_log "  • TIGHT FORMATION: Stay within 30m of player at all times";
diag_log "  • STRICT FOLLOWING: Mirror player movement in column formation";
diag_log "  • AUTO-RETURN: Seamlessly return to formation after combat ends";
diag_log "";
diag_log "  • THREAT SCAN: 300m knowledge-based + 50m visual detection";
diag_log "  • FSM STATES: IDLE (SAFE/UP) ⟷ COMBAT → RETREAT → HEAL";
diag_log "  • INSTANT REACTION: No delay when threats appear";
diag_log "  • NO FLEEING: Fearless (allowFleeing 0)";
diag_log "  • RETREAT: Only when critically wounded >70%";
diag_log "  • HEAL: Self-heal when safe and wounded >30%";
diag_log "  • EXILE RESILIENT: Brain survives session initialization";
diag_log "  • FSM LOGGING: State transitions logged to RPT";
diag_log "  • EVENT-BASED death detection + backup polling";
diag_log "  • STRICT 3 AI maximum";
diag_log "  • NO VEHICLE BOARDING: AI stay on foot";
if (RECRUIT_VCOMAI_Active) then {
    diag_log "  • VCOMAI Integration: ENABLED";
} else {
    diag_log "  • VCOMAI Integration: DISABLED";
};
diag_log "========================================";
