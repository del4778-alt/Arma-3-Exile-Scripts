/*
    A3XAI Elite - Remove Spawn
    Removes a spawn from the spatial grid system

    Parameters:
        0: HASHMAP - Spawn data or spawn ID
        OR
        0: ARRAY - Position [x,y,z] to remove all spawns at

    Returns:
        BOOL - Success
*/

params ["_input"];

private _removed = false;

// Handle position input - remove all spawns at location
if (_input isEqualType []) then {
    private _pos = _input;
    private _cellID = [_pos] call A3XAI_fnc_getCellID;
    private _cellKey = str _cellID;

    private _cell = A3XAI_spawnGrid getOrDefault [_cellKey, []];
    private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];

    private _newCell = _cell select {
        private _spawnPos = _x get "position";
        private _spawnLocID = format ["%1_%2", floor(_spawnPos select 0), floor(_spawnPos select 1)];
        _spawnLocID != _locationID
    };

    if (count _newCell != count _cell) then {
        if (count _newCell == 0) then {
            A3XAI_spawnGrid deleteAt _cellKey;
        } else {
            A3XAI_spawnGrid set [_cellKey, _newCell];
        };
        _removed = true;

        if (A3XAI_debugMode) then {
            [4, format ["Removed %1 spawns at position %2", count _cell - count _newCell, _pos]] call A3XAI_fnc_log;
        };
    };

// Handle spawn data input - remove specific spawn
} else if (_input isEqualType createHashMap) then {
    private _spawnData = _input;
    private _pos = _spawnData get "position";

    if (!isNil "_pos") then {
        private _cellID = [_pos] call A3XAI_fnc_getCellID;
        private _cellKey = str _cellID;

        private _cell = A3XAI_spawnGrid getOrDefault [_cellKey, []];
        private _index = _cell find _spawnData;

        if (_index != -1) then {
            _cell deleteAt _index;

            if (count _cell == 0) then {
                A3XAI_spawnGrid deleteAt _cellKey;
            } else {
                A3XAI_spawnGrid set [_cellKey, _cell];
            };

            _removed = true;

            if (A3XAI_debugMode) then {
                [4, format ["Removed spawn from cell %1", _cellKey]] call A3XAI_fnc_log;
            };
        };
    };
};

_removed
