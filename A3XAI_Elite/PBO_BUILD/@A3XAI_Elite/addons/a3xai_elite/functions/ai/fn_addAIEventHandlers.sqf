/*
    A3XAI Elite - Add AI Event Handlers
    Adds event handlers for AI units (Killed, Hit, etc.)

    Parameters:
        0: OBJECT - AI unit

    Returns:
        BOOL - Success
*/

params ["_unit"];

if (isNull _unit) exitWith {false};

// Killed event handler
_unit addEventHandler ["Killed", {
    params ["_unit", "_killer"];

    // Update statistics
    if (A3XAI_stats getOrDefault ["totalKills", 0] >= 0) then {
        A3XAI_stats set ["totalKills", (A3XAI_stats get "totalKills") + 1];
    };

    // Remove from tracking
    A3XAI_activeGroups = A3XAI_activeGroups - [group _unit];

    // Remove high-value items if configured
    if (!isNil "A3XAI_removeLaunchers" && {A3XAI_removeLaunchers}) then {
        {
            if (_x isKindOf ["Launcher", configFile >> "CfgWeapons"]) then {
                _unit removeWeapon _x;
            };
        } forEach weapons _unit;
    };

    if (!isNil "A3XAI_removeNVG" && {A3XAI_removeNVG}) then {
        if ("NVGoggles" in (assignedItems _unit)) then {
            _unit unlinkItem "NVGoggles";
        };
        if ("NVGoggles_OPFOR" in (assignedItems _unit)) then {
            _unit unlinkItem "NVGoggles_OPFOR";
        };
    };

    // Award respect if killer is player
    if (isPlayer _killer && {isClass (configFile >> "CfgPatches" >> "exile_server")}) then {
        private _difficulty = _unit getVariable ["A3XAI_difficulty", "medium"];

        // Base respect based on difficulty
        private _baseRespect = switch (_difficulty) do {
            case "easy": {10};
            case "medium": {20};
            case "hard": {35};
            case "extreme": {50};
            default {20};
        };

        // Distance bonus (up to 2x for 500m+ kills)
        private _distance = _killer distance _unit;
        private _distanceMultiplier = 1 + ((_distance min 500) / 500);

        private _respect = floor(_baseRespect * _distanceMultiplier);

        // Award respect
        private _currentRespect = _killer getVariable ["ExileScore", 0];
        _killer setVariable ["ExileScore", _currentRespect + _respect];

        // Send notification
        if (!isNil "ExileClient_system_network_send") then {
            [_killer, "showFragRequest", [[format ["+%1 Respect", _respect]], 3]] call ExileClient_system_network_send;
        };

        // Kill streak tracking
        if (!isNil "A3XAI_killStreaks") then {
            private _playerUID = getPlayerUID _killer;
            private _streak = A3XAI_killStreaks getOrDefault [_playerUID, 0];
            _streak = _streak + 1;
            A3XAI_killStreaks set [_playerUID, _streak];

            // Kill streak milestones
            if (_streak in [5, 10, 25, 50]) then {
                private _bonus = _streak * 10;
                _killer setVariable ["ExileScore", (_killer getVariable ["ExileScore", 0]) + _bonus];

                if (!isNil "ExileClient_system_network_send") then {
                    [_killer, "toastRequest", ["Success", format ["%1 Kill Streak! +%2 Respect Bonus", _streak, _bonus]]] call ExileClient_system_network_send;
                };
            };
        };

        // Poptabs reward
        if (!isNil "A3XAI_poptabsReward" && {A3XAI_poptabsReward}) then {
            private _poptabs = switch (_difficulty) do {
                case "easy": {50};
                case "medium": {100};
                case "hard": {200};
                case "extreme": {350};
                default {100};
            };

            private _money = _killer getVariable ["ExileMoney", 0];
            _killer setVariable ["ExileMoney", _money + _poptabs];
        };
    };

    // Zombie resurrection (if enabled)
    if (!isNil "A3XAI_zombieResurrection" && {A3XAI_zombieResurrection} && {random 1 < 0.3}) then {
        [{
            params ["_unit"];

            if (!isNull _unit && {!alive _unit}) then {
                private _zombiePos = getPosATL _unit;
                private _zombie = createAgent ["RyanZombieC_man_1slow", _zombiePos, [], 0, "NONE"];

                if (!isNull _zombie) then {
                    _zombie setDir (random 360);
                    _zombie setVariable ["A3XAI_zombie", true];

                    // Track zombies for cleanup
                    if (isNil "A3XAI_zombies") then {A3XAI_zombies = []};
                    A3XAI_zombies pushBack _zombie;
                };
            };

            deleteVehicle _unit;
        }, [_unit], 2] call A3XAI_fnc_setTimeout;
    } else {
        // Standard body cleanup
        [{
            params ["_unit"];
            if (!isNull _unit) then {
                deleteVehicle _unit;
            };
        }, [_unit], 300] call A3XAI_fnc_setTimeout;  // 5 minute cleanup
    };
}];

// Hit event handler (for aggressive reaction)
_unit addEventHandler ["Hit", {
    params ["_unit", "_source", "_damage"];

    if (!isNull _source && {isPlayer _source}) then {
        // Reveal shooter to group
        {
            _x reveal [_source, 4];
        } forEach units (group _unit);

        // Set combat mode to red
        (group _unit) setCombatMode "RED";
        (group _unit) setBehaviour "COMBAT";
    };
}];

true
