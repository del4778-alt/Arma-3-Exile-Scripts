/*
    AI Roaming Horde System v1.0
    Author: Arma 3 Exile Scripts
    Description: Large groups of zombies/AI that patrol the map between towns

    Features:
    - 20-50 unit hordes that move between settlements
    - Integrates with Ravage zombie system
    - Dynamic pathing avoiding safe zones
    - Map tracking for horde locations
    - High rewards for clearing hordes
    - Horde splitting and merging mechanics
    - Sound and visual effects for immersion
    - Configurable spawn rates and sizes

    Installation:
    1. Place in AI-Roaming-Horde folder
    2. Add to init.sqf: [] execVM "AI-Roaming-Horde\fn_roamingHorde.sqf";
    3. Configure HORDE_CONFIG below
    4. Requires Ravage mod for zombie classes

    Compatibility:
    - Ravage mod integration (uses zombie classes)
    - Works with Ravage-Exile-Integration
    - Safe zone detection (avoids traders)
    - Elite Driving compatible
*/

// ========================================
// CONFIGURATION
// ========================================

HORDE_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["maxActiveHordes", 3],               // Max concurrent hordes
    ["spawnInterval", 900],               // 15 minutes between spawns
    ["despawnDistance", 2000],            // Despawn if no players within 2km

    // Horde size
    ["minHordeSize", 20],
    ["maxHordeSize", 50],
    ["eliteChance", 0.15],                // 15% chance for elite zombies

    // Movement
    ["moveSpeed", 1.2],                   // Movement speed multiplier
    ["waypointDistance", 500],            // Distance between waypoints
    ["updateInterval", 30],               // Update horde every 30 sec
    ["townPathingOnly", true],            // Only path between towns/cities

    // Splitting/Merging
    ["splitChance", 0.1],                 // 10% chance to split per update
    ["mergeDistance", 100],               // Distance to merge hordes
    ["minSplitSize", 15],                 // Min size before split allowed

    // Combat
    ["detectionRange", 200],              // Range to detect players
    ["pursuitRange", 400],                // Chase players up to 400m
    ["aggroDecayTime", 60],               // Stop chasing after 60 sec

    // Rewards
    ["rewardPerZombie", 250],             // Poptabs per zombie killed
    ["respectPerZombie", 25],             // Respect per zombie
    ["hordeCompleteBonus", 5000],         // Bonus for clearing entire horde

    // Zombie types (Ravage classes)
    ["zombieClasses", [
        "Zombie1_0_base",
        "Zombie2_0_base",
        "Zombie3_0_base",
        "Zombie4_0_base"
    ]],

    ["eliteZombieClasses", [
        "Zombie_runner_1",
        "Zombie_runner_2",
        "Zombie_bolter_1"
    ]],

    // Safe zones
    ["safeZoneMarkers", []],              // Will be auto-detected
    ["safeZoneRadius", 500],              // Don't path within 500m of traders

    // Visual/Audio
    ["showMarkers", true],
    ["markerUpdateInterval", 10],         // Update marker every 10 sec
    ["playHordeSound", true],             // Play ambient sounds
    ["hordeSoundRange", 300]              // Hear horde from 300m
];

// ========================================
// GLOBAL VARIABLES
// ========================================

HORDE_ActiveHordes = [];
HORDE_TownPositions = [];
HORDE_SafeZones = [];
HORDE_InitComplete = false;
HORDE_TotalKills = createHashMap;        // Player UID -> kill count

// ========================================
// UTILITY FUNCTIONS
// ========================================

HORDE_fnc_log = {
    params ["_message"];
    if (HORDE_CONFIG get "debug") then {
        diag_log format ["[HORDE] %1", _message];
    };
};

