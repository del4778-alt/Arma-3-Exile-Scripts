/*
    rmg_ravage_exile_config.sqf - SAFE ZOMBIE RESURRECTION

    v2.7 - ZOMBIE RESURRECTION WITH LIMITS:
        ✅ Zombies can now resurrect (CIVILIAN added to spawn sides)
        ✅ Resurrection limit prevents infinite loops (default: 1 resurrection)
        ✅ Tracks resurrection count per zombie
        ✅ Configurable via maxZombieResurrections

    v2.6 - DEBUG MODE:
        Added comprehensive debug logging to diagnose zombie spawning
*/

if (!isServer) exitWith {};

diag_log "========================================";
diag_log "[RMG:Ravage] Initializing Ravage/Exile integration v2.7...";
diag_log "========================================";

// ========================== CONFIG ==========================
private _CFG = [
    // --- Safe zones (traders)
    ["safeZoneMarkers", ["MafiaTraderCity","TraderZoneSilderas","TraderZoneFolia"]],
    ["safeZoneRadius", 500],

    // --- Zed-on-death behavior
    ["zedClasses", ["zombie_bolter","zombie_walker","zombie_runner"]],
    ["hordeSizeRange", [6, 12]],
    ["spawnDelay", 0.10],
    ["spawnOffset", 1.0],
    ["chanceHorde", 0.10],
    // ✅ ALL AI sides spawn zombies (EAST, WEST, RESISTANCE, CIVILIAN)
    // RECRUIT AI is still EXCLUDED via ExileRecruited check below
    ["spawnFromSides", [east, west, resistance, civilian]],
    ["minPlayerDist", 10],
    // ✅ v2.7: Zombie resurrection limit (prevents infinite loops)
    // 0 = zombies never resurrect, 1 = resurrect once, 2 = twice, etc.
    ["maxZombieResurrections", 1],

    // --- Ambient bandits/scavengers
    ["ambientEnabled", true],
    ["ambientMaxGroups", 6],
    ["ambientGroupSize", [2,4]],
    ["ambientSpawnRadius", [100, 200]],
    ["ambientMinPlayerDist", 300],
    ["ambientDespawnDist", 1000],
    ["ambientPatrolRadius", 250],
    ["ambientRespawnDelay", [60, 120]],
    ["ambientClasses", [
        "I_C_Soldier_Bandit_2_F","I_C_Soldier_Bandit_5_F","I_C_Soldier_Bandit_7_F",
        "I_C_Soldier_Para_2_F","I_C_Soldier_Para_3_F","I_C_Soldier_Para_4_F",
        "O_G_Soldier_F","O_G_Soldier_AR_F","O_G_Soldier_LAT_F"
    ]],

    // --- Performance / safety
    ["globalAICap", 100],

    // --- Zombie faction hostility (zombies are CIVILIAN)
    // All these sides will attack zombies (and zombies attack them)
    ["zombieHostileSides", [east, resistance, west]],

    // --- Zombie kill rewards
    ["zombieKillRewardPoptabs", 200],
    ["zombieKillRewardRespect", 250],

    // --- DEBUG MODE
    ["debugMode", true]  // ✅ ENABLE DEBUG LOGGING
];

// Convert to GLOBAL functions with namespace prefix
RMG_Ravage_CFG = _CFG;

RMG_Ravage_get = {
    params ["_k"];
    private _index = RMG_Ravage_CFG findIf {(_x select 0) isEqualTo _k};
    if (_index == -1) exitWith { nil };
    (RMG_Ravage_CFG select _index) select 1
};

private _get = RMG_Ravage_get;

// =================== ZOMBIE FACTION SETUP ===================
// ✅ Zombies are CIVILIAN - make all sides hostile to them
private _hostileSides = ["zombieHostileSides"] call _get;
{
    civilian setFriend [_x, 0];
    _x setFriend [civilian, 0];
} forEach _hostileSides;

diag_log format ["[RMG:Ravage] Zombie faction relations configured: CIVILIAN hostile to %1", _hostileSides];

// =================== HELPERS ===================
RMG_Ravage_inSafeZone = {
    params ["_pos"];
    private _markers = ["safeZoneMarkers"] call RMG_Ravage_get;
    private _r = ["safeZoneRadius"] call RMG_Ravage_get;
    private _debug = ["debugMode"] call RMG_Ravage_get;

    private _result = false;
    {
        private _mPos = getMarkerPos _x;
        if !(_mPos isEqualTo [0,0,0]) then {
            private _dist = _pos distance2D _mPos;
            if (_dist <= _r) then {
                _result = true;
                if (_debug) then {
                    diag_log format ["[RMG:Ravage:DEBUG] Position in safe zone '%1' (dist: %2m, radius: %3m)",
                        _x, round _dist, _r];
                };
            };
        };
    } forEach _markers;

    if (!_result && _debug) then {
        diag_log "[RMG:Ravage:DEBUG] Position NOT in any safe zone";
    };

    _result
};

