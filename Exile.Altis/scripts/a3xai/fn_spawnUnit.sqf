params ["_grp","_pos"];

private _u = _grp createUnit ["O_Soldier_F", _pos, [], 3, "NONE"];

[_u] call (UMC get "applySkill");

private _loot = ["Tier2"] call (UMC get "getLoot");
_u addWeapon (_loot select 0);
_u addMagazines [(_loot select 1), 4];

_u addEventHandler ["Killed", {
    params ["_unit","_killer"];
    [_killer,5,10] call (UMC get "reward");
}];

_u


diag_log format ["[UMC][A3XAI] DEBUG spawnUnit side %1 for group %2", str side _grp, _grp];
