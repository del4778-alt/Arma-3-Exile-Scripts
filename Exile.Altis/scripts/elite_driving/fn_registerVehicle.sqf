/*
    Register a vehicle for Elite Driving System
    
    Params:
    0: Vehicle
*/

params ["_veh"];

// Check if already registered
if (_veh in ELITE_DRIVE_VEHICLES) exitWith {};

// Add to tracking array
ELITE_DRIVE_VEHICLES pushBack _veh;

diag_log format ["[ELITE DRIVE] Registered: %1", typeOf _veh];

// Start the driving loop for this vehicle
[_veh] spawn {
    params ["_veh"];
    
    private _scanInterval = ELITE_DRIVE_CONFIG get "scanInterval";
    
    while {alive _veh && !isNull _veh} do {
        private _driver = driver _veh;
        
        // Only process if AI is driving
        if (!isNull _driver && !isPlayer _driver && alive _driver) then {
            // Run the main processing
            [_veh, _driver] call (ELITE_DRIVE get "processVehicle");
            
            // Self-maintenance
            [_veh] call (ELITE_DRIVE get "selfMaintain");
        };
        
        sleep _scanInterval;
    };
    
    // Cleanup when vehicle destroyed/deleted
    ELITE_DRIVE_VEHICLES = ELITE_DRIVE_VEHICLES - [_veh];
    diag_log format ["[ELITE DRIVE] Unregistered: %1 (destroyed/deleted)", typeOf _veh];
};
