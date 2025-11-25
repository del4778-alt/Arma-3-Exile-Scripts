params ["_pos"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "Occupation");
private _min = getNumber (_cfg >> "patrolSizeMin");
private _max = getNumber (_cfg >> "patrolSizeMax");
private _count = _min + floor random (_max - _min + 1);

private _grp = ["EAST"] call (UMC get "createSafeGroup");

for "_i" from 1 to _count do {
    private _p = _pos getPos [random 40, random 360];
    private _u = _grp createUnit ["O_G_Soldier_F", _p, [], 3, "NONE"];
    [_u] call (UMC get "applySkill");
    private _loot = ["Tier1"] call (UMC get "getLoot");
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 3];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,3,5] call (UMC get "reward");
    }];
};

for "_i" from 1 to 3 do {
    private _wpPos = _pos getPos [random 80, random 360];
    private _wp = _grp addWaypoint [_wpPos, 20];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "SAFE";
};

private _act = OCC get "activePatrols";
_act pushBack _grp;
OCC set ["activePatrols", _act];

_grp
