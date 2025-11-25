/*
    VEMFr (UMC Version)
    Town Invasions & Reinforcement Waves
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][VEMF] ERROR: UMC not initialized, aborting.";
};

diag_log "[UMC][VEMF] Initializing...";

if (isNil "VEMF") then { VEMF = createHashMap; };

VEMF set ["selectTown",    compile preprocessFileLineNumbers "scripts\vemf\fn_selectTown.sqf"];
VEMF set ["startInvasion", compile preprocessFileLineNumbers "scripts\vemf\fn_startInvasion.sqf"];
VEMF set ["spawnWave",     compile preprocessFileLineNumbers "scripts\vemf\fn_spawnWave.sqf"];
VEMF set ["spawnHeli",     compile preprocessFileLineNumbers "scripts\vemf\fn_spawnHeli.sqf"];
VEMF set ["cleanup",       compile preprocessFileLineNumbers "scripts\vemf\fn_cleanup.sqf"];

VEMF set ["activeInvasions", []];

// ✅ Scheduler hook
["registerQueue", ["VEMF", 180]] call (UMC get "scheduler");
["setFunction",  ["VEMF", {
    [] call (VEMF get "startInvasion");
    [] call (VEMF get "cleanup");
}]] call (UMC get "scheduler");

diag_log "[UMC][VEMF] Ready.";
