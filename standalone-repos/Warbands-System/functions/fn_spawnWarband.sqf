params ["_factionId"];
if (!isServer) exitWith { grpNull };

private _f = WB_factions select (WB_factions findIf { (_x select 0) isEqualTo _factionId });
if (isNil "_f") exitWith { grpNull };

private _side  = _f select 4;
private _homes = _f select 3;
private _homeMkr = selectRandom _homes;
private _pos = getMarkerPos _homeMkr;

private _sizeRange = missionNamespace getVariable ["WB_WARBAND_SIZE_RANGE",[6,12]];
private _n = floor random [_sizeRange select 0, ((_sizeRange select 0)+(_sizeRange select 1))/2, _sizeRange select 1];

private _grp = createGroup [_side, true];
for "_i" from 1 to _n do {
    private _type = switch (_side) do {
        case west:        { selectRandom ["B_Soldier_F","B_Soldier_GL_F","B_soldier_AR_F"] };
        case east:        { selectRandom ["O_Soldier_F","O_Soldier_GL_F","O_Soldier_AR_F"] };
        case independent: { selectRandom ["I_Soldier_F","I_Soldier_GL_F","I_Soldier_AR_F"] };
        case resistance:  { selectRandom ["C_Man_Messenger_01_F","C_man_p_beggar_F","C_man_p_shorts_1_F"] };
        default { "B_Soldier_F" };
    };
    private _u = _grp createUnit [_type, _pos, [], 5, "FORM"];
    _u setVariable ["WB_factionId", _factionId, true];
    _u setVariable ["WB_tier", 0, true];
    _u setVariable ["WB_xp", 0, true];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        if (!isNull _killer && {isKindOf _killer "Man"}) then {
            _killer setVariable ["WB_xp", (_killer getVariable ["WB_xp",0]) + 1, true];
        };
    }];
    _u enableDynamicSimulation true;
};

_grp setBehaviourStrong "AWARE";
_grp setSpeedMode "FULL";
_grp setFormation "WEDGE";

private _owned = WB_zones select { (_x select 3) isEqualTo _factionId };
if (_owned isNotEqualTo []) then {
    {
        private _m = _x select 0;
        private _wp = _grp addWaypoint [getMarkerPos _m, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 20;
    } forEach (_owned call BIS_fnc_arrayShuffle);
};

private _arr = WB_officers getOrDefault [_factionId, []];
_arr pushBackUnique _grp;
WB_officers set [_factionId, _arr];

if (missionNamespace getVariable ["WB_ENABLE_HC",true]) then {
    private _hcs = entities "HeadlessClient_F";
    if (count _hcs > 0) then { _grp setGroupOwner (owner (_hcs select 0)); };
};

_grp
