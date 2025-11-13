/*
    rmg_ravage_exile_config.sqf

    Ravage Mod Integration for Exile

    Features:
    - Zombie resurrection system (AI death -> zombie spawn)
    - 90% single zombie, 10% horde (6-12 zombies)
    - Ambient bandit/scavenger patrols
    - Trader zone protection (no spawns in safe zones)
    - Zombie faction hostility (EAST, RESISTANCE, WEST attack zombies)
    - Zombie kill rewards (100 poptabs + 250 respect per kill)
    - Performance optimized with AI cap culling
    - Server-side only execution

    Author: RMG
    Version: 2.3 - SUSPENSION FIX (Spawn wrapper for uiSleep)
*/

if (!isServer) exitWith {};

diag_log "========================================";
diag_log "[RMG:Ravage] Initializing Ravage/Exile integration v2.3...";
diag_log "========================================";

// ========================== CONFIG ==========================
private _CFG = [
    // --- Safe zones (traders)
    ["safeZoneMarkers", ["MafiaTraderCity","TraderZoneSilderas","TraderZoneFolia"]],
    ["safeZoneRadius", 500],  // matches your trader zone radius

    // --- Zed-on-death behavior
    ["zedClasses", ["zombie_runner","zombie_bolter","zombie_walker"]],   // <- your classes
    ["hordeSizeRange", [6, 12]],      // inclusive min,max for 10% horde
    ["spawnDelay", 0.10],             // seconds after death before spawn
    ["spawnOffset", 1.0],             // lift above ground to avoid clipping
    ["chanceHorde", 0.10],            // 10%
    ["spawnFromSides", [east, resistance, west]], // AI sides that can resurrect
    // NOTE: Recruit AI are usually 'resistance'. A3XAI are typically 'east'.
    // Add 'civilian' here if you want civilian-side AI to resurrect
    ["minPlayerDist", 10],            // don't spawn if a player is closer than this

    // --- Ambient bandits/scavengers
    ["ambientEnabled", true],
    ["ambientMaxGroups", 6],
    ["ambientGroupSize", [2,4]],
    ["ambientSpawnRadius", [100, 200]], // from a random online player
    ["ambientMinPlayerDist", 300],
    ["ambientDespawnDist", 1000],
    ["ambientPatrolRadius", 250],
    ["ambientRespawnDelay", [60, 120]],  // seconds
    // vanilla light bandit/scav classes (edit to taste or to RHS/CUP etc.)
    ["ambientClasses", [
        "I_C_Soldier_Bandit_2_F","I_C_Soldier_Bandit_5_F","I_C_Soldier_Bandit_7_F",
        "I_C_Soldier_Para_2_F","I_C_Soldier_Para_3_F","I_C_Soldier_Para_4_F",
        "O_G_Soldier_F","O_G_Soldier_AR_F","O_G_Soldier_LAT_F"
    ]],

    // --- Performance / safety
    ["globalAICap", 80],  // hard ceiling for all non-player units (bandits + zeds)

    // --- Zombie faction hostility (sides that will attack zombies)
    ["zombieHostileSides", [east, resistance, west]],  // All AI factions hostile to zombies

    // --- Zombie kill rewards (Exile)
    ["zombieKillRewardPoptabs", 200],   // poptabs per zombie kill
    ["zombieKillRewardRespect", 250]    // respect per zombie kill
];

// Convert to GLOBAL functions with namespace prefix for event handler access
RMG_Ravage_CFG = _CFG;

RMG_Ravage_get = {
    params ["_k"];
    private _index = RMG_Ravage_CFG findIf {(_x select 0) isEqualTo _k};
    if (_index == -1) exitWith { nil };
    (RMG_Ravage_CFG select _index) select 1
};

// Local alias for convenience (most code uses this)
private _get = RMG_Ravage_get;

// =================== ZOMBIE FACTION SETUP ===================
// Make zombies (CIVILIAN side) hostile to configured AI sides
// This ensures AI factions will attack zombies on sight
private _hostileSides = ["zombieHostileSides"] call _get;
{
    civilian setFriend [_x, 0];  // zombies hostile to this side
    _x setFriend [civilian, 0];  // this side hostile to zombies
} forEach _hostileSides;

diag_log format ["[RMG:Ravage] Zombie faction relations configured: CIVILIAN hostile to %1", _hostileSides];

