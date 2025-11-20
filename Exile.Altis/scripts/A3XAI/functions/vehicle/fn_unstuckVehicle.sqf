/*
    A3XAI Elite - Unstuck Vehicle
    Attempts to recover stuck vehicle

    Parameters:
        0: OBJECT - Vehicle
        1: STRING - Stuck reason

    Returns:
        BOOL - Success
*/

params ["_vehicle", "_reason"];

if (isNull _vehicle) exitWith {false};

// Track recovery attempts
private _attempts = _vehicle getVariable ["A3XAI_recoveryAttempts", 0];
_attempts = _attempts + 1;
_vehicle setVariable ["A3XAI_recoveryAttempts", _attempts];

// Give up after max attempts
if (_attempts >= (A3XAI_maxRecoveryAttempts max 3)) exitWith {
    [2, format ["Vehicle %1 abandoned after %2 recovery attempts", typeOf _vehicle, _attempts]] call A3XAI_fnc_log;

    // Despawn vehicle and crew
    {
        deleteVehicle _x;
    } forEach crew _vehicle;

    deleteVehicle _vehicle;
    A3XAI_activeVehicles = A3XAI_activeVehicles - [_vehicle];

    false
};

[3, format ["Attempting to unstuck vehicle (attempt %1/%2): %3", _attempts, A3XAI_maxRecoveryAttempts, _reason]] call A3XAI_fnc_log;

private _currentPos = getPosATL _vehicle;
private _recovered = false;

switch (_reason) do {
    case "STEEP_TERRAIN": {
        // Teleport to nearest flat road
        private _roads = _currentPos nearRoads 200;
        if (count _roads > 0) then {
            private _roadPos = position (_roads select 0);
            _vehicle setPos _roadPos;
            _vehicle setVectorUp [0, 0, 1];
            _recovered = true;
        };
    };

    case "WATER": {
        // Teleport to nearest land
        private _landPos = [_currentPos, 0, 100, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
        if (count _landPos > 0) then {
            _vehicle setPos _landPos;
            _recovered = true;
        };
    };

    case "COLLISION": {
        // Move back and try to continue
        private _dir = getDir _vehicle;
        private _backPos = _vehicle getPos [10, _dir + 180];
        _vehicle setPos _backPos;

        // If EAD available, recalculate route
        if (A3XAI_EAD_available && {_vehicle getVariable ["EAD_enabled", false]}) then {
            if (!isNil "EAD_fnc_recalculateRoute") then {
                [_vehicle] call EAD_fnc_recalculateRoute;
            };
        };

        _recovered = true;
    };

    case "OFF_ROAD": {
        // Teleport to nearest road
        private _roads = _currentPos nearRoads 100;
        if (count _roads > 0) then {
            private _roadPos = position (_roads select 0);
            _vehicle setPos _roadPos;
            _recovered = true;
        };
    };

    case "STUCK_UNKNOWN": {
        // Generic recovery: small teleport forward
        private _dir = getDir _vehicle;
        private _newPos = _vehicle getPos [15, _dir];
        _vehicle setPos _newPos;
        _vehicle setVectorUp [0, 0, 1];
        _recovered = true;
    };
};

// Reset stuck detection timer
if (_recovered) then {
    _vehicle setVariable ["A3XAI_lastPos", getPosATL _vehicle];
    _vehicle setVariable ["A3XAI_lastMoveTime", time];
    _vehicle setVariable ["A3XAI_stuckCheckTime", time + 30];

    [3, format ["Vehicle recovery successful: %1", _reason]] call A3XAI_fnc_log;
};

_recovered
