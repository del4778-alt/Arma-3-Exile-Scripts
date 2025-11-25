private _active = OCC get "activePatrols";

{
    private _grp = _x;
    if (count units _grp == 0) then {
        deleteGroup _grp;
        _active = _active - [_grp];
    };
} forEach +_active;

OCC set ["activePatrols", _active];
