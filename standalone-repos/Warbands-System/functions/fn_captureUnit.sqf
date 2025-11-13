if (!isServer) exitWith {};
params ["_player","_target"];
if (isNull _player || isNull _target || {!alive _target}) exitWith {};

if ((damage _target) < WB_CAPTURE_HEALTH_THRESHOLD) then {
    private _hasZip = ("Exile_Item_ZipTie" in (magazines _player + items _player + assignedItems _player));
    if (_hasZip) then {
        _player removeItem "Exile_Item_ZipTie";
        _target disableAI "MOVE"; _target disableAI "FIRE"; _target setCaptive true;
        _target setVariable ["WB_captured", true, true];
    };
};