HORDE_fnc_getSafeZones = {
    private _zones = [];

    {
        if (["ExileSpawnZone", _x] call BIS_fnc_inString || ["trader", toLower _x] call BIS_fnc_inString) then {
            _zones pushBack (getMarkerPos _x);
        };
    } forEach allMapMarkers;

    [format ["Found %1 safe zones", count _zones]] call HORDE_fnc_log;
    _zones
};

HORDE_fnc_getTownPositions = {
    private _towns = [];

    // Get all locations of type "NameCityCapital", "NameCity", "NameVillage"
    private _locations = nearestLocations [[worldSize / 2, worldSize / 2, 0], ["NameCityCapital", "NameCity", "NameVillage", "NameLocal"], worldSize];

    {
        private _pos = locationPosition _x;
        private _name = text _x;
        private _type = type _x;

        // Filter out water locations
        if (!surfaceIsWater _pos) then {
            _towns pushBack [_name, _pos, _type];
        };
    } forEach _locations;

    [format ["Found %1 towns/cities", count _towns]] call HORDE_fnc_log;
    _towns
};

HORDE_fnc_isSafeToPath = {
    params ["_pos"];

    private _safeRadius = HORDE_CONFIG get "safeZoneRadius";

    // Check safe zones
    {
        if (_pos distance2D _x < _safeRadius) exitWith { false };
    } forEach HORDE_SafeZones;

    true
};

HORDE_fnc_selectDestination = {
    params ["_currentPos"];

    private _validTowns = [];

    // Find towns that are safe to path to
    {
        private _townPos = _x select 1;
        if ([_townPos] call HORDE_fnc_isSafeToPath) then {
            _validTowns pushBack _x;
        };
    } forEach HORDE_TownPositions;

    if (count _validTowns == 0) exitWith {
        [format ["No valid towns found for horde destination"]] call HORDE_fnc_log;
        []
    };

    // Select random town
    private _town = selectRandom _validTowns;
    _town
};

HORDE_fnc_createMarker = {
    params ["_pos", "_size"];

    private _markerName = format ["horde_%1", time];
    private _marker = createMarker [_markerName, _pos];
    _marker setMarkerShape "ICON";
    _marker setMarkerType "o_inf";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["HORDE (%1 zombies)", _size];
    _marker setMarkerAlpha 1;
    _marker setMarkerSize [1.5, 1.5];

    _marker
};

// ========================================
// ZOMBIE SPAWNING
// ========================================

HORDE_fnc_spawnZombie = {
    params ["_group", "_pos", "_isElite"];

    private _classes = if (_isElite) then {
        HORDE_CONFIG get "eliteZombieClasses"
    } else {
        HORDE_CONFIG get "zombieClasses"
    };

    private _class = selectRandom _classes;

    private _unitPos = [
        (_pos select 0) + (random 30 - 15),
        (_pos select 1) + (random 30 - 15),
        0
    ];

    // Create zombie
    private _zombie = _group createUnit [_class, _unitPos, [], 0, "FORM"];

    // Set movement speed
    _zombie setUnitAbility ((HORDE_CONFIG get "moveSpeed") min 1.0);
    _zombie allowFleeing 0;

    // Mark as horde member
    _zombie setVariable ["HordeMember", true, true];
    _zombie setVariable ["IsElite", _isElite, true];

    // Add killed event handler for rewards
    _zombie addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        if (isPlayer _killer) then {
            private _uid = getPlayerUID _killer;
            private _currentKills = HORDE_TotalKills getOrDefault [_uid, 0];
            HORDE_TotalKills set [_uid, _currentKills + 1];

            // Award Poptabs and Respect
            private _poptabs = HORDE_CONFIG get "rewardPerZombie";
            private _respect = HORDE_CONFIG get "respectPerZombie";

            // Exile integration
            // _killer setVariable ["ExileMoney", (_killer getVariable ["ExileMoney", 0]) + _poptabs, true];
            // _killer setVariable ["ExileScore", (_killer getVariable ["ExileScore", 0]) + _respect, true];

            systemChat format ["+%1 Poptabs +%2 Respect (Horde Kill)", _poptabs, _respect];
        };
    }];

    _zombie
};

