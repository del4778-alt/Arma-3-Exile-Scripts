/*
    Occupation (UMC Version)
    Town patrols, roadblocks, roaming vehicles
    
    Now with proper spawn limits and player-based activation
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][Occupation] ERROR: UMC not initialized, aborting.";
};

diag_log "[UMC][Occupation] Initializing...";

if (isNil "OCC") then { OCC = createHashMap; };

// Configuration
OCC set ["maxPatrols", 8];  // Maximum simultaneous patrols

OCC set ["selectTown",       compile preprocessFileLineNumbers "scripts\occupation\fn_selectTown.sqf"];
OCC set ["spawnTownPatrol",  compile preprocessFileLineNumbers "scripts\occupation\fn_spawnTownPatrol.sqf"];
OCC set ["spawnRoadblock",   compile preprocessFileLineNumbers "scripts\occupation\fn_spawnRoadblock.sqf"];
OCC set ["spawnRoamVehicle", compile preprocessFileLineNumbers "scripts\occupation\fn_spawnRoamVehicle.sqf"];
OCC set ["cleanup",          compile preprocessFileLineNumbers "scripts\occupation\fn_cleanup.sqf"];

OCC set ["activePatrols", []];

// ✅ Scheduler hook
["registerQueue", ["OCC", 150]] call (UMC get "scheduler");
["setFunction",  ["OCC", {
    // Always run cleanup first
    [] call (OCC get "cleanup");
    
    // Check spawn limit
    private _active = OCC get "activePatrols";
    private _maxPatrols = OCC get "maxPatrols";
    
    if (count _active >= _maxPatrols) exitWith {
        diag_log format ["[UMC][Occupation] At max patrols (%1/%2)", count _active, _maxPatrols];
    };
    
    // Only spawn if there are players online
    if (count allPlayers == 0) exitWith {};
    
    private _townPos = call (OCC get "selectTown");
    
    if (!isNil "_townPos") then {
        [_townPos] call (OCC get "spawnTownPatrol");
        
        private _cfg = (missionConfigFile >> "UMC_Master" >> "Occupation");
        
        if (random 1 < getNumber (_cfg >> "roadblockChance")) then {
            [_townPos] call (OCC get "spawnRoadblock");
        };
    };

    if (random 1 < getNumber ((missionConfigFile >> "UMC_Master" >> "Occupation") >> "roamVehicleChance")) then {
        [] call (OCC get "spawnRoamVehicle");
    };
    
    diag_log format ["[UMC][Occupation] Active patrols: %1/%2", count (OCC get "activePatrols"), _maxPatrols];
}]] call (UMC get "scheduler");

diag_log "[UMC][Occupation] Ready.";
