/*
    A3XAI Elite - Initialize Headless Client
    Detects and initializes headless client support

    Returns:
        BOOL - Success
*/

if (!isServer) exitWith {false};

// Detect headless clients
private _hcClients = [];

{
    if (!isPlayer _x && {!hasInterface} && {!isDedicated}) then {
        _hcClients pushBack _x;
    };
} forEach allPlayers;

if (count _hcClients > 0) then {
    A3XAI_HCConnected = true;
    A3XAI_HCClients = _hcClients;

    [3, format ["Headless Client initialized: %1 HC(s) detected", count _hcClients]] call A3XAI_fnc_log;

    // Monitor HC connection
    [] spawn {
        while {A3XAI_enabled} do {
            sleep 60;  // Check every minute

            // Update HC client list
            private _currentHCs = [];
            {
                if (!isPlayer _x && {!hasInterface} && {!isDedicated}) then {
                    _currentHCs pushBack _x;
                };
            } forEach allPlayers;

            // Detect changes
            if (count _currentHCs != count A3XAI_HCClients) then {
                [2, format ["HC count changed: %1 -> %2", count A3XAI_HCClients, count _currentHCs]] call A3XAI_fnc_log;

                A3XAI_HCClients = _currentHCs;

                if (count _currentHCs == 0) then {
                    A3XAI_HCConnected = false;
                    [2, "All HCs disconnected - migrating groups back to server"] call A3XAI_fnc_log;

                    // Migrate all groups back to server
                    {
                        if (!isNull _x && {_x getVariable ["A3XAI_group", false]}) then {
                            _x setGroupOwner 2;  // 2 = server
                        };
                    } forEach A3XAI_activeGroups;
                } else {
                    A3XAI_HCConnected = true;
                    // Rebalance groups
                    [] call A3XAI_fnc_balanceHC;
                };
            };
        };
    };

    true
} else {
    [3, "No Headless Clients detected"] call A3XAI_fnc_log;
    A3XAI_HCConnected = false;
    A3XAI_HCClients = [];

    false
}
