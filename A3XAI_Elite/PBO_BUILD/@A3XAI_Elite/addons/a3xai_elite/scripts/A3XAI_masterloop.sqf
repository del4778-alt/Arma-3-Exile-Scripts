/*
    A3XAI Elite - Master Spawn Loop
    Main loop that handles AI spawning, cell management, and mission triggers
*/

if (!isServer) exitWith {};

waitUntil {!isNil "A3XAI_initialized" && {A3XAI_initialized}};

[3, "Master spawn loop started"] call A3XAI_fnc_log;

private _loopInterval = 30; // Main loop runs every 30 seconds
private _lastMissionSpawn = 0;
private _missionSpawnInterval = 600; // Spawn mission every 10 minutes

while {A3XAI_enabled} do {
    sleep _loopInterval;

    // Skip if no players online
    private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};
    if (count _players == 0) then {continue};

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

    private _currentAI = count (allUnits select {side _x == EAST});

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

    // 1. Random Infantry Spawns (60% chance)
    if (random 1 < 0.6 && _spawnAttempts < _maxSpawnsThisCycle) then {
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

    // 2. Vehicle Patrols (25% chance)
    if (random 1 < 0.25 && _spawnAttempts < _maxSpawnsThisCycle) then {
        // Check if we haven't hit vehicle limit
        if (count A3XAI_activeVehicles < 10) then {
            private _player = selectRandom _players;
            if (!isNull _player) then {
                private _distance = A3XAI_spawnDistanceMin + 500;
                private _dir = random 360;
                private _spawnPos = (position _player) getPos [_distance, _dir];

                // Must be near road
                private _roads = _spawnPos nearRoads 200;
                if (count _roads > 0) then {
                    private _road = _roads select 0;
                    _spawnPos = position _road;

                    private _difficulty = selectRandom ["easy", "medium", "hard"];
                    private _result = [A3XAI_fnc_spawnVehicle, [_spawnPos, _difficulty], "spawnVehicle"] call A3XAI_fnc_safeCall;

                    if (!isNil "_result") then {
                        _spawnAttempts = _spawnAttempts + 1;
                        [4, format ["Spawned vehicle patrol at %1 (%2)", _spawnPos, _difficulty]] call A3XAI_fnc_log;
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
    // SPAWN MISSIONS
    // ============================================

    if ((time - _lastMissionSpawn) >= _missionSpawnInterval) then {
        if (count A3XAI_activeMissions < 3) then { // Max 3 concurrent missions
            // Select mission type and difficulty
            private _missionType = [nil] call A3XAI_fnc_selectMission;
            private _difficulty = selectRandom ["medium", "hard", "extreme"];

            // Find suitable location away from players
            private _player = selectRandom _players;
            if (!isNull _player) then {
                private _distance = 1500 + random 1000;
                private _dir = random 360;
                private _missionPos = (position _player) getPos [_distance, _dir];

                // Spawn mission
                private _result = [A3XAI_fnc_spawnMission, [_missionType, _missionPos, _difficulty], "spawnMission"] call A3XAI_fnc_safeCall;

                if (!isNil "_result") then {
                    _lastMissionSpawn = time;
                    [3, format ["Spawned %1 mission at %2 (%3 difficulty)", _missionType, _missionPos, _difficulty]] call A3XAI_fnc_log;
                };
            };
        };
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
