/*
    A3XAI Despawn - Cleanup function for AI groups far from all players
    
    This is a backup cleanup - the main logic handles location-based despawning.
    This catches any orphaned groups or dynamic patrols that wandered too far.
*/

private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");
private _radius = getNumber (_cfg >> "despawnRadius");

private _active = A3XAI get "activeGroups";
private _removed = 0;

{
    private _grp = _x;
    private _units = units _grp;

    if (isNull _grp || count _units == 0) then {
        // Empty or null group - clean up
        if (!isNull _grp) then { deleteGroup _grp };
        _active = _active - [_grp];
        _removed = _removed + 1;
    } else {
        private _pos = getPosATL (leader _grp);
        private _nearestDist = 99999;
        
        {
            private _d = _pos distance2D _x;
            if (_d < _nearestDist) then { _nearestDist = _d };
        } forEach allPlayers;

        if (_nearestDist > _radius) then {
            // Too far from all players - despawn
            private _name = _grp getVariable ["A3XAI_spawnName", "Unknown"];
            diag_log format ["[UMC][A3XAI] Despawning %1 (%2 units) - %3m from nearest player", 
                _name, count _units, round _nearestDist];
            
            { deleteVehicle _x } forEach _units;
            deleteGroup _grp;
            _active = _active - [_grp];
            _removed = _removed + 1;
        };
    };
} forEach +_active;

if (_removed > 0) then {
    A3XAI set ["activeGroups", _active];
};
