/*
    VEMF Cleanup - Removes completed/timed out invasions
*/

private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
private _delay = getNumber (_cfg >> "despawnDelay");

private _active = VEMF get "activeInvasions";

{
    // Format: [_id, _townPos, _townName, _currentWave, _maxWaves, _startTime]
    private _id = _x select 0;
    private _pos = _x select 1;
    private _townName = _x param [2, "Unknown"];
    private _currentWave = _x param [3, 0];
    private _maxWaves = _x param [4, 1];
    private _start = _x param [5, 0];
    
    // Check if invasion should be cleaned up
    private _shouldCleanup = false;
    
    // Time-based cleanup
    if (time > _start + _delay) then {
        _shouldCleanup = true;
    };
    
    // All waves complete cleanup (after short delay)
    if (_currentWave >= _maxWaves && time > _start + 300) then {
        _shouldCleanup = true;
    };
    
    if (_shouldCleanup) then {
        diag_log format ["[UMC][VEMF] Cleanup invasion %1 at %2", _id, _townName];
        
        // Delete markers
        private _markers = VEMF getOrDefault [_id + "_markers", []];
        { deleteMarker _x } forEach _markers;
        VEMF deleteAt (_id + "_markers");
        
        // Clean up dead AI near the location
        {
            if (_x distance _pos < 250) then { deleteVehicle _x };
        } forEach allDeadMen;
        
        _active = _active - [_x];
    };
} forEach +_active;

VEMF set ["activeInvasions", _active];
