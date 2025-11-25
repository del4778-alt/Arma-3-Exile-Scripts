/*
    A3XAI (UMC Version)
    Ambient AI patrols
*/

if (!isServer) exitWith {};

// Make sure UMC exists
if (isNil "UMC") exitWith {
    diag_log "[UMC][A3XAI] ERROR: UMC not initialized, aborting A3XAI init.";
};

diag_log "[UMC][A3XAI] Initializing...";

// namespace
if (isNil "A3XAI") then { A3XAI = createHashMap; };

// load functions
A3XAI set ["spawnUnit",          compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnUnit.sqf"];
A3XAI set ["spawnGroup",         compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnGroup.sqf"];
A3XAI set ["spawnPatrol",        compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnPatrol.sqf"];
A3XAI set ["spawnVehiclePatrol", compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnVehiclePatrol.sqf"];
A3XAI set ["registerGroup",      compile preprocessFileLineNumbers "scripts\a3xai\fn_registerGroup.sqf"];
A3XAI set ["despawn",            compile preprocessFileLineNumbers "scripts\a3xai\fn_despawn.sqf"];
A3XAI set ["logic",              compile preprocessFileLineNumbers "scripts\a3xai\fn_logic.sqf"];

// active groups
A3XAI set ["activeGroups", []];

// ✅ Proper scheduler registration
["registerQueue", ["A3XAI", 45]] call (UMC get "scheduler");
["setFunction",  ["A3XAI", { [] call (A3XAI get "logic") }]] call (UMC get "scheduler");

diag_log "[UMC][A3XAI] Ready.";
