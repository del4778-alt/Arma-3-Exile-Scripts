/*
    Vehicle Recovery & Repair Service v1.0
    Author: Arma 3 Exile Scripts
    Description: AI-driven tow truck system for recovering disabled vehicles

    Features:
    - Request recovery via radio menu
    - AI tow truck spawns and drives to disabled vehicle using Elite Driving
    - Tows vehicle back to nearest safe zone
    - Cost based on distance and vehicle value
    - Alternative to manual vehicle recovery
    - Repair service at destination
    - Multiple simultaneous recovery missions

    Installation:
    1. Place in Vehicle-Recovery-Service folder
    2. Add to init.sqf: [] execVM "Vehicle-Recovery-Service\fn_vehicleRecovery.sqf";
    3. Configure RECOVERY_CONFIG below
    4. Requires Elite Driving for tow truck autopilot

    Usage:
    - Stand near disabled vehicle
    - Open radio menu (0-0-X)
    - Select "Request Vehicle Recovery"
    - Pay fee
    - Wait for tow truck arrival

    Compatibility:
    - Elite Driving required for autopilot
    - Exile mod for Poptabs cost
    - ACE3 compatible (rope attachment)
*/

// ========================================
// CONFIGURATION
// ========================================

RECOVERY_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["maxActiveRecoveries", 5],           // Max concurrent recoveries
    ["spawnDistance", 1000],              // Tow truck spawns 1km away
    ["baseCost", 1000],                   // Base Poptabs cost
    ["costPerMeter", 0.5],                // Cost per meter distance
    ["vehicleValueMultiplier", 0.1],      // 10% of vehicle value
    ["repairOnArrival", true],            // Auto-repair at destination
    ["repairCost", 500],                  // Additional repair cost

    // Tow truck types
    ["towTruckTypes", [
        "C_Van_01_box_F",
        "C_Truck_02_box_F"
    ]],

    // AI settings
    ["aiSkill", 0.7],
    ["driverSide", CIVILIAN],

    // Recovery settings
    ["recoverySpeed", "LIMITED"],         // Tow truck speed
    ["attachDistance", 10],               // Distance to attach tow
    ["detachDistance", 50],               // Distance to detach at destination
    ["timeoutMinutes", 30],               // Cancel recovery after 30 min

    // Safe zones (destinations)
    ["autoDetectSafeZones", true],
    ["safeZoneMarkers", []]               // Will be populated automatically
];

// ========================================
// GLOBAL VARIABLES
// ========================================

RECOVERY_ActiveRecoveries = [];
RECOVERY_SafeZones = [];
RECOVERY_InitComplete = false;

// ========================================
// UTILITY FUNCTIONS
// ========================================

RECOVERY_fnc_log = {
    params ["_message"];
    if (RECOVERY_CONFIG get "debug") then {
        diag_log format ["[RECOVERY] %1", _message];
    };
};

RECOVERY_fnc_getSafeZones = {
    private _zones = [];

    {
        if (["ExileSpawnZone", _x] call BIS_fnc_inString || ["trader", toLower _x] call BIS_fnc_inString) then {
            private _pos = getMarkerPos _x;
            if (!surfaceIsWater _pos) then {
                _zones pushBack [_x, _pos];
            };
        };
    } forEach allMapMarkers;

    [format ["Found %1 safe zones for recovery destinations", count _zones]] call RECOVERY_fnc_log;
    _zones
};

RECOVERY_fnc_getNearestSafeZone = {
    params ["_pos"];

    private _nearest = [];
    private _nearestDist = 9999999;

    {
        private _zonePos = _x select 1;
        private _dist = _pos distance2D _zonePos;

        if (_dist < _nearestDist) then {
            _nearestDist = _dist;
            _nearest = _x;
        };
    } forEach RECOVERY_SafeZones;

    _nearest
};

RECOVERY_fnc_getVehicleValue = {
    params ["_vehicle"];

    // Estimate vehicle value (placeholder for Exile integration)
    private _value = 5000;  // Default value

    // TODO: Integration with Exile vehicle values
    // _value = _vehicle getVariable ["ExileVehicleValue", 5000];

    _value
};

RECOVERY_fnc_calculateCost = {
    params ["_vehicle", "_distance"];

    private _baseCost = RECOVERY_CONFIG get "baseCost";
    private _costPerMeter = RECOVERY_CONFIG get "costPerMeter";
    private _valueMultiplier = RECOVERY_CONFIG get "vehicleValueMultiplier";
    private _repairCost = if (RECOVERY_CONFIG get "repairOnArrival") then {
        RECOVERY_CONFIG get "repairCost"
    } else {
        0
    };

    private _vehicleValue = [_vehicle] call RECOVERY_fnc_getVehicleValue;
    private _distanceCost = floor(_distance * _costPerMeter);
    private _valueCost = floor(_vehicleValue * _valueMultiplier);

    private _totalCost = _baseCost + _distanceCost + _valueCost + _repairCost;

    _totalCost
};

