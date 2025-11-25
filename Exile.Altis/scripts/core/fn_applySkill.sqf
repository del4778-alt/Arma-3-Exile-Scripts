params ["_unit"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "Difficulty");

{
    private _skill = getNumber (_cfg >> (_x select 1));
    _unit setSkill [_x select 0, _skill];
} forEach [
    ["aimingAccuracy","aimAccuracy"],
    ["aimingShake","aimShake"],
    ["aimingSpeed","aimSpeed"],
    ["spotDistance","spotDistance"],
    ["spotTime","spotTime"],
    ["courage","courage"],
    ["commanding","commanding"],
    ["reloadSpeed","reloadSpeed"]
];

_unit
