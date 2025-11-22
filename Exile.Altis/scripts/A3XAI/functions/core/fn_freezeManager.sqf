/*
    A3XAI Elite - AI Freeze Manager
    Inspired by DMS_Exile and VEMF Reloaded

    Freezes AI simulation when no players are nearby to save performance.
    Unfreezes when players approach.

    Key Features:
    - Distance-based freezing (configurable, default 3500m)
    - Freeze check interval (configurable, default 15 seconds)
    - Supports Headless Client offloading
    - Won't freeze groups with players or single-unit groups
*/

if (!isServer) exitWith {};

// Configuration (can be overridden in config)
private _freezeDistance = missionNamespace getVariable ["A3XAI_freezeDistance", 3500];
private _unfreezeDistance = missionNamespace getVariable ["A3XAI_unfreezeDistance", 3000];
private _checkInterval = missionNamespace getVariable ["A3XAI_freezeCheckInterval", 15];
private _freezeEnabled = missionNamespace getVariable ["A3XAI_freezingEnabled", true];
private _offloadToHC = missionNamespace getVariable ["A3XAI_offloadToHC", true];

if (!_freezeEnabled) exitWith {
    [3, "[FREEZE] AI freezing disabled in config"] call A3XAI_fnc_log;
};

[3, format ["[FREEZE] Starting freeze manager - Distance: %1m, Interval: %2s", _freezeDistance, _checkInterval]] call A3XAI_fnc_log;

// Find Headless Client if available
private _fnc_findHC = {
    private _hc = objNull;
    {
        if (!isPlayer _x && !hasInterface && !isDedicated) exitWith {
            _hc = _x;
        };
    } forEach allPlayers;

    // Alternative: Check for HC owner IDs (typically 3+)
    if (isNull _hc) then {
        private _hcOwner = -1;
        for "_i" from 3 to 10 do {
            if (!isNull (missionNamespace getVariable [format ["HC_%1", _i], objNull])) exitWith {
                _hcOwner = _i;
            };
        };
        if (_hcOwner > 0) then {
            _hc = _hcOwner;
        };
    };

    _hc
};

// Main freeze loop
while {A3XAI_enabled} do {
    sleep _checkInterval;

    private _frozenCount = 0;
    private _unfrozenCount = 0;
    private _offloadedCount = 0;

    // Get all players for distance checks
    private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};

    if (count _players == 0) then {
        // No players - freeze everything
        {
            private _group = _x;
            private _isFrozen = _group getVariable ["A3XAI_frozen", false];

            if (!_isFrozen) then {
                // Freeze the group
                {
                    _x enableSimulationGlobal false;
                    if (vehicle _x != _x) then {
                        (vehicle _x) enableSimulationGlobal false;
                    };
                } forEach units _group;

                _group setVariable ["A3XAI_frozen", true];
                _frozenCount = _frozenCount + 1;
            };
        } forEach A3XAI_activeGroups;
    } else {
        // Process each active group
        {
            private _group = _x;

            // Skip invalid groups
            if (isNull _group || {count units _group == 0}) then {continue};

            // Skip groups containing players
            private _hasPlayer = false;
            {
                if (isPlayer _x) exitWith {_hasPlayer = true};
            } forEach units _group;
            if (_hasPlayer) then {continue};

            // Skip single-unit groups (Exile flyover detection)
            if (count units _group == 1 && {vehicle (leader _group) != leader _group}) then {continue};

            // Get group position (leader or average)
            private _groupPos = getPosATL (leader _group);

            // Find nearest player distance
            private _nearestPlayerDist = 999999;
            {
                private _dist = _groupPos distance2D _x;
                if (_dist < _nearestPlayerDist) then {
                    _nearestPlayerDist = _dist;
                };
            } forEach _players;

            private _isFrozen = _group getVariable ["A3XAI_frozen", false];

            // Freeze logic
            if (_nearestPlayerDist > _freezeDistance && !_isFrozen) then {
                // Freeze the group - disable simulation
                {
                    _x enableSimulationGlobal false;
                    if (vehicle _x != _x) then {
                        (vehicle _x) enableSimulationGlobal false;
                    };
                } forEach units _group;

                _group setVariable ["A3XAI_frozen", true];
                _frozenCount = _frozenCount + 1;

            } else {
                // Unfreeze logic
                if (_nearestPlayerDist < _unfreezeDistance && _isFrozen) then {
                    // Unfreeze the group - enable simulation
                    {
                        _x enableSimulationGlobal true;
                        if (vehicle _x != _x) then {
                            (vehicle _x) enableSimulationGlobal true;
                        };

                        // Re-enable AI features after unfreeze
                        _x enableAI "ALL";
                        _x enableAI "MOVE";
                        _x enableAI "PATH";
                        _x enableAI "FSM";
                        _x enableAI "TARGET";
                        _x enableAI "AUTOTARGET";
                    } forEach units _group;

                    _group setVariable ["A3XAI_frozen", false];
                    _unfrozenCount = _unfrozenCount + 1;

                    // Offload to Headless Client if available and enabled
                    if (_offloadToHC) then {
                        private _hc = call _fnc_findHC;
                        if (!isNull _hc) then {
                            private _hcOwner = if (_hc isEqualType 0) then {_hc} else {owner _hc};
                            if (_hcOwner > 2 && groupOwner _group != _hcOwner) then {
                                _group setGroupOwner _hcOwner;
                                _group setVariable ["A3XAI_offloaded", true];
                                _offloadedCount = _offloadedCount + 1;
                            };
                        };
                    };
                };
            };
        } forEach A3XAI_activeGroups;
    };

    // Log activity at debug level
    if ((_frozenCount > 0 || _unfrozenCount > 0) && A3XAI_debugLevel >= 4) then {
        [4, format ["[FREEZE] Frozen: %1, Unfrozen: %2, Offloaded: %3", _frozenCount, _unfrozenCount, _offloadedCount]] call A3XAI_fnc_log;
    };
};

[2, "[FREEZE] Freeze manager stopped"] call A3XAI_fnc_log;
