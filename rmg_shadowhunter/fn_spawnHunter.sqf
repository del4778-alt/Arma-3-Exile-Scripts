/*
    Shadow Hunter Spawn Function
    Creates 3 hunter units for a player with evolution mechanics
    Parameters: [_player] - Player object to spawn hunters for
*/

params [["_player", objNull, [objNull]]];

// Validation
if (isNull _player || !isPlayer _player) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid player object in spawn function";
};

if (!isServer) exitWith {
    diag_log "[Shadow Hunter] ERROR: Spawn function called on client";
};

private _uid = getPlayerUID _player;
if (_uid == "") exitWith {
    diag_log "[Shadow Hunter] ERROR: Player has no UID";
};

// Store player reference for respawn lookups (more efficient than allPlayers)
if (isNil "SHW_playerRegistry") then { SHW_playerRegistry = []; };
private _index = SHW_playerRegistry findIf { (_x select 0) == _uid };
if (_index == -1) then {
    SHW_playerRegistry pushBack [_uid, _player];
} else {
    SHW_playerRegistry set [_index, [_uid, _player]];
};

private _spawnPos = _player modelToWorld [3 + random 2, 3 + random 2, 0];
private _group = createGroup [resistance, true];

for "_i" from 1 to 3 do {
    private _unit = _group createUnit ["B_Soldier_F", _spawnPos, [], 0, "FORM"];

    if (isNull _unit) then {
        diag_log "[Shadow Hunter] ERROR: Failed to create unit";
    } else {
        // Apply current evolution stats
        _unit setSkill ["aimingAccuracy", SHW_accuracy];
        _unit setSkill ["spotDistance", 0.8 + SHW_stealth];
        _unit setSkill ["courage", 1.0];
        _unit setUnitPos "MIDDLE";
        _unit setVariable ["SHW_isHunter", true, true];
        _unit setVariable ["SHW_OwnerUID", _uid, true];

        // Assign loadout using pre-compiled function
        [_unit, SHW_loadoutTier min SHW_MAX_LOADOUT_TIER] call SHW_fnc_assignLoadout;

        // Start escort behavior using pre-compiled function
        [_unit, _player] spawn SHW_fnc_escortLoop;

        // Evolution on death event handler
        _unit addEventHandler ["Killed", {
            params ["_unit", "_killer", "_instigator"];

            // Trigger evolution
            [_unit, _instigator] call SHW_fnc_evolveOnDeath;

            // Respawn after delay
            private _uid = _unit getVariable ["SHW_OwnerUID", ""];
            if (_uid != "") then {
                [_uid] spawn {
                    params ["_uid"];
                    sleep 15;

                    // Find player from registry (faster than allPlayers)
                    private _playerData = SHW_playerRegistry select { (_x select 0) == _uid };
                    if (count _playerData > 0) then {
                        private _plr = (_playerData select 0) select 1;
                        if (!isNull _plr && alive _plr) then {
                            [_plr] call SHW_fnc_spawnHunter;
                        };
                    };
                };
            };
        }];

        // Evolution on kill event handler
        _unit addEventHandler ["HandleScore", {
            params ["_unit", "_victim"];
            if (!isNull _victim && (side _victim) isEqualTo east && !isPlayer _victim) then {
                [_unit, _victim] call SHW_fnc_evolveOnKill;
            };
        }];
    };
};

diag_log format ["[Shadow Hunter] Spawned 3 hunters for player: %1 (UID: %2)", name _player, _uid];
