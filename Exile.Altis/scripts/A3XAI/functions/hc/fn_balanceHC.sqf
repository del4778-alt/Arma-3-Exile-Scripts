/*
    A3XAI Elite - Balance Headless Clients
    Redistributes AI groups evenly across all HCs

    Returns:
        NUMBER - Groups rebalanced
*/

if (!A3XAI_HCConnected || count A3XAI_HCClients == 0) exitWith {0};

[3, "Rebalancing AI groups across Headless Clients..."] call A3XAI_fnc_log;

// Count current load per HC
private _hcLoads = createHashMap;

{
    private _hc = _x;
    private _load = {groupOwner _x == owner _hc} count A3XAI_activeGroups;
    _hcLoads set [owner _hc, _load];
} forEach A3XAI_HCClients;

// Calculate target load per HC
private _totalGroups = count A3XAI_activeGroups;
private _targetLoad = ceil(_totalGroups / (count A3XAI_HCClients));

private _rebalanced = 0;

// Redistribute groups
{
    private _group = _x;

    if (!isNull _group && {count units _group > 0}) then {
        // Don't move groups with players
        if ({isPlayer _x} count units _group == 0) then {
            private _currentOwner = groupOwner _group;

            // Find most underloaded HC
            private _bestHC = A3XAI_HCClients select 0;
            private _lowestLoad = 9999;

            {
                private _load = _hcLoads getOrDefault [owner _x, 0];

                if (_load < _lowestLoad && {_load < _targetLoad}) then {
                    _lowestLoad = _load;
                    _bestHC = _x;
                };
            } forEach A3XAI_HCClients;

            // Transfer if beneficial
            if (owner _bestHC != _currentOwner && {_lowestLoad < _targetLoad}) then {
                private _success = _group setGroupOwner (owner _bestHC);

                if (_success) then {
                    _group setVariable ["A3XAI_HCOwner", owner _bestHC];
                    _hcLoads set [owner _bestHC, _lowestLoad + 1];
                    _rebalanced = _rebalanced + 1;
                };
            };
        };
    };
} forEach A3XAI_activeGroups;

if (_rebalanced > 0) then {
    [3, format ["Rebalanced %1 groups across %2 HC(s)", _rebalanced, count A3XAI_HCClients]] call A3XAI_fnc_log;

    // Log final distribution
    {
        private _hcName = name _x;
        private _load = _hcLoads getOrDefault [owner _x, 0];
        [4, format ["  %1: %2 groups", _hcName, _load]] call A3XAI_fnc_log;
    } forEach A3XAI_HCClients;
};

_rebalanced