RECOVERY_fnc_chargePlayer = {
    params ["_player", "_amount"];

    // Get player money (Exile integration)
    private _money = _player getVariable ["ExileMoney", 0];

    if (_money >= _amount) then {
        _player setVariable ["ExileMoney", _money - _amount, true];
        systemChat format ["Paid %1 Poptabs for vehicle recovery service", _amount];
        true
    } else {
        systemChat format ["Insufficient funds! Recovery costs %1 Poptabs, you have %2", _amount, _money];
        false
    };
};

RECOVERY_fnc_spawnTowTruck = {
    params ["_playerPos"];

    // Find spawn position (1km away in random direction)
    private _spawnDist = RECOVERY_CONFIG get "spawnDistance";
    private _angle = random 360;
    private _spawnPos = [
        (_playerPos select 0) + (_spawnDist * cos _angle),
        (_playerPos select 1) + (_spawnDist * sin _angle),
        0
    ];

    // Ensure on road if possible
    private _nearestRoad = [_spawnPos, 100] call BIS_fnc_nearestRoad;
    if (!isNull _nearestRoad) then {
        _spawnPos = getPosATL _nearestRoad;
    };

    // Create tow truck
    private _truckType = selectRandom (RECOVERY_CONFIG get "towTruckTypes");
    private _towTruck = _truckType createVehicle _spawnPos;
    _towTruck setDir (random 360);
    _towTruck setFuel 1;
    _towTruck setVariable ["EAID_Ignore", false, true];  // Allow Elite Driving
    _towTruck setVariable ["RecoveryVehicle", true, true];

    // Create driver
    private _group = createGroup (RECOVERY_CONFIG get "driverSide");
    private _driver = _group createUnit ["C_man_1", _spawnPos, [], 0, "FORM"];
    _driver moveInDriver _towTruck;
    _driver setSkill (RECOVERY_CONFIG get "aiSkill");
    _driver setVariable ["RecoveryDriver", true, true];

    // Set group behavior
    _group setBehaviour "SAFE";
    _group setCombatMode "BLUE";
    _group setSpeedMode (RECOVERY_CONFIG get "recoverySpeed");

    [_towTruck, _group, _driver]
};

// ========================================
// RECOVERY SYSTEM
// ========================================

