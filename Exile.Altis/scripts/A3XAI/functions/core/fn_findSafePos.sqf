params ["_center", ["_minDist", 50], ["_maxDist", 500], ["_waterMode", 0]];
private _safePos = [_center, _minDist, _maxDist, 5, _waterMode, 0.3, 0] call BIS_fnc_findSafePos;
if (count _safePos == 0) then {_safePos = _center};
_safePos
