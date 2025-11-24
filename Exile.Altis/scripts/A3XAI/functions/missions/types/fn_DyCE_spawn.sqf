/*
    A3XAI Elite - DyCE Unified Convoy Spawner
    Spawns any convoy type from DyCE_ConvoyTypes configuration

    v3.17: Lazy-Loading Road Cache
        - Replaced full map cache (34,625 roads) with grid-based lazy cache
        - Roads only cached when needed in 2km grid squares
        - ~90% memory reduction, zero startup delay
        - DyCE_fnc_getCachedRoads: Get roads near position (uses cache)
        - DyCE_fnc_getRandomSpawnRoad: Get random road from spawn zones

    Road-finding logic adapted from original DyCE:
    https://github.com/ExiledHeisenberg/DyCE

    Parameters:
        0: STRING - Convoy type ("armedConvoy", "troopConvoy", etc.)
        1: ARRAY - Spawn position (optional - auto-selects if empty)

    Returns:
        HASHMAP - Mission data (or empty hashmap on failure)
*/

params [["_convoyType", "armedConvoy"], ["_spawnPos", []]];

// Ensure DyCE is initialized
if (isNil "DyCE_Initialized" || !DyCE_Initialized) exitWith {
    diag_log "[DyCE] ERROR: DyCE not initialized";
    createHashMap
};

// ============================================================
// v3.17: LAZY-LOADING ROAD CACHE (replaces full map cache)
// Only caches roads in grid squares as needed - 90% memory reduction
// ============================================================
if (isNil "DyCE_RoadCache") then {
    DyCE_RoadCache = createHashMap;
    DyCE_CacheGridSize = 2000;  // 2km grid squares
    [3, "[DyCE] Initialized lazy road cache (v3.17)"] call A3XAI_fnc_log;
};

// Function to get roads near a position using lazy cache
DyCE_fnc_getCachedRoads = {
    params ["_centerPos", ["_radius", 1000]];

    private _gridX = floor ((_centerPos select 0) / DyCE_CacheGridSize);
    private _gridY = floor ((_centerPos select 1) / DyCE_CacheGridSize);
    private _gridKey = format ["%1_%2", _gridX, _gridY];

    // Check if this grid is cached
    private _cachedRoads = DyCE_RoadCache getOrDefault [_gridKey, []];

    if (count _cachedRoads == 0) then {
        // Cache roads in this grid square (on-demand)
        private _gridCenter = [
            (_gridX + 0.5) * DyCE_CacheGridSize,
            (_gridY + 0.5) * DyCE_CacheGridSize,
            0
        ];
        _cachedRoads = _gridCenter nearRoads (DyCE_CacheGridSize * 0.75);
        DyCE_RoadCache set [_gridKey, _cachedRoads];
        [4, format ["[DyCE] Lazy cached grid %1: %2 roads", _gridKey, count _cachedRoads]] call A3XAI_fnc_log;
    };

    // Return roads within requested radius
    _cachedRoads select {(_centerPos distance2D _x) < _radius}
};

// Function to get a random road from spawn zones (for convoy start points)
DyCE_fnc_getRandomSpawnRoad = {
    private _spawnZones = if (!isNil "DyCE_SpawnZones") then {
        values DyCE_SpawnZones
    } else {
        // Fallback Altis towns
        [[3874,13281,0], [9927,12083,0], [17138,12719,0], [25713,21330,0], [8613,18272,0]]
    };

    // Pick random spawn zone and get roads near it
    private _zonePos = selectRandom _spawnZones;
    private _nearbyRoads = [_zonePos, 2000] call DyCE_fnc_getCachedRoads;

    if (count _nearbyRoads > 0) then {
        selectRandom _nearbyRoads
    } else {
        // Fallback: direct road search
        private _roads = _zonePos nearRoads 2000;
        if (count _roads > 0) then {selectRandom _roads} else {objNull}
    }
};

// Get convoy configuration
private _convoyConfig = DyCE_ConvoyTypes getOrDefault [_convoyType, createHashMap];
if (count _convoyConfig == 0) exitWith {
    diag_log format ["[DyCE] ERROR: Unknown convoy type: %1", _convoyType];
    createHashMap
};

// Extract configuration
private _name = _convoyConfig get "name";
private _speedLimit = _convoyConfig get "speedLimit";
private _spawnAltitude = _convoyConfig get "spawnAltitude";
private _alertMessage = _convoyConfig get "alertMessage";
private _vehicleCountRange = _convoyConfig get "vehicleCount";
private _crewRange = _convoyConfig get "crewPerVehicle";
private _vehicleClasses = _convoyConfig get "vehicles";
private _uniforms = _convoyConfig get "uniforms";
private _vests = _convoyConfig get "vests";
private _lootRange = _convoyConfig get "lootRange";
private _difficulty = _convoyConfig get "difficulty";
private _markerColor = _convoyConfig get "markerColor";
private _markerType = _convoyConfig get "markerType";

