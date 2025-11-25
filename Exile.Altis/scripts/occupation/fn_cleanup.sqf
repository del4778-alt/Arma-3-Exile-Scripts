/*
    Occupation Cleanup - Removes empty groups and groups far from players
*/

private _active = OCC get "activePatrols";
private _despawnRadius = 1200;  // Despawn if all players beyond this distance

{
    private _grp = _x;
    
    if (isNull _grp || count units _grp == 0) then {
        // Empty group - clean up
        if (!isNull _grp) then { deleteGroup _grp };
        _active = _active - [_grp];
    } else {
        // Check if any player is nearby
        private _pos = getPosATL (leader _grp);
        private _nearestDist = 99999;
        
        {
            private _d = _pos distance2D _x;
            if (_d < _nearestDist) then { _nearestDist = _d };
        } forEach allPlayers;
        
        if (_nearestDist > _despawnRadius) then {
            // Too far from all players - despawn
            diag_log format ["[UMC][Occupation] Despawning patrol - %1m from nearest player", round _nearestDist];
            
            { deleteVehicle _x } forEach units _grp;
            deleteGroup _grp;
            _active = _active - [_grp];
        };
    };
} forEach +_active;

OCC set ["activePatrols", _active];
