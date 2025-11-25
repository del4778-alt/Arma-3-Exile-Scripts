params ["_tierClass"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "Loot" >> _tierClass);

private _weapon = selectRandom (getArray (_cfg >> "weapons"));
private _mag    = selectRandom (getArray (_cfg >> "mags"));
private _item   = selectRandom (getArray (_cfg >> "items"));

[_weapon,_mag,_item]
