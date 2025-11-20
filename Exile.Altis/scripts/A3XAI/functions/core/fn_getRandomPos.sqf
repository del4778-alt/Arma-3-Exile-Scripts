params [["_center", []], ["_minDist", 500], ["_maxDist", 2000]];
if (count _center == 0) then {_center = [] call A3XAI_fnc_getMapCenter};
private _dist = _minDist + random (_maxDist - _minDist);
private _dir = random 360;
_center getPos [_dist, _dir]
