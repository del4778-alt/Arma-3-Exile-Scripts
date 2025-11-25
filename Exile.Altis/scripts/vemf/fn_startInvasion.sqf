if (!isServer) exitWith {};

private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
if (random 1 > getNumber (_cfg >> "invasionChance")) exitWith {};

private _town = call (VEMF get "selectTown");
if (isNil "_town") exitWith {};

private _min = getNumber (_cfg >> "minWaves");
private _max = getNumber (_cfg >> "maxWaves");
private _waves = _min + floor random (_max - _min + 1);

private _id = format ["VEMF_%1", diag_tickTime];

private _entry = [_id,_town,0,_waves,time];
private _active = VEMF get "activeInvasions";
_active pushBack _entry;
VEMF set ["activeInvasions", _active];

diag_log format ["[UMC][VEMF] invasion %1 at %2 (%3 waves)", _id,_town,_waves];

[_id] call (VEMF get "spawnWave");
