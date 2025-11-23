/*
    A3XAI Elite - Master Spawn Loop
    Main loop that handles AI spawning, cell management, and mission triggers

    v3.14: Player Proximity Trigger System
        - AI only spawns when players enter town areas (400m default)
        - AI despawns when all players leave (800m + 5min delay)
        - Much more efficient than random spawning
        - Configurable trigger/despawn radii and delays

    v3.13: Town Spawn Limits & Cooldowns
        - Per-town group limit (default 2 groups = 8 AI max per town)
        - Per-town respawn cooldown (default 15 minutes)
        - Tracks active groups per town, cleans up dead groups
        - Prevents aggressive spawn stacking in towns

    v3.6: Town-based Infantry & Player Scaling
        - Infantry now spawns in towns/villages (like original A3XAI)
        - Dynamic AI limit: 50 base + 20 per player online
        - Only 2 initial infantry patrols (reduced from 4)
        - Expanded town list: Kavala, Zaros, Pyrgos, Sofia, Syrta, Athira, Rodopoli, Agios Dionysios

    v3.5: Infantry Spawn Improvements
        - Reduced startup delay from 180s to 60s
        - Increased infantry spawn chance from 60% to 80%
        - Added initial infantry patrols at startup
        - Infantry now spawns faster and more reliably

    v3.4: Ground-only DyCE (no helis/tanks)
        - Armed convoys, troop transports, supply trucks
        - Police/Gendarmerie themed units
        - Exile toast notifications + map markers
        - Integrated from: https://github.com/ExiledHeisenberg/DyCE

    v3.2: Highway Patrol System
        - Highway patrols spawn between Exile spawn zones
        - Up to 4 highway patrols active at once
        - New patrol every 5 minutes
        - Dynamic routes on major road corridors

    v3.1: Mission Scheduler
        - Wait 3 minutes after first player for server to settle
        - Spawn 3 missions at startup
        - Replace completed missions on schedule (15 min interval)
*/

if (!isServer) exitWith {};

waitUntil {!isNil "A3XAI_initialized" && {A3XAI_initialized}};

[3, "Master spawn loop started"] call A3XAI_fnc_log;

// ============================================
// MISSION SCHEDULER CONFIGURATION
// ============================================
private _loopInterval = 30;              // Main loop runs every 30 seconds
private _startupDelay = 60;              // 1 minute (60 seconds) startup delay (was 180)
private _maxConcurrentMissions = 3;      // Max missions active at once
private _missionCheckInterval = 900;     // Check/spawn missions every 15 minutes
private _lastMissionCheck = 0;
private _missionsInitialized = false;
private _firstPlayerTime = -1;

// Legacy compatibility
private _lastMissionSpawn = 0;
private _missionSpawnInterval = 600;

// ============================================
// HIGHWAY PATROL CONFIGURATION
// ============================================
private _highwayPatrolInterval = 300;    // Spawn highway patrol every 5 minutes
private _lastHighwayPatrol = 0;
private _maxHighwayPatrols = 4;          // Max concurrent highway patrols
private _highwayPatrolsSpawned = 0;

// ============================================
// DyCE DYNAMIC CONVOY CONFIGURATION
// ============================================
private _dyceInterval = 180;             // Check DyCE spawn every 3 minutes (was 2)
private _lastDyceCheck = 0;
private _dyceInitialized = false;
private _dyceConvoyTypes = ["armedConvoy", "troopConvoy", "supplyTruck"];
private _maxDyceConvoys = 3;             // Max 3 convoys total on map

[3, format ["Mission scheduler: %1s startup delay, max %2 missions, %3s check interval",
    _startupDelay, _maxConcurrentMissions, _missionCheckInterval]] call A3XAI_fnc_log;
[3, "DyCE Dynamic Convoy Events enabled"] call A3XAI_fnc_log;

// ============================================
// v3.13: TOWN SPAWN LIMIT HELPERS
// ============================================

// Get current active groups in a town (removes dead/empty groups from tracking)
private _fnc_getTownGroups = {
    params ["_townName"];

    private _groups = A3XAI_townSpawns getOrDefault [_townName, []];

    // Filter out dead/empty groups
    private _activeGroups = _groups select {
        !isNull _x && {{alive _x} count units _x > 0}
    };

    // Update tracking with cleaned list
    if (count _activeGroups != count _groups) then {
        A3XAI_townSpawns set [_townName, _activeGroups];
        [4, format ["[TownSpawn] Cleaned %1: %2 active groups (was %3)", _townName, count _activeGroups, count _groups]] call A3XAI_fnc_log;
    };

    _activeGroups
};

