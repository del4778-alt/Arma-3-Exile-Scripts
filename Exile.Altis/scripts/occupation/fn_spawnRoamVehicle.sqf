/*
    Occupation Roaming Vehicle - Spawns a vehicle patrol near a player
*/

// Check spawn limit
private _active = OCC get "activePatrols";
if (count _active >= 10) exitWith {
    diag_log "[UMC][Occupation] Max patrols reached, skipping roam vehicle";
};

// Find a road near a random player
if (count allPlayers == 0) exitWith {};

private _player = selectRandom allPlayers;
private _playerPos = getPosATL _player;

// Find roads 500-1500m from player
private _roads = _playerPos nearRoads 1500;
_roads = _roads select { _x distance2D _playerPos > 500 };

if (count _roads == 0) exitWith {
    diag_log "[UMC][Occupation] No suitable roads for roam vehicle";
};

private _road = selectRandom _roads;
private _pos = getPosATL _road;

// Check not too close to existing patrols
private _tooClose = false;
{
    if ((leader _x) distance2D _pos < 400) exitWith { _tooClose = true };
} forEach _active;

if (_tooClose) exitWith {
    diag_log "[UMC][Occupation] Road too close to existing patrol";
};

// Create vehicle patrol
private _grp = ["EAST"] call (UMC get "createSafeGroup");
private _vehTypes = ["O_MRAP_02_F", "O_Truck_02_covered_F", "I_MRAP_03_F"];
private _veh = createVehicle [selectRandom _vehTypes, _pos, [], 0, "NONE"];
_veh lock 3;

for "_i" from 1 to 3 do {
    private _u = _grp createUnit ["O_G_Soldier_F", _pos, [], 0, "NONE"];
    _u moveInAny _veh;
    [_u] call (UMC get "applySkill");
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer, 5, 10] call (UMC get "reward");
    }];
};

// Add patrol waypoints
for "_i" from 1 to 4 do {
    private _wpRoads = _pos nearRoads 1000;
    if (count _wpRoads > 0) then {
        private _wpPos = getPosATL (selectRandom _wpRoads);
        private _wp = _grp addWaypoint [_wpPos, 30];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointSpeed "LIMITED";
    };
};

// Cycle
private _cycleWP = _grp addWaypoint [_pos, 50];
_cycleWP setWaypointType "CYCLE";

// Track it
_active pushBack _grp;
OCC set ["activePatrols", _active];

diag_log format ["[UMC][Occupation] Spawned roam vehicle at %1", _pos];

_veh
