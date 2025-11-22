/*
    A3XAI Elite - Master Spawn Loop
    Main loop that handles AI spawning, cell management, and mission triggers

    v3.5: Infantry Spawn Improvements
        - Reduced startup delay from 180s to 60s
        - Increased infantry spawn chance from 60% to 80%
        - Added 4 initial infantry patrols at startup
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
private _dyceInterval = 120;             // Check DyCE spawn every 2 minutes
private _lastDyceCheck = 0;
private _dyceInitialized = false;
private _dyceConvoyTypes = ["armedConvoy", "troopConvoy", "supplyTruck"];

[3, format ["Mission scheduler: %1s startup delay, max %2 missions, %3s check interval",
    _startupDelay, _maxConcurrentMissions, _missionCheckInterval]] call A3XAI_fnc_log;
[3, "DyCE Dynamic Convoy Events enabled"] call A3XAI_fnc_log;

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
    // CHECK CURRENT AI COUNT
    // ============================================
    // Count AI with A3XAI variables OR units in EAST groups (more reliable than config side check)
    private _currentAI = count (allUnits select {
        alive _x && {
            (_x getVariable ["A3XAI_unit", false]) ||
            (_x getVariable ["A3XAI_spawned", false]) ||
            (side group _x == EAST && !isPlayer _x)
        }
    });

    if (_currentAI >= A3XAI_maxAIGlobal) then {
        [4, format ["At AI limit (%1/%2) - skipping spawns", _currentAI, A3XAI_maxAIGlobal]] call A3XAI_fnc_log;
        continue;
    };

    private _availableSlots = A3XAI_maxAIGlobal - _currentAI;

    // ============================================
    // SPAWN NEW AI
    // ============================================

    // Determine how many spawns we can attempt this cycle
    private _maxSpawnsThisCycle = floor(_availableSlots / 4); // Each spawn creates ~4 AI
    if (_maxSpawnsThisCycle < 1) then {continue};

    // Prioritize different spawn types
    private _spawnAttempts = 0;

    // 1. Random Infantry Spawns (80% chance - increased from 60%)
    if (random 1 < 0.8 && _spawnAttempts < _maxSpawnsThisCycle) then {
        // Select random player
        private _player = selectRandom _players;
        if (!isNull _player) then {
            // Find position between min and max distance
            private _distance = A3XAI_spawnDistanceMin + random (A3XAI_spawnDistanceMax - A3XAI_spawnDistanceMin);
            private _dir = random 360;
            private _spawnPos = (position _player) getPos [_distance, _dir];

            // Validate and spawn
            if ([_spawnPos, "land"] call A3XAI_fnc_isValidSpawnPos) then {
                private _difficulty = selectRandom ["easy", "medium", "hard"];
                private _result = [A3XAI_fnc_spawnInfantry, [_spawnPos, 4, _difficulty], "spawnInfantry"] call A3XAI_fnc_safeCall;

                if (!isNil "_result") then {
                    _spawnAttempts = _spawnAttempts + 1;
                    [4, format ["Spawned infantry patrol at %1 (%2)", _spawnPos, _difficulty]] call A3XAI_fnc_log;
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
            // Check total DyCE events active
            private _currentDyceEvents = A3XAI_activeMissions select {
                _x getOrDefault ["dyce", false]
            };

            private _maxEvents = if (!isNil "DyCE_Config") then {
                DyCE_Config getOrDefault ["maxTotalDynamicEvents", 8]
            } else {8};

            if (count _currentDyceEvents < _maxEvents) then {
                // Select random convoy type to spawn
                private _convoyType = selectRandom _dyceConvoyTypes;

                // Check specific limits for this type
                private _typeCount = {(_x getOrDefault ["type", ""]) == _convoyType} count _currentDyceEvents;
                private _typeLimit = switch (_convoyType) do {
                    case "armedConvoy": {2};
                    case "troopConvoy": {2};
                    case "supplyTruck": {2};
                    default {2};
                };

                if (_typeCount < _typeLimit) then {
                    // Spawn the convoy
                    private _result = [A3XAI_fnc_DyCE_spawn, [_convoyType, []], "DyCE_spawn"] call A3XAI_fnc_safeCall;

                    if (!isNil "_result" && {count _result > 0}) then {
                        [3, format ["[DyCE] Spawned %1 [%2/%3 events active]",
                            _convoyType, (count _currentDyceEvents) + 1, _maxEvents]] call A3XAI_fnc_log;
                    } else {
                        [4, format ["[DyCE] Failed to spawn %1", _convoyType]] call A3XAI_fnc_log;
                    };
                } else {
                    [4, format ["[DyCE] %1 limit reached (%2/%3)", _convoyType, _typeCount, _typeLimit]] call A3XAI_fnc_log;
                };
            } else {
                [4, format ["[DyCE] Event limit reached (%1/%2)", count _currentDyceEvents, _maxEvents]] call A3XAI_fnc_log;
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

        // Spawn initial DyCE convoys
        if (!isNil "DyCE_Initialized" && {DyCE_Initialized}) then {
            [3, "=== SPAWNING INITIAL DyCE CONVOYS ==="] call A3XAI_fnc_log;

            // Spawn initial ground convoys at startup
            private _initialDyceTypes = ["armedConvoy", "troopConvoy"];
            {
                private _result = [A3XAI_fnc_DyCE_spawn, [_x, []], "DyCE_spawn"] call A3XAI_fnc_safeCall;
                if (!isNil "_result" && {count _result > 0}) then {
                    [3, format ["[DyCE] Initial %1 spawned", _x]] call A3XAI_fnc_log;
                };
                sleep 2;
            } forEach _initialDyceTypes;

            _lastDyceCheck = time;
            [3, format ["=== DyCE CONVOYS ACTIVE: %1 ===", count DyCE_ActiveConvoys]] call A3XAI_fnc_log;
        };

        _dyceInitialized = true;
    };

    // Spawn initial roaming infantry patrols (only 2 groups of 4 around player)
    [3, "=== SPAWNING INITIAL INFANTRY PATROLS ==="] call A3XAI_fnc_log;
    private _initialInfantry = 2;  // Only 2 infantry patrols around player
    for "_inf" from 1 to _initialInfantry do {
        private _player = selectRandom _players;
        if (!isNull _player) then {
            private _distance = A3XAI_spawnDistanceMin + random (A3XAI_spawnDistanceMax - A3XAI_spawnDistanceMin);
            private _dir = (360 / _initialInfantry) * _inf + random 30;  // Spread around player
            private _spawnPos = (position _player) getPos [_distance, _dir];

            if ([_spawnPos, "land"] call A3XAI_fnc_isValidSpawnPos) then {
                private _difficulty = selectRandom ["easy", "medium", "hard"];
                private _result = [A3XAI_fnc_spawnInfantry, [_spawnPos, 4, _difficulty], "spawnInfantry"] call A3XAI_fnc_safeCall;

                if (!isNil "_result" && {count _result > 0}) then {
                    [3, format ["[%1/%2] Initial infantry patrol spawned (%3) at %4", _inf, _initialInfantry, _difficulty, _spawnPos]] call A3XAI_fnc_log;
                };
            };
        };
        sleep 1;
    };
    [3, format ["=== INITIAL INFANTRY PATROLS: %1 ===", _initialInfantry]] call A3XAI_fnc_log;

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
