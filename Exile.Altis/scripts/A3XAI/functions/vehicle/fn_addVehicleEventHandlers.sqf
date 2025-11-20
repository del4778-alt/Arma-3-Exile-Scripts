/*
    A3XAI Elite - Add Vehicle Event Handlers
    Adds event handlers for vehicles

    Parameters:
        0: OBJECT - Vehicle

    Returns:
        BOOL - Success
*/

params ["_vehicle"];

if (isNull _vehicle) exitWith {false};

// GetIn event - prevent players from entering active AI vehicles
_vehicle addEventHandler ["GetIn", {
    params ["_vehicle", "_role", "_unit"];

    if (isPlayer _unit && {_vehicle getVariable ["A3XAI_vehicle", false]}) then {
        // Check if vehicle has active crew
        private _hasActiveCrew = false;
        {
            if (alive _x && {!isPlayer _x}) then {
                _hasActiveCrew = true;
            };
        } forEach crew _vehicle;

        // If AI still alive, kick player out
        if (_hasActiveCrew) then {
            _unit action ["Eject", _vehicle];
            if (isPlayer _unit) then {
                ["You cannot enter an active AI vehicle"] remoteExec ["systemChat", _unit];
            };
        } else {
            // Vehicle captured by player
            _vehicle setVariable ["A3XAI_playerClaimed", true, true];
            _vehicle lock 0; // Unlock for players
        };
    };
}];

// Killed event
_vehicle addEventHandler ["Killed", {
    params ["_vehicle"];

    // Remove from tracking
    A3XAI_activeVehicles = A3XAI_activeVehicles - [_vehicle];

    // Cleanup after delay
    [{
        params ["_vehicle"];
        if (!isNull _vehicle && {!(_vehicle getVariable ["A3XAI_playerClaimed", false])}) then {
            deleteVehicle _vehicle;
        };
    }, [_vehicle], 600] call A3XAI_fnc_setTimeout; // 10 minute cleanup
}];

true
