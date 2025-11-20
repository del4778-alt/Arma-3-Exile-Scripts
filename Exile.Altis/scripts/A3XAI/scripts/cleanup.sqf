/*
    A3XAI Elite - Cleanup Scheduler
    Periodically removes dead AI, empty groups, and destroyed vehicles
*/

if (!isServer) exitWith {};

private _cleanupInterval = 120; // Every 2 minutes

[3, "Cleanup scheduler started"] call A3XAI_fnc_log;

while {A3XAI_enabled} do {
    sleep _cleanupInterval;

    private _startTime = diag_tickTime;
    private _cleaned = createHashMapFromArray [
        ["deadAI", 0],
        ["emptyGroups", 0],
        ["destroyedVehicles", 0],
        ["invalidSpawns", 0],
        ["completedMissions", 0]
    ];

    // Clean dead AI from tracking
    {
        if (!alive _x || isNull _x) then {
            _cleaned set ["deadAI", (_cleaned get "deadAI") + 1];
            // Remove from any tracking arrays
            A3XAI_activeGroups = A3XAI_activeGroups - [group _x];
        };
    } forEach allDeadMen;

    // Clean empty groups
    private _groupsToRemove = [];
    {
        if (count units _x == 0) then {
            deleteGroup _x;
            _groupsToRemove pushBack _x;
            _cleaned set ["emptyGroups", (_cleaned get "emptyGroups") + 1];
        };
    } forEach A3XAI_activeGroups;

    A3XAI_activeGroups = A3XAI_activeGroups - _groupsToRemove;

    // Clean destroyed vehicles
    private _vehiclesToRemove = [];
    {
        if (!alive _x || isNull _x || damage _x >= 1) then {
            // Check if it's not a player-claimed vehicle
            if !(_x getVariable ["A3XAI_playerClaimed", false]) then {
                deleteVehicle _x;
                _vehiclesToRemove pushBack _x;
                _cleaned set ["destroyedVehicles", (_cleaned get "destroyedVehicles") + 1];
            };
        };
    } forEach A3XAI_activeVehicles;

    A3XAI_activeVehicles = A3XAI_activeVehicles - _vehiclesToRemove;

    // Clean invalid spawns from grid
    private _cellsToUpdate = [];
    {
        private _cellID = _x;
        private _spawns = _y;
        private _validSpawns = [];

        {
            private _spawn = _x;
            private _valid = true;

            // Check if spawn still has active groups
            private _groups = _spawn getOrDefault ["groups", []];
            private _activeGroups = _groups select {count units _x > 0};

            if (count _activeGroups == 0 && !(_spawn get "persistent")) then {
                _valid = false;
                _cleaned set ["invalidSpawns", (_cleaned get "invalidSpawns") + 1];
            } else {
                _spawn set ["groups", _activeGroups];
                _validSpawns pushBack _spawn;
            };
        } forEach _spawns;

        if (count _validSpawns != count _spawns) then {
            _cellsToUpdate pushBack [_cellID, _validSpawns];
        };
    } forEach A3XAI_spawnGrid;

    // Update cells with cleaned spawns
    {
        _x params ["_cellID", "_validSpawns"];
        if (count _validSpawns == 0) then {
            A3XAI_spawnGrid deleteAt _cellID;
        } else {
            A3XAI_spawnGrid set [_cellID, _validSpawns];
        };
    } forEach _cellsToUpdate;

    // Clean completed missions older than threshold
    private _missionsToRemove = [];
    {
        if ((_x get "status") == "completed") then {
            private _completedTime = _x get "completedTime";
            if ((time - _completedTime) > (A3XAI_missionCleanupDelay + 300)) then {
                _missionsToRemove pushBack _x;
                _cleaned set ["completedMissions", (_cleaned get "completedMissions") + 1];
            };
        };
    } forEach A3XAI_activeMissions;

    A3XAI_activeMissions = A3XAI_activeMissions - _missionsToRemove;

    // Log cleanup report
    private _cleanupTime = ((diag_tickTime - _startTime) * 1000) toFixed 0;

    if (_cleaned get "deadAI" > 0 || _cleaned get "emptyGroups" > 0 || _cleaned get "destroyedVehicles" > 0) then {
        [4, format ["Cleanup: %1 dead AI, %2 empty groups, %3 destroyed vehicles, %4 invalid spawns (%5ms)",
            _cleaned get "deadAI",
            _cleaned get "emptyGroups",
            _cleaned get "destroyedVehicles",
            _cleaned get "invalidSpawns",
            _cleanupTime
        ]] call A3XAI_fnc_log;
    };
};

[2, "Cleanup scheduler stopped"] call A3XAI_fnc_log;
