WB_getTreasury = {
    params ["_fid"];
    WB_treasury getOrDefault [_fid, 0]
};

WB_addTreasury = {
    params ["_fid","_delta"];
    private _t = [_fid] call WB_getTreasury;
    _t = _t + _delta max 0;
    WB_treasury set [_fid,_t];
    _t
};
