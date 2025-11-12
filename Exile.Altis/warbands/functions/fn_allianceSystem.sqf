if (!isServer) exitWith {};
{
    private _fidA = _x select 0;
    private _rels = WB_relations getOrDefault [_fidA, []];
    {
        _x params ["_fidB","_score"];
        private _ns = _score + (if (_fidA isEqualTo _fidB) then {0} else {1});
        _rels set [_forEachIndex, [_fidB, _ns max -100 min 100]];
    } forEach _rels;
    WB_relations set [_fidA,_rels];
} forEach WB_factions;
