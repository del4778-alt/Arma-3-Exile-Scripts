/*
    IVORY DIAGNOSTIC TOOL

    This script helps identify which vehicle is causing the takedown error
    by logging all Ivory vehicle spawns and monitoring for errors.

    Installation:
    1. Add to init.sqf: [] execVM "scripts\ivory_diagnostic.sqf";
    2. Check your server RPT log for "[IVORY DIAG]" entries
    3. When you see the error, check the most recently spawned vehicle
*/

if (!isServer) exitWith {};

diag_log "[IVORY DIAG] ========================================";
diag_log "[IVORY DIAG] Ivory Vehicle Diagnostic Starting...";
diag_log "[IVORY DIAG] ========================================";

// Track all vehicle spawns
IVORY_DIAG_VehicleLog = [];

addMissionEventHandler ["EntityCreated", {
    params ["_entity"];

    if (_entity isKindOf "LandVehicle") then {
        private _classname = typeOf _entity;

        // Only log Ivory vehicles (adjust prefix if different)
        if (_classname find "ivory" >= 0) then {
            private _time = time;
            private _pos = getPosATL _entity;

            IVORY_DIAG_VehicleLog pushBack [_time, _classname, _pos];

            diag_log format ["[IVORY DIAG] Vehicle spawned: %1 at %2 (time: %3)", _classname, _pos, _time];

            // Monitor this vehicle for the takedown variable
            _entity spawn {
                private _veh = _this;
                private _lastTakedown = nil;

                while {alive _veh} do {
                    sleep 1;

                    // Check if takedown variable exists
                    private _takedown = _veh getVariable ["ani_takedown", "UNDEFINED"];

                    if (_takedown != _lastTakedown) then {
                        if (_takedown == "UNDEFINED") then {
                            diag_log format ["[IVORY DIAG] ⚠️ WARNING: Vehicle %1 has UNDEFINED ani_takedown variable! This can cause the error!", typeOf _veh];
                        } else {
                            diag_log format ["[IVORY DIAG] Vehicle %1 takedown state changed: %2", typeOf _veh, _takedown];
                        };
                        _lastTakedown = _takedown;
                    };
                };
            };
        };
    };
}];

// Log the last 5 spawned vehicles every 60 seconds
[] spawn {
    while {true} do {
        sleep 60;

        private _count = count IVORY_DIAG_VehicleLog;
        if (_count > 0) then {
            diag_log format ["[IVORY DIAG] Total Ivory vehicles spawned: %1", _count];

            // Show last 5
            private _recent = [];
            for "_i" from ((_count - 5) max 0) to (_count - 1) do {
                _recent pushBack (IVORY_DIAG_VehicleLog select _i);
            };

            diag_log "[IVORY DIAG] Recent vehicles:";
            {
                _x params ["_time", "_class", "_pos"];
                diag_log format ["  - %1 (time: %2)", _class, _time];
            } forEach _recent;
        };
    };
};

diag_log "[IVORY DIAG] ✅ Diagnostic monitoring active!";
diag_log "[IVORY DIAG] Watch for '⚠️ WARNING' messages to identify problem vehicles";
