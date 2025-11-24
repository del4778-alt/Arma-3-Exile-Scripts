/*
    A3XAI Elite - Find Safe Spawn Position
    Finds a valid spawn position with DMS-style retries and constraint relaxation

    Parameters:
        0: ARRAY - Center position [x,y,z]
        1: NUMBER - Minimum distance from center (default: 50)
        2: NUMBER - Maximum distance from center (default: 500)
        3: NUMBER - Water mode: 0=land only, 1=water only, 2=both (default: 0)
        4: NUMBER - Max attempts (default: 100)

    Returns:
        ARRAY - Safe position [x,y,z] or empty array if failed

    v2.0: DMS-style retry logic with progressive constraint relaxation
*/

params ["_center", ["_minDist", 50], ["_maxDist", 500], ["_waterMode", 0], ["_maxAttempts", 100]];

private _safePos = [];
private _attempt = 0;
private _relaxFactor = 1.0;

// Validation distances (like DMS)
private _minPlayerDist = 300;      // Min distance from players
private _minMissionDist = 500;     // Min distance from other missions
private _minTraderDist = 1000;     // Min distance from traders/blacklist

// Get active missions for distance check
private _activeMissionPositions = [];
{
    private _pos = _x getOrDefault ["position", []];
    if (count _pos >= 2) then {
        _activeMissionPositions pushBack _pos;
    };
} forEach A3XAI_activeMissions;

// Get player positions
private _playerPositions = [];
{
    if (alive _x && !(_x getVariable ["ExileIsBambi", false])) then {
        _playerPositions pushBack (position _x);
    };
} forEach allPlayers;

while {_attempt < _maxAttempts && count _safePos == 0} do {
    _attempt = _attempt + 1;

    // Progressive relaxation after many failed attempts (like DMS)
    if (_attempt > 15 && _attempt % 5 == 0) then {
        _relaxFactor = _relaxFactor * 0.9;  // Reduce constraints by 10%
        _minPlayerDist = (_minPlayerDist * _relaxFactor) max 100;
        _minMissionDist = (_minMissionDist * _relaxFactor) max 200;

        if (A3XAI_debugMode && _attempt % 20 == 0) then {
            [4, format ["FindSafePos: Relaxing constraints (attempt %1, factor %2)", _attempt, _relaxFactor toFixed 2]] call A3XAI_fnc_log;
        };
    };

    // Generate candidate position
    private _testPos = [_center, _minDist, _maxDist, 5, _waterMode, 0.3, 0] call BIS_fnc_findSafePos;

    // Validate: Must have valid result
    if (count _testPos < 2) then {continue};

    // Validate: World bounds
    if ((_testPos select 0) < 50 || (_testPos select 0) > (worldSize - 50)) then {continue};
    if ((_testPos select 1) < 50 || (_testPos select 1) > (worldSize - 50)) then {continue};

    // Validate: Water mode
    private _isWater = surfaceIsWater _testPos;
    if (_waterMode == 0 && _isWater) then {continue};  // Land only, but got water
    if (_waterMode == 1 && !_isWater) then {continue}; // Water only, but got land

    // Validate: Terrain height (not in void)
    private _terrainHeight = getTerrainHeightASL _testPos;
    if (_terrainHeight < -10) then {continue};

    // Validate: Not in blacklist zone
    if ([_testPos] call A3XAI_fnc_inBlacklist) then {continue};

    // Validate: Distance from players (don't spawn too close)
    private _tooCloseToPlayer = false;
    {
        if (_testPos distance2D _x < _minPlayerDist) exitWith {
            _tooCloseToPlayer = true;
        };
    } forEach _playerPositions;
    if (_tooCloseToPlayer) then {continue};

    // Validate: Distance from other missions
    private _tooCloseToMission = false;
    {
        if (_testPos distance2D _x < _minMissionDist) exitWith {
            _tooCloseToMission = true;
        };
    } forEach _activeMissionPositions;
    if (_tooCloseToMission) then {continue};

    // Validate: Flat terrain (surface normal check like DMS)
    private _surfaceNormal = surfaceNormal _testPos;
    private _slopeAngle = acos (_surfaceNormal select 2);  // Angle from vertical
    if (_slopeAngle > 20) then {continue};  // Max 20 degree slope

    // All checks passed!
    _safePos = _testPos;
};

// Log result
if (count _safePos > 0) then {
    if (A3XAI_debugMode) then {
        [4, format ["FindSafePos: Found position %1 after %2 attempts", _safePos, _attempt]] call A3XAI_fnc_log;
    };
} else {
    [2, format ["FindSafePos: FAILED after %1 attempts near %2", _maxAttempts, _center]] call A3XAI_fnc_log;

    // Emergency fallback: just use BIS_fnc_findSafePos result without validation
    _safePos = [_center, _minDist, _maxDist, 5, _waterMode, 0.5, 0] call BIS_fnc_findSafePos;
    if (count _safePos < 2) then {
        _safePos = _center;  // Last resort: use center
    };
    [2, format ["FindSafePos: Using fallback position %1", _safePos]] call A3XAI_fnc_log;
};

_safePos
