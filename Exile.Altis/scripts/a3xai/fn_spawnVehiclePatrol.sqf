/*
    A3XAI Spawn Vehicle Patrol - Creates an AI vehicle patrol
    
    Parameters:
    0: Position (ideally on a road)
    
    Returns: [vehicle, group]
*/

params ["_pos"];

// Vehicle types for patrol
private _vehicleTypes = [
    "O_MRAP_02_F",
    "O_MRAP_02_hmg_F",
    "I_MRAP_03_F",
    "O_Truck_02_covered_F"
];

// Create group
private _grp = ["EAST"] call (UMC get "createSafeGroup");

if (isNull _grp) exitWith {
    diag_log "[UMC][A3XAI] ERROR: Failed to create vehicle patrol group";
    [objNull, grpNull]
};

// Create vehicle
private _vehType = selectRandom _vehicleTypes;
private _veh = createVehicle [_vehType, _pos, [], 0, "NONE"];
_veh lock 3;
_veh setVariable ["A3XAI_vehicle", true, true];

// Crew count based on vehicle capacity
private _crewCount = 2 + floor random 2;  // 2-3 crew

for "_i" from 1 to _crewCount do {
    private _u = _grp createUnit ["O_G_Soldier_F", _pos, [], 0, "NONE"];
    _u moveInAny _veh;
    [_u] call (UMC get "applySkill");
    
    _u addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        [_killer, 6, 12] call (UMC get "reward");
    }];
};

// Set up patrol waypoints along roads
private _roads = _pos nearRoads 1500;
if (count _roads >= 3) then {
    private _selectedRoads = [];
    for "_i" from 1 to 4 do {
        _selectedRoads pushBack (selectRandom _roads);
    };
    
    {
        private _wp = _grp addWaypoint [getPosATL _x, 30];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointSpeed "LIMITED";
    } forEach _selectedRoads;
    
    // Cycle back
    private _cycleWP = _grp addWaypoint [_pos, 50];
    _cycleWP setWaypointType "CYCLE";
} else {
    // No roads - just patrol in a circle
    for "_i" from 1 to 4 do {
        private _wpPos = _pos getPos [500 + random 500, _i * 90];
        private _wp = _grp addWaypoint [_wpPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
    };
    private _cycleWP = _grp addWaypoint [_pos, 50];
    _cycleWP setWaypointType "CYCLE";
};

// Track the group
_grp setVariable ["A3XAI_spawnPos", _pos, true];
_grp setVariable ["A3XAI_spawnName", "Vehicle Patrol", true];
_grp setVariable ["A3XAI_vehicle", _veh, true];

// Register with A3XAI tracking
[_grp] call (A3XAI get "registerGroup");

// Add to active groups
private _active = A3XAI get "activeGroups";
_active pushBack _grp;
A3XAI set ["activeGroups", _active];

diag_log format ["[UMC][A3XAI] Spawned vehicle patrol: %1 with %2 crew at %3", _vehType, _crewCount, _pos];

[_veh, _grp]
