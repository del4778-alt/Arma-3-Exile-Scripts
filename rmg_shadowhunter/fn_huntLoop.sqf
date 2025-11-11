
params ["_unit"];

while {alive _unit} do {
    private _tgt = _unit findNearestEnemy _unit;

    if (!isNull _tgt && (side _tgt) isEqualTo east) then {
        if (SHW_loadoutTier >= 3 && random 1 < 0.2) then {
            _unit hideObjectGlobal true;
            sleep 3;
            _unit hideObjectGlobal false;
        };

        _unit doMove (getPosATL _tgt);
        _unit reveal _tgt;

        if (_unit distance _tgt < SHW_aggression) then {
            _unit doFire _tgt;
        };
    } else {
        private _w = 50 + random 50;
        private _pos = (getPosATL _unit) getPos [_w, random 360];
        _unit doMove _pos;
    };

    // Self-heal logic: heal after each combat loop if wounded
    if ((damage _unit) > 0.01) then {
        _unit setDamage ((damage _unit) - 0.1 max 0);
    };

    sleep 3 + SHW_stealth;
};
