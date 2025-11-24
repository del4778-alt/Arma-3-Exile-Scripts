/*
    A3XAI Elite - Check Mission Completion
    Monitors mission status and triggers completion when conditions met

    Parameters:
        0: HASHMAP - Mission data

    Returns:
        BOOL - True if mission complete
*/

params ["_missionData"];

private _status = _missionData get "status";
if (_status != "active") exitWith {false};

private _triggerType = _missionData get "triggerType";
private _complete = false;

switch (_triggerType) do {
    case "kill_all": {
        // All AI must be dead
        private _groups = _missionData getOrDefault ["aiGroups", []];
        private _allDead = true;

        {
            if (count units _x > 0) then {
                _allDead = false;
            };
        } forEach _groups;

        if (_allDead) then {
            _complete = true;
            [3, format ["Mission '%1' complete: All AI eliminated", _missionData get "name"]] call A3XAI_fnc_log;
        };
    };

    case "loot": {
        // All loot boxes must be accessed
        private _boxes = _missionData getOrDefault ["lootBoxes", []];
        private _allLooted = true;

        {
            if (!(_x getVariable ["looted", false])) then {
                _allLooted = false;
            };
        } forEach _boxes;

        if (_allLooted) then {
            _complete = true;
            [3, format ["Mission '%1' complete: All loot collected", _missionData get "name"]] call A3XAI_fnc_log;
        };
    };

    case "timer": {
        // Mission expires after time limit
        private _spawnTime = _missionData get "spawnTime";
        private _duration = _missionData get "duration";

        if (time - _spawnTime >= _duration) then {
            _complete = true;
            [3, format ["Mission '%1' expired after %2s", _missionData get "name", _duration]] call A3XAI_fnc_log;
        };
    };

    case "hybrid": {
        // Either kill all OR loot (whichever first)
        private _groups = _missionData getOrDefault ["aiGroups", []];
        private _boxes = _missionData getOrDefault ["lootBoxes", []];

        // Check if all AI dead
        private _allDead = true;
        {
            if (count units _x > 0) then {_allDead = false};
        } forEach _groups;

        // Check if loot taken
        private _allLooted = true;
        {
            if (!(_x getVariable ["looted", false])) then {_allLooted = false};
        } forEach _boxes;

        if (_allDead || _allLooted) then {
            _complete = true;
            private _method = if (_allDead) then {"combat"} else {"stealth"};
            [3, format ["Mission '%1' complete via %2", _missionData get "name", _method]] call A3XAI_fnc_log;
        };
    };

    // v3.16: Added "clear" trigger type for cache and invasion missions
    case "clear": {
        // All AI must be eliminated to complete (same as kill_all)
        private _groups = _missionData getOrDefault ["aiGroups", []];
        private _allDead = true;

        {
            if (count units _x > 0) then {
                _allDead = false;
            };
        } forEach _groups;

        if (_allDead) then {
            _complete = true;
            [3, format ["Mission '%1' complete: Area cleared of hostiles", _missionData get "name"]] call A3XAI_fnc_log;
        };
    };

    // v3.16: Added "roaming" trigger type for DyCE convoys and highway patrols
    case "roaming": {
        // Roaming missions complete when all AI eliminated OR after max duration
        private _groups = _missionData getOrDefault ["aiGroups", []];
        private _vehicles = _missionData getOrDefault ["vehicles", []];
        private _spawnTime = _missionData getOrDefault ["spawnTime", time];
        private _maxDuration = _missionData getOrDefault ["maxDuration", 3600]; // Default 1 hour

        // Check if all AI dead
        private _allDead = true;
        {
            if (count units _x > 0) then {
                _allDead = false;
            };
        } forEach _groups;

        // Check if all vehicles destroyed
        private _allVehiclesDestroyed = true;
        {
            if (!isNull _x && {alive _x}) then {
                _allVehiclesDestroyed = false;
            };
        } forEach _vehicles;

        // Check timeout
        private _timedOut = (time - _spawnTime) >= _maxDuration;

        if (_allDead || _timedOut) then {
            _complete = true;
            private _reason = if (_allDead) then {"all hostiles eliminated"} else {"patrol expired"};
            [3, format ["Mission '%1' complete: %2", _missionData get "name", _reason]] call A3XAI_fnc_log;
        };
    };

    default {
        [2, format ["Unknown mission trigger type: %1", _triggerType]] call A3XAI_fnc_log;
    };
};

// Trigger completion if conditions met
if (_complete) then {
    [_missionData] call A3XAI_fnc_completeMission;
};

_complete
