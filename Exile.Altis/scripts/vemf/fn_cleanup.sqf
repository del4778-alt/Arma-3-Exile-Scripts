private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
private _delay = getNumber (_cfg >> "despawnDelay");

private _active = VEMF get "activeInvasions";

{
    private _start = _x select 4;
    if (time > _start + _delay) then {
        diag_log format ["[UMC][VEMF] cleanup invasion %1", _x select 0];
        _active = _active - [_x];
    };
} forEach +_active;

VEMF set ["activeInvasions", _active];
