/*
    Occupation (UMC Version)
    Town patrols, roadblocks, roaming vehicles
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][Occupation] ERROR: UMC not initialized, aborting.";
};

diag_log "[UMC][Occupation] Initializing...";

if (isNil "OCC") then { OCC = createHashMap; };

OCC set ["selectTown",       compile preprocessFileLineNumbers "scripts\occupation\fn_selectTown.sqf"];
OCC set ["spawnTownPatrol",  compile preprocessFileLineNumbers "scripts\occupation\fn_spawnTownPatrol.sqf"];
OCC set ["spawnRoadblock",   compile preprocessFileLineNumbers "scripts\occupation\fn_spawnRoadblock.sqf"];
OCC set ["spawnRoamVehicle", compile preprocessFileLineNumbers "scripts\occupation\fn_spawnRoamVehicle.sqf"];
OCC set ["cleanup",          compile preprocessFileLineNumbers "scripts\occupation\fn_cleanup.sqf"];

OCC set ["activePatrols", []];

// ✅ Scheduler hook
["registerQueue", ["OCC", 150]] call (UMC get "scheduler");
["setFunction",  ["OCC", {
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

    [] call (OCC get "cleanup");
}]] call (UMC get "scheduler");

diag_log "[UMC][Occupation] Ready.";
