private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");
private _radius = getNumber (_cfg >> "despawnRadius");

private _active = A3XAI get "activeGroups";

{
    private _grp = _x;
    private _units = units _grp;

    if ((count _units) == 0) then {
        deleteGroup _grp;
        _active = _active - [_grp];
    } else {
        private _pos = getPosATL (_units select 0);
        private _near = 99999;
        {
            private _d = _pos distance _x;
            if (_d < _near) then { _near = _d };
        } forEach allPlayers;

        if (_near > _radius) then {
            { deleteVehicle _x } forEach _units;
            deleteGroup _grp;
            _active = _active - [_grp];
        };
    };
} forEach +_active;

A3XAI set ["activeGroups", _active];
