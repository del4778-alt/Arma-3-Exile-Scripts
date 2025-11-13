if (!isServer) exitWith {};
private _sec = WB_TROOP_UPGRADE_MINUTES * 60;
while { true } do {
    {
        private _grp = _x; if (isNull _grp) then { continue };
        {
            private _u = _x; if (!alive _u) then { continue };
            private _fid = _u getVariable ["WB_factionId",""]; if (_fid isEqualTo "") then { continue };
            private _xp  = _u getVariable ["WB_xp",0];
            private _tier = _u getVariable ["WB_tier",0];
            if (_tier < 3 && {_xp >= (WB_troopXpThresholds select _tier)}) then {
                private _tree = WB_troopTrees getOrDefault [_fid, []];
                if (_tree isNotEqualTo []) then {
                    private _nextClass = selectRandom ((_tree select _tier) max []);
                    private _pos = getPosATL _u; private _dir = getDir _u;
                    deleteVehicle _u;
                    private _nu = (group _grp) createUnit [_nextClass, _pos, [], 0, "FORM"];
                    _nu setDir _dir; _nu setVariable ["WB_factionId", _fid, true];
                    _nu setVariable ["WB_tier", _tier + 1, true];
                    _nu setVariable ["WB_xp", 0, true];
                    _nu enableDynamicSimulation true;
                };
            };
        } forEach units _grp;
    } forEach allGroups;
    uiSleep _sec;
};
