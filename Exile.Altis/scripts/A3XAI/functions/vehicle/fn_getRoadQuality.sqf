/*
    A3XAI Elite - Get Road Quality
    Validates road quality for Arma 3 2.00+ (uses getRoadInfo)

    Parameters:
        0: OBJECT - Road object

    Returns:
        NUMBER - Quality: 0=invalid, 1=trail, 2=track, 3=road
*/

params ["_road"];

if (isNull _road) exitWith {0};

// Get road info (Arma 3 2.00+)
private _info = getRoadInfo _road;

// _info format: [mapType, width, isPedestrian, texture, textureEnd, material, begPos, endPos, isBridge]
if (count _info == 0) exitWith {0};

private _type = _info select 0;
private _width = _info select 1;

// Check against blacklist
if (!isNil "A3XAI_roadBlacklist") then {
    if (_type in A3XAI_roadBlacklist) exitWith {0};
};

// Check minimum width
if (!isNil "A3XAI_roadMinWidth") then {
    if (_width < A3XAI_roadMinWidth) exitWith {0};
};

// Classify road quality
private _quality = switch (true) do {
    case (_type == "TRAIL"): {1};
    case (_type == "TRACK"): {2};
    case (_width < 6): {2};  // Narrow road/track
    case (_width >= 6): {3}; // Full road
    default {2};
};

_quality