RMG_Ravage_nearestPlayerDist = {
    params ["_pos"];
    if (count allPlayers == 0) exitWith { 99999 };
    private _d = 99999;
    {
        private _dd = _pos distance2D (getPosATL _x);
        if (_dd < _d) then { _d = _dd };
    } forEach allPlayers;
    _d
};

// DISABLED - Let Exile handle AI cleanup instead of Ravage
// This was causing aggressive deletion of AI units immediately after spawning
RMG_Ravage_capCull = {
    // Disabled - no cleanup performed
    // Let Exile's native cleanup system handle this instead
};

RMG_Ravage_spawnZed = {
    params ["_cls", "_pos"];

    private _debug = ["debugMode"] call RMG_Ravage_get;

    if (_debug) then {
        diag_log format ["[RMG:Ravage:DEBUG] Attempting to spawn zombie: %1 at %2", _cls, _pos];
    };

    if ([_pos] call RMG_Ravage_inSafeZone) exitWith {
        if (_debug) then {
            diag_log "[RMG:Ravage:DEBUG] Spawn blocked: In safe zone";
        };
        objNull
    };

    if ((["minPlayerDist"] call RMG_Ravage_get) > 0) then {
        private _pDist = [_pos] call RMG_Ravage_nearestPlayerDist;
        if (_pDist < (["minPlayerDist"] call RMG_Ravage_get)) exitWith {
            if (_debug) then {
                diag_log format ["[RMG:Ravage:DEBUG] Spawn blocked: Too close to player (%1m < %2m required)",
                    round _pDist, ["minPlayerDist"] call RMG_Ravage_get];
            };
            objNull
        };
    };

    private _grp = createGroup [civilian, true];
    if (isNull _grp) exitWith {
        diag_log "[RMG:Ravage:ERROR] Failed to create civilian group!";
        objNull
    };

    private _spawnPos = [(_pos select 0), (_pos select 1), (_pos select 2) + (["spawnOffset"] call RMG_Ravage_get)];
    private _u = _grp createUnit [_cls, _spawnPos, [], 0, "NONE"];

    if (isNull _u) exitWith {
        diag_log format ["[RMG:Ravage:ERROR] Failed to create zombie unit: %1", _cls];
        objNull
    };

    // ✅ Ravage zombie initialization
    if (!isNil "rvg_fnc_infectCivilian") then {
        [_u] call rvg_fnc_infectCivilian;
        if (_debug) then {
            diag_log format ["[RMG:Ravage:DEBUG] Called rvg_fnc_infectCivilian on %1", _u];
        };
    } else {
        diag_log "[RMG:Ravage:WARNING] rvg_fnc_infectCivilian not found - Ravage mod loaded?";
    };

    // ✅ v2.7: Initialize resurrection counter (starts at 0)
    _u setVariable ["RMG_ResurrectionCount", 0, true];

    if (_debug) then {
        diag_log format ["[RMG:Ravage:DEBUG] ✓ Zombie spawned successfully: %1 (side: %2)", typeOf _u, side _u];
    };

    _u
};

private _inSafeZone = RMG_Ravage_inSafeZone;
private _nearestPlayerDist = RMG_Ravage_nearestPlayerDist;
private _capCull = RMG_Ravage_capCull;
private _spawnZed = RMG_Ravage_spawnZed;

// ====================== COMBINED ENTITY KILLED HANDLER =====================
diag_log "[RMG:Ravage] Registering combined EntityKilled event handler...";

addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator", "_useEffects"];

    private _debug = ["debugMode"] call RMG_Ravage_get;

    // Determine actual killer for rewards
    private _actualKiller = if (!isNull _instigator && {isPlayer _instigator}) then {
        _instigator
    } else {
        _killer
    };

    // ========== PART 1: ZOMBIE KILL REWARDS ==========
    if (!isNull _killed && {!isNull _actualKiller} && {isPlayer _actualKiller}) then {
        private _zedClasses = ["zedClasses"] call RMG_Ravage_get;
        private _killedType = typeOf _killed;

        // ✅ Check if killed unit is a zombie (CIVILIAN side + correct classname)
        if (side _killed == civilian && {_killedType in _zedClasses}) then {
            private _poptabs = ["zombieKillRewardPoptabs"] call RMG_Ravage_get;
            private _respect = ["zombieKillRewardRespect"] call RMG_Ravage_get;

            if (_poptabs > 0) then {
                _actualKiller setVariable ["ExileMoney", (_actualKiller getVariable ["ExileMoney", 0]) + _poptabs, true];
            };

            if (_respect > 0) then {
                _actualKiller setVariable ["ExileScore", (_actualKiller getVariable ["ExileScore", 0]) + _respect, true];
            };

            if (_poptabs > 0 || _respect > 0) then {
                private _msg = format ["Zombie Kill: +%1 Poptabs, +%2 Respect", _poptabs, _respect];
                [["Success", _msg], "ExileClient_system_notification_create", _actualKiller, true] call ExileServer_system_network_send_to;
            };

            diag_log format ["[RMG:Ravage] Player %1 killed zombie %2: +%3 poptabs, +%4 respect",
                name _actualKiller, _killedType, _poptabs, _respect];
        };
    };

    // ========== PART 2: ZOMBIE RESURRECTION ==========
    if (_debug) then {
        diag_log "=================================================";
        diag_log format ["[RMG:Ravage:DEBUG] EntityKilled fired: %1", name _killed];
        diag_log format ["  - Type: %1", typeOf _killed];
        diag_log format ["  - Side: %1", side _killed];
        diag_log format ["  - Is CAManBase: %1", _killed isKindOf "CAManBase"];
        diag_log format ["  - Is Player: %1", isPlayer _killed];
    };

    if (!isNull _killed && {_killed isKindOf "CAManBase"} && {!isPlayer _killed}) then {

        // ✅ Explicit recruit AI exclusion
        private _isRecruitAI = _killed getVariable ["ExileRecruited", false];

        if (_debug) then {
            diag_log format ["  - ExileRecruited: %1", _isRecruitAI];
        };

        if (_isRecruitAI) exitWith {
            diag_log format ["[RMG:Ravage] Recruit AI death ignored: %1 (no zombie spawn)", name _killed];
        };

        // ✅ A3XAI hostage exclusion - Don't spawn zombies from mission hostages
        // NOTE: Regular A3XAI units (EAST) SHOULD spawn zombies - this helps players!
        private _isHostage = _killed getVariable ["A3XAI_hostage", false];

        if (_debug) then {
            diag_log format ["  - A3XAI Hostage: %1", _isHostage];
        };

        if (_isHostage) exitWith {
            diag_log format ["[RMG:Ravage] A3XAI hostage death ignored: %1 (no zombie spawn)", name _killed];
        };

        // ✅ v2.7: Check zombie resurrection limit (prevents infinite loops)
        // Use flag variable to control spawn logic
        private _allowSpawn = true;

        if (side _killed == civilian) then {
            private _resCount = _killed getVariable ["RMG_ResurrectionCount", 0];
            private _maxRes = ["maxZombieResurrections"] call RMG_Ravage_get;

            if (_debug) then {
                diag_log format ["[RMG:Ravage:DEBUG] Zombie death detected: %1", name _killed];
                diag_log format ["  - Resurrection count: %1 / %2 max", _resCount, _maxRes];
            };

            // ✅ CRITICAL FIX: Set flag to prevent spawning if limit reached
            if (_resCount >= _maxRes) then {
                _allowSpawn = false;
                if (_debug) then {
                    diag_log format ["[RMG:Ravage] Zombie %1 reached resurrection limit (%2/%3) - NO SPAWN",
                        name _killed, _resCount, _maxRes];
                    diag_log "=================================================";
                };
            } else {
                // ✅ Zombie can still resurrect - increment counter for next spawn
                if (_debug) then {
                    diag_log format ["[RMG:Ravage] Zombie %1 can resurrect (%2/%3) - SPAWNING",
                        name _killed, _resCount, _maxRes];
                };
            };
        };

        // Check if side is allowed to resurrect
        private _sides = ["spawnFromSides"] call RMG_Ravage_get;
        private _killedSide = side _killed;

        if (_debug) then {
            diag_log format ["  - Allowed sides: %1", _sides];
            diag_log format ["  - Killed side: %1", _killedSide];
            diag_log format ["  - Side match: %1", _killedSide in _sides];
            diag_log format ["  - Allow spawn: %1", _allowSpawn];
        };

        if (_killedSide in _sides && _allowSpawn) then {
            private _pos = getPosATL _killed;
            private _killedName = name _killed;
            // ✅ v2.7: Get resurrection counter from parent zombie (or 0 if non-zombie)
            private _parentResCount = _killed getVariable ["RMG_ResurrectionCount", 0];

            if (_debug) then {
                diag_log format ["[RMG:Ravage:DEBUG] ✓ ZOMBIE SPAWN CONDITIONS MET for %1", _killedName];
                diag_log format ["  - Position: %1", _pos];
                diag_log format ["  - Parent resurrection count: %1", _parentResCount];
                diag_log "  - Spawning thread started...";
            };

            // Spawn in new thread for sleep commands
            [_pos, _killedName, _parentResCount, _debug] spawn {
                params ["_pos", "_killedName", "_parentResCount", "_debug"];

                if (_debug) then {
                    diag_log format ["[RMG:Ravage:DEBUG] Spawn thread running for %1", _killedName];
                };

                // Check safe zone
                if ([_pos] call RMG_Ravage_inSafeZone) exitWith {
                    diag_log format ["[RMG:Ravage] Zombie spawn blocked - %1 died in safe zone", _killedName];
                };

                // Delay for drama
                private _delay = ["spawnDelay"] call RMG_Ravage_get;
                if (_debug) then {
                    diag_log format ["[RMG:Ravage:DEBUG] Waiting %1s before spawn...", _delay];
                };
                uiSleep _delay;

                // Horde chance
                private _hordeChance = ["chanceHorde"] call RMG_Ravage_get;
                private _pool = ["zedClasses"] call RMG_Ravage_get;
                private _roll = random 1;

                if (_debug) then {
                    diag_log format ["[RMG:Ravage:DEBUG] Horde roll: %1 (threshold: %2)", _roll, _hordeChance];
                };

                if (_roll < _hordeChance) then {
                    // HORDE SPAWN
                    private _minMax = ["hordeSizeRange"] call RMG_Ravage_get;
                    private _count = floor ( (_minMax select 0) + random ((_minMax select 1) - (_minMax select 0) + 1) );
                    private _rad = 8 max (_count * 0.7);

                    diag_log format ["[RMG:Ravage] ★★★ SPAWNING HORDE: %1 zombies from %2 ★★★", _count, _killedName];

                    for "_i" from 1 to _count do {
                        private _pick = selectRandom _pool;
                        private _theta = random 360;
                        private _r = random _rad;
                        private _p = [_pos select 0, _pos select 1, _pos select 2];
                        _p set [0, (_p select 0) + (sin _theta) * _r];
                        _p set [1, (_p select 1) + (cos _theta) * _r];

                        private _zombie = [_pick, _p] call RMG_Ravage_spawnZed;

                        if (!isNull _zombie) then {
                            // ✅ v2.7: Inherit and increment resurrection counter
                            _zombie setVariable ["RMG_ResurrectionCount", _parentResCount + 1, true];
                        };

                        if (_debug) then {
                            if (isNull _zombie) then {
                                diag_log format ["[RMG:Ravage:DEBUG] Horde zombie #%1 FAILED", _i];
                            } else {
                                diag_log format ["[RMG:Ravage:DEBUG] Horde zombie #%1 OK: %2 (ResCount: %3)",
                                    _i, typeOf _zombie, _parentResCount + 1];
                            };
                        };

                        // Small delay between spawns to allow network sync (reduces "Object not found" spam)
                        uiSleep 0.1;
                    };
                } else {
                    // SINGLE SPAWN
                    diag_log format ["[RMG:Ravage] ★ SPAWNING SINGLE ZOMBIE from %1 ★", _killedName];

                    private _pick = selectRandom _pool;
                    private _zombie = [_pick, _pos] call RMG_Ravage_spawnZed;

                    if (!isNull _zombie) then {
                        // ✅ v2.7: Inherit and increment resurrection counter
                        _zombie setVariable ["RMG_ResurrectionCount", _parentResCount + 1, true];
                    };

                    if (_debug) then {
                        if (isNull _zombie) then {
                            diag_log "[RMG:Ravage:DEBUG] Single zombie spawn FAILED!";
                        } else {
                            diag_log format ["[RMG:Ravage:DEBUG] Single zombie spawn OK: %1 (ResCount: %2)",
                                typeOf _zombie, _parentResCount + 1];
                        };
                    };
                };

                call RMG_Ravage_capCull;

                if (_debug) then {
                    diag_log "[RMG:Ravage:DEBUG] Spawn thread complete";
                };
            };
        } else {
            if (_debug) then {
                diag_log format ["[RMG:Ravage:DEBUG] ✗ Side %1 not in allowed list - no zombie spawn", _killedSide];
            };
        };
    } else {
        if (_debug) then {
            diag_log "[RMG:Ravage:DEBUG] ✗ Not a valid AI death (null/player/not CAManBase)";
        };
    };

    if (_debug) then {
        diag_log "=================================================";
    };
}];