// Check if town can accept more spawns
private _fnc_canSpawnInTown = {
    params ["_townName"];

    // Check cooldown first
    private _lastSpawn = A3XAI_townCooldowns getOrDefault [_townName, 0];
    private _timeSince = time - _lastSpawn;
    private _cooldown = if (!isNil "A3XAI_townRespawnCooldown") then {A3XAI_townRespawnCooldown} else {900};

    if (_timeSince < _cooldown) then {
        [4, format ["[TownSpawn] %1 on cooldown (%2s remaining)", _townName, ceil(_cooldown - _timeSince)]] call A3XAI_fnc_log;
        false
    } else {
        // Check group limit
        private _activeGroups = [_townName] call _fnc_getTownGroups;
        private _maxGroups = if (!isNil "A3XAI_maxGroupsPerTown") then {A3XAI_maxGroupsPerTown} else {2};

        if (count _activeGroups >= _maxGroups) then {
            [4, format ["[TownSpawn] %1 at group limit (%2/%3)", _townName, count _activeGroups, _maxGroups]] call A3XAI_fnc_log;
            false
        } else {
            true
        }
    }
};

// Register a spawn to a town
private _fnc_registerTownSpawn = {
    params ["_townName", "_group"];

    private _groups = A3XAI_townSpawns getOrDefault [_townName, []];
    _groups pushBack _group;
    A3XAI_townSpawns set [_townName, _groups];
    A3XAI_townCooldowns set [_townName, time];

    private _maxGroups = if (!isNil "A3XAI_maxGroupsPerTown") then {A3XAI_maxGroupsPerTown} else {2};
    [3, format ["[TownSpawn] Registered group in %1 (%2/%3 groups)", _townName, count _groups, _maxGroups]] call A3XAI_fnc_log;
};

// Check if any player is within radius of a position
private _fnc_playersNearPos = {
    params ["_pos", "_radius"];
    private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};
    private _nearPlayer = _players findIf {(_x distance2D _pos) < _radius};
    _nearPlayer >= 0
};

// Despawn all AI in a town (safe cleanup)
private _fnc_despawnTown = {
    params ["_townName"];

    private _groups = A3XAI_townSpawns getOrDefault [_townName, []];
    private _despawnCount = 0;

    {
        if (!isNull _x) then {
            // Delete all units in group
            {
                if (alive _x) then {
                    deleteVehicle _x;
                    _despawnCount = _despawnCount + 1;
                };
            } forEach units _x;
            deleteGroup _x;
        };
    } forEach _groups;

    // Clear tracking
    A3XAI_townSpawns set [_townName, []];
    A3XAI_townDespawnTimers deleteAt _townName;

    if (_despawnCount > 0) then {
        [3, format ["[TownTrigger] Despawned %1 AI from %2 (no players nearby)", _despawnCount, _townName]] call A3XAI_fnc_log;
    };
};

private _triggerEnabled = if (!isNil "A3XAI_townTriggerEnabled") then {A3XAI_townTriggerEnabled} else {true};
private _triggerRadius = if (!isNil "A3XAI_townTriggerRadius") then {A3XAI_townTriggerRadius} else {350};
private _despawnRadius = if (!isNil "A3XAI_townDespawnRadius") then {A3XAI_townDespawnRadius} else {600};
private _despawnDelay = if (!isNil "A3XAI_townDespawnDelay") then {A3XAI_townDespawnDelay} else {120};
private _spawnChance = if (!isNil "A3XAI_townSpawnChance") then {A3XAI_townSpawnChance} else {60};

[3, format ["Town spawn limits: Max %1 groups per town, %2s cooldown",
    (if (!isNil "A3XAI_maxGroupsPerTown") then {A3XAI_maxGroupsPerTown} else {2}),
    (if (!isNil "A3XAI_townRespawnCooldown") then {A3XAI_townRespawnCooldown} else {900})]] call A3XAI_fnc_log;

if (_triggerEnabled) then {
    [3, format ["Town trigger system ENABLED: %1m spawn, %2m despawn, %3s delay, %4%5 chance",
        _triggerRadius, _despawnRadius, _despawnDelay, _spawnChance, "%"]] call A3XAI_fnc_log;
} else {
    [3, "Town trigger system DISABLED - using random spawning"] call A3XAI_fnc_log;
};

