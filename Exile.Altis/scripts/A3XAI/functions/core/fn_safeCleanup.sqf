/*
    A3XAI Elite - Safe Cleanup System
    Inspired by DMS_Exile cleanup manager

    Features:
    - Player proximity check before deletion
    - Retry queue for objects near players
    - Scheduled cleanup with delays
    - Batch processing to prevent lag spikes
*/

params [
    ["_object", objNull],
    ["_delay", 0],
    ["_force", false]
];

if (isNull _object) exitWith {false};

// Configuration
private _playerSafeRadius = missionNamespace getVariable ["A3XAI_cleanupPlayerRadius", 25];
private _retryDelay = 30; // Retry after 30 seconds if player nearby

// Initialize cleanup queue if not exists
if (isNil "A3XAI_cleanupQueue") then {
    A3XAI_cleanupQueue = [];
};

// Helper function to check if any player is nearby
private _fnc_playerNearby = {
    params ["_obj", "_radius"];
    private _pos = if (_obj isEqualType []) then {_obj} else {getPosATL _obj};
    private _nearby = false;

    {
        if (alive _x && (_pos distance2D _x) < _radius) exitWith {
            _nearby = true;
        };
    } forEach allPlayers;

    _nearby
};

// If delay specified, add to queue
if (_delay > 0) then {
    A3XAI_cleanupQueue pushBack [_object, time + _delay, _force];
    true
} else {
    // Immediate cleanup attempt
    if (_force || !([_object, _playerSafeRadius] call _fnc_playerNearby)) then {
        // Safe to delete
        if (_object isEqualType grpNull) then {
            // Group cleanup
            {
                if (!isNull _x) then {deleteVehicle _x};
            } forEach units _object;
            deleteGroup _object;
        } else {
            // Object cleanup
            if (!isNull _object) then {
                deleteVehicle _object;
            };
        };
        true
    } else {
        // Player nearby - add to retry queue
        A3XAI_cleanupQueue pushBack [_object, time + _retryDelay, false];
        if (A3XAI_debugLevel >= 4) then {
            [4, format ["[CLEANUP] Delayed cleanup for %1 - player nearby", typeOf _object]] call A3XAI_fnc_log;
        };
        false
    };
};
