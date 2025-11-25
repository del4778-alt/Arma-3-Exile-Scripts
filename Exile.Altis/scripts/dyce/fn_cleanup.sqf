/*
    DyCE Cleanup - Removes old crash events
*/

private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");
private _delay = getNumber (_cfg >> "despawnDelay");

private _active = DYCE get "activeCrashes";

{
    // New format: [_id, _pos, time, [markers], _wreck, _smoke, _fire, _crate]
    // Old format: [_id, _pos, time]
    
    private _id = _x select 0;
    private _pos = _x select 1;
    private _start = _x select 2;

    if (time > _start + _delay) then {
        diag_log format ["[UMC][DyCE] Cleanup crash event %1", _id];
        
        // Delete markers (new format)
        if (count _x > 3) then {
            private _markers = _x select 3;
            { deleteMarker _x } forEach _markers;
            
            // Delete specific objects
            private _wreck = _x param [4, objNull];
            private _smoke = _x param [5, objNull];
            private _fire = _x param [6, objNull];
            private _crate = _x param [7, objNull];
            
            { if (!isNull _x) then { deleteVehicle _x } } forEach [_wreck, _smoke, _fire, _crate];
        };
        
        // Cleanup any remaining objects near position
        {
            if (_x distance _pos < 80) then { deleteVehicle _x };
        } forEach (vehicles + allDeadMen);
        
        // Notification
        [format ["Crash site %1 has been cleared.", _id]] remoteExec ["systemChat", 0];
        
        _active = _active - [_x];
    };
} forEach +_active;

DYCE set ["activeCrashes", _active];
