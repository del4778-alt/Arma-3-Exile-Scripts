params ["_pos","_count"];

private _grp = ["EAST"] call (UMC get "createSafeGroup");

for "_i" from 1 to _count do {
    private _u = _grp createUnit ["O_Soldier_F", _pos, [], 10, "NONE"];
    [_u] call (UMC get "applySkill");
    private _loot = ["Tier3"] call (UMC get "getLoot");
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 4];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,15,25] call (UMC get "reward");
    }];
};

_grp


diag_log format ["[UMC][DMS] DEBUG group side %1 for new group %2", str side _grp, _grp];