while {A3XAI_enabled} do {
    sleep _loopInterval;

    // Skip if no players online
    private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};
    if (count _players == 0) then {
        _firstPlayerTime = -1;  // Reset timer when no players
        continue;
    };

    // Track first player join time
    if (_firstPlayerTime < 0) then {
        _firstPlayerTime = time;
        [3, format ["First player detected - waiting %1 seconds before spawning missions", _startupDelay]] call A3XAI_fnc_log;
    };

    // Wait for startup delay
    if ((time - _firstPlayerTime) < _startupDelay) then {
        private _remaining = ceil(_startupDelay - (time - _firstPlayerTime));
        if (_remaining % 60 == 0 || _remaining <= 10) then {
            [4, format ["Mission startup: %1 seconds remaining", _remaining]] call A3XAI_fnc_log;
        };
        continue;
    };

    // Check server FPS
    private _fps = diag_fps;
    if (_fps < A3XAI_minServerFPS) then {
        [2, format ["Skipping spawn cycle - Low FPS: %1", _fps toFixed 1]] call A3XAI_fnc_log;
        continue;
    };

    // ============================================
    // UPDATE ACTIVE CELLS BASED ON PLAYER POSITIONS
    // ============================================

    private _newActiveCells = createHashMap;

    {
        private _playerPos = position _x;
        private _playerCell = [_playerPos] call A3XAI_fnc_getCellID;

        // Mark player's cell and surrounding cells as active
        for "_xOffset" from -1 to 1 do {
            for "_yOffset" from -1 to 1 do {
                private _cellID = [
                    (_playerCell select 0) + _xOffset,
                    (_playerCell select 1) + _yOffset
                ];

                _newActiveCells set [str _cellID, true];
            };
        };
    } forEach _players;

    // Disable simulation for inactive cells
    {
        private _cellID = _x;
        private _active = _newActiveCells getOrDefault [_cellID, false];

        private _spawns = A3XAI_spawnGrid getOrDefault [_cellID, []];

        {
            private _groups = _x getOrDefault ["groups", []];

            {
                {
                    _x enableSimulation _active;
                } forEach units _x;
            } forEach _groups;

        } forEach _spawns;

    } forEach A3XAI_spawnGrid;

    A3XAI_activeCells = _newActiveCells;

    // ============================================
    // CHECK CURRENT AI COUNT (Dynamic per-player scaling)
    // ============================================
    // Count AI with A3XAI variables OR units in EAST groups
    private _currentAI = count (allUnits select {
        alive _x && {
            (_x getVariable ["A3XAI_unit", false]) ||
            (_x getVariable ["A3XAI_spawned", false]) ||
            (side group _x == EAST && !isPlayer _x)
        }
    });

    // Dynamic AI limit: base + (per player * player count)
    // Example: 50 base + (20 * 1 player) = 70 max AI for 1 player
    //          50 base + (20 * 5 players) = 150 max AI for 5 players
    private _playerCount = count _players;
    private _perPlayerAI = if (!isNil "A3XAI_maxAIPerPlayer") then {A3XAI_maxAIPerPlayer} else {20};
    private _dynamicMaxAI = A3XAI_maxAIGlobal + (_perPlayerAI * _playerCount);

    if (_currentAI >= _dynamicMaxAI) then {
        [4, format ["At AI limit (%1/%2 for %3 players) - skipping spawns", _currentAI, _dynamicMaxAI, _playerCount]] call A3XAI_fnc_log;
        continue;
    };

    private _availableSlots = _dynamicMaxAI - _currentAI;

    // ============================================
    // SPAWN NEW AI
    // ============================================

    // Determine how many spawns we can attempt this cycle
    private _maxSpawnsThisCycle = floor(_availableSlots / 4); // Each spawn creates ~4 AI
    if (_maxSpawnsThisCycle < 1) then {continue};

    // Prioritize different spawn types
    private _spawnAttempts = 0;

    // 1. Town Infantry Spawns - Trigger-based or Random
    // v3.14: Player proximity triggers (spawn when player enters town)
    // v3.13: Respects per-town group limits and cooldowns

    // Get towns/villages from Exile spawn zones or map locations
    private _spawnLocations = if (!isNil "DyCE_SpawnZones") then {
        DyCE_SpawnZones
    } else {
        // Fallback Altis towns - expanded list
        createHashMapFromArray [
            ["Kavala", [3874, 13281, 0]],
            ["Zaros", [9927, 12083, 0]],
            ["Pyrgos", [17138, 12719, 0]],
            ["Sofia", [25713, 21330, 0]],
            ["Syrta", [8613, 18272, 0]],
            ["Athira", [14526, 18873, 0]],
            ["Rodopoli", [14298, 14786, 0]],
            ["Agios Dionysios", [18693, 14728, 0]]
        ]
    };

    private _townNames = keys _spawnLocations;

    if (_triggerEnabled) then {
        // ============================================
        // TRIGGER-BASED SPAWNING (v3.14)
        // Check each town for player proximity
        // ============================================

        {
            private _townName = _x;
            private _townPos = _spawnLocations get _townName;
            private _townGroups = [_townName] call _fnc_getTownGroups;
            private _hasAI = count _townGroups > 0;

            // Check if players are within trigger radius (spawn zone)
            private _playersInTrigger = [_townPos, _triggerRadius] call _fnc_playersNearPos;

            // Check if players are within despawn radius (keep-alive zone)
            private _playersInDespawn = [_townPos, _despawnRadius] call _fnc_playersNearPos;

            if (_playersInTrigger) then {
                // Player in town - spawn AI if allowed (with chance roll)
                A3XAI_townDespawnTimers deleteAt _townName;  // Cancel any despawn timer

                if (_spawnAttempts < _maxSpawnsThisCycle) then {
                    if ([_townName] call _fnc_canSpawnInTown) then {
                        // Roll spawn chance (original A3XAI style - not guaranteed)
                        if ((random 100) < _spawnChance) then {
                            // Find spawn position within town area (50-150m from center)
                            private _distance = 50 + random 100;
                            private _dir = random 360;
                            private _spawnPos = _townPos getPos [_distance, _dir];

                            if ([_spawnPos, "land"] call A3XAI_fnc_isValidSpawnPos) then {
                                private _difficulty = selectRandom ["easy", "medium", "hard"];
                                private _groupSize = if (!isNil "A3XAI_maxAIPerGroup") then {A3XAI_maxAIPerGroup} else {4};
                                private _result = [A3XAI_fnc_spawnInfantry, [_spawnPos, _groupSize, _difficulty], "spawnInfantry"] call A3XAI_fnc_safeCall;

                                if (!isNil "_result") then {
                                    _spawnAttempts = _spawnAttempts + 1;

                                    private _group = _result getOrDefault ["group", grpNull];
                                    if (!isNull _group) then {
                                        [_townName, _group] call _fnc_registerTownSpawn;
                                    };

                                    [3, format ["[TownTrigger] Player entered %1 - spawned infantry (%2)", _townName, _difficulty]] call A3XAI_fnc_log;
                                };
                            };
                        } else {
                            [4, format ["[TownTrigger] Player in %1 - spawn roll failed (%2%3 chance)", _townName, _spawnChance, "%"]] call A3XAI_fnc_log;
                        };
                    };
                };
            } else {
                if (_hasAI) then {
                // No players in trigger zone but town has AI - check despawn
                if (!_playersInDespawn) then {
                    // Players left despawn zone - start/check timer
                    private _timerStart = A3XAI_townDespawnTimers getOrDefault [_townName, -1];

                    if (_timerStart < 0) then {
                        // Start despawn timer
                        A3XAI_townDespawnTimers set [_townName, time];
                        [4, format ["[TownTrigger] Players left %1 - despawn timer started (%2s)", _townName, _despawnDelay]] call A3XAI_fnc_log;
                    } else {
                        // Check if timer expired
                        private _elapsed = time - _timerStart;
                        if (_elapsed >= _despawnDelay) then {
                            [_townName] call _fnc_despawnTown;
                        };
                    };
                } else {
                    // Players still in despawn zone - cancel timer
                    if (_townName in A3XAI_townDespawnTimers) then {
                        A3XAI_townDespawnTimers deleteAt _townName;
                        [4, format ["[TownTrigger] Player returned near %1 - despawn cancelled", _townName]] call A3XAI_fnc_log;
                    };
                };
                };
            };
        } forEach _townNames;

    } else {
        // ============================================
        // RANDOM SPAWNING (legacy, trigger disabled)
        // ============================================

        if (random 1 < 0.8 && _spawnAttempts < _maxSpawnsThisCycle) then {
            if (count _townNames > 0) then {
                private _shuffledTowns = _townNames call BIS_fnc_arrayShuffle;
                private _selectedTown = "";
                private _selectedPos = [];

                {
                    if ([_x] call _fnc_canSpawnInTown) exitWith {
                        _selectedTown = _x;
                        _selectedPos = _spawnLocations get _x;
                    };
                } forEach _shuffledTowns;

                if (_selectedTown != "") then {
                    private _distance = 50 + random 100;
                    private _dir = random 360;
                    private _spawnPos = _selectedPos getPos [_distance, _dir];

                    if ([_spawnPos, "land"] call A3XAI_fnc_isValidSpawnPos) then {
                        private _difficulty = selectRandom ["easy", "medium", "hard"];
                        private _groupSize = if (!isNil "A3XAI_maxAIPerGroup") then {A3XAI_maxAIPerGroup} else {4};
                        private _result = [A3XAI_fnc_spawnInfantry, [_spawnPos, _groupSize, _difficulty], "spawnInfantry"] call A3XAI_fnc_safeCall;

                        if (!isNil "_result") then {
                            _spawnAttempts = _spawnAttempts + 1;

                            private _group = _result getOrDefault ["group", grpNull];
                            if (!isNull _group) then {
                                [_selectedTown, _group] call _fnc_registerTownSpawn;
                            };

                            [4, format ["Spawned infantry patrol in %1 (%2)", _selectedTown, _difficulty]] call A3XAI_fnc_log;
                        };
                    };
                } else {
                    [4, "All towns at spawn limit or on cooldown - skipping infantry spawn"] call A3XAI_fnc_log;
                };
            };
        };
    };

    // 2. Vehicle Patrols (25% chance) - Spawn near Exile towns, cycle between them
    if (random 1 < 0.25 && _spawnAttempts < _maxSpawnsThisCycle) then {
        // Check if we haven't hit vehicle limit
        if (count A3XAI_activeVehicles < 10) then {
            // Use Exile spawn zone towns for vehicle patrol routes
            private _spawnZones = if (!isNil "DyCE_SpawnZones") then {
                DyCE_SpawnZones
            } else {
                // Fallback Altis towns
                createHashMapFromArray [
                    ["Kavala", [3874, 13281, 0]],
                    ["Zaros", [9927, 12083, 0]],
                    ["Pyrgos", [17138, 12719, 0]],
                    ["Sofia", [25713, 21330, 0]],
                    ["Syrta", [8613, 18272, 0]]
                ]
            };

            private _townNames = keys _spawnZones;
            if (count _townNames >= 2) then {
                // Pick random start town
                private _startTown = selectRandom _townNames;
                private _startPos = _spawnZones get _startTown;

                // Find road near start town
                private _roads = _startPos nearRoads 500;
                if (count _roads > 0) then {
                    private _road = _roads select 0;
                    private _spawnPos = position _road;

                    private _difficulty = selectRandom ["easy", "medium", "hard"];
                    private _result = [A3XAI_fnc_spawnVehicle, [_spawnPos, _difficulty], "spawnVehicle"] call A3XAI_fnc_safeCall;

                    if (!isNil "_result") then {
                        _spawnAttempts = _spawnAttempts + 1;
                        [4, format ["Spawned vehicle patrol near %1 (%2)", _startTown, _difficulty]] call A3XAI_fnc_log;
                    };
                };
            };
        };
    };

    // 3. Air Patrols (10% chance)
    if (random 1 < 0.1 && _spawnAttempts < _maxSpawnsThisCycle) then {
        // Check if we haven't hit air limit
        private _airVehicles = A3XAI_activeVehicles select {_x isKindOf "Helicopter" || _x isKindOf "Plane"};
        if (count _airVehicles < 2) then {
            private _player = selectRandom _players;
            if (!isNull _player) then {
                private _distance = A3XAI_spawnDistanceMin + 1000;
                private _dir = random 360;
                private _spawnPos = (position _player) getPos [_distance, _dir];
                _spawnPos set [2, 100 + random 200]; // Spawn at altitude

                private _difficulty = selectRandom ["medium", "hard", "extreme"];
                private _result = [A3XAI_fnc_spawnHeli, [_spawnPos, _difficulty], "spawnHeli"] call A3XAI_fnc_safeCall;

                if (!isNil "_result") then {
                    _spawnAttempts = _spawnAttempts + 1;
                    [4, format ["Spawned helicopter patrol at %1 (%2)", _spawnPos, _difficulty]] call A3XAI_fnc_log;
                };
            };
        };
    };

    // ============================================
    // 4. HIGHWAY PATROLS (Every 5 minutes)
    // ============================================
    // Spawn enemy vehicle patrols on highways between Exile spawn zones
    // These are separate from regular missions and provide road encounters

    if ((time - _lastHighwayPatrol) >= _highwayPatrolInterval) then {
        // Count current highway patrols
        private _currentHighwayPatrols = A3XAI_activeMissions select {
            (_x getOrDefault ["type", ""]) == "highwayPatrol"
        };

        if (count _currentHighwayPatrols < _maxHighwayPatrols) then {
            // Spawn a new highway patrol
            private _difficulty = selectRandom ["easy", "medium", "medium", "hard"];

            // Empty position = let fn_highwayPatrol pick random highway route
            private _result = [A3XAI_fnc_highwayPatrol, [[], _difficulty], "highwayPatrol"] call A3XAI_fnc_safeCall;

            if (!isNil "_result" && {count _result > 0}) then {
                _highwayPatrolsSpawned = _highwayPatrolsSpawned + 1;
                private _route = _result getOrDefault ["route", ["unknown", "unknown"]];
                [3, format ["Highway patrol spawned: %1-%2 route (%3) [%4/%5 active]",
                    _route select 0, _route select 1, _difficulty,
                    (count _currentHighwayPatrols) + 1, _maxHighwayPatrols]] call A3XAI_fnc_log;
            } else {
                [2, "Failed to spawn highway patrol"] call A3XAI_fnc_log;
            };
        } else {
            [4, format ["Highway patrol limit reached (%1/%2)", count _currentHighwayPatrols, _maxHighwayPatrols]] call A3XAI_fnc_log;
        };

        _lastHighwayPatrol = time;
    };

    // ============================================
    // 5. DyCE DYNAMIC CONVOY EVENTS (Every 2 minutes)
    // ============================================
    // Spawn random convoy types from DyCE configuration
    // Types: armedConvoy, troopConvoy, supplyTruck (ground only)

    if (!isNil "DyCE_Initialized" && {DyCE_Initialized}) then {
        if ((time - _lastDyceCheck) >= _dyceInterval) then {
            // Check total DyCE convoys active (max 3)
            private _currentDyceEvents = A3XAI_activeMissions select {
                _x getOrDefault ["dyce", false]
            };

            if (count _currentDyceEvents < _maxDyceConvoys) then {
                // Select random convoy type to spawn
                private _convoyType = selectRandom _dyceConvoyTypes;

                // Spawn the convoy
                private _result = [A3XAI_fnc_DyCE_spawn, [_convoyType, []], "DyCE_spawn"] call A3XAI_fnc_safeCall;

                if (!isNil "_result" && {count _result > 0}) then {
                    [3, format ["[DyCE] Spawned %1 [%2/%3 convoys active]",
                        _convoyType, (count _currentDyceEvents) + 1, _maxDyceConvoys]] call A3XAI_fnc_log;
                } else {
                    [4, format ["[DyCE] Failed to spawn %1", _convoyType]] call A3XAI_fnc_log;
                };
            } else {
                [4, format ["[DyCE] Convoy limit reached (%1/%2)", count _currentDyceEvents, _maxDyceConvoys]] call A3XAI_fnc_log;
            };

            _lastDyceCheck = time;
        };
    };

    // ============================================
    // MISSION SCHEDULER v3.1
    // ============================================

    // INITIAL MISSION SPAWN: Spawn all 3 missions at startup
    if (!_missionsInitialized) then {
        [3, "=== INITIAL MISSION SPAWN ==="] call A3XAI_fnc_log;
        [3, format ["Spawning %1 missions after %1s startup delay", _maxConcurrentMissions, _startupDelay]] call A3XAI_fnc_log;

        for "_m" from 1 to _maxConcurrentMissions do {
            private _missionType = [] call A3XAI_fnc_selectMission;
            private _difficulty = selectRandom ["medium", "hard", "extreme"];

            // Find location spread around map center or random player
            private _basePos = if (count _players > 0) then {
                position (selectRandom _players)
            } else {
                [] call A3XAI_fnc_getMapCenter
            };

            // Spread missions apart (different directions)
            private _distance = 1500 + random 1500;
            private _dir = (360 / _maxConcurrentMissions) * _m + random 30;
            private _missionPos = _basePos getPos [_distance, _dir];

            // Spawn mission
            private _result = [A3XAI_fnc_spawnMission, [_missionType, _missionPos, _difficulty], "spawnMission"] call A3XAI_fnc_safeCall;

            if (!isNil "_result" && {count _result > 0}) then {
                [3, format ["[%1/%2] Spawned %3 mission (%4)", _m, _maxConcurrentMissions, _missionType, _difficulty]] call A3XAI_fnc_log;
            } else {
                [2, format ["[%1/%2] Failed to spawn %3 mission", _m, _maxConcurrentMissions, _missionType]] call A3XAI_fnc_log;
            };

            sleep 2;  // Small delay between spawns
        };

        _missionsInitialized = true;
        _lastMissionCheck = time;
        [3, format ["=== INITIAL SPAWN COMPLETE: %1 missions active ===", count A3XAI_activeMissions]] call A3XAI_fnc_log;

        // Spawn initial highway patrols
        [3, "=== SPAWNING INITIAL HIGHWAY PATROLS ==="] call A3XAI_fnc_log;
        private _initialPatrols = 2;  // Start with 2 highway patrols
        for "_p" from 1 to _initialPatrols do {
            private _difficulty = selectRandom ["easy", "medium"];
            private _result = [A3XAI_fnc_highwayPatrol, [[], _difficulty], "highwayPatrol"] call A3XAI_fnc_safeCall;

            if (!isNil "_result" && {count _result > 0}) then {
                _highwayPatrolsSpawned = _highwayPatrolsSpawned + 1;
                private _route = _result getOrDefault ["route", ["unknown", "unknown"]];
                [3, format ["[%1/%2] Highway patrol: %3-%4 (%5)",
                    _p, _initialPatrols, _route select 0, _route select 1, _difficulty]] call A3XAI_fnc_log;
            };
            sleep 2;
        };
        _lastHighwayPatrol = time;
        [3, format ["=== HIGHWAY PATROLS ACTIVE: %1 ===", _highwayPatrolsSpawned]] call A3XAI_fnc_log;

        // Spawn initial DyCE convoy (just 1 to start)
        if (!isNil "DyCE_Initialized" && {DyCE_Initialized}) then {
            [3, "=== SPAWNING INITIAL DyCE CONVOY ==="] call A3XAI_fnc_log;

            // Spawn just 1 convoy at startup
            private _result = [A3XAI_fnc_DyCE_spawn, ["armedConvoy", []], "DyCE_spawn"] call A3XAI_fnc_safeCall;
            if (!isNil "_result" && {count _result > 0}) then {
                [3, "[DyCE] Initial armedConvoy spawned"] call A3XAI_fnc_log;
            };

            _lastDyceCheck = time;
            [3, format ["=== DyCE CONVOYS ACTIVE: 1/%1 ===", _maxDyceConvoys]] call A3XAI_fnc_log;
        };

        _dyceInitialized = true;
    };

    // Spawn initial roaming infantry patrols in towns/villages (2 groups of 4)
    // v3.14: Skip initial spawns if trigger mode enabled (main loop handles it)
    // v3.13: Respects per-town limits, registers to tracking
    if (!_triggerEnabled) then {
        [3, "=== SPAWNING INITIAL INFANTRY PATROLS (in towns) ==="] call A3XAI_fnc_log;
        private _initialInfantry = 2;  // 2 infantry patrols in random towns

        // Get spawn locations (towns)
        private _infantrySpawnLocations = if (!isNil "DyCE_SpawnZones") then {
            DyCE_SpawnZones
        } else {
            createHashMapFromArray [
                ["Kavala", [3874, 13281, 0]],
                ["Zaros", [9927, 12083, 0]],
                ["Pyrgos", [17138, 12719, 0]],
                ["Sofia", [25713, 21330, 0]],
                ["Syrta", [8613, 18272, 0]],
                ["Athira", [14526, 18873, 0]],
                ["Rodopoli", [14298, 14786, 0]],
                ["Agios Dionysios", [18693, 14728, 0]]
            ]
        };

        private _infantryTownNames = keys _infantrySpawnLocations;
        private _shuffledTowns = _infantryTownNames call BIS_fnc_arrayShuffle;
        private _initialSpawned = 0;

        for "_inf" from 0 to (_initialInfantry - 1) do {
            if (_inf < count _shuffledTowns) then {
                private _townName = _shuffledTowns select _inf;
                private _townPos = _infantrySpawnLocations get _townName;

                // Spawn within town (50-150m from center)
                private _distance = 50 + random 100;
                private _dir = random 360;
                private _spawnPos = _townPos getPos [_distance, _dir];

                if ([_spawnPos, "land"] call A3XAI_fnc_isValidSpawnPos) then {
                    private _difficulty = selectRandom ["easy", "medium", "hard"];
                    private _groupSize = if (!isNil "A3XAI_maxAIPerGroup") then {A3XAI_maxAIPerGroup} else {4};
                    private _result = [A3XAI_fnc_spawnInfantry, [_spawnPos, _groupSize, _difficulty], "spawnInfantry"] call A3XAI_fnc_safeCall;

                    if (!isNil "_result" && {count _result > 0}) then {
                        _initialSpawned = _initialSpawned + 1;

                        // v3.13: Register spawn to town tracking
                        private _group = _result getOrDefault ["group", grpNull];
                        if (!isNull _group) then {
                            [_townName, _group] call _fnc_registerTownSpawn;
                        };

                        [3, format ["[%1/%2] Initial infantry patrol in %3 (%4)", _initialSpawned, _initialInfantry, _townName, _difficulty]] call A3XAI_fnc_log;
                    };
                };
            };
            sleep 1;
        };
        [3, format ["=== INITIAL INFANTRY PATROLS: %1 (in towns) ===", _initialSpawned]] call A3XAI_fnc_log;
    } else {
        [3, "=== INITIAL INFANTRY: Skipped (trigger mode - spawns on player proximity) ==="] call A3XAI_fnc_log;
    };

    // SCHEDULED MISSION CHECK: Replace completed missions
    if ((time - _lastMissionCheck) >= _missionCheckInterval) then {
        private _activeMissions = count A3XAI_activeMissions;
        private _missionsNeeded = _maxConcurrentMissions - _activeMissions;

        if (_missionsNeeded > 0) then {
            [3, format ["Mission check: %1 active, spawning %2 replacement(s)", _activeMissions, _missionsNeeded]] call A3XAI_fnc_log;

            for "_m" from 1 to _missionsNeeded do {
                private _missionType = [] call A3XAI_fnc_selectMission;
                private _difficulty = selectRandom ["medium", "hard", "extreme"];

                // Find suitable location away from players
                private _player = selectRandom _players;
                if (!isNull _player) then {
                    private _distance = 1500 + random 1500;
                    private _dir = random 360;
                    private _missionPos = (position _player) getPos [_distance, _dir];

                    private _result = [A3XAI_fnc_spawnMission, [_missionType, _missionPos, _difficulty], "spawnMission"] call A3XAI_fnc_safeCall;

                    if (!isNil "_result" && {count _result > 0}) then {
                        [3, format ["Replacement mission: %1 (%2)", _missionType, _difficulty]] call A3XAI_fnc_log;
                    };
                };

                sleep 1;
            };
        } else {
            [4, format ["Mission check: All %1 missions active, no replacements needed", _activeMissions]] call A3XAI_fnc_log;
        };

        _lastMissionCheck = time;
    };

    // ============================================
    // CHECK MISSION COMPLETION
    // ============================================

    {
        [_x] call A3XAI_fnc_checkMissionComplete;
    } forEach A3XAI_activeMissions;

    // ============================================
    // MONITOR STUCK VEHICLES
    // ============================================

    {
        private _vehicle = _x;
        if (alive _vehicle) then {
            private _status = [_vehicle] call A3XAI_fnc_isVehicleStuck;

            if (_status != "MOVING") then {
                [2, format ["Vehicle %1 stuck: %2", typeOf _vehicle, _status]] call A3XAI_fnc_log;
                [_vehicle, _status] call A3XAI_fnc_unstuckVehicle;
            };
        };
    } forEach A3XAI_activeVehicles;

    // End of main loop cycle
    if (A3XAI_debugMode) then {
        [4, format ["Main loop cycle complete - AI: %1/%2, Spawns attempted: %3", _currentAI, A3XAI_maxAIGlobal, _spawnAttempts]] call A3XAI_fnc_log;
    };
};

[2, "Master spawn loop stopped"] call A3XAI_fnc_log;
