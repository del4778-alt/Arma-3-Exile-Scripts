/*
    A3XAI Elite - Is Vehicle Stuck
    Multi-factor detection of stuck vehicles

    Parameters:
        0: OBJECT - Vehicle

    Returns:
        STRING - Status: "MOVING", "STEEP_TERRAIN", "WATER", "COLLISION", "OFF_ROAD", "STUCK_UNKNOWN", "DISABLED"
*/

params ["_vehicle"];

if (isNull _vehicle || !alive _vehicle) exitWith {"DISABLED"};

// Don't check too frequently
private _lastCheck = _vehicle getVariable ["A3XAI_stuckCheckTime", 0];
if (time < _lastCheck) exitWith {"MOVING"};

_vehicle setVariable ["A3XAI_stuckCheckTime", time + 15]; // Check every 15s

// Get current position and speed
private _currentPos = getPosATL _vehicle;
private _speed = speed _vehicle;
private _lastPos = _vehicle getVariable ["A3XAI_lastPos", _currentPos];
private _lastMoveTime = _vehicle getVariable ["A3XAI_lastMoveTime", time];

// Calculate distance moved
private _distanceMoved = _currentPos distance2D _lastPos;

// Update last position
_vehicle setVariable ["A3XAI_lastPos", _currentPos];

// If moving significantly, not stuck
if (_distanceMoved > 5 || abs _speed > 5) exitWith {
    _vehicle setVariable ["A3XAI_lastMoveTime", time];
    "MOVING"
};

// Has been stationary - check why
private _stationaryTime = time - _lastMoveTime;

// Give 30 seconds grace period
if (_stationaryTime < 30) exitWith {"MOVING"};

// Check terrain gradient (steep terrain)
private _gradient = abs ((getPosASL _vehicle) select 2) - ((getPosATL _vehicle) select 2);
if (_gradient > 5) exitWith {"STEEP_TERRAIN"};

// Check if vehicle is in water (for land vehicles)
if (!(_vehicle isKindOf "Ship") && {surfaceIsWater _currentPos}) exitWith {"WATER"};

// Check for collision with objects
private _nearObjects = nearestObjects [_vehicle, ["Building", "House", "Wall"], 5];
if (count _nearObjects > 0) exitWith {"COLLISION"};

// Check if vehicle should be on road but isn't
if (_vehicle isKindOf "Car" || _vehicle isKindOf "Tank") then {
    private _roads = _currentPos nearRoads 20;
    if (count _roads == 0 && {_stationaryTime > 45}) exitWith {"OFF_ROAD"};
};

// Unknown stuck condition
if (_stationaryTime > 60) exitWith {"STUCK_UNKNOWN"};

"MOVING"
