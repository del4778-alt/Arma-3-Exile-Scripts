if (!isServer) exitWith {};
params ["_player","_prisonMarker"];
private _pos = getMarkerPos _prisonMarker;
{
    if (_x getVariable ["WB_captured",false]) then {
        _x setPosATL _pos; _x setCaptive true; _x disableAI "MOVE"; _x disableAI "FIRE";
        _x setVariable ["WB_prison", _prisonMarker, true];
    };
} forEach allUnits;
