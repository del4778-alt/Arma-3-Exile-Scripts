/*
    CONVOY SPAWN FIX - Universal Patch for Dynamic Mission Systems

    FIXES:
    - AI dying instantly when convoy spawns
    - Vehicles exploding on spawn
    - AI getting run over by their own vehicles
    - Fall damage from spawning in air
    - Collision damage from vehicles spawning too close

    COMPATIBILITY:
    - A3XAI
    - DMS (Defent's Mission System)
    - VEMF Reloaded
    - Custom mission systems

    USAGE:
    Call this function instead of directly creating vehicles:

    _vehicles = [_spawnPos, _vehicleClasses, _side] call CONVOY_fnc_SafeSpawn;

    Version: 1.0
*/

if (!isServer) exitWith {};

diag_log "[CONVOY FIX] Initializing safe convoy spawn system...";

// ============================================================
// SAFE CONVOY SPAWN FUNCTION
// ============================================================
CONVOY_fnc_SafeSpawn = {
    params [
        "_centerPos",        // [x,y,z] - Center position for convoy
        "_vehicleClasses",   // Array of vehicle classnames to spawn
        "_side",             // Side (east/west/resistance)
        ["_spacing", 25],    // Distance between vehicles (default 25m)
        ["_crewCount", 3]    // AI per vehicle (default 3)
    ];

    private _spawnedVehicles = [];
    private _spawnedUnits = [];
    private _roadPos = _centerPos;

    // Try to find a road nearby
    private _nearRoads = _centerPos nearRoads 150;
    if (count _nearRoads > 0) then {
        _roadPos = getPos (_nearRoads select 0);
        diag_log format ["[CONVOY FIX] Found road at %1m from spawn point", round (_centerPos distance2D _roadPos)];
    } else {
        diag_log "[CONVOY FIX] WARNING: No road found within 150m - spawning on terrain";
    };

    // Calculate spawn positions along road
    private _spawnPositions = [];
    private _dir = random 360;

    for "_i" from 0 to (count _vehicleClasses - 1) do {
        private _offset = _i * _spacing;
        private _pos = _roadPos getPos [_offset, _dir];
        _pos set [2, 0]; // Force ground level
        _spawnPositions pushBack [_pos, _dir];
    };

    // Spawn vehicles with safety measures
    {
        _x params ["_pos", "_heading"];
        private _vehClass = _vehicleClasses select _forEachIndex;

        diag_log format ["[CONVOY FIX] Spawning vehicle %1/%2: %3 at %4",
            _forEachIndex + 1, count _vehicleClasses, _vehClass, _pos];

        // Create vehicle with damage disabled
        private _veh = createVehicle [_vehClass, _pos, [], 0, "NONE"];

        if (isNull _veh) then {
            diag_log format ["[CONVOY FIX] ERROR: Failed to create vehicle %1", _vehClass];
        } else {
            // ✅ CRITICAL: Disable damage until fully initialized
            _veh allowDamage false;

            // Set position and direction
            _veh setPos _pos;
            _veh setDir _heading;
            _veh setVectorUp [0,0,1];

            // ✅ CRITICAL: Disable simulation briefly to prevent physics issues
            _veh enableSimulationGlobal false;

            // Clear velocity
            _veh setVelocity [0,0,0];

            // Fuel and ammo
            _veh setFuel 1;
            _veh setVehicleAmmo 1;

            // Lock for AI use
            _veh lock 2;

            // Create AI crew
            private _grp = createGroup [_side, true];

            // Driver
            private _driver = _grp createUnit ["I_Soldier_F", [0,0,0], [], 0, "NONE"];
            _driver allowDamage false; // ✅ Protect during spawn
            _driver moveInDriver _veh;
            _spawnedUnits pushBack _driver;

            // Gunner (if turret exists)
            if (count (allTurrets [_veh, true]) > 0) then {
                private _gunner = _grp createUnit ["I_Soldier_F", [0,0,0], [], 0, "NONE"];
                _gunner allowDamage false;
                _gunner moveInGunner _veh;
                _spawnedUnits pushBack _gunner;
            };

            // Cargo
            private _cargoSeats = _veh emptyPositions "cargo";
            private _cargoCrew = (_crewCount - 2) min _cargoSeats;

            for "_c" from 1 to _cargoCrew do {
                private _cargo = _grp createUnit ["I_Soldier_F", [0,0,0], [], 0, "NONE"];
                _cargo allowDamage false;
                _cargo moveInCargo _veh;
                _spawnedUnits pushBack _cargo;
            };

            // Set group behavior
            _grp setBehaviour "SAFE";
            _grp setSpeedMode "LIMITED";
            _grp setCombatMode "YELLOW";

            _spawnedVehicles pushBack _veh;

            diag_log format ["[CONVOY FIX] ✓ Vehicle spawned with %1 crew", count (crew _veh)];
        };

    } forEach _spawnPositions;

    // ✅ DELAYED INITIALIZATION - Enable everything after spawn
    [{
        params ["_vehicles", "_units"];

        diag_log format ["[CONVOY FIX] Enabling simulation and damage for %1 vehicles, %2 units",
            count _vehicles, count _units];

        // Re-enable simulation
        {
            _x enableSimulationGlobal true;
        } forEach _vehicles;

        // Wait for physics to settle
        uiSleep 1;

        // Re-enable damage
        {
            _x allowDamage true;
        } forEach _vehicles;

        {
            _x allowDamage true;
        } forEach _units;

        diag_log "[CONVOY FIX] ✓ Convoy fully initialized and ready";

    }, [_spawnedVehicles, _spawnedUnits], 2] call BIS_fnc_execVM;

    // Return array of spawned vehicles
    _spawnedVehicles
};

