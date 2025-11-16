/*
    CONVOY SPAWN FIX - Patch for fn_dynamicMissions.sqf

    PROBLEM: Convoys spawn with AI/vehicles dead due to:
    - 15m spacing (too close, causes collisions)
    - Random vehicle directions (collision risk)
    - No damage/simulation protection during spawn

    SOLUTION: Replace MISSION_fnc_createConvoy function with this safe version

    INSTALLATION:
    1. Open fn_dynamicMissions.sqf
    2. Find the MISSION_fnc_createConvoy function (around line 310)
    3. Replace the ENTIRE function with this code
    4. Save and restart server
*/

// ========================================
// FIXED MISSION TYPE: CONVOY INTERCEPT
// ========================================

MISSION_fnc_createConvoy = {
    params ["_pos"];

    private _difficulty = selectRandom ["medium", "hard"];  // No easy convoys
    private _missionData = createHashMapFromArray [
        ["type", "convoy"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["moving", true]
    ];

    // Determine destination (1000-2000m away)
    private _distance = 1000 + random 1000;
    private _angle = random 360;
    private _destination = [
        (_pos select 0) + (_distance * cos _angle),
        (_pos select 1) + (_distance * sin _angle),
        0
    ];
    _missionData set ["destination", _destination];

    // Create convoy vehicles with SAFE SPAWN
    private _vehicles = [];
    private _allCrew = [];  // Track all spawned crew
    private _vehicleCount = if (_difficulty == "hard") then { 3 } else { 2 };

    // ✅ FIX #1: All vehicles face same direction (convoy formation)
    private _convoyDirection = random 360;

    for "_i" from 0 to (_vehicleCount - 1) do {
        // ✅ FIX #2: INCREASED SPACING from 15m to 30m
        private _vehiclePos = [
            (_pos select 0) + (_i * 30 * cos _convoyDirection),
            (_pos select 1) + (_i * 30 * sin _convoyDirection),
            0  // ✅ FIX #3: Force ground level
        ];

        private _vehicleType = selectRandom (MISSION_CONFIG get "lootVehicles");

        // ✅ FIX #4: Create vehicle with safety measures
        private _vehicle = _vehicleType createVehicle _vehiclePos;

        // ✅ FIX #5: CRITICAL - Disable damage and simulation during spawn
        _vehicle allowDamage false;
        _vehicle enableSimulationGlobal false;

        // ✅ FIX #6: Set position, direction, and physics properly
        _vehicle setPos _vehiclePos;
        _vehicle setDir _convoyDirection;  // Same direction as convoy
        _vehicle setVectorUp [0,0,1];      // Level vehicle
        _vehicle setVelocity [0,0,0];      // Clear any velocity

        // Set vehicle properties
        _vehicle setFuel 1;
        _vehicle setVariable ["EAID_Ignore", false, true];  // Allow Elite Driving control
        _vehicle setVariable ["ConvoyVehicle", true, true];

        _vehicles pushBack _vehicle;

        // Create AI crew
        private _group = createGroup EAST;

        // ✅ FIX #7: Protect AI during spawn too
        // Driver
        private _driver = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _driver allowDamage false;  // ✅ Protect from spawn damage
        _driver moveInDriver _vehicle;
        _driver setSkill (MISSION_CONFIG get "aiSkill");
        _allCrew pushBack _driver;

        // Gunner
        private _gunner = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _gunner allowDamage false;  // ✅ Protect from spawn damage
        _gunner moveInGunner _vehicle;
        _gunner setSkill (MISSION_CONFIG get "aiSkill");
        _allCrew pushBack _gunner;

        // Cargo troops
        private _cargoCount = 2;
        for "_j" from 1 to _cargoCount do {
            private _cargo = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
            _cargo allowDamage false;  // ✅ Protect from spawn damage
            _cargo moveInCargo _vehicle;
            _cargo setSkill (MISSION_CONFIG get "aiSkill");
            _allCrew pushBack _cargo;
        };

        // Set waypoint to destination
        private _wp = _group addWaypoint [_destination, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";

        // Store group
        if (!isNil "MISSION_ActiveMissions") then {
            _missionData set ["aiGroups", (_missionData getOrDefault ["aiGroups", []]) + [_group]];
        };
    };

    _missionData set ["vehicles", _vehicles];

    // Add loot to last vehicle
    private _lastVehicle = _vehicles select (count _vehicles - 1);
    clearBackpackCargoGlobal _lastVehicle;
    clearItemCargoGlobal _lastVehicle;
    clearMagazineCargoGlobal _lastVehicle;
    clearWeaponCargoGlobal _lastVehicle;

    // Add valuable loot
    for "_i" from 1 to 5 do {
        _lastVehicle addWeaponCargoGlobal [selectRandom (MISSION_CONFIG get "lootWeapons"), 1];
    };
    for "_i" from 1 to 10 do {
        _lastVehicle addItemCargoGlobal [selectRandom (MISSION_CONFIG get "lootItems"), 1];
    };

    // ✅ FIX #8: CRITICAL - DELAYED ACTIVATION
    // This prevents collision damage by allowing vehicles to settle before enabling physics
    [{
        params ["_vehArray", "_crewArray"];

        diag_log format ["[MISSION FIX] Enabling simulation for %1 convoy vehicles", count _vehArray];

        // Step 1: Re-enable simulation
        {
            _x enableSimulationGlobal true;
        } forEach _vehArray;

        // Step 2: Wait for physics to settle (1 second)
        uiSleep 1;

        // Step 3: Re-enable damage for vehicles
        {
            _x allowDamage true;
        } forEach _vehArray;

        // Step 4: Re-enable damage for all crew
        {
            _x allowDamage true;
        } forEach _crewArray;

        diag_log format ["[MISSION FIX] ✓ Convoy fully initialized - %1 vehicles, %2 crew ready",
            count _vehArray, count _crewArray];

    }, [_vehicles, _allCrew], 2] call BIS_fnc_execVM;  // ✅ 2-second delay before activation

    // Create marker
    private _marker = [_pos, "convoy", format ["Convoy [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    [format ["Convoy mission spawned at %1 (Difficulty: %2, Vehicles: %3)", _pos, _difficulty, count _vehicles]] call MISSION_fnc_log;

    _missionData
};

/*
    CHANGES MADE:

    ✅ FIX #1: All vehicles now face same direction (convoy formation) - prevents head-on collisions
    ✅ FIX #2: Increased spacing from 15m to 30m - prevents side collisions
    ✅ FIX #3: Force ground level (z=0) - prevents fall damage
    ✅ FIX #4: Create with createVehicle as before (no change needed)
    ✅ FIX #5: allowDamage false + enableSimulationGlobal false during spawn - CRITICAL
    ✅ FIX #6: Proper positioning with setVectorUp and setVelocity - prevents physics issues
    ✅ FIX #7: Protect AI crew with allowDamage false during spawn
    ✅ FIX #8: 2-second delayed activation - gives physics time to settle

    EXPECTED RESULT:
    - Vehicles spawn in proper convoy formation
    - 30m spacing prevents collisions
    - Damage disabled during spawn prevents instant deaths
    - 2-second delay allows physics to stabilize
    - All AI and vehicles should be alive and functional when mission is active

    TESTING:
    1. Spawn a convoy mission
    2. Teleport to mission location: player setPos <mission pos>
    3. Check: All vehicles intact? All AI alive?
    4. Check RPT logs for "[MISSION FIX]" messages
*/
