/*
    A3XAI Elite - Validate Spawn Position
    Checks if position is within world bounds and suitable for spawning

    Parameters:
        0: ARRAY - Position [x,y,z]
        1: STRING - Spawn type: "land", "water", "air" (default: "land")

    Returns:
        BOOL - True if valid spawn position
*/

params ["_pos", ["_spawnType", "land"]];

// Check world boundaries
private _worldSize = worldSize;
if ((_pos select 0) < 0 || (_pos select 0) > _worldSize) exitWith {
    if (A3XAI_debugMode) then {
        [4, format ["Position outside world bounds (X): %1", _pos]] call A3XAI_fnc_log;
    };
    false
};

if ((_pos select 1) < 0 || (_pos select 1) > _worldSize) exitWith {
    if (A3XAI_debugMode) then {
        [4, format ["Position outside world bounds (Y): %1", _pos]] call A3XAI_fnc_log;
    };
    false
};

// Check if position is valid based on spawn type
switch (_spawnType) do {
    case "land": {
        // Must not be in water
        if (surfaceIsWater _pos) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Land spawn position in water: %1", _pos]] call A3XAI_fnc_log;
            };
            false
        };

        // Check terrain height (avoid spawning in void)
        private _height = getTerrainHeightASL _pos;
        if (_height < -10) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Position below terrain void threshold: %1", _pos]] call A3XAI_fnc_log;
            };
            false
        };

        true
    };

    case "water": {
        // Must be in water
        if !(surfaceIsWater _pos) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Water spawn position on land: %1", _pos]] call A3XAI_fnc_log;
            };
            false
        };

        // Check water depth
        private _depth = abs((ATLToASL _pos) select 2);
        if (_depth < A3XAI_waterMinDepth) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Water too shallow (%1m): %2", _depth, _pos]] call A3XAI_fnc_log;
            };
            false
        };

        true
    };

    case "air": {
        // Air spawns can be anywhere, just check height
        private _height = getTerrainHeightASL _pos;
        if (_height < -10) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Air spawn position below terrain: %1", _pos]] call A3XAI_fnc_log;
            };
            false
        };

        true
    };

    default {
        [2, format ["Unknown spawn type: %1", _spawnType]] call A3XAI_fnc_log;
        false
    };
};