// ============================================================
// A3XAI INTEGRATION (if detected)
// ============================================================
if (!isNil "A3XAI_spawnVehicle") then {
    diag_log "[CONVOY FIX] A3XAI detected - patching convoy spawns...";

    // Store original function
    A3XAI_spawnVehicle_ORIGINAL = A3XAI_spawnVehicle;

    // Replace with safe version
    A3XAI_spawnVehicle = {
        params ["_vehClass", "_pos", "_dir", "_side"];

        // Use safe spawn method
        private _veh = createVehicle [_vehClass, _pos, [], 0, "NONE"];

        if (!isNull _veh) then {
            // Apply safety measures
            _veh allowDamage false;
            _veh enableSimulationGlobal false;
            _veh setPos _pos;
            _veh setDir _dir;
            _veh setVectorUp [0,0,1];
            _veh setVelocity [0,0,0];

            // Delayed enable
            [{
                params ["_v"];
                _v enableSimulationGlobal true;
                uiSleep 0.5;
                _v allowDamage true;
            }, [_veh], 1.5] call BIS_fnc_execVM;
        };

        _veh
    };

    diag_log "[CONVOY FIX] ✓ A3XAI convoy spawn patched";
};

// ============================================================
// DIAGNOSTICS
// ============================================================
CONVOY_fnc_DiagnoseMission = {
    params ["_missionPos", ["_radius", 200]];

    diag_log "========================================";
    diag_log format ["[CONVOY FIX] Diagnosing mission at %1 (radius %2m)", _missionPos, _radius];

    private _nearUnits = _missionPos nearEntities [["CAManBase"], _radius];
    private _nearVehicles = _missionPos nearEntities [["LandVehicle", "Air", "Ship"], _radius];

    diag_log format ["  Units found: %1", count _nearUnits];
    diag_log format ["  Vehicles found: %1", count _nearVehicles];

    private _deadUnits = _nearUnits select {!alive _x};
    private _deadVehicles = _nearVehicles select {!alive _x};

    diag_log format ["  Dead units: %1", count _deadUnits];
    diag_log format ["  Dead vehicles: %1", count _deadVehicles];

    if (count _deadUnits > 0) then {
        {
            private _causeOfDeath = _x getVariable ["bis_fnc_killed_by", "UNKNOWN"];
            diag_log format ["    - %1 died (cause: %2, damage: %3)",
                typeOf _x, _causeOfDeath, damage _x];
        } forEach _deadUnits;
    };

    if (count _deadVehicles > 0) then {
        {
            diag_log format ["    - %1 destroyed (damage: %2, fuel: %3)",
                typeOf _x, damage _x, fuel _x];
        } forEach _deadVehicles;
    };

    // Check for collision issues
    private _clustered = 0;
    {
        private _v1 = _x;
        private _nearby = _nearVehicles select {_x distance _v1 < 5 && _x != _v1};
        if (count _nearby > 0) then {
            _clustered = _clustered + 1;
            diag_log format ["  WARNING: Vehicle %1 has %2 vehicles within 5m (collision risk)",
                typeOf _v1, count _nearby];
        };
    } forEach _nearVehicles;

    diag_log "========================================";
};

diag_log "[CONVOY FIX] ✓ Safe convoy spawn system ready";
diag_log "[CONVOY FIX] Use: [pos, [vehClasses], side] call CONVOY_fnc_SafeSpawn";