private _missionName = format ["DyCE_%1_%2", _convoyType, floor(random 9999)];
[3, format ["[DyCE] Spawning %1 (%2)", _name, _difficulty]] call A3XAI_fnc_log;

// ============================================================
// FIND SPAWN POSITION (DyCE-Style Road Finding)
// ============================================================
private _vehicleSpawnPoints = [];
private _endWaypoint = [];
private _spawnRadius = DyCE_Config getOrDefault ["vehicleSpawnSearchRadius", 100];
private _minPlayerDist = DyCE_Config getOrDefault ["minDistanceFromPlayers", 500];

if (count _spawnPos == 0) then {
    if (_convoyType == "highwayPatrol") then {
        // Use highway route system for highway patrols
        private _route = selectRandom DyCE_HighwayRoutes;
        _spawnPos = _route select 2;  // Midpoint of route

        // Find roads near the route midpoint
        _vehicleSpawnPoints = _spawnPos nearRoads _spawnRadius;
        if (count _vehicleSpawnPoints > 0) then {
            _spawnPos = getPos (selectRandom _vehicleSpawnPoints);
        };
    } else {
        // v3.17: Use lazy-loaded road cache instead of full map cache
        private _attempts = 0;
        private _maxAttempts = 20;
        private _validSpawn = false;

        while {!_validSpawn && _attempts < _maxAttempts} do {
            _attempts = _attempts + 1;

            // v3.17: Get random road from spawn zones (lazy cached)
            private _randomRoad = [] call DyCE_fnc_getRandomSpawnRoad;
            if (isNull _randomRoad) then {continue};

            private _testPos = getPos _randomRoad;

            // Check distance from all players
            private _tooClose = false;
            {
                if (alive _x && {(_testPos distance2D _x) < _minPlayerDist}) exitWith {
                    _tooClose = true;
                };
            } forEach allPlayers;

            if (!_tooClose) then {
                // v3.17: Use lazy cache for nearby roads
                _vehicleSpawnPoints = [_testPos, _spawnRadius] call DyCE_fnc_getCachedRoads;

                // Need enough spawn points for convoy vehicles
                private _neededVehicles = _vehicleCountRange select 1;  // Max vehicles
                if (count _vehicleSpawnPoints >= _neededVehicles) then {
                    _spawnPos = _testPos;
                    _validSpawn = true;
                    [4, format ["[DyCE] Found valid spawn at %1 (attempt %2, %3 roads nearby)",
                        _spawnPos, _attempts, count _vehicleSpawnPoints]] call A3XAI_fnc_log;
                };
            };
        };

        // Fallback if no valid position found
        if (!_validSpawn) then {
            private _fallbackRoad = [] call DyCE_fnc_getRandomSpawnRoad;
            if (!isNull _fallbackRoad) then {
                _spawnPos = getPos _fallbackRoad;
            };
            _vehicleSpawnPoints = [_spawnPos, _spawnRadius * 2] call DyCE_fnc_getCachedRoads;
            [2, format ["[DyCE] Using fallback spawn at %1 after %2 attempts", _spawnPos, _attempts]] call A3XAI_fnc_log;
        };
    };
};

// ============================================================
// FIND END WAYPOINT (v3.17: Uses lazy cache, requires 4km+ distance)
// ============================================================
private _goodPosDist = 0;

// v3.17: Get end waypoint from a different spawn zone (ensures good distance)
private _spawnZones = if (!isNil "DyCE_SpawnZones") then {
    values DyCE_SpawnZones
} else {
    [[3874,13281,0], [9927,12083,0], [17138,12719,0], [25713,21330,0], [8613,18272,0]]
};

// Sort zones by distance from spawn, pick one that's far enough
private _sortedZones = [_spawnZones, [], {_spawnPos distance2D _x}, "DESCEND"] call BIS_fnc_sortBy;

{
    private _zoneRoads = [_x, 1500] call DyCE_fnc_getCachedRoads;
    if (count _zoneRoads > 0) then {
        private _testEndpoint = getPos (selectRandom _zoneRoads);
        private _dist = _spawnPos distance2D _testEndpoint;
        if (_dist > _goodPosDist) then {
            _endWaypoint = _testEndpoint;
            _goodPosDist = _dist;
        };
    };
    if (_goodPosDist >= 4000) exitWith {};
} forEach _sortedZones;

