params ["_sideName"];

private _side = east;
if (_sideName isEqualTo "WEST") then {_side = west};
if (_sideName isEqualTo "GUER") then {_side = resistance};
if (_sideName isEqualTo "CIV") then {_side = civilian};

createGroup [_side, true]
