private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");
private _radius = getNumber (_cfg >> "spawnRadius");

if ((count allPlayers) == 0) exitWith {};

private _player = selectRandom allPlayers;
private _pos = _player getPos [random [_radius/2,_radius,_radius*1.5], random 360];

[_pos] call (A3XAI get "spawnPatrol");

if (random 1 < 0.1) then {
    [_pos] call (A3XAI get "spawnVehiclePatrol");
};

[] call (A3XAI get "despawn");
