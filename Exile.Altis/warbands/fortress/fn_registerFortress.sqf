params ["_fid","_pos","_objs"];
if (isNil "WB_fortresses") then { WB_fortresses = createHashMap; };

WB_fortresses set [_fid, [
    "pos", _pos,
    "objects", _objs,
    "garrison", objNull,
    "prisonMarker", createMarker [format["WB_Prison_%1",_fid], _pos]
]];

private _m = createMarker [format["WB_Fortress_%1",_fid], _pos];
_m setMarkerShape "ICON"; _m setMarkerType "mil_flag";
_m setMarkerText format ["Fortress (%1)",_fid]; _m setMarkerColor "ColorBlue";

[_fid] call WB_fnc_spawnGarrison;