// =================== ZOMBIE KILL REWARDS ====================
// Reward players for killing zombies (Exile integration)
// Adds poptabs and respect, prevents negative effects for killing CIVILIAN zombies
addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator", "_useEffects"];

    // Determine the actual player (handle vehicle kills)
    private _actualKiller = if (!isNull _instigator && {isPlayer _instigator}) then { _instigator } else { _killer };

    // Check if a player killed a zombie
    if (!isNull _killed && {!isNull _actualKiller} && {isPlayer _actualKiller}) then {
        private _zedClasses = ["zedClasses"] call RMG_Ravage_get;
        private _killedType = typeOf _killed;

        // Is the killed unit a zombie?
        if (_killedType in _zedClasses) then {
            private _poptabs = ["zombieKillRewardPoptabs"] call RMG_Ravage_get;
            private _respect = ["zombieKillRewardRespect"] call RMG_Ravage_get;

            // Add poptabs to player's account
            if (_poptabs > 0) then {
                _actualKiller setVariable ["ExileMoney", (_actualKiller getVariable ["ExileMoney", 0]) + _poptabs, true];
            };

            // Add respect to player's score
            if (_respect > 0) then {
                _actualKiller setVariable ["ExileScore", (_actualKiller getVariable ["ExileScore", 0]) + _respect, true];
            };

            // Notify player
            if (_poptabs > 0 || _respect > 0) then {
                private _msg = format ["Zombie Kill: +%1 Poptabs, +%2 Respect", _poptabs, _respect];
                [["Success", _msg], "ExileClient_system_notification_create", _actualKiller, true] call ExileServer_system_network_send_to;
            };

            diag_log format ["[RMG:Ravage] Player %1 killed zombie %2: +%3 poptabs, +%4 respect",
                name _actualKiller, _killedType, _poptabs, _respect];
        };
    };
}];

diag_log "[RMG:Ravage] Zombie kill reward system initialized";

// ========================= HELPERS ==========================
// Make helper functions GLOBAL for event handler access
RMG_Ravage_inSafeZone = {
    params ["_pos"];
    private _markers = ["safeZoneMarkers"] call RMG_Ravage_get;
    private _r = ["safeZoneRadius"] call RMG_Ravage_get;
    {
        private _mPos = getMarkerPos _x;
        if !(_mPos isEqualTo [0,0,0]) then {
            if ((_pos distance2D _mPos) <= _r) exitWith { true };
        };
    } forEach _markers;
    false
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

RMG_Ravage_capCull = {
    // Cull farthest non-player AI if we exceed the cap.
    private _cap = ["globalAICap"] call RMG_Ravage_get;
    private _units = allUnits select { !isPlayer _x && alive _x };
    private _over = (count _units) - _cap;
    if (_over <= 0) exitWith {};
    private _center = if (count allPlayers > 0) then { getPosASL (allPlayers select 0) } else { [0,0,0] };
    // Create [distance, unit] pairs and sort by distance (farthest first)
    private _pairs = _units apply { [_x distance2D _center, _x] };
    _pairs sort false;
    private _culled = 0;
    {
        deleteVehicle (_x select 1);
        _culled = _culled + 1;
        if (_culled >= _over) exitWith {};
    } forEach _pairs;
    diag_log format ["[RMG:Ravage] Culled %1 entities over cap %2.", _culled, _cap];
};

// spawn one zed of given class at pos, call ravage init if present
RMG_Ravage_spawnZed = {
    params ["_cls", "_pos"];
    if ([_pos] call RMG_Ravage_inSafeZone) exitWith { objNull };
    if ((["minPlayerDist"] call RMG_Ravage_get) > 0) then {
        if (([_pos] call RMG_Ravage_nearestPlayerDist) < (["minPlayerDist"] call RMG_Ravage_get)) exitWith { objNull };
    };

    private _grp = createGroup [civilian, true];  // zeds usually don't need command side
    private _u = _grp createUnit [_cls, [(_pos select 0), (_pos select 1), (_pos select 2) + (["spawnOffset"] call RMG_Ravage_get)], [], 0, "NONE"];
    if (!isNil "rvg_fnc_zed_init") then { [_u] spawn rvg_fnc_zed_init; };
    _u
};

// Local aliases for backward compatibility
private _inSafeZone = RMG_Ravage_inSafeZone;
private _nearestPlayerDist = RMG_Ravage_nearestPlayerDist;
private _capCull = RMG_Ravage_capCull;
private _spawnZed = RMG_Ravage_spawnZed;

// ====================== ZED RESURRECTION =====================
diag_log "[RMG:Ravage] Registering zombie resurrection event handler...";

addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator", "_useEffects"];

    // Only non-player AI on allowed sides resurrect
    if (!isNull _killed && {_killed isKindOf "CAManBase"} && {!isPlayer _killed}) then {
        private _sides = ["spawnFromSides"] call RMG_Ravage_get;
        private _killedSide = side _killed;
        
        // DEBUG: Log all AI deaths with their side
        diag_log format ["[RMG:Ravage] AI killed: %1 (Type: %2, Side: %3)", 
            name _killed, typeOf _killed, _killedSide];
        
        if (_killedSide in _sides) then {
            private _pos = getPosATL _killed;
            private _killedName = name _killed;
            
            // SPAWN a new thread so we can use sleep commands
            [_pos, _killedName] spawn {
                params ["_pos", "_killedName"];
                
                // Check safe zone
                if ([_pos] call RMG_Ravage_inSafeZone) exitWith {
                    diag_log format ["[RMG:Ravage] Zombie spawn blocked - %1 died in safe zone", _killedName];
                };

                // delay a bit for drama
                uiSleep (["spawnDelay"] call RMG_Ravage_get);

                // chance split: 10% horde, 90% single
                private _hordeChance = ["chanceHorde"] call RMG_Ravage_get;
                private _pool = ["zedClasses"] call RMG_Ravage_get;

                if ((random 1) < _hordeChance) then {
                    private _minMax = ["hordeSizeRange"] call RMG_Ravage_get;
                    private _count = floor ( (_minMax select 0) + random ((_minMax select 1) - (_minMax select 0) + 1) );
                    private _rad = 8 max (_count * 0.7);
                    diag_log format ["[RMG:Ravage] Spawning HORDE of %1 zombies from %2", _count, _killedName];
                    for "_i" from 1 to _count do {
                        private _pick = selectRandom _pool;
                        private _theta = random 360;
                        private _r = random _rad;
                        private _p = [_pos select 0, _pos select 1, _pos select 2];
                        _p set [0, (_p select 0) + (sin _theta) * _r];
                        _p set [1, (_p select 1) + (cos _theta) * _r];
                        [_pick, _p] call RMG_Ravage_spawnZed;
                    };
                } else {
                    diag_log format ["[RMG:Ravage] Spawning single zombie from %1", _killedName];
                    private _pick = selectRandom _pool;
                    [_pick, _pos] call RMG_Ravage_spawnZed;
                };

                call RMG_Ravage_capCull;
            };
        } else {
            diag_log format ["[RMG:Ravage] Zombie spawn SKIPPED - %1 is on side %2 (not in allowed sides: %3)", 
                name _killed, _killedSide, _sides];
        };
    };
}];

