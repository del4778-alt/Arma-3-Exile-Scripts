params ["_pos"];
if (isNil "A3XAI_blacklistZones") exitWith {false};
private _inZone = false;
{
    _x params ["_name", "_center", "_radius"];
    if (_pos distance2D _center < _radius) exitWith {_inZone = true};
} forEach A3XAI_blacklistZones;
_inZone