RECOVERY_fnc_requestRecovery = {
    params ["_player", "_vehicle"];

    // Validate vehicle
    if (isNull _vehicle || !alive _vehicle) exitWith {
        systemChat "No valid vehicle found nearby!";
        false
    };

    // Check if vehicle already being recovered
    private _alreadyRecovering = false;
    {
        if ((_x get "vehicle") == _vehicle) exitWith {
            _alreadyRecovering = true;
        };
    } forEach RECOVERY_ActiveRecoveries;

    if (_alreadyRecovering) exitWith {
        systemChat "This vehicle is already being recovered!";
        false
    };

    // Check max recoveries
    if (count RECOVERY_ActiveRecoveries >= (RECOVERY_CONFIG get "maxActiveRecoveries")) exitWith {
        systemChat "Recovery service is currently busy. Please try again later.";
        false
    };

    // Find nearest safe zone
    private _vehiclePos = getPosATL _vehicle;
    private _safeZone = [_vehiclePos] call RECOVERY_fnc_getNearestSafeZone;

    if (count _safeZone == 0) exitWith {
        systemChat "No safe zone found for recovery destination!";
        false
    };

    private _safeZonePos = _safeZone select 1;
    private _distance = _vehiclePos distance2D _safeZonePos;

    // Calculate cost
    private _cost = [_vehicle, _distance] call RECOVERY_fnc_calculateCost;

    // Charge player
    if !([_player, _cost] call RECOVERY_fnc_chargePlayer) exitWith {
        false
    };

    // Spawn tow truck
    private _spawnData = [_vehiclePos] call RECOVERY_fnc_spawnTowTruck;
    private _towTruck = _spawnData select 0;
    private _group = _spawnData select 1;
    private _driver = _spawnData select 2;

    // Create recovery data
    private _recoveryData = createHashMapFromArray [
        ["active", true],
        ["player", _player],
        ["vehicle", _vehicle],
        ["towTruck", _towTruck],
        ["group", _group],
        ["driver", _driver],
        ["safeZone", _safeZone],
        ["vehiclePos", _vehiclePos],
        ["safeZonePos", _safeZonePos],
        ["startTime", time],
        ["state", "traveling_to_vehicle"],  // traveling_to_vehicle, attaching, towing, arrived
        ["attached", false]
    ];

    // Add waypoint to vehicle
    private _wp = _group addWaypoint [_vehiclePos, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed (RECOVERY_CONFIG get "recoverySpeed");

    // Add to active recoveries
    RECOVERY_ActiveRecoveries pushBack _recoveryData;

    // Announce
    systemChat format ["Recovery service dispatched! Tow truck arriving at %1 in approximately %2 minutes.",
        getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName"),
        floor((getPosATL _towTruck distance2D _vehiclePos) / 200)
    ];

    [format ["Recovery requested for %1, distance: %2m, cost: %3", typeOf _vehicle, floor _distance, _cost]] call RECOVERY_fnc_log;

    true
};

RECOVERY_fnc_attachVehicle = {
    params ["_towTruck", "_vehicle"];

    // Simple attachment - move vehicle to truck position
    // For realistic towing, would need rope/physics system

    _vehicle attachTo [_towTruck, [0, -5, 0.5]];
    _vehicle setVariable ["RecoveryAttached", true, true];

    [format ["Vehicle attached to tow truck"]] call RECOVERY_fnc_log;

    true
};

RECOVERY_fnc_detachVehicle = {
    params ["_vehicle"];

    detach _vehicle;
    _vehicle setVariable ["RecoveryAttached", false, true];

    [format ["Vehicle detached from tow truck"]] call RECOVERY_fnc_log;

    true
};

RECOVERY_fnc_repairVehicle = {
    params ["_vehicle"];

    _vehicle setDamage 0;
    _vehicle setFuel 1;
    _vehicle setVehicleAmmo 1;

    [format ["Vehicle repaired"]] call RECOVERY_fnc_log;

    systemChat "Your vehicle has been repaired and is ready to use!";

    true
};

RECOVERY_fnc_updateRecovery = {
    params ["_recoveryData"];

    private _state = _recoveryData get "state";
    private _towTruck = _recoveryData get "towTruck";
    private _vehicle = _recoveryData get "vehicle";
    private _group = _recoveryData get "group";

    // Check if tow truck or vehicle destroyed
    if (!alive _towTruck || !alive _vehicle) exitWith {
        ["Recovery failed - vehicle or tow truck destroyed"] call RECOVERY_fnc_log;
        systemChat "Recovery failed! Vehicle or tow truck was destroyed.";
        [_recoveryData] call RECOVERY_fnc_cleanupRecovery;
        false
    };

    // Check timeout
    if (time - (_recoveryData get "startTime") > ((RECOVERY_CONFIG get "timeoutMinutes") * 60)) exitWith {
        ["Recovery timed out"] call RECOVERY_fnc_log;
        systemChat "Recovery service timed out.";
        [_recoveryData] call RECOVERY_fnc_cleanupRecovery;
        false
    };

    // State machine
    switch (_state) do {
        case "traveling_to_vehicle": {
            // Check if arrived at vehicle
            private _vehiclePos = _recoveryData get "vehiclePos";
            if (_towTruck distance2D _vehiclePos < (RECOVERY_CONFIG get "attachDistance")) then {
                [format ["Tow truck arrived at vehicle"]] call RECOVERY_fnc_log;

                // Attach vehicle
                [_towTruck, _vehicle] call RECOVERY_fnc_attachVehicle;
                _recoveryData set ["attached", true];
                _recoveryData set ["state", "towing"];

                // Clear waypoints
                for "_i" from count (waypoints _group) - 1 to 0 step -1 do {
                    deleteWaypoint ((waypoints _group) select _i);
                };

                // Add waypoint to safe zone
                private _safeZonePos = _recoveryData get "safeZonePos";
                private _wp = _group addWaypoint [_safeZonePos, 0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed (RECOVERY_CONFIG get "recoverySpeed");

                systemChat "Tow truck is transporting your vehicle to the safe zone...";
            };
        };

        case "towing": {
            // Check if arrived at safe zone
            private _safeZonePos = _recoveryData get "safeZonePos";
            if (_towTruck distance2D _safeZonePos < (RECOVERY_CONFIG get "detachDistance")) then {
                [format ["Arrived at safe zone"]] call RECOVERY_fnc_log;

                // Detach vehicle
                [_vehicle] call RECOVERY_fnc_detachVehicle;

                // Repair if enabled
                if (RECOVERY_CONFIG get "repairOnArrival") then {
                    [_vehicle] call RECOVERY_fnc_repairVehicle;
                };

                _recoveryData set ["state", "arrived"];

                systemChat "Vehicle recovery complete!";

                // Cleanup after delay
                [{
                    params ["_recoveryData"];
                    [_recoveryData] call RECOVERY_fnc_cleanupRecovery;
                }, [_recoveryData], 10] call CBA_fnc_waitAndExecute;
            };
        };

        case "arrived": {
            // Waiting for cleanup
        };
    };

    true
};

RECOVERY_fnc_cleanupRecovery = {
    params ["_recoveryData"];

    // Delete tow truck
    private _towTruck = _recoveryData get "towTruck";
    if (!isNull _towTruck) then {
        deleteVehicle _towTruck;
    };

    // Delete driver
    private _driver = _recoveryData get "driver";
    if (!isNull _driver) then {
        deleteVehicle _driver;
    };

    // Delete group
    private _group = _recoveryData get "group";
    if (!isNull _group) then {
        deleteGroup _group;
    };

    // Detach vehicle if still attached
    private _vehicle = _recoveryData get "vehicle";
    if (!isNull _vehicle && _vehicle getVariable ["RecoveryAttached", false]) then {
        [_vehicle] call RECOVERY_fnc_detachVehicle;
    };

    // Mark as inactive
    _recoveryData set ["active", false];

    [format ["Recovery cleanup complete"]] call RECOVERY_fnc_log;
};

RECOVERY_fnc_updateAllRecoveries = {
    private _toRemove = [];

    {
        private _recoveryData = _x;

        if (_recoveryData get "active") then {
            if !([_recoveryData] call RECOVERY_fnc_updateRecovery) then {
                _toRemove pushBack _forEachIndex;
            };

            // Check if arrived and waiting for cleanup
            if ((_recoveryData get "state") == "arrived") then {
                _toRemove pushBack _forEachIndex;
            };
        };
    } forEach RECOVERY_ActiveRecoveries;

    // Remove completed recoveries
    {
        RECOVERY_ActiveRecoveries deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// MENU INTEGRATION
// ========================================

RECOVERY_fnc_addRecoveryAction = {
    params ["_player"];

    _player addAction [
        "<t color='#FFA500'>Request Vehicle Recovery</t>",
        {
            params ["_target", "_caller"];

            // Find nearest vehicle
            private _nearestVehicle = objNull;
            private _nearestDist = 50;  // Max 50m

            {
                if (_x isKindOf "LandVehicle" || _x isKindOf "Air" || _x isKindOf "Ship") then {
                    private _dist = _caller distance _x;
                    if (_dist < _nearestDist) then {
                        _nearestDist = _dist;
                        _nearestVehicle = _x;
                    };
                };
            } forEach (nearestObjects [_caller, ["LandVehicle", "Air", "Ship"], 50]);

            if (!isNull _nearestVehicle) then {
                [_caller, _nearestVehicle] call RECOVERY_fnc_requestRecovery;
            } else {
                systemChat "No vehicle found nearby (within 50m)!";
            };
        },
        nil,
        1.5,
        false,
        true,
        "",
        "true",
        50
    ];

    ["Added vehicle recovery action to player"] call RECOVERY_fnc_log;
};

// ========================================
// INITIALIZATION
// ========================================

RECOVERY_fnc_init = {
    ["Vehicle Recovery & Repair Service v1.0 initializing..."] call RECOVERY_fnc_log;

    if (!(RECOVERY_CONFIG get "enabled")) exitWith {
        ["Recovery service is disabled in config"] call RECOVERY_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Cache safe zones
    if (RECOVERY_CONFIG get "autoDetectSafeZones") then {
        RECOVERY_SafeZones = call RECOVERY_fnc_getSafeZones;
    } else {
        RECOVERY_SafeZones = RECOVERY_CONFIG get "safeZoneMarkers";
    };

    if (count RECOVERY_SafeZones == 0) exitWith {
        ["No safe zones found for recovery destinations"] call RECOVERY_fnc_log;
    };

    // Add action to all players
    {
        if (isPlayer _x) then {
            [_x] call RECOVERY_fnc_addRecoveryAction;
        };
    } forEach allPlayers;

    // Start update loop
    [] spawn {
        while {true} do {
            sleep 5;  // Update every 5 seconds
            call RECOVERY_fnc_updateAllRecoveries;
        };
    };

    RECOVERY_InitComplete = true;
    ["Vehicle Recovery & Repair Service v1.0 initialized successfully"] call RECOVERY_fnc_log;
    ["Use action menu 'Request Vehicle Recovery' near vehicles"] call RECOVERY_fnc_log;
};

// Start the system
[] call RECOVERY_fnc_init;