diag_log "[RMG:Ravage] Zombie resurrection event handler registered successfully!";

// ================== AMBIENT BANDITS / SCAVENGERS =================
if (["ambientEnabled"] call _get) then {
    [_CFG, _inSafeZone, _nearestPlayerDist, _capCull] spawn {
        params ["_CFG", "_inSafeZone", "_nearestPlayerDist", "_capCull"];
        
        // Recreate _get function in this scope
        private _get = {
            params ["_k"];
            private _index = _CFG findIf {(_x select 0) isEqualTo _k};
            if (_index == -1) exitWith { nil };
            (_CFG select _index) select 1
        };
        
        private _maxGroups = ["ambientMaxGroups"] call _get;
        private _aliveGroups = [];

        while {true} do {
            // Clean dead/empty
            _aliveGroups = _aliveGroups select { alive leader _x && {(count units _x) > 0} };

            if ((count _aliveGroups) < _maxGroups && {count allPlayers > 0}) then {
                private _anchor = selectRandom allPlayers;
                private _spawnR = ["ambientSpawnRadius"] call _get;
                private _dist = (_spawnR select 0) + random ((_spawnR select 1) - (_spawnR select 0));
                private _ang = random 360;
                private _pos = (getPos _anchor) getPos [ _dist, _ang ];

                // respect min player dist and safe zones
                if ([_pos] call _inSafeZone) then { uiSleep 3; continue };
                if (([_pos] call _nearestPlayerDist) < (["ambientMinPlayerDist"] call _get)) then { uiSleep 3; continue };

                private _size = ["ambientGroupSize"] call _get;
                private _n = floor ( (_size select 0) + random ((_size select 1) - (_size select 0) + 1) );
                private _clsPool = ["ambientClasses"] call _get;

                private _grp = createGroup [resistance, true];
                for "_i" from 1 to _n do {
                    private _c = selectRandom _clsPool;
                    _grp createUnit [_c, _pos, [], 5, "NONE"];
                };

                // simple patrol
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

                // soft cap cull if needed
                call _capCull;
            };

            // Despawn logic for far groups
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
diag_log "[RMG:Ravage] Exile integration complete!";
diag_log "[RMG:Ravage] - Zombie resurrection: ACTIVE";
diag_log "[RMG:Ravage] - Zombie kill rewards: ACTIVE";
diag_log "[RMG:Ravage] - Ambient bandits: ACTIVE";
diag_log "[RMG:Ravage] - Faction hostility: CONFIGURED";
diag_log "[RMG:Ravage] All systems operational.";
diag_log "========================================";