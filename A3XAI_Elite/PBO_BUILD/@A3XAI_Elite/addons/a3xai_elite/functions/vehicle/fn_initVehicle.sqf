/*
    A3XAI Elite - Initialize Vehicle
    Basic vehicle initialization

    Parameters:
        0: OBJECT - Vehicle

    Returns:
        BOOL - Success
*/

params ["_vehicle"];

if (isNull _vehicle) exitWith {false};

// Mark as A3XAI vehicle
_vehicle setVariable ["A3XAI_vehicle", true, true];
_vehicle setVariable ["A3XAI_spawnTime", time];

// Initialize stuck detection variables
_vehicle setVariable ["A3XAI_lastPos", getPosATL _vehicle];
_vehicle setVariable ["A3XAI_lastMoveTime", time];
_vehicle setVariable ["A3XAI_stuckCheckTime", time + 30]; // First check after 30s
_vehicle setVariable ["A3XAI_recoveryAttempts", 0];

// Set invincibility timeout (prevents instant destruction)
_vehicle allowDamage false;
[{
    params ["_vehicle"];
    if (!isNull _vehicle) then {
        _vehicle allowDamage true;
    };
}, [_vehicle], 5] call A3XAI_fnc_setTimeout;

true
