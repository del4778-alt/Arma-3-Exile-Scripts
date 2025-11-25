params ["_pos"];

private _grp = ["EAST"] call (UMC get "createSafeGroup");
private _veh = createVehicle ["O_MRAP_02_F", _pos, [], 0, "NONE"];
_veh lock 3;

for "_i" from 1 to 3 do {
    private _u = _grp createUnit ["O_Soldier_F", _pos, [], 0, "NONE"];
    _u moveInAny _veh;
    [_u] call (UMC get "applySkill");
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,5,10] call (UMC get "reward");
    }];
};

[_grp] call (A3XAI get "registerGroup");

[_veh,_grp]
