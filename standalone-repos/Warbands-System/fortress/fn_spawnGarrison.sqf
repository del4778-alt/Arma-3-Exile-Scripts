params ["_fid"];
private _tree = WB_troopTrees getOrDefault [_fid, WB_troopTrees get "PLAYER_DEFAULT"];
private _units = (_tree select 0) + (_tree select 1);
private _pos = ((WB_fortresses get _fid) select 1);

private _side = switch (_fid) do {
    case "KAV": {west};
    case "PYR": {east};
    case "ATH": {independent};
    case "CIV": {resistance};
    default {resistance};
};

if (_fid isEqualTo "CIV" && {missionNamespace getVariable ["WB_USE_AGENTS_FOR_CIV",true]}) then {
    // Light civilian ambience as agents
    for "_i" from 1 to 8 do {
        private _a = createAgent ["C_Man_1", _pos getPos [random 10, random 360], [], 0, "CAN_COLLIDE"];
        _a enableSimulationGlobal false;
    };
} else {
    private _grp = createGroup [_side, true];
    for "_i" from 1 to (8 + floor random 4) do {
        private _type = selectRandom _units;
        private _unit = _grp createUnit [_type, _pos getPos [random 10, random 360], [], 0, "CAN_COLLIDE"];
        _unit setVariable ["WB_factionId", _fid, true];
        _unit setSkill random [0.4,0.6,0.8];
        _unit enableDynamicSimulation true;
    };
    (WB_fortresses get _fid) set [4, _grp];
};
