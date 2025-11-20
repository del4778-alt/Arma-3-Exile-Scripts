/*
    A3XAI Elite - Complete Mission
    Handles mission cleanup and cooldown after completion

    Parameters:
        0: HASHMAP - Mission data

    Returns:
        BOOL - Success
*/

params ["_missionData"];

private _missionName = _missionData get "name";
private _missionType = _missionData get "type";

// Mark as completed
_missionData set ["status", "completed"];
_missionData set ["completedTime", time];

// Remove from active missions
private _index = A3XAI_activeMissions findIf {(_x get "name") == _missionName};
if (_index != -1) then {
    A3XAI_activeMissions deleteAt _index;
};

// Send completion notification
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["Mission completed: %1", _missionName];
    remoteExec ["systemChat", -2];
    [3, _msg] call A3XAI_fnc_log;
};

// Cleanup mission objects after delay
[{
    params ["_missionData"];

    // Remove markers
    private _markers = _missionData getOrDefault ["markers", []];
    {
        deleteMarker _x;
    } forEach _markers;

    // Remove AI groups
    private _groups = _missionData getOrDefault ["aiGroups", []];
    {
        {
            deleteVehicle _x;
        } forEach units _x;
        deleteGroup _x;
    } forEach _groups;

    // Remove vehicles (if not destroyed by players)
    private _vehicles = _missionData getOrDefault ["vehicles", []];
    {
        if (alive _x && {!(_x getVariable ["A3XAI_playerClaimed", false])}) then {
            deleteVehicle _x;
        };
    } forEach _vehicles;

    // Keep loot boxes for configured time
    private _boxes = _missionData getOrDefault ["lootBoxes", []];
    {
        private _box = _x;
        [{
            params ["_box"];
            if (!isNull _box) then {
                deleteVehicle _box;
            };
        }, [_box], A3XAI_lootDespawnTime] call A3XAI_fnc_setTimeout;
    } forEach _boxes;

    [3, format ["Mission cleanup complete: %1", _missionData get "name"]] call A3XAI_fnc_log;

}, [_missionData], A3XAI_missionCleanupDelay] call A3XAI_fnc_setTimeout;

// Set location cooldown
if (A3XAI_missionCooldownEnabled) then {
    private _pos = _missionData get "position";
    private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];
    A3XAI_missionCooldowns set [_locationID, time];

    [4, format ["Mission location '%1' on cooldown for %2s", _locationID, A3XAI_missionCooldownTime]] call A3XAI_fnc_log;
};

// Update statistics
A3XAI_stats set ["missionsCompleted", (A3XAI_stats getOrDefault ["missionsCompleted", 0]) + 1];

private _typeStat = format ["missions_%1", _missionType];
A3XAI_stats set [_typeStat, (A3XAI_stats getOrDefault [_typeStat, 0]) + 1];

true
