/*
    A3XAI Elite - Generate Defense Positions
    Creates defensive positions around a central point

    Parameters:
        0: ARRAY - Center position [x,y,z]
        1: NUMBER - Number of positions to generate
        2: NUMBER - Minimum radius from center
        3: NUMBER - Maximum radius from center

    Returns:
        ARRAY - Array of positions
*/

params ["_center", "_count", ["_minRadius", 20], ["_maxRadius", 50]];

private _positions = [];

for "_i" from 0 to (_count - 1) do {
    private _angle = (360 / _count) * _i;
    private _distance = _minRadius + random (_maxRadius - _minRadius);

    // Calculate position
    private _pos = _center getPos [_distance, _angle];

    // Find nearest cover/terrain feature
    private _nearObjects = nearestTerrainObjects [_pos, ["BUSH", "TREE", "SMALL TREE", "HIDE", "ROCK"], 10];

    if (count _nearObjects > 0) then {
        // Position near cover
        private _coverObj = _nearObjects select 0;
        _pos = (position _coverObj) getPos [2, _angle + 180]; // Behind cover
    } else {
        // Use calculated position
        _pos set [2, 0];
    };

    _positions pushBack _pos;
};

_positions
