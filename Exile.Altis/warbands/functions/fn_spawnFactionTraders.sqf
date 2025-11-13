if (!isServer) exitWith {};
{
    private _fid = _x select 0;
    if (random 1 < 0.6) then { [_fid] call WB_fnc_spawnCaravan; };
} forEach WB_factions;
