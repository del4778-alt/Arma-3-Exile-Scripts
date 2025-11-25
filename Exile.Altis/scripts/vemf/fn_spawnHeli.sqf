params ["_pos"];

private _heliPos = _pos vectorAdd [0,0,120];
private _heli = createVehicle ["O_Heli_Transport_04_F", _heliPos, [], 0, "FLY"];
_heli flyInHeight 80;
_heli setSpeedMode "FULL";

private _grp = ["EAST"] call (UMC get "createSafeGroup");

for "_i" from 1 to 8 do {
    private _u = _grp createUnit ["O_Soldier_F", getPos _heli, [], 0, "NONE"];
    _u moveInCargo _heli;
    [_u] call (UMC get "applySkill");
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,10,20] call (UMC get "reward");
    }];
};

[_heli,_grp]
