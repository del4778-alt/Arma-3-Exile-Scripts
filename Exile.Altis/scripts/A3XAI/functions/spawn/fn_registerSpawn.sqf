/*
    A3XAI Elite - Register Spawn
    Registers a spawn in the spatial grid system

    Parameters:
        0: HASHMAP - Spawn data containing at minimum:
            - position: ARRAY [x,y,z]
            - type: STRING (infantry, vehicle, air, sea)
            - groups: ARRAY of GROUPs
            - difficulty: STRING

    Returns:
        BOOL - Success
*/

params ["_spawnData"];

if (!isNil "_spawnData" && {_spawnData isEqualType createHashMap}) then {
    private _pos = _spawnData get "position";

    if (isNil "_pos") exitWith {
        [1, "Cannot register spawn: missing position"] call A3XAI_fnc_log;
        false
    };

    // Get spatial grid cell ID
    private _cellID = [_pos] call A3XAI_fnc_getCellID;
    private _cellKey = str _cellID;

    // Get or create cell
    private _cell = A3XAI_spawnGrid getOrDefault [_cellKey, []];

    // Add spawn to cell
    _cell pushBack _spawnData;
    A3XAI_spawnGrid set [_cellKey, _cell];

    // Set spawn time for cooldown
    private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];
    A3XAI_spawnCooldowns set [_locationID, time];

    // Update statistics
    A3XAI_stats set ["totalSpawns", (A3XAI_stats getOrDefault ["totalSpawns", 0]) + 1];

    if (A3XAI_debugMode) then {
        [4, format ["Registered spawn in cell %1: %2 at %3", _cellKey, _spawnData get "type", _pos]] call A3XAI_fnc_log;
    };

    true
} else {
    [1, "Cannot register spawn: invalid spawn data"] call A3XAI_fnc_log;
    false
};
