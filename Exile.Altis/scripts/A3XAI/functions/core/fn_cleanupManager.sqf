/*
    A3XAI Elite - Cleanup Queue Manager
    Inspired by DMS_Exile cleanup system

    Processes the cleanup queue with:
    - Player proximity safety checks
    - Batch processing to prevent lag
    - Retry logic for delayed cleanups
*/

if (!isServer) exitWith {};

[3, "[CLEANUP] Starting cleanup queue manager"] call A3XAI_fnc_log;

// Configuration
private _checkInterval = 10; // Process queue every 10 seconds
private _batchSize = 5;      // Process max 5 items per cycle
private _playerSafeRadius = missionNamespace getVariable ["A3XAI_cleanupPlayerRadius", 25];
private _retryDelay = 30;

// Initialize queue
if (isNil "A3XAI_cleanupQueue") then {
    A3XAI_cleanupQueue = [];
};

// Helper function
private _fnc_playerNearby = {
    params ["_obj", "_radius"];
    private _pos = if (_obj isEqualType []) then {_obj} else {
        if (isNull _obj) exitWith {[0,0,0]};
        getPosATL _obj
    };
    private _nearby = false;

    {
        if (alive _x && (_pos distance2D _x) < _radius) exitWith {
            _nearby = true;
        };
    } forEach allPlayers;

    _nearby
};

while {A3XAI_enabled} do {
    sleep _checkInterval;

    if (count A3XAI_cleanupQueue == 0) then {continue};

    private _processed = 0;
    private _newQueue = [];
    private _deleted = 0;
    private _retried = 0;

    {
        _x params ["_object", "_scheduledTime", "_force"];

        // Check if scheduled time has passed
        if (time >= _scheduledTime) then {
            // Check if object still exists
            if (isNull _object) then {
                // Already deleted, skip
                _processed = _processed + 1;
            } else {
                // Check player proximity
                if (_force || !([_object, _playerSafeRadius] call _fnc_playerNearby)) then {
                    // Safe to delete
                    if (_object isEqualType grpNull) then {
                        {
                            if (!isNull _x) then {deleteVehicle _x};
                        } forEach units _object;
                        deleteGroup _object;
                    } else {
                        deleteVehicle _object;
                    };
                    _deleted = _deleted + 1;
                    _processed = _processed + 1;
                } else {
                    // Player nearby - retry later
                    _newQueue pushBack [_object, time + _retryDelay, false];
                    _retried = _retried + 1;
                    _processed = _processed + 1;
                };
            };
        } else {
            // Not yet scheduled - keep in queue
            _newQueue pushBack _x;
        };

        // Batch limit
        if (_processed >= _batchSize) exitWith {};
    } forEach A3XAI_cleanupQueue;

    // Update queue (remove processed items, keep unprocessed + new retries)
    private _remaining = A3XAI_cleanupQueue select [_processed, count A3XAI_cleanupQueue];
    A3XAI_cleanupQueue = _newQueue + _remaining;

    // Log activity
    if ((_deleted > 0 || _retried > 0) && A3XAI_debugLevel >= 4) then {
        [4, format ["[CLEANUP] Deleted: %1, Retried: %2, Queue: %3", _deleted, _retried, count A3XAI_cleanupQueue]] call A3XAI_fnc_log;
    };
};

[2, "[CLEANUP] Cleanup manager stopped"] call A3XAI_fnc_log;
