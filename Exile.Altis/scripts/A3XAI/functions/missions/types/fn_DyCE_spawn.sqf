/*
    A3XAI Elite - DyCE Unified Convoy Spawner
    Spawns any convoy type from DyCE_ConvoyTypes configuration

    Parameters:
        0: STRING - Convoy type ("armedConvoy", "troopConvoy", "heliPatrol", etc.)
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
// FIND SPAWN POSITION (Ground vehicles only)
// ============================================================
if (count _spawnPos == 0) then {
    // Auto-select spawn position based on convoy type
    if (_convoyType == "highwayPatrol") then {
        // Use highway route system
        private _route = selectRandom DyCE_HighwayRoutes;
        _spawnPos = _route select 2;  // Midpoint
    } else {
        // Ground convoy - find road near player
        private _players = allPlayers select {alive _x};
        if (count _players > 0) then {
            private _player = selectRandom _players;
            private _searchRadius = DyCE_Config get "playerProximityCheck";
            private _minDist = DyCE_Config get "minDistanceFromPlayers";

            // Find road away from player
            private _distance = _minDist + random (_searchRadius - _minDist);
            private _dir = random 360;
            private _testPos = (position _player) getPos [_distance, _dir];
            private _roads = _testPos nearRoads (DyCE_Config get "vehicleSpawnSearchRadius");

            if (count _roads > 0) then {
                _spawnPos = getPos (selectRandom _roads);
            } else {
                _spawnPos = _testPos;
            };
        } else {
            _spawnPos = [] call A3XAI_fnc_getMapCenter;
        };
    };
};

// Validate spawn - find nearest road
private _roads = _spawnPos nearRoads 300;
if (count _roads > 0) then {
    _spawnPos = getPos (_roads select 0);
} else {
    [2, format ["[DyCE] No road found for %1 at %2, using position anyway", _convoyType, _spawnPos]] call A3XAI_fnc_log;
};

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
// SPAWN VEHICLES
// ============================================================
private _vehicleCount = (_vehicleCountRange select 0) + floor(random ((_vehicleCountRange select 1) - (_vehicleCountRange select 0) + 1));
private _allGroups = [];
private _allVehicles = [];
private _allLoot = [];
private _currentPos = _spawnPos;

for "_i" from 0 to (_vehicleCount - 1) do {
    // Select vehicle class
    private _vehicleClass = selectRandom _vehicleClasses;

    // Calculate spawn position (line formation behind lead)
    private _vehSpawnPos = _currentPos getPos [50 * _i, 180];

    // Spawn vehicle
    private _vehicle = createVehicle [_vehicleClass, _vehSpawnPos, [], 0, "NONE"];
    if (isNull _vehicle) then {
        [2, format ["[DyCE] Failed to spawn vehicle: %1", _vehicleClass]] call A3XAI_fnc_log;
        continue;
    };

    _vehicle setDir (random 360);
    _vehicle setFuel (0.8 + random 0.2);
    _vehicle lock 2;

    // ========================================
    // CREATE CREW
    // ========================================
    private _group = createGroup [DyCE_Config get "aiSide", true];
    private _crewCount = (_crewRange select 0) + floor(random ((_crewRange select 1) - (_crewRange select 0) + 1));

    for "_j" from 0 to (_crewCount - 1) do {
        private _unitType = "O_Soldier_F";
        private _unit = _group createUnit [_unitType, _vehSpawnPos, [], 0, "NONE"];

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
        _unit setVariable ["DyCE_unit", true];
        _unit setVariable ["A3XAI_mission", _missionName];

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
    };

    // ========================================
    // SET GROUP BEHAVIOR
    // ========================================
    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setFormation "COLUMN";
    _group setSpeedMode "LIMITED";
    _group setVariable ["DyCE_speedLimit", _speedLimit];

    // ========================================
    // GENERATE WAYPOINTS (Ground routes)
    // ========================================
    private _waypointCount = 8;
    private _routeLength = 3000;

    private _waypoints = [_vehSpawnPos, _routeLength, _waypointCount] call A3XAI_fnc_generateRoute;

    if (count _waypoints < 3) then {
        // Fallback route
        for "_w" from 1 to _waypointCount do {
            private _wpPos = _vehSpawnPos getPos [500 * _w, (45 * _w) % 360];
            _waypoints pushBack _wpPos;
        };
    };

    {
        private _wp = _group addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointFormation "COLUMN";
    } forEach _waypoints;

    // Cycle back
    private _wp = _group addWaypoint [_waypoints select 0, 0];
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
    [_lootBox, _difficulty, "convoy"] call A3XAI_fnc_spawnLoot;

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
// SEND EXILE TOAST NOTIFICATION
// ============================================================
if (DyCE_Config get "enableNotifications" && _alertMessage != "") then {
    // Use Exile's toast notification system
    private _toastTitle = "POLICE ACTIVITY";
    private _toastText = _alertMessage;

    // Format: ["toastRequest", [type, [title, text]]]
    // Types: "SuccessTitleAndText", "ErrorTitleAndText", "InfoTitleAndText", "WarningTitleAndText"
    ["toastRequest", ["WarningTitleAndText", [_toastTitle, _toastText]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", 0];

    // Also show hint with position info
    private _posGrid = mapGridPosition _spawnPos;
    private _hintMsg = format ["<t size='1.2' color='#ff0000'>%1</t><br/><t size='0.9'>%2</t><br/><t size='0.8' color='#ffff00'>Grid: %3</t>", _toastTitle, _alertMessage, _posGrid];
    [_hintMsg] remoteExec ["hint", 0];
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

[3, format ["[DyCE] %1 spawned: %2 vehicles, %3 AI at %4",
    _name, count _allVehicles,
    {count units _x} count _allGroups,
    _spawnPos]] call A3XAI_fnc_log;

_missionData
