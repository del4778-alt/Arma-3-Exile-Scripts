params ["_pos"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");
private _min = getNumber (_cfg >> "aiCountMin");
private _max = getNumber (_cfg >> "aiCountMax");
private _count = _min + floor random (_max - _min + 1);

private _grp = ["EAST"] call (UMC get "createSafeGroup");

diag_log format ["[UMC][DyCE] DEBUG group side %1 for new group %2", str side _grp, _grp];

for "_i" from 1 to _count do {
    private _p = _pos getPos [random 30, random 360];
    private _u = _grp createUnit ["O_Soldier_F", _p, [], 2, "NONE"];
    [_u] call (UMC get "applySkill");
    private _loot = ["Tier2"] call (UMC get "getLoot");
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 4];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,5,10] call (UMC get "reward");
    }];
};

_grp
