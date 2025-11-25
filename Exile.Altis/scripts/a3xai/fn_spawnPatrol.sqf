params ["_centerPos"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");
private _min = getNumber (_cfg >> "minAI");
private _max = getNumber (_cfg >> "maxAI");
private _count = _min + floor random (_max - _min + 1);

private _grp = [_centerPos,_count] call (A3XAI get "spawnGroup");

for "_i" from 1 to 3 do {
    private _wpPos = _centerPos getPos [random 150, random 360];
    private _wp = _grp addWaypoint [_wpPos, 25];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "AWARE";
};

_grp
