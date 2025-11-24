/*
    A3XAI Elite - Get Vehicle Turrets
    Recursively explores all turrets and sub-turrets on a vehicle (Sarge-AI style)

    Parameters:
        0: OBJECT or STRING - Vehicle or vehicle classname
        1: ARRAY - Parent turret path (optional, for recursion)

    Returns:
        ARRAY - Array of turret paths [[0], [1], [0,0], etc.]

    v1.0: Based on Sarge-AI fn_fnc_returnVehicleTurrets pattern
*/

params ["_vehicle", ["_parentPath", []]];

private _turrets = [];
private _config = configNull;

// Get config based on input type
if (typeName _vehicle == "OBJECT") then {
    _config = configFile >> "CfgVehicles" >> typeOf _vehicle >> "Turrets";
} else {
    _config = configFile >> "CfgVehicles" >> _vehicle >> "Turrets";
};

if (isNull _config) exitWith {_turrets};

// Iterate through all turrets at this level
for "_i" from 0 to (count _config - 1) do {
    private _turretConfig = _config select _i;

    if (isClass _turretConfig) then {
        // Build turret path
        private _turretPath = _parentPath + [_i];

        // Check if this turret has weapons (armed turret)
        private _weapons = getArray (_turretConfig >> "weapons");
        private _hasWeapons = count _weapons > 0;

        // Check if this is a cargo position or actual turret
        private _isPersonTurret = getNumber (_turretConfig >> "isPersonTurret") == 1;

        // Add turret info
        _turrets pushBack [
            _turretPath,
            _hasWeapons,
            _isPersonTurret,
            configName _turretConfig
        ];

        // Recursively check for sub-turrets
        private _subTurretsConfig = _turretConfig >> "Turrets";
        if (isClass _subTurretsConfig && count _subTurretsConfig > 0) then {
            private _subTurrets = [_vehicle, _turretPath] call A3XAI_fnc_getVehicleTurrets;
            {
                _turrets pushBack _x;
            } forEach _subTurrets;
        };
    };
};

_turrets
