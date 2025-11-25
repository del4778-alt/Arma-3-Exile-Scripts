/*
    DyCE (UMC Version)
    Dynamic Aircraft Crash Events
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][DyCE] ERROR: UMC not initialized, aborting.";
};

diag_log "[UMC][DyCE] Initializing...";

if (isNil "DYCE") then { DYCE = createHashMap; };

DYCE set ["spawnCrash", compile preprocessFileLineNumbers "scripts\dyce\fn_spawnCrash.sqf"];
DYCE set ["spawnAI",    compile preprocessFileLineNumbers "scripts\dyce\fn_spawnAI.sqf"];
DYCE set ["spawnLoot",  compile preprocessFileLineNumbers "scripts\dyce\fn_spawnLoot.sqf"];
DYCE set ["cleanup",    compile preprocessFileLineNumbers "scripts\dyce\fn_cleanup.sqf"];

DYCE set ["activeCrashes", []];

// ✅ Scheduler hook
["registerQueue", ["DYCE", 240]] call (UMC get "scheduler");
["setFunction",  ["DYCE", {
    [] call (DYCE get "spawnCrash");
    [] call (DYCE get "cleanup");
}]] call (UMC get "scheduler");

diag_log "[UMC][DyCE] Ready.";
