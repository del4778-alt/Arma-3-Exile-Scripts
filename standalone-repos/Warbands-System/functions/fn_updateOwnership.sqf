if (!isServer) exitWith {};
private _gain = missionNamespace getVariable ["WB_OWNERSHIP_SCORE_GAIN",10];
{
    private _m = _x select 0;
    private _idx = _forEachIndex;
    private _zonePos = getMarkerPos _m;
    private _sides = [west,east,resistance,independent];
    private _counts = +(_sides apply { 0 });

    {
        private _grp = _x;
        if (isNull _grp) then { continue };
        private _units = units _grp;
        if (_units isEqualTo []) then { continue };
        private _side = side _grp;
        private _c = _units findIf { alive _x && (_x distance2D _zonePos) < 300 };
        if (_c >= 0) then {
            private _si = _sides find _side;
            if (_si >= 0) then { _counts set [_si, (_counts select _si) + 1]; };
        };
    } forEach allGroups;

    private _maxIdx = _counts find (max _counts);
    if (_maxIdx < 0) then { continue };
    private _winningSide = _sides select _maxIdx;

    private _ownerId = (WB_zones select _idx) select 3;
    private _candidate = "";
    {
        if ((_x select 4) isEqualTo _winningSide) exitWith { _candidate = _x select 0; };
    } forEach WB_factions;

    if (_candidate isEqualTo "") then { continue };

    if (_candidate isEqualTo _ownerId) then {
        WB_zones set [_idx, [ (WB_zones select _idx) select 0, (WB_zones select _idx) select 1,
                              (WB_zones select _idx) select 2, _ownerId,
                              ((WB_zones select _idx) select 4) + _gain ]];
    } else {
        WB_zones set [_idx, [ (WB_zones select _idx) select 0, (WB_zones select _idx) select 1,
                              (WB_zones select _idx) select 2, _ownerId,
                              ((WB_zones select _idx) select 4) - _gain ]];
        if (((WB_zones select _idx) select 4) <= 0) then {
            WB_zones set [_idx, [ (WB_zones select _idx) select 0, (WB_zones select _idx) select 1,
                                  (WB_zones select _idx) select 2, _candidate, 10 ]];
            diag_log format ["[WB] Zone %1 now owned by %2", (WB_zones select _idx) select 1, _candidate];
        };
    };
} forEach WB_zones;
