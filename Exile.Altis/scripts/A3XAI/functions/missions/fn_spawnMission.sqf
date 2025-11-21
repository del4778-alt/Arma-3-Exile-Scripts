/*
    A3XAI Elite - Spawn Mission
    Spawns a mission of specified type

    Parameters:
        0: STRING - Mission type: "convoy", "crash", "camp", "hunter", "rescue", "supplyDrop", "outpost"
        1: ARRAY - Position [x,y,z]
        2: STRING - Difficulty (default: "medium")

    Returns:
        HASHMAP - Mission data or empty hashmap on failure
*/

params ["_type", "_pos", ["_difficulty", "medium"]];

// Validate mission type
if !(_type in ["convoy", "crash", "camp", "hunter", "rescue", "supplyDrop", "outpost"]) exitWith {
    [1, format ["Invalid mission type: %1", _type]] call A3XAI_fnc_log;
    createHashMap
};

// Check mission cooldown for location
if (!isNil "A3XAI_missionCooldowns" && {!isNil "A3XAI_missionCooldownEnabled"} && {A3XAI_missionCooldownEnabled}) then {
    private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];
    private _lastMission = A3XAI_missionCooldowns getOrDefault [_locationID, 0];
    private _timeSince = time - _lastMission;

    if (_timeSince < (A3XAI_missionCooldownTime max 600)) exitWith {
        [4, format ["Mission location on cooldown (%1s remaining)", ceil(A3XAI_missionCooldownTime - _timeSince)]] call A3XAI_fnc_log;
        createHashMap
    };
};

// Dispatch to specific mission type
private _missionData = createHashMap;

switch (_type) do {
    case "convoy": {
        _missionData = [_pos, _difficulty] call A3XAI_fnc_convoy;
    };

    case "crash": {
        _missionData = [_pos, _difficulty] call A3XAI_fnc_crash;
    };

    case "camp": {
        _missionData = [_pos, _difficulty] call A3XAI_fnc_camp;
    };

    case "hunter": {
        _missionData = [_pos, _difficulty] call A3XAI_fnc_hunter;
    };

    case "rescue": {
        _missionData = [_pos, _difficulty] call A3XAI_fnc_rescue;
    };

    default {
        [1, format ["Unknown mission type: %1", _type]] call A3XAI_fnc_log;
    };
};

// Return mission data
_missionData
