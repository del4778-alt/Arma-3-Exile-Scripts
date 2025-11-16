/*
    IVORY VEHICLE BLACKLIST

    If specific vehicles keep causing the takedown error, add them here to prevent spawning

    Usage:
    1. Add to init.sqf: [] execVM "scripts\ivory_vehicle_blacklist.sqf";
    2. Add problematic vehicle classnames to the array below
    3. Restart server
*/

diag_log "[IVORY BLACKLIST] Vehicle blacklist loading...";

// Add problematic vehicle classnames here (example: ["ivory_charger", "ivory_cvpi"])
IVORY_BLACKLIST_VEHICLES = [
    // Add vehicle classnames here if you identify specific problem vehicles
    // Example: "ivory_charger_2012"
];

if (isServer) then {
    // Hook into vehicle spawn events to block blacklisted vehicles
    addMissionEventHandler ["EntityCreated", {
        params ["_entity"];

        if (_entity isKindOf "LandVehicle") then {
            private _classname = typeOf _entity;

            // Check if vehicle is blacklisted
            if (_classname in IVORY_BLACKLIST_VEHICLES) then {
                diag_log format ["[IVORY BLACKLIST] Blocked spawn of blacklisted vehicle: %1", _classname];
                deleteVehicle _entity;
            };
        };
    }];

    diag_log format ["[IVORY BLACKLIST] ✅ Loaded with %1 blacklisted vehicles", count IVORY_BLACKLIST_VEHICLES];
};

// Function to add vehicles to blacklist at runtime
IVORY_fnc_blacklistVehicle = {
    params ["_classname"];

    if !(_classname in IVORY_BLACKLIST_VEHICLES) then {
        IVORY_BLACKLIST_VEHICLES pushBack _classname;
        diag_log format ["[IVORY BLACKLIST] Added %1 to blacklist", _classname];

        // Delete all existing instances
        {
            if (typeOf _x == _classname) then {
                deleteVehicle _x;
                diag_log format ["[IVORY BLACKLIST] Deleted existing instance of %1", _classname];
            };
        } forEach vehicles;
    };
};

diag_log "[IVORY BLACKLIST] To blacklist a vehicle at runtime, use: ['classname'] call IVORY_fnc_blacklistVehicle;";
