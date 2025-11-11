
/*
    Shadow Hunter Escort Logic
    Keeps Hunters in formation with the player unless engaged.
    Parameters: [_unit, _player] - Hunter unit and owner player
*/

params [["_unit", objNull, [objNull]], ["_player", objNull, [objNull]]];

// Validation
if (isNull _unit || isNull _player) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid parameters in escortLoop";
};

private _group = group _unit;
private _lastHealTime = time;
private _inCombat = false;

while {alive _unit && alive _player && !isNull _player} do {
    // Find nearest enemy
    private _nearestEnemy = _unit findNearestEnemy _unit;

    // Check for valid enemy target
    if (!isNull _nearestEnemy && {alive _nearestEnemy} && {(side _nearestEnemy) isEqualTo east}) then {
        _inCombat = true;
        private _distance = _unit distance _nearestEnemy;

        // Reveal and engage target
        _unit reveal [_nearestEnemy, 4];
        _group reveal [_nearestEnemy, 4];

        // Use doTarget and commandFire for better accuracy
        _unit doTarget _nearestEnemy;

        // Engage if within aggression range
        if (_distance < SHW_aggression) then {
            _unit commandFire _nearestEnemy;

            // Advanced stealth: temporarily reduce detection at tier 3
            if (SHW_loadoutTier >= 3 && random 1 < (0.1 + SHW_stealth * 0.3)) then {
                _unit setCaptive true;
                [_unit] spawn {
                    params ["_u"];
                    sleep (2 + random 2);
                    if (!isNull _u && alive _u) then {
                        _u setCaptive false;
                    };
                };
            };
        } else {
            // Move to engage if target is beyond range
            _unit doMove (getPosATL _nearestEnemy);
        };

    } else {
        // No enemies - return to escort formation
        if (_inCombat) then {
            _unit doFollow _player;
            _inCombat = false;
        };

        // Maintain formation near player
        private _playerDist = _unit distance _player;
        if (_playerDist > 10) then {
            _unit doMove (getPosATL _player);
        } else if (_playerDist < 3) then {
            // Too close, back off a bit
            private _backoffPos = _unit getPos [5, (_unit getDir _player) + 180];
            _unit doMove _backoffPos;
        };
    };

    // Optimized self-healing: only heal every 5 seconds and only if damaged
    if (time - _lastHealTime > 5 && damage _unit > 0.05) then {
        private _newDamage = ((damage _unit) - 0.15) max 0;
        _unit setDamage _newDamage;
        _lastHealTime = time;
    };

    // Dynamic sleep based on stealth (higher stealth = slower reaction time but harder to detect)
    sleep (2 + (SHW_stealth * 2));
};

// Cleanup on exit
if (!isNull _unit) then {
    diag_log format ["[Shadow Hunter] Escort loop ended for unit: %1 (Alive: %2, Player alive: %3)", _unit, alive _unit, alive _player];
};
