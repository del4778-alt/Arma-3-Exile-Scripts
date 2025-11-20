/*
    A3XAI Elite - Hunter Mission
    Spawns aggressive AI squad that hunts nearest player

    Parameters:
        0: ARRAY - Spawn position [x,y,z]
        1: STRING - Difficulty level
        2: OBJECT - Target player (optional, auto-selects if nil)

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty", ["_targetPlayer", objNull]];

private _missionName = format ["Hunter_%1", floor(random 9999)];
[3, format ["Spawning hunter mission at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Validate spawn position
if !([_pos, "land"] call A3XAI_fnc_isValidSpawnPos) exitWith {
    [2, format ["Invalid hunter spawn position: %1", _pos]] call A3XAI_fnc_log;
    createHashMap
};

// Find target player if not specified
if (isNull _targetPlayer) then {
    private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};
    if (count _players == 0) exitWith {
        [2, "No valid players for hunter mission"] call A3XAI_fnc_log;
    };

    // Select random player or closest player
    if (A3XAI_hunterTargetClosest) then {
        _players = [_players, [], {_x distance2D _pos}, "ASCEND"] call BIS_fnc_sortBy;
        _targetPlayer = _players select 0;
    } else {
        _targetPlayer = selectRandom _players;
    };
};

if (isNull _targetPlayer) exitWith {
    [2, "Failed to select target for hunter mission"] call A3XAI_fnc_log;
    createHashMap
};

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "hunter"],
    ["status", "active"],
    ["triggerType", "kill_all"],
    ["position", _pos],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["targetPlayer", _targetPlayer],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

// Determine hunter squad size
private _squadSize = switch (_difficulty) do {
    case "easy": {3};
    case "medium": {4};
    case "hard": {6};
    case "extreme": {8};
    default {3};
};

// Create hunter group
private _group = createGroup [EAST, true];
_group setVariable ["A3XAI_isHunter", true];
_group setVariable ["A3XAI_hunterTarget", _targetPlayer];

for "_i" from 0 to (_squadSize - 1) do {
    private _spawnPos = _pos getPos [5 + random 5, random 360];

    private _unitType = "I_Soldier_F";
    private _unit = _group createUnit [_unitType, _spawnPos, [], 0, "NONE"];

    // Initialize AI with hunter-specific settings
    [_unit, _difficulty] call A3XAI_fnc_initAI;
    [_unit, _difficulty] call A3XAI_fnc_setAISkill;
    [_unit, _difficulty] call A3XAI_fnc_equipAI;
    [_unit] call A3XAI_fnc_addAIEventHandlers;

    // Boost hunter skills slightly
    _unit setSkill ["courage", 0.8];
    _unit setSkill ["commanding", 0.7];
};

// Set aggressive hunter behavior
[_group, "hunter"] call A3XAI_fnc_setGroupBehavior;

// Create waypoints to hunt target
private _wp = _group addWaypoint [position _targetPlayer, 0];
_wp setWaypointType "SAD"; // Search and Destroy
_wp setWaypointSpeed "FULL";
_wp setWaypointBehaviour "AWARE";
_wp setWaypointCombatMode "RED";

// Add dynamic pursuit script
[_group, _targetPlayer] spawn {
    params ["_group", "_target"];

    while {count units _group > 0 && alive _target} do {
        // Update waypoint to target's current position
        private _wps = waypoints _group;
        if (count _wps > 0) then {
            (_wps select 0) setWaypointPosition [position _target, 0];
        };

        // Check if close enough to target
        if ((leader _group) distance2D _target < 50) then {
            // Reveal target to group
            {
                _x reveal [_target, 4];
            } forEach units _group;
        };

        sleep 10;
    };
};

// Hunter groups don't get loot crates (they hunt players)
// But we can reward killer of hunters
_group setVariable ["A3XAI_hunterReward", true];

// Create markers (only show if mission markers enabled)
if (A3XAI_enableMissionMarkers && A3XAI_showHunterMarkers) then {
    private _marker = createMarker [_missionName, _pos];
    _marker setMarkerType "mil_warning";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText format ["Hunter Squad (%1)", _difficulty];

    _missionData set ["markers", [_marker]];
};

// Store mission data
_missionData set ["aiGroups", [_group]];
_missionData set ["vehicles", []];
_missionData set ["lootBoxes", []];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification to target player
if (A3XAI_enableMissionNotifications) then {
    private _msg = format ["You are being hunted by a %1 squad!", _difficulty];
    [_msg] remoteExec ["systemChat", _targetPlayer];

    // General notification
    private _globalMsg = format ["Mission started: Hunter squad deployed (%1 difficulty)", _difficulty];
    [_globalMsg] remoteExec ["systemChat", -2];
};

[3, format ["Hunter mission '%1' spawned with %2 units targeting %3", _missionName, _squadSize, name _targetPlayer]] call A3XAI_fnc_log;

_missionData
