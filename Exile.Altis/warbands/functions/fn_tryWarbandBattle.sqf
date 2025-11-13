if (!isServer) exitWith {};
private _radius = missionNamespace getVariable ["WB_BATTLE_DISTANCE",350];

private _allOfficerGroups = [];
{ private _gs = WB_officers getOrDefault [_x select 0, []]; { if (!isNull _x) then { _allOfficerGroups pushBack _x; }; } forEach _gs; } forEach WB_factions;

for "_i" from 0 to ((count _allOfficerGroups) - 2) do {
    private _g1 = _allOfficerGroups select _i; if (isNull _g1) then { continue };
    private _p1 = getPos leader _g1;
    for "_j" from (_i+1) to ((count _allOfficerGroups) - 1) do {
        private _g2 = _allOfficerGroups select _j; if (isNull _g2) then { continue };
        if (side _g1 isEqualTo side _g2) then { continue };
        private _p2 = getPos leader _g2;
        if ((_p1 distance2D _p2) < _radius) then {
            _g1 reveal [leader _g2, 4]; _g2 reveal [leader _g1, 4];
            _g1 doTarget leader _g2;     _g2 doTarget leader _g1;
            _g1 doFire leader _g2;       _g2 doFire leader _g1;
        };
    };
};
