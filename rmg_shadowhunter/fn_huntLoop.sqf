/*
    Shadow Hunter Independent Hunt Logic
    Hunters patrol and hunt enemies autonomously without player escort
    Parameters: [_unit] - Hunter unit
    NOTE: Currently unused - hunters use escort mode by default
*/

params [["_unit", objNull, [objNull]]];

// Validation
if (isNull _unit) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid unit in huntLoop";
};

private _lastHealTime = time;
private _patrolCenter = getPosATL _unit;
private _searchRadius = 200;

while {alive _unit && !isNull _unit} do {
    // Find nearest enemy
    private _target = _unit findNearestEnemy _unit;

    // Check for valid enemy target
    if (!isNull _target && {alive _target} && {(side _target) isEqualTo east}) then {
        private _distance = _unit distance _target;

        // Reveal and engage target
        _unit reveal [_target, 4];
        (group _unit) reveal [_target, 4];

        // Use doTarget and commandFire for better accuracy
        _unit doTarget _target;

        // Engage if within aggression range
        if (_distance < SHW_aggression) then {
            _unit commandFire _target;

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
            // Move toward target
            _unit doMove (getPosATL _target);
        };

        // Update patrol center to last combat location
        _patrolCenter = getPosATL _unit;

    } else {
        // No enemies - patrol known hotspots or random area
        private _targetPos = [];

        // 50% chance to check hotspots if available
        if (count SHW_lastKnownHotspots > 0 && random 1 > 0.5) then {
            _targetPos = selectRandom SHW_lastKnownHotspots;
        } else {
            // Random patrol within radius
            private _distance = 50 + random _searchRadius;
            private _direction = random 360;
            _targetPos = _patrolCenter getPos [_distance, _direction];
        };

        _unit doMove _targetPos;
    };

    // Optimized self-healing: only heal every 5 seconds and only if damaged
    if (time - _lastHealTime > 5 && damage _unit > 0.05) then {
        private _newDamage = ((damage _unit) - 0.15) max 0;
        _unit setDamage _newDamage;
        _lastHealTime = time;
    };

    // Dynamic sleep based on stealth
    sleep (2 + (SHW_stealth * 2));
};

// Cleanup on exit
if (!isNull _unit) then {
    diag_log format ["[Shadow Hunter] Hunt loop ended for unit: %1 (Alive: %2)", _unit, alive _unit];
};
