/*
    A3XAI Elite - Offload Group to HC
    Transfers a group to headless client with load balancing

    Parameters:
        0: GROUP - Group to offload

    Returns:
        BOOL - Success
*/

params ["_group"];

if (isNull _group) exitWith {false};
if (!A3XAI_HCConnected || count A3XAI_HCClients == 0) exitWith {false};

// Don't offload groups with players
if ({isPlayer _x} count units _group > 0) exitWith {false};

// Find HC with lowest load
private _bestHC = A3XAI_HCClients select 0;
private _lowestLoad = 9999;

{
    private _hcLoad = {groupOwner _x == owner _x} count A3XAI_activeGroups;

    if (_hcLoad < _lowestLoad) then {
        _lowestLoad = _hcLoad;
        _bestHC = _x;
    };
} forEach A3XAI_HCClients;

// Transfer group ownership
private _success = _group setGroupOwner (owner _bestHC);

if (_success) then {
    _group setVariable ["A3XAI_HCOwner", owner _bestHC];

    if (A3XAI_debugMode) then {
        [4, format ["Group offloaded to HC (load: %1)", _lowestLoad]] call A3XAI_fnc_log;
    };

    true
} else {
    [2, "Failed to offload group to HC"] call A3XAI_fnc_log;
    false
}
