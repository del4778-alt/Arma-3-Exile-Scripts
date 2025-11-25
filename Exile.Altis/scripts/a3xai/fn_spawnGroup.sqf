params ["_pos","_count"];

private _grp = ["EAST"] call (UMC get "createSafeGroup");

for "_i" from 1 to _count do {
    [_grp,_pos] call (A3XAI get "spawnUnit");
};

[_grp] call (A3XAI get "registerGroup");

_grp