diag_log "[RMG:Ravage] Combined EntityKilled handler registered successfully!";

// ================== AMBIENT BANDITS / SCAVENGERS =================
if (["ambientEnabled"] call _get) then {
    [_CFG, _inSafeZone, _nearestPlayerDist, _capCull] spawn {
        params ["_CFG", "_inSafeZone", "_nearestPlayerDist", "_capCull"];

        private _get = {
            params ["_k"];
            private _index = _CFG findIf {(_x select 0) isEqualTo _k};
            if (_index == -1) exitWith { nil };
            (_CFG select _index) select 1
        };

        private _maxGroups = ["ambientMaxGroups"] call _get;
        private _aliveGroups = [];

        while {true} do {
            _aliveGroups = _aliveGroups select { alive leader _x && {(count units _x) > 0} };

            if ((count _aliveGroups) < _maxGroups && {count allPlayers > 0}) then {
                private _anchor = selectRandom allPlayers;
                private _spawnR = ["ambientSpawnRadius"] call _get;
                private _dist = (_spawnR select 0) + random ((_spawnR select 1) - (_spawnR select 0));
                private _ang = random 360;
                private _pos = (getPos _anchor) getPos [ _dist, _ang ];

                if ([_pos] call _inSafeZone) then { uiSleep 3; continue };
                if (([_pos] call _nearestPlayerDist) < (["ambientMinPlayerDist"] call _get)) then { uiSleep 3; continue };

                private _size = ["ambientGroupSize"] call _get;
                private _n = floor ( (_size select 0) + random ((_size select 1) - (_size select 0) + 1) );
                private _clsPool = ["ambientClasses"] call _get;

                // FIX: Changed from resistance to EAST to match A3XAI (prevents AI infighting)
                private _grp = createGroup [EAST, true];
                for "_i" from 1 to _n do {
                    private _c = selectRandom _clsPool;
                    _grp createUnit [_c, _pos, [], 5, "NONE"];
                };

                // Simple patrol
                private _pr = ["ambientPatrolRadius"] call _get;
                for "_w" from 1 to 4 do {
                    private _wpPos = _pos getPos [ random _pr, random 360 ];
                    private _wp = _grp addWaypoint [_wpPos, 0];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointBehaviour "AWARE";
                    _wp setWaypointCombatMode "YELLOW";
                    _wp setWaypointSpeed "LIMITED";
                    _wp setWaypointFormation "STAG COLUMN";
                };
                (_grp addWaypoint [_pos, 0]) setWaypointType "CYCLE";

                _aliveGroups pushBack _grp;

                call _capCull;
            };

            // Despawn logic
            private _despawnDist = ["ambientDespawnDist"] call _get;
            {
                private _g = _x;
                private _lead = leader _g;
                if (!isNull _lead) then {
                    private _pDist = [getPosATL _lead] call _nearestPlayerDist;
                    if (_pDist > _despawnDist) then {
                        { deleteVehicle _x } forEach units _g;
                        deleteGroup _g;
                    };
                };
            } forEach +_aliveGroups;

            uiSleep ( (["ambientRespawnDelay"] call _get) call {
                params ["_min","_max"]; _min + random (_max - _min)
            });
        };
    };
};

diag_log "========================================";
diag_log "[RMG:Ravage] Exile integration complete - v2.7";
diag_log "[RMG:Ravage] - Zombie resurrection: ACTIVE WITH LIMITS";
diag_log format ["[RMG:Ravage] - Max resurrections per zombie: %1", ["maxZombieResurrections"] call RMG_Ravage_get];
diag_log "[RMG:Ravage] - Zombies: CIVILIAN side (zombie_bolter, zombie_walker, zombie_runner)";
diag_log "[RMG:Ravage] - Recruit AI exclusion: ENABLED (no resurrection)";
diag_log "[RMG:Ravage] - Spawn sides: EAST, CIVILIAN (ambient bandits now EAST to match A3XAI)";
diag_log "[RMG:Ravage] - Zombie kill rewards: ACTIVE";
diag_log "[RMG:Ravage] - Ambient bandits: ACTIVE";
diag_log "[RMG:Ravage] - Faction hostility: ALL vs CIVILIAN zombies";
diag_log format ["[RMG:Ravage] - DEBUG MODE: %1", if (["debugMode"] call RMG_Ravage_get) then {"ENABLED"} else {"DISABLED"}];
diag_log "[RMG:Ravage] All systems operational.";
diag_log "========================================";