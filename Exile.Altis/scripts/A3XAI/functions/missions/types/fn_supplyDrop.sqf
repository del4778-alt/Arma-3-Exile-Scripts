/*
    A3XAI Elite - Supply Drop Mission
    Helicopter drops supply crate via parachute with AI paratroopers
    Inspired by DMS reinforcement mechanics

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["SupplyDrop_%1", floor(random 9999)];
[3, format ["Spawning supply drop mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid supply drop spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "supplyDrop"],
    ["status", "active"],
    ["triggerType", "hybrid"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// Find safe drop zone (flat area)
private _dropZone = [_pos, 50, 150, 15, 0, 0.1, 0] call BIS_fnc_findSafePos;

// Spawn transport helicopter (EAST)
private _heliSpawn = [_dropZone select 0, _dropZone select 1, 500]; // 500m altitude
private _heliClass = switch (_difficulty) do {
    case "easy": {"O_Heli_Light_02_unarmed_F"};
    case "medium": {"O_Heli_Transport_04_covered_F"};
    case "hard": {"O_Heli_Transport_04_covered_F"};
    case "extreme": {"O_Heli_Transport_04_covered_F"};
    default {"O_Heli_Light_02_unarmed_F"};
};

private _heli = createVehicle [_heliClass, _heliSpawn, [], 0, "FLY"];
_heli setDir (random 360);
_heli setFuel 1;
_heli flyInHeight 200;

// Create pilot group
private _pilotGroup = createGroup [EAST, true];
private _pilot = _pilotGroup createUnit ["O_helipilot_F", _heliSpawn, [], 0, "NONE"];
_pilot moveInDriver _heli;
[_pilot, _difficulty] call A3XAI_fnc_setAISkill;

// Create supply crate
private _crateClass = selectRandom ["Box_NATO_Wps_F", "Box_NATO_Ammo_F", "Box_NATO_Support_F"];
private _crate = createVehicle [_crateClass, [_dropZone select 0, _dropZone select 1, 200], [], 0, "NONE"];

// Attach parachute to crate
private _parachute = createVehicle ["B_Parachute_02_F", position _crate, [], 0, "FLY"];
_crate attachTo [_parachute, [0, 0, -1]];

// Fill crate with loot
[_crate, _difficulty, "supplyDrop"] call A3XAI_fnc_spawnLoot;

// Determine paratrooper count
private _paradropCount = switch (_difficulty) do {
    case "easy": {3};
    case "medium": {5};
    case "hard": {7};
    case "extreme": {9};
    default {3};
};

// Create paratrooper group
private _paraGroup = createGroup [EAST, true];

// Spawn paratroopers
private _paratroopers = [];
for "_i" from 0 to (_paradropCount - 1) do {
    private _para = _paraGroup createUnit ["O_Soldier_F", _heliSpawn, [], 0, "NONE"];

    // Initialize AI
    [_para, _difficulty] call A3XAI_fnc_initAI;
    [_para, _difficulty] call A3XAI_fnc_setAISkill;
    [_para, _difficulty] call A3XAI_fnc_equipAI;
    [_para] call A3XAI_fnc_addAIEventHandlers;

    _paratroopers pushBack _para;
    _para moveInCargo _heli;
};

// Fly helicopter to drop zone
private _wp1 = _pilotGroup addWaypoint [_dropZone, 0];
_wp1 setWaypointType "MOVE";
_wp1 setWaypointSpeed "FULL";

// Script to handle paradrop
[_heli, _crate, _parachute, _paratroopers, _paraGroup, _dropZone, _missionData] spawn {
    params ["_heli", "_crate", "_parachute", "_paratroopers", "_paraGroup", "_dropZone", "_missionData"];

    // Wait until heli reaches drop zone
    waitUntil {sleep 1; (_heli distance2D _dropZone < 100) || !alive _heli};

    if (!alive _heli) exitWith {
        [2, "Supply drop helicopter destroyed before reaching drop zone"] call A3XAI_fnc_log;
    };

    // Drop crate
    detach _crate;

    // Eject paratroopers
    {
        if (alive _x) then {
            unassignVehicle _x;
            _x action ["GetOut", _heli];

            // Add parachute
            sleep 0.5;
            private _chute = createVehicle ["Steerable_Parachute_F", position _x, [], 0, "FLY"];
            _x moveInDriver _chute;
        };
        sleep 1;
    } forEach _paratroopers;

    // Heli flies away
    private _exitPos = [_dropZone, 2000, random 360] call BIS_fnc_relPos;
    private _wp2 = group driver _heli addWaypoint [_exitPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointSpeed "FULL";

    // Wait for crate to land
    waitUntil {sleep 1; (getPosATL _crate select 2) < 2};

    // Detach from parachute
    detach _crate;
    _crate setPos [position _crate select 0, position _crate select 1, 0];
    deleteVehicle _parachute;

    // Add smoke grenades for visibility
    private _smoke1 = "SmokeShellGreen" createVehicle (position _crate);
    private _smoke2 = "SmokeShellRed" createVehicle (_crate getPos [5, 0]);

    // Add loot detection
    _crate addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    // Wait for all paratroopers to land
    {
        waitUntil {sleep 0.5; (getPosATL _x select 2) < 2 || !alive _x};
    } forEach _paratroopers;

    // Set paratroopers to defend crate
    [_paraGroup, "defend"] call A3XAI_fnc_setGroupBehavior;

    // Add defensive waypoints around crate
    private _cratePos = position _crate;
    for "_i" from 0 to 3 do {
        private _wpPos = _cratePos getPos [25, 90 * _i];
        private _wp = _paraGroup addWaypoint [_wpPos, 0];
        _wp setWaypointType "GUARD";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointCompletionRadius 20;
    };

    private _wp = _paraGroup addWaypoint [_cratePos, 0];
    _wp setWaypointType "CYCLE";
    _wp setWaypointCompletionRadius 15;

    // Update mission data
    _missionData set ["lootBoxes", [_crate]];

    // Delete heli after it's far away
    [_heli] spawn {
        params ["_heli"];
        sleep 120;
        if (!isNull _heli) then {
            {deleteVehicle _x} forEach crew _heli;
            deleteVehicle _heli;
        };
    };
};

// Create markers
if (A3XAI_enableMissionMarkers) then {
    private _marker = createMarker [_missionName, _dropZone];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Supply Drop (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_paraGroup]];
_missionData set ["vehicles", [_heli]];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission started: Enemy supply drop detected (%1 difficulty)", _difficulty];
    [_msg] remoteExec ["systemChat", -2];
};

[3, format ["Supply drop mission '%1' spawned with %2 paratroopers", _missionName, _paradropCount]] call A3XAI_fnc_log;

_missionData
