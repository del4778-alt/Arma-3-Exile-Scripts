/*
    A3XAI Elite - Generate Route
    Generates a route along the road network

    Parameters:
        0: ARRAY - Start position [x,y,z]
        1: NUMBER - Route length (radius in meters, default: 1500)
        2: NUMBER - Number of waypoints (default: 10)

    Returns:
        ARRAY - Array of waypoint positions, or empty array if failed
*/

params ["_startPos", ["_routeLength", 1500], ["_maxWaypoints", 10]];

private _waypoints = [];

// Find starting road
private _roads = _startPos nearRoads 100;
if (count _roads == 0) exitWith {
    [2, "Cannot generate route: no roads nearby"] call A3XAI_fnc_log;
    []
};

private _currentRoad = _roads select 0;
private _currentPos = position _currentRoad;
_waypoints pushBack _currentPos;

private _visited = [_currentRoad];
private _minSpacing = 100; // Minimum distance between waypoints

// Generate waypoints by following road network
for "_i" from 1 to (_maxWaypoints - 1) do {
    // Find connected roads
    private _connectedRoads = roadsConnectedTo _currentRoad;

    // Filter out already visited roads
    _connectedRoads = _connectedRoads - _visited;

    // Filter by quality
    private _goodRoads = [];
    {
        private _quality = [_x] call A3XAI_fnc_getRoadQuality;
        if (_quality >= 2) then {
            _goodRoads pushBack _x;
        };
    } forEach _connectedRoads;

    // Use any road if no good roads found
    if (count _goodRoads == 0) then {
        _goodRoads = _connectedRoads;
    };

    // If no connected roads, break
    if (count _goodRoads == 0) exitWith {};

    // Select random connected road
    private _nextRoad = selectRandom _goodRoads;
    private _nextPos = position _nextRoad;

    // Check spacing
    if (_currentPos distance2D _nextPos >= _minSpacing) then {
        _waypoints pushBack _nextPos;
        _visited pushBack _nextRoad;
        _currentRoad = _nextRoad;
        _currentPos = _nextPos;
    };

    // Stop if we've gone far enough
    if (_startPos distance2D _nextPos >= _routeLength) exitWith {};
};

// If we got less than 3 waypoints, route generation failed
if (count _waypoints < 3) exitWith {
    [2, format ["Route generation failed: only %1 waypoints generated", count _waypoints]] call A3XAI_fnc_log;
    []
};

[4, format ["Generated route with %1 waypoints", count _waypoints]] call A3XAI_fnc_log;

_waypoints