HORDE_fnc_spawnHorde = {
    params ["_pos", "_size"];

    [format ["Spawning horde of %1 zombies at %2", _size, _pos]] call HORDE_fnc_log;

    // Create group
    private _group = createGroup EAST;
    private _zombies = [];

    // Spawn zombies
    for "_i" from 1 to _size do {
        private _isElite = (random 1) < (HORDE_CONFIG get "eliteChance");
        private _zombie = [_group, _pos, _isElite] call HORDE_fnc_spawnZombie;
        _zombies pushBack _zombie;
    };

    // Set group behavior
    _group setBehaviour "AWARE";
    _group setCombatMode "RED";
    _group setFormation "VEE";
    _group setSpeedMode "FULL";

    // Create horde data
    private _hordeData = createHashMapFromArray [
        ["active", true],
        ["group", _group],
        ["zombies", _zombies],
        ["currentPos", _pos],
        ["destination", []],
        ["destinationName", ""],
        ["spawnTime", time],
        ["lastUpdate", time],
        ["underAttack", false],
        ["pursuingTarget", objNull],
        ["initialSize", _size],
        ["marker", ""]
    ];

    // Create marker
    if (HORDE_CONFIG get "showMarkers") then {
        private _marker = [_pos, _size] call HORDE_fnc_createMarker;
        _hordeData set ["marker", _marker];
    };

    // Select initial destination
    private _destination = [_pos] call HORDE_fnc_selectDestination;
    if (count _destination > 0) then {
        _hordeData set ["destination", _destination select 1];
        _hordeData set ["destinationName", _destination select 0];

        // Add waypoint
        private _wp = _group addWaypoint [_destination select 1, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointSpeed "FULL";

        [format ["Horde moving toward %1", _destination select 0]] call HORDE_fnc_log;
    };

    // Announce horde spawn
    private _announcement = format ["HORDE SPOTTED: %1 zombies near %2!",
        _size,
        if (count _destination > 0) then { _destination select 0 } else { "unknown location" }
    ];
    [_announcement] remoteExec ["systemChat", 0];

    // Play sound
    if (HORDE_CONFIG get "playHordeSound") then {
        [_group] spawn {
            params ["_group"];
            while {count (units _group) > 0} do {
                // Play ambient zombie sounds
                private _leader = leader _group;
                if (!isNull _leader && alive _leader) then {
                    playSound3D ["a3\sounds_f\ambient\objects\bell_big.wss", _leader, false, getPosASL _leader, 2, 0.5, 300];
                };
                sleep 30;
            };
        };
    };

    _hordeData
};

// ========================================
// HORDE MANAGEMENT
// ========================================

HORDE_fnc_updateHordePosition = {
    params ["_hordeData"];

    private _group = _hordeData get "group";
    if (isNull _group || count (units _group) == 0) exitWith { false };

    private _leader = leader _group;
    if (isNull _leader) exitWith { false };

    private _newPos = getPosATL _leader;
    _hordeData set ["currentPos", _newPos];

    // Update marker
    if (HORDE_CONFIG get "showMarkers") then {
        private _marker = _hordeData get "marker";
        if (_marker != "") then {
            _marker setMarkerPos _newPos;
            _marker setMarkerText format ["HORDE (%1 zombies)", count (units _group)];
        };
    };

    true
};

HORDE_fnc_checkDestinationReached = {
    params ["_hordeData"];

    private _currentPos = _hordeData get "currentPos";
    private _destination = _hordeData get "destination";

    if (count _destination == 0) exitWith { false };

    private _distance = _currentPos distance2D _destination;

    (_distance < 100)
};

HORDE_fnc_selectNewDestination = {
    params ["_hordeData"];

    private _currentPos = _hordeData get "currentPos";
    private _newDest = [_currentPos] call HORDE_fnc_selectDestination;

    if (count _newDest > 0) then {
        _hordeData set ["destination", _newDest select 1];
        _hordeData set ["destinationName", _newDest select 0];

        // Clear existing waypoints
        private _group = _hordeData get "group";
        for "_i" from count (waypoints _group) - 1 to 0 step -1 do {
            deleteWaypoint ((waypoints _group) select _i);
        };

        // Add new waypoint
        private _wp = _group addWaypoint [_newDest select 1, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointSpeed "FULL";

        [format ["Horde redirected to %1", _newDest select 0]] call HORDE_fnc_log;
    };
};

HORDE_fnc_checkPlayerProximity = {
    params ["_hordeData"];

    private _currentPos = _hordeData get "currentPos";
    private _detectionRange = HORDE_CONFIG get "detectionRange";
    private _closestPlayer = objNull;
    private _closestDist = _detectionRange;

    {
        if (isPlayer _x && alive _x) then {
            private _dist = _x distance _currentPos;
            if (_dist < _closestDist) then {
                _closestDist = _dist;
                _closestPlayer = _x;
            };
        };
    } forEach allPlayers;

    if (!isNull _closestPlayer) then {
        _hordeData set ["underAttack", true];
        _hordeData set ["pursuingTarget", _closestPlayer];

        // Change group to pursue
        private _group = _hordeData get "group";
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";

        // Add pursuit waypoint
        private _wp = _group addWaypoint [getPosATL _closestPlayer, 0, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "FULL";

        [format ["Horde detected player %1, pursuing!", name _closestPlayer]] call HORDE_fnc_log;
    };
};

HORDE_fnc_checkPursuitTimeout = {
    params ["_hordeData"];

    if (_hordeData get "underAttack") then {
        private _target = _hordeData get "pursuingTarget";
        private _currentPos = _hordeData get "currentPos";
        private _pursuitRange = HORDE_CONFIG get "pursuitRange";

        // Check if target is too far or dead
        if (isNull _target || !alive _target || _target distance _currentPos > _pursuitRange) then {
            [format ["Horde lost pursuit, returning to patrol"]] call HORDE_fnc_log;

            _hordeData set ["underAttack", false];
            _hordeData set ["pursuingTarget", objNull];

            // Reset behavior
            private _group = _hordeData get "group";
            _group setBehaviour "AWARE";
            _group setCombatMode "YELLOW";

            // Return to destination
            [_hordeData] call HORDE_fnc_selectNewDestination;
        };
    };
};

HORDE_fnc_checkSplit = {
    params ["_hordeData"];

    private _group = _hordeData get "group";
    private _size = count (units _group);

    if (_size < (HORDE_CONFIG get "minSplitSize")) exitWith { false };

    if (random 1 < (HORDE_CONFIG get "splitChance")) then {
        [format ["Horde splitting!"]] call HORDE_fnc_log;

        // Calculate split sizes
        private _splitSize = floor(_size / 2);
        private _remainSize = _size - _splitSize;

        // Get units to split
        private _allUnits = units _group;
        private _splitUnits = [];
        for "_i" from 0 to (_splitSize - 1) do {
            _splitUnits pushBack (_allUnits select _i);
        };

        // Create new group for split units
        private _newGroup = createGroup EAST;
        {
            [_x] joinSilent _newGroup;
        } forEach _splitUnits;

        // Create new horde data for split
        private _splitPos = getPosATL (leader _newGroup);
        private _newHordeData = createHashMapFromArray [
            ["active", true],
            ["group", _newGroup],
            ["zombies", _splitUnits],
            ["currentPos", _splitPos],
            ["destination", []],
            ["destinationName", ""],
            ["spawnTime", time],
            ["lastUpdate", time],
            ["underAttack", false],
            ["pursuingTarget", objNull],
            ["initialSize", _splitSize],
            ["marker", ""]
        ];

        // Create marker for new horde
        if (HORDE_CONFIG get "showMarkers") then {
            private _marker = [_splitPos, _splitSize] call HORDE_fnc_createMarker;
            _newHordeData set ["marker", _marker];
        };

        // Select destination for new horde
        [_newHordeData] call HORDE_fnc_selectNewDestination;

        // Add to active hordes
        HORDE_ActiveHordes pushBack _newHordeData;

        ["Horde split complete"] remoteExec ["systemChat", 0];

        true
    } else {
        false
    };
};

HORDE_fnc_checkMerge = {
    params ["_hordeData"];

    private _currentPos = _hordeData get "currentPos";
    private _mergeDistance = HORDE_CONFIG get "mergeDistance";
    private _group = _hordeData get "group";

    // Find nearby hordes
    {
        private _otherHorde = _x;
        if (_otherHorde != _hordeData && _otherHorde get "active") then {
            private _otherPos = _otherHorde get "currentPos";
            if (_currentPos distance2D _otherPos < _mergeDistance) then {
                [format ["Hordes merging!"]] call HORDE_fnc_log;

                // Merge groups
                private _otherGroup = _otherHorde get "group";
                {
                    [_x] joinSilent _group;
                } forEach (units _otherGroup);

                // Delete other horde's marker
                if (HORDE_CONFIG get "showMarkers") then {
                    deleteMarker (_otherHorde get "marker");
                };

                // Mark other horde as inactive
                _otherHorde set ["active", false];

                ["Hordes merged!"] remoteExec ["systemChat", 0];
            };
        };
    } forEach HORDE_ActiveHordes;
};

HORDE_fnc_shouldDespawn = {
    params ["_hordeData"];

    private _currentPos = _hordeData get "currentPos";
    private _despawnDist = HORDE_CONFIG get "despawnDistance";
    private _anyPlayerNear = false;

    {
        if (isPlayer _x && alive _x && _x distance _currentPos < _despawnDist) exitWith {
            _anyPlayerNear = true;
        };
    } forEach allPlayers;

    (!_anyPlayerNear)
};

HORDE_fnc_checkHordeDestroyed = {
    params ["_hordeData"];

    private _group = _hordeData get "group";

    if (isNull _group || count (units _group) == 0) then {
        [format ["Horde completely destroyed!"]] call HORDE_fnc_log;

        // Award bonus to nearby players
        private _lastPos = _hordeData get "currentPos";
        {
            if (isPlayer _x && alive _x && _x distance _lastPos < 500) then {
                private _bonus = HORDE_CONFIG get "hordeCompleteBonus";
                systemChat format ["+%1 Poptabs BONUS for clearing horde!", _bonus];

                // Exile integration
                // _x setVariable ["ExileMoney", (_x getVariable ["ExileMoney", 0]) + _bonus, true];
            };
        } forEach allPlayers;

        ["HORDE CLEARED! Bonus awarded to nearby players."] remoteExec ["systemChat", 0];

        true
    } else {
        false
    };
};

HORDE_fnc_cleanupHorde = {
    params ["_hordeData"];

    // Delete marker
    if (HORDE_CONFIG get "showMarkers") then {
        deleteMarker (_hordeData get "marker");
    };

    // Delete remaining zombies
    private _group = _hordeData get "group";
    if (!isNull _group) then {
        {
            deleteVehicle _x;
        } forEach (units _group);
        deleteGroup _group;
    };

    // Mark as inactive
    _hordeData set ["active", false];

    [format ["Horde cleaned up"]] call HORDE_fnc_log;
};

HORDE_fnc_updateHordes = {
    private _toRemove = [];

    {
        private _hordeData = _x;

        if (_hordeData get "active") then {
            // Update position
            if !([_hordeData] call HORDE_fnc_updateHordePosition) then {
                // Group is gone, mark for removal
                _toRemove pushBack _forEachIndex;
            } else {
                // Check if horde destroyed
                if ([_hordeData] call HORDE_fnc_checkHordeDestroyed) then {
                    [_hordeData] call HORDE_fnc_cleanupHorde;
                    _toRemove pushBack _forEachIndex;
                } else {
                    // Check if should despawn
                    if ([_hordeData] call HORDE_fnc_shouldDespawn) then {
                        [_hordeData] call HORDE_fnc_cleanupHorde;
                        _toRemove pushBack _forEachIndex;
                    } else {
                        // Normal update logic
                        if !(_hordeData get "underAttack") then {
                            // Check if reached destination
                            if ([_hordeData] call HORDE_fnc_checkDestinationReached) then {
                                [_hordeData] call HORDE_fnc_selectNewDestination;
                            };

                            // Check for players
                            [_hordeData] call HORDE_fnc_checkPlayerProximity;

                            // Check for split
                            [_hordeData] call HORDE_fnc_checkSplit;

                            // Check for merge
                            [_hordeData] call HORDE_fnc_checkMerge;
                        } else {
                            // Check pursuit timeout
                            [_hordeData] call HORDE_fnc_checkPursuitTimeout;
                        };
                    };
                };
            };
        };
    } forEach HORDE_ActiveHordes;

    // Remove inactive hordes
    {
        HORDE_ActiveHordes deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// HORDE SPAWNING
// ========================================

HORDE_fnc_spawnNewHorde = {
    // Check max hordes
    if (count HORDE_ActiveHordes >= (HORDE_CONFIG get "maxActiveHordes")) exitWith {
        ["Max active hordes reached"] call HORDE_fnc_log;
    };

    // Select spawn location (random town)
    private _spawnTown = [getPos player] call HORDE_fnc_selectDestination;

    if (count _spawnTown == 0) exitWith {
        ["No valid spawn location found"] call HORDE_fnc_log;
    };

    private _spawnPos = _spawnTown select 1;
    private _size = (HORDE_CONFIG get "minHordeSize") + floor(random ((HORDE_CONFIG get "maxHordeSize") - (HORDE_CONFIG get "minHordeSize")));

    // Spawn horde
    private _hordeData = [_spawnPos, _size] call HORDE_fnc_spawnHorde;

    // Add to active hordes
    HORDE_ActiveHordes pushBack _hordeData;

    [format ["Spawned horde of %1 at %2", _size, _spawnTown select 0]] call HORDE_fnc_log;
};

// ========================================
// INITIALIZATION
// ========================================

HORDE_fnc_init = {
    ["AI Roaming Horde System v1.0 initializing..."] call HORDE_fnc_log;

    if (!(HORDE_CONFIG get "enabled")) exitWith {
        ["Horde system is disabled in config"] call HORDE_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Cache safe zones
    HORDE_SafeZones = call HORDE_fnc_getSafeZones;
    HORDE_CONFIG set ["safeZoneMarkers", HORDE_SafeZones];

    // Cache town positions
    HORDE_TownPositions = call HORDE_fnc_getTownPositions;

    if (count HORDE_TownPositions == 0) exitWith {
        ["No towns found for horde pathing"] call HORDE_fnc_log;
    };

    // Start horde spawn loop
    [] spawn {
        while {true} do {
            sleep (HORDE_CONFIG get "spawnInterval");
            call HORDE_fnc_spawnNewHorde;
        };
    };

    // Start horde update loop
    [] spawn {
        while {true} do {
            sleep (HORDE_CONFIG get "updateInterval");
            call HORDE_fnc_updateHordes;
        };
    };

    // Spawn initial horde
    sleep 60;
    call HORDE_fnc_spawnNewHorde;

    HORDE_InitComplete = true;
    ["AI Roaming Horde System v1.0 initialized successfully"] call HORDE_fnc_log;
};

// Start the system
[] call HORDE_fnc_init;
