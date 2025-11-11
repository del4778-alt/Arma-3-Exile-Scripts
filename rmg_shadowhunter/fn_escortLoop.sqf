
/*
    Shadow Hunter Escort Logic
    Keeps Hunters in formation with the player unless engaged.
*/

params ["_unit", "_player"];

private _group = group _unit;

while {alive _unit && alive _player} do {
    private _target = _unit findNearestEnemy _unit;

    if (!isNull _target && (side _target) isEqualTo east) then {
        _unit reveal _target;

        // Break formation to engage
        _unit doMove getPosATL _target;

        if (SHW_loadoutTier >= 3 && random 1 < 0.2) then {
            _unit hideObjectGlobal true;
            sleep 3;
            _unit hideObjectGlobal false;
        };

        if (_unit distance _target < SHW_aggression) then {
            _unit doFire _target;
        };

    } else {
        // Return to escort formation
        _unit doFollow _player;

        if (_unit distance _player > 5) then {
            _unit doMove (getPosATL _player);
        };
    };

    // Self-heal
    if ((damage _unit) > 0.01) then {
        _unit setDamage ((damage _unit) - 0.1 max 0);
    };

    sleep 3 + SHW_stealth;
};
