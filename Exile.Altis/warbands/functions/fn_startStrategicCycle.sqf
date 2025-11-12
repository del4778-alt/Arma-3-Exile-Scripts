if (!isServer) exitWith {};
private _tickSec = (missionNamespace getVariable ["WB_STRATEGIC_TICK_MINUTES",10]) * 60;

while { true } do
{
    // Spawn/maintain warbands per faction with AI cap
    private _activeGroups = { local _x } count allGroups;
    private _cap = missionNamespace getVariable ["WB_MAX_ACTIVE_GROUPS",80];

    if (_activeGroups < _cap) then {
        {
            private _fid = _x select 0;
            private _officers = WB_officers getOrDefault [_fid, []];
            private _need = (missionNamespace getVariable ["WB_MAX_WARBANDS_PER_FACTION",6]) - (count _officers);
            _need = _need max 0 min 3;
            for "_i" from 1 to _need do { [_fid] call WB_fnc_spawnWarband; };
        } forEach WB_factions;
    };

    [] call WB_fnc_tryWarbandBattle;
    [] call WB_fnc_updateOwnership;

    // Cleanup far groups
    {
        private _grp = _x;
        if (isNull _grp) then { continue };
        private _near = allPlayers findIf { (_grp call BIS_fnc_groupParams) isEqualTo _grp; false };// placeholder
        private _leader = leader _grp;
        private _dmin = 99999;
        {
            _dmin = _dmin min (_leader distance2D _x);
        } forEach allPlayers;
        if (_dmin > (missionNamespace getVariable ["WB_DESPAWN_DISTANCE",2500])) then {
            { deleteVehicle _x } forEach units _grp;
            deleteGroup _grp;
        };
    } forEach allGroups;

    uiSleep _tickSec;
};
