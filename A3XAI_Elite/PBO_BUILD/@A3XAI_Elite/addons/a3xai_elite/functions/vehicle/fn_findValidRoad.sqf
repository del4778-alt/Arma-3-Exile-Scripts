/*
    A3XAI Elite - Find Valid Road
    Finds a valid road near position (filters by quality)

    Parameters:
        0: ARRAY - Position [x,y,z]
        1: NUMBER - Search radius (default: 200)

    Returns:
        ARRAY - Road position or empty array if none found
*/

params ["_pos", ["_radius", 200]];

private _roads = _pos nearRoads _radius;

if (count _roads == 0) exitWith {
    [4, format ["No roads found within %1m of %2", _radius, _pos]] call A3XAI_fnc_log;
    []
};

// Filter roads by quality
private _validRoads = [];

{
    private _road = _x;
    private _quality = [_road] call A3XAI_fnc_getRoadQuality;

    // Accept roads with quality >= 2 (tracks and roads, not trails)
    if (_quality >= 2) then {
        _validRoads pushBack _road;
    };
} forEach _roads;

// If no valid roads, fall back to any road
if (count _validRoads == 0) then {
    [4, "No quality roads found, using any available road"] call A3XAI_fnc_log;
    _validRoads = _roads;
};

// Return position of closest valid road
if (count _validRoads > 0) then {
    private _closest = _validRoads select 0;
    position _closest
} else {
    []
}