// Fallback if no good endpoint found
if (_goodPosDist < 4000) then {
    private _dir = random 360;
    private _targetPos = _spawnPos getPos [5000, _dir];
    private _nearbyRoads = [_targetPos, 1500] call DyCE_fnc_getCachedRoads;
    if (count _nearbyRoads > 0) then {
        _endWaypoint = getPos (selectRandom _nearbyRoads);
    } else {
        // Direct road search as last resort
        _nearbyRoads = _targetPos nearRoads 1500;
        if (count _nearbyRoads > 0) then {
            _endWaypoint = getPos (selectRandom _nearbyRoads);
        } else {
            _endWaypoint = _targetPos;
        };
    };
};

[4, format ["[DyCE] Convoy route: %1 -> %2 (%3m)", _spawnPos, _endWaypoint, round(_spawnPos distance2D _endWaypoint)]] call A3XAI_fnc_log;

// ============================================================
// CREATE MISSION DATA
// ============================================================
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", _convoyType],
    ["dyce", true],                     // Flag as DyCE event
    ["status", "active"],
    ["triggerType", "roaming"],
    ["position", _spawnPos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["lastMoveTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// ============================================================
// SPAWN VEHICLES (DyCE-Style: Use actual road positions)
// ============================================================
private _vehicleCount = (_vehicleCountRange select 0) + floor(random ((_vehicleCountRange select 1) - (_vehicleCountRange select 0) + 1));
private _allGroups = [];
private _allVehicles = [];
private _allLoot = [];

// Get road positions for each vehicle (DyCE style)
private _usedRoads = [];
if (count _vehicleSpawnPoints == 0) then {
    _vehicleSpawnPoints = _spawnPos nearRoads 150;
};

for "_i" from 0 to (_vehicleCount - 1) do {
    // Select vehicle class
    private _vehicleClass = selectRandom _vehicleClasses;

    // DyCE-style: Use actual road positions for vehicle placement
    private _vehSpawnPos = _spawnPos;
    if (count _vehicleSpawnPoints > _i) then {
        // Use actual road position
        private _roadObj = _vehicleSpawnPoints select _i;
        _vehSpawnPos = getPos _roadObj;

        // Get road direction for vehicle alignment
        private _roadDir = getDir _roadObj;
        if (_roadDir == 0) then {
            // Try to get road info for proper direction
            private _roadInfo = getRoadInfo _roadObj;
            if (count _roadInfo > 0) then {
                _roadDir = (_roadInfo select 3);
            };
        };
    } else {
        // Fallback: Offset from spawn position on road
        _vehSpawnPos = _spawnPos getPos [50 * _i, 180];
    };

    // Spawn vehicle
    private _vehicle = createVehicle [_vehicleClass, _vehSpawnPos, [], 0, "NONE"];
    if (isNull _vehicle) then {
        [2, format ["[DyCE] Failed to spawn vehicle: %1", _vehicleClass]] call A3XAI_fnc_log;
        continue;
    };

    // ✅ v3.9: IMMEDIATE vehicle protection - prevents explosion during crew loading
    _vehicle allowDamage false;

    // Set vehicle direction towards endpoint for convoy formation
    private _vehDir = _vehSpawnPos getDir _endWaypoint;
    _vehicle setDir _vehDir;
    _vehicle setFuel (0.8 + random 0.2);

    // Vehicle always unlocked - players can take after killing crew
    _vehicle lock 0;
    _vehicle setVariable ["DyCE_vehicle", true, true];

    // ========================================
    // CREATE CREW
    // ========================================
    private _group = createGroup [DyCE_Config get "aiSide", true];

    // ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
    if (isNull _group) then {
        [1, format ["[DyCE] Vehicle %1 SKIPPED: createGroup returned null - group limit reached", _i]] call A3XAI_fnc_log;
        deleteVehicle _vehicle;
        continue;
    };

    private _groupSide = side _group;
    if (_groupSide != EAST) then {
        private _eastGroups = {side _x == EAST} count allGroups;
        deleteGroup _group;
        deleteVehicle _vehicle;
        [1, format ["[DyCE] Vehicle %1 SKIPPED: Group created as %2 instead of EAST (EAST groups: %3/144)", _i, _groupSide, _eastGroups]] call A3XAI_fnc_log;
        continue;
    };

    private _crewCount = (_crewRange select 0) + floor(random ((_crewRange select 1) - (_crewRange select 0) + 1));
    private _crewUnits = [];

    for "_j" from 0 to (_crewCount - 1) do {
        private _unitType = "O_Soldier_F";
        private _unit = _group createUnit [_unitType, _vehSpawnPos, [], 0, "CAN_COLLIDE"];

        // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
        // Must happen before anything else to prevent instant death from collision/terrain
        _unit setDamage 0;
    _unit allowDamage false;
    _unit setVariable ["A3XAI_spawnProtected", true, true];

        // Temporarily disable AI during setup (DyCE style)
        _unit disableAI "ALL";

        // Apply A3XAI initialization
        [_unit, _difficulty] call A3XAI_fnc_initAI;
        [_unit, _difficulty] call A3XAI_fnc_setAISkill;
        [_unit, _difficulty] call A3XAI_fnc_equipAI;
        [_unit] call A3XAI_fnc_addAIEventHandlers;

        // Apply DyCE-specific gear
        if (count _uniforms > 0) then {
            _unit forceAddUniform (selectRandom _uniforms);
        };
        if (count _vests > 0) then {
            _unit addVest (selectRandom _vests);
        };

        // Mark as DyCE unit
        _unit setVariable ["DyCE_unit", true, true];
        _unit setVariable ["DyCE_vehicle", _vehicle, true];
        _unit setVariable ["A3XAI_mission", _missionName, true];

        // Assign to vehicle (ground vehicles only)
        if (_j == 0) then {
            _unit assignAsDriver _vehicle;
            _unit moveInDriver _vehicle;
        } else {
            if (_j == 1 && {getNumber (configFile >> "CfgVehicles" >> _vehicleClass >> "hasGunner") > 0}) then {
                _unit assignAsGunner _vehicle;
                _unit moveInGunner _vehicle;
            } else {
                _unit assignAsCargo _vehicle;
                _unit moveInAny _vehicle;
            };
        };

        // Re-enable AI after setup
        _unit enableAI "ALL";
        _crewUnits pushBack _unit;
    };

    // Store crew reference on vehicle
    _vehicle setVariable ["DyCE_crew", _crewUnits, true];

    // ========================================
    // SET GROUP BEHAVIOR (Aggressive Police)
    // ========================================
    _group setBehaviour "AWARE";
    _group setCombatMode "RED";           // Engage at will - shoot on sight
    _group setFormation "COLUMN";
    _group setSpeedMode "NORMAL";         // Full speed patrols
    _group setVariable ["DyCE_speedLimit", _speedLimit];

    // Enable all AI behaviors explicitly
    {
        _x enableAI "TARGET";
        _x enableAI "AUTOTARGET";
        _x enableAI "MOVE";
        _x enableAI "FSM";
        _x enableAI "AUTOCOMBAT";
        _x enableAI "COVER";
        _x enableAI "SUPPRESSION";
        _x enableAI "CHECKVISIBLE";
        _x enableAI "PATH";
    } forEach (units _group);

    // Set vehicle speed limit
    _vehicle limitSpeed _speedLimit;

    // ========================================
    // GENERATE WAYPOINTS (DyCE-Style Road Routes)
    // ========================================
    // Use the pre-calculated _endWaypoint (4km+ away)
    // Generate intermediate waypoints along roads

    private _waypoints = [];

    // Method 1: Try A3XAI route generator first
    private _generatedRoute = [_vehSpawnPos, 4000, 6] call A3XAI_fnc_generateRoute;
    if (count _generatedRoute >= 3) then {
        _waypoints = _generatedRoute;
    } else {
        // Method 2: DyCE-style - find roads between spawn and endpoint
        private _dir = _vehSpawnPos getDir _endWaypoint;
        private _totalDist = _vehSpawnPos distance2D _endWaypoint;

        for "_w" from 1 to 6 do {
            private _dist = (_totalDist / 7) * _w;
            private _wpTestPos = _vehSpawnPos getPos [_dist, _dir];
            private _nearbyRoads = _wpTestPos nearRoads 500;

            if (count _nearbyRoads > 0) then {
                _waypoints pushBack (getPos (selectRandom _nearbyRoads));
            } else {
                _waypoints pushBack _wpTestPos;
            };
        };
    };

    // Add the endpoint as final waypoint
    _waypoints pushBack _endWaypoint;

    // Create waypoints
    // ✅ v3.12b: Fixed driving behavior - reduced completion radius to prevent offroad shortcuts
    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";  // SAFE = careful driving, stays on roads
        _wp setWaypointFormation "COLUMN";
        _wp setWaypointCompletionRadius 15;  // Was 50m! Caused massive corner-cutting
    } forEach _waypoints;

    // Cycle back to start
    private _wp = _group addWaypoint [_spawnPos, 0];
    _wp setWaypointType "CYCLE";

    // ========================================
    // INITIALIZE VEHICLE WITH A3XAI
    // ========================================
    [_vehicle] call A3XAI_fnc_initVehicle;
    [_vehicle] call A3XAI_fnc_addVehicleEventHandlers;

    // EAD integration for ground vehicles
    if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {
        private _driver = driver _vehicle;
        if (!isNull _driver) then {
            private _result = [EAD_fnc_registerDriver, [_driver, _vehicle], "EAD_dyce"] call A3XAI_fnc_safeCall;
            if (!isNil "_result") then {
                _vehicle setVariable ["EAD_enabled", true];
                _vehicle setVariable ["EAD_dyce", true];
            };
        };
    };

    // Mark vehicle
    _vehicle setVariable ["DyCE_vehicle", true];
    _vehicle setVariable ["DyCE_convoyType", _convoyType];
    _vehicle setVariable ["A3XAI_mission", _missionName];

    // ========================================
    // ADD LOOT
    // ========================================
    private _lootBox = "Box_East_Support_F" createVehicle (position _vehicle);
    _lootBox attachTo [_vehicle, [0, -0.5, 0.3]];
    // Pass convoy type for type-specific loot (includes Exile concrete kits)
    [_lootBox, _difficulty, _convoyType] call A3XAI_fnc_spawnLoot;

    _lootBox addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _allLoot pushBack _lootBox;
    _allGroups pushBack _group;
    _allVehicles pushBack _vehicle;
};

// ============================================================
// CREATE MARKER
// ============================================================
if (DyCE_Config get "enableMarkers") then {
    // Main marker
    private _marker = createMarker [_missionName, _spawnPos];
    _marker setMarkerType _markerType;
    _marker setMarkerColor _markerColor;
    _marker setMarkerText format ["%1", _name];
    _marker setMarkerSize [1, 1];

    // Area marker (circle around mission)
    private _areaMarker = createMarker [format ["%1_area", _missionName], _spawnPos];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerSize [300, 300];
    _areaMarker setMarkerColor _markerColor;
    _areaMarker setMarkerAlpha 0.3;
    _areaMarker setMarkerBrush "SolidBorder";

    _missionData set ["markers", [_marker, _areaMarker]];

    // Update marker position as convoy moves
    [_missionData, _missionName, _allVehicles] spawn {
        params ["_missionData", "_missionName", "_vehicles"];
        while {(_missionData get "status") == "active"} do {
            sleep 10;
            private _aliveVehicles = _vehicles select {alive _x};
            if (count _aliveVehicles > 0) then {
                private _leadVeh = _aliveVehicles select 0;
                private _pos = getPos _leadVeh;
                _missionName setMarkerPos _pos;
                (format ["%1_area", _missionName]) setMarkerPos _pos;
            };
        };
    };
};

// ============================================================
// SEND NOTIFICATIONS
// ============================================================
if (DyCE_Config get "enableNotifications" && _alertMessage != "") then {
    private _posGrid = mapGridPosition _spawnPos;

    // System chat notification (always works)
    private _chatMsg = format ["[POLICE] %1 - Grid: %2", _alertMessage, _posGrid];
    _chatMsg remoteExec ["systemChat", 0];

    // Hint notification with formatting
    private _hintMsg = format [
        "<t size='1.3' color='#ff0000'>POLICE ACTIVITY</t><br/><br/><t size='1.0'>%1</t><br/><br/><t size='0.9' color='#ffff00'>Grid: %2</t>",
        _alertMessage,
        _posGrid
    ];
    _hintMsg remoteExec ["hint", 0];
};

// ============================================================
// FINALIZE
// ============================================================
_missionData set ["aiGroups", _allGroups];
_missionData set ["vehicles", _allVehicles];
_missionData set ["lootBoxes", _allLoot];

// Register with A3XAI mission system
A3XAI_activeMissions pushBack _missionData;
DyCE_ActiveConvoys pushBack _missionData;
DyCE_LastSpawnTime = time;
DyCE_TotalSpawned = DyCE_TotalSpawned + 1;

// Calculate total AI count
private _totalAI = 0;
{_totalAI = _totalAI + count units _x} forEach _allGroups;

[3, format ["[DyCE] %1 spawned: %2 vehicles, %3 AI at %4",
    _name, count _allVehicles,
    _totalAI,
    _spawnPos]] call A3XAI_fnc_log;

_missionData
