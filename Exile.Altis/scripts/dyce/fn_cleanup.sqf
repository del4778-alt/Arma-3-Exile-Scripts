private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");
private _delay = getNumber (_cfg >> "despawnDelay");

private _active = DYCE get "activeCrashes";

{
    private _id = _x select 0;
    private _pos = _x select 1;
    private _start = _x select 2;

    if (time > _start + _delay) then {
        diag_log format ["[UMC][DyCE] cleanup crash %1", _id];
        {
            if (_x distance _pos < 60) then { deleteVehicle _x };
        } forEach (vehicles + allDeadMen);
        _active = _active - [_x];
    };
} forEach +_active;

DYCE set ["activeCrashes", _active];
