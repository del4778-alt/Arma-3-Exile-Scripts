/*
    IVORY'S CAR PACK - FN_TAKEDOWN.SQF PATCH v2.0
    Fixes: "waitUntil returned nil" spam error on line 57
    Enhanced: Better boolean handling, error recovery, logging

    Installation:
    1. Place this file in: mpmissions\__cur_mp.Altis\scripts\ivory_patch.sqf
    2. Add to your init.sqf: [] execVM "scripts\ivory_patch.sqf";
    3. This OVERRIDES the buggy function WITHOUT touching the mod

    This keeps your server "green button" (no mod modifications)
*/

// Run on BOTH client and server to catch all vehicle spawns
if (!hasInterface && !isDedicated) exitWith {};

diag_log "[IVORY PATCH v2.0] Starting Ivory takedown function override...";

// Wait for CfgFunctions to compile (Ivory's mod functions)
[] spawn {
    private _timeout = time + 30; // 30 second timeout
    waitUntil {
        sleep 0.5; 
        !isNil {missionNamespace getVariable "ivory_fnc_takedown"} || time > _timeout
    };

    if (time > _timeout) exitWith {
        diag_log "[IVORY PATCH] ⚠️ WARNING: Ivory functions not found after 30s, patch not applied!";
    };

    diag_log "[IVORY PATCH] Ivory functions loaded, replacing buggy fn_takedown...";

// ✅ FIXED VERSION - Added default values to prevent nil errors
ivory_fnc_takedown = {
    params["_car"];

    // Safety check
    if (isNull _car || !alive _car) exitWith {
        diag_log "[IVORY PATCH] Error: Invalid vehicle passed to fn_takedown";
    };

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
        if (alive _car && !isNull driver _car && {(_car getVariable ["ani_takedown", 0]) > 0} && {(player distance _car) <= 350}) then {			

            _dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _this;
            _dummy attachTo [_this,[0,0,0]];

            [_this,_airhorn,_airhornTime,_airhorn2,_airhornTime2,_dummy] spawn {
                params["_this","_airhorn","_airhornTime","_airhorn2","_airhornTime2","_dummy"];
                
                // ✅ FIX #2: Added default value (0)
                while{(_this getVariable ["ani_takedown", 0]) == 1} do {
                    _timeStarted = time;
                    
                    // ✅ FIX #3: Added default value (0) to both getVariable calls
                    if((_this getVariable ["ani_siren", 0]) > 0 && {(_this getVariable ["ani_siren", 0]) != 3}) then {
                        _dummy say3D [_airhorn2,250];
                        
                        // ✅ FIX #4: Added default value (0) + proper boolean wrapping
                        waitUntil { 
                            sleep 0.01;
                            time >= _timeStarted + _airhornTime2 || {(_this getVariable ["ani_takedown", 0]) != 1}
                        };
                    } else {
                        _dummy say3D [_airhorn,250];
                        
                        // ✅ FIX #5: Added default value (0) + proper boolean wrapping
                        waitUntil { 
                            sleep 0.01;
                            time >= _timeStarted + _airhornTime || {(_this getVariable ["ani_takedown", 0]) != 1}
                        };
                    };

                };
            };
            
            // ✅ FIX #6: Added default value (0)
            waitUntil { 
                sleep 0.01;
                (_car getVariable ["ani_takedown", 0]) == 0 || {!alive _car}
            };

        } else {
            
            detach _dummy;
            deleteVehicle _dummy;

            // ✅ FIX #7: THE BIG ONE - Line 57 fix with default value + proper boolean wrapping
            // This was causing 120+ errors per 10 seconds!
            waitUntil {
                sleep 0.01; 
                !alive _car || {
                    !isNull driver _car && 
                    {(_car getVariable ["ani_takedown", 0]) > 0} && 
                    {(player distance _car) <= 350}
                }
            };

        };

    };
};

    // Force compile the function into mission namespace
    missionNamespace setVariable ["ivory_fnc_takedown", ivory_fnc_takedown];
    publicVariable "ivory_fnc_takedown";

    diag_log "[IVORY PATCH] ✅ fn_takedown patched successfully! All 7 nil-check fixes applied.";
};