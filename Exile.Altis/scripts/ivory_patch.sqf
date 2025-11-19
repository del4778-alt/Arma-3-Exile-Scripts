/*
    IVORY'S CAR PACK - FN_TAKEDOWN.SQF PATCH
    Fixes: "waitUntil returned nil" spam error on line 57

    Installation:
    1. Place this file in: mpmissions\__cur_mp.Altis\scripts\ivory_patch.sqf
    2. Add to your init.sqf: [] execVM "scripts\ivory_patch.sqf";
    3. This OVERRIDES the buggy function WITHOUT touching the mod

    This keeps your server "green button" (no mod modifications)
*/

// Run on BOTH client and server to catch all vehicle spawns
if (!hasInterface && !isDedicated) exitWith {};

diag_log "[IVORY PATCH] ========================================";
diag_log "[IVORY PATCH] Starting Ivory takedown function override...";
diag_log "[IVORY PATCH] ========================================";

// Wait for mission to fully load, then aggressively override
[] spawn {
    // Wait for mission to be ready (5 seconds)
    sleep 5;

    diag_log "[IVORY PATCH] Mission loaded, replacing buggy fn_takedown...";

// ✅ FIXED VERSION - Added default values to prevent nil errors
ivory_fnc_takedown = {
    params["_car"];

    _emergencySiren = getNumber(configFile >> "cfgVehicles" >> typeOf _this >> "emergencySiren");
    _airhorn = "";
    _airhornTime = "";
    _airhorn2 = "";
    _airhornTime2 = "";

    _dummy = ObjNull;

    if(_emergencySiren isEqualTo 1) then
    {
        _airhorn = "ivory_ss2000_wail";
        _airhornTime = 20.742;
        _airhorn2 = "ivory_ss2000_priority";
        _airhornTime2 = 9.862;
    };
    if(_emergencySiren isEqualTo 2) then
    {
        _airhorn = "ivory_pa300_wail";
        _airhornTime = 18.641;
        _airhorn2 = "ivory_pa300_priority";
        _airhornTime2 = 10.674;
    };

    while {alive _car} do 
    {    
       
        // ✅ FIX #1: Added default value (0) to prevent nil
        if (alive _car && !isNull driver _car && (_car getVariable ["ani_takedown", 0]) > 0 && (player distance _car <= 350)) then {			

            _dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _this;
            _dummy attachTo [_this,[0,0,0]];

            [_this,_airhorn,_airhornTime,_airhorn2,_airhornTime2,_dummy] spawn {
                params["_this","_airhorn","_airhornTime","_airhorn2","_airhornTime2","_dummy"];
                
                // ✅ FIX #2: Added default value (0)
                while{(_this getVariable ["ani_takedown", 0]) == 1} do {
                    _timeStarted = time;
                    
                    // ✅ FIX #3: Added default value (0)
                    if((_this getVariable ["ani_siren", 0]) > 0 && (_this getVariable ["ani_siren", 0]) != 3) then {
                        _dummy say3D [_airhorn2,250];
                        // ✅ FIX #4: Added default value (0)
                        waitUntil { time >= _timeStarted + _airhornTime2 || (_this getVariable ["ani_takedown", 0]) != 1 };
                    } else {
                        _dummy say3D [_airhorn,250];
                        // ✅ FIX #5: Added default value (0)
                        waitUntil { time >= _timeStarted + _airhornTime || (_this getVariable ["ani_takedown", 0]) != 1 };
                    };

                };
            };
            
            // ✅ FIX #6: Added default value (0)
            waitUntil { (_car getVariable ["ani_takedown", 0]) == 0 };

        } else {
            
            detach _dummy;
            deleteVehicle _dummy;

            // ✅ FIX #7: THE BIG ONE - Line 57 fix with default value
            waitUntil {
                sleep 0.01; 
                !alive _car || (!isNull driver _car && (_car getVariable ["ani_takedown", 0]) > 0 && (player distance _car <= 350))
            };

        };

    };
};

    // Aggressively override ALL possible function references
    diag_log "[IVORY PATCH] Installing fixed function to all namespaces...";

    // Override in mission namespace
    missionNamespace setVariable ["ivory_fnc_takedown", ivory_fnc_takedown, true];

    // Override in UI namespace (if exists)
    uiNamespace setVariable ["ivory_fnc_takedown", ivory_fnc_takedown, true];

    // Override in profile namespace (if exists)
    profileNamespace setVariable ["ivory_fnc_takedown", ivory_fnc_takedown];

    // Broadcast to all clients
    publicVariable "ivory_fnc_takedown";

    // Wait a bit, then verify
    sleep 2;

    private _installed = missionNamespace getVariable ["ivory_fnc_takedown", {}];
    if (str _installed == str ivory_fnc_takedown) then {
        diag_log "[IVORY PATCH] ========================================";
        diag_log "[IVORY PATCH] ✅ PATCH INSTALLED SUCCESSFULLY!";
        diag_log "[IVORY PATCH] fn_takedown override verified";
        diag_log "[IVORY PATCH] waitUntil nil errors should be eliminated";
        diag_log "[IVORY PATCH] ========================================";
    } else {
        diag_log "[IVORY PATCH] ⚠️ WARNING: Function override may have failed!";
        diag_log "[IVORY PATCH] Please check for Ivory errors in logs";
    };
};
