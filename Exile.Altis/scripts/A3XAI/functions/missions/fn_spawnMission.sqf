/*
    A3XAI Elite - Spawn Mission
    Spawns a mission of specified type with DMS-style validation and notifications

    Parameters:
        0: STRING - Mission type
        1: ARRAY - Position [x,y,z]
        2: STRING - Difficulty (default: "medium")

    Returns:
        HASHMAP - Mission data or empty hashmap on failure

    v3.2: DMS-style position validation, logging, and player notifications
*/

params ["_type", "_pos", ["_difficulty", "medium"]];

[3, format ["=== SPAWNING MISSION: %1 at %2 (%3) ===", _type, _pos, _difficulty]] call A3XAI_fnc_log;

// Valid mission types
private _validTypes = ["convoy", "crash", "camp", "hunter", "cache", "supplyDrop", "outpost", "invasion"];

// Validate mission type
if !(_type in _validTypes) exitWith {
    [1, format ["Invalid mission type: %1 (valid: %2)", _type, _validTypes]] call A3XAI_fnc_log;
    createHashMap
};

// Validate position
if (count _pos < 2) exitWith {
    [1, format ["Invalid mission position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Check if position is valid spawn location using improved findSafePos
private _safePos = [_pos, 20, 200, 0, 50] call A3XAI_fnc_findSafePos;
if (count _safePos < 2) exitWith {
    [1, format ["Could not find safe position near %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Update position to safe location
_pos = _safePos;
[4, format ["Mission position validated: %1", _pos]] call A3XAI_fnc_log;

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

// Get mission function name
private _fnName = format ["A3XAI_fnc_%1", _type];
private _fn = missionNamespace getVariable [_fnName, {}];

// Verify function exists
if (isNil "_fn" || {str _fn == "{}"}) exitWith {
    [1, format ["Mission function not found: %1", _fnName]] call A3XAI_fnc_log;
    createHashMap
};

// Dispatch to specific mission type with error handling
private _missionData = createHashMap;

[4, format ["Calling mission function: %1", _fnName]] call A3XAI_fnc_log;

try {
    _missionData = [_pos, _difficulty] call _fn;
} catch {
    [1, format ["ERROR spawning %1 mission: %2", _type, str _exception]] call A3XAI_fnc_log;
    _missionData = createHashMap;
};

// Verify mission was created
if (count _missionData == 0) exitWith {
    [2, format ["Mission %1 returned empty data - spawn failed", _type]] call A3XAI_fnc_log;
    createHashMap
};

// Verify AI were spawned
private _aiGroups = _missionData getOrDefault ["aiGroups", []];
private _totalAI = 0;
{
    _totalAI = _totalAI + count units _x;
} forEach _aiGroups;

if (_totalAI == 0) then {
    [2, format ["WARNING: Mission %1 spawned with 0 AI units!", _type]] call A3XAI_fnc_log;
} else {
    [3, format ["Mission %1 spawned successfully with %2 AI units", _type, _totalAI]] call A3XAI_fnc_log;
};

// Update mission cooldown
if (!isNil "A3XAI_missionCooldowns") then {
    private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];
    A3XAI_missionCooldowns set [_locationID, time];
};

// DMS-style player notification
if (A3XAI_enableMissionNotifications) then {
    private _missionName = _missionData getOrDefault ["name", _type];
    private _notifyMsg = "";

    switch (_type) do {
        case "convoy": {
            _notifyMsg = format ["[A3XAI] Enemy convoy spotted! (%1 difficulty)", _difficulty];
        };
        case "crash": {
            _notifyMsg = format ["[A3XAI] Helicopter crash site discovered! (%1 difficulty)", _difficulty];
        };
        case "camp": {
            _notifyMsg = format ["[A3XAI] Bandit camp located! (%1 difficulty)", _difficulty];
        };
        case "hunter": {
            _notifyMsg = format ["[A3XAI] Hunter squad deployed against players! (%1 difficulty)", _difficulty];
        };
        case "cache": {
            _notifyMsg = format ["[A3XAI] Weapons cache discovered! (%1 difficulty)", _difficulty];
        };
        case "supplyDrop": {
            _notifyMsg = format ["[A3XAI] Supply drop inbound! (%1 difficulty)", _difficulty];
        };
        case "outpost": {
            _notifyMsg = format ["[A3XAI] Military outpost detected! (%1 difficulty)", _difficulty];
        };
        case "invasion": {
            _notifyMsg = format ["[A3XAI] Town invasion in progress! (%1 difficulty)", _difficulty];
        };
        default {
            _notifyMsg = format ["[A3XAI] New mission available! (%1)", _difficulty];
        };
    };

    // Broadcast to all players
    if (_notifyMsg != "") then {
        // Method 1: Hint notification with formatted text
        private _hintMsg = parseText format ["<t size='1.2' color='#FF8C00'>A3XAI MISSION</t><br/><t color='#FFFFFF'>%1</t>", _notifyMsg];
        [_hintMsg] remoteExec ["hint", -2];

        // Method 2: System chat fallback
        _notifyMsg remoteExec ["systemChat", -2];

        [4, format ["Mission notification sent: %1", _notifyMsg]] call A3XAI_fnc_log;
    };
};

[3, format ["=== MISSION SPAWN COMPLETE: %1 ===", _type]] call A3XAI_fnc_log;

// Return mission data
_missionData
