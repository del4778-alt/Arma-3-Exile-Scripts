params ["_pos"];

private _blockPos = _pos getPos [random 50, random 360];
private _b = createVehicle ["Land_BagFence_Round_F", _blockPos, [], 0, "CAN_COLLIDE"];
_b setDir random 360;

private _grp = ["EAST"] call (UMC get "createSafeGroup");
private _cnt = 1 + floor random 2;

for "_i" from 1 to _cnt do {
    private _p = _blockPos getPos [random 5, random 360];
    private _u = _grp createUnit ["O_Soldier_F", _p, [], 1, "NONE"];
    [_u] call (UMC get "applySkill");
    _u addWeapon "arifle_Katiba_F";
    _u addMagazines ["30Rnd_65x39_caseless_green", 3];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,4,10] call (UMC get "reward");
    }];
};

[_b,_grp]
