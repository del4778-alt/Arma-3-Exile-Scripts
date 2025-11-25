/*
    Dynamic Mission System (UMC Version)
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][DMS] ERROR: UMC not initialized, aborting.";
};

diag_log "[UMC][DMS] Initializing...";

if (isNil "DMS") then { DMS = createHashMap; };

DMS set ["spawnMission",   compile preprocessFileLineNumbers "scripts\dms\fn_spawnMission.sqf"];
DMS set ["spawnAIGroup",   compile preprocessFileLineNumbers "scripts\dms\fn_spawnAIGroup.sqf"];
DMS set ["spawnCrate",     compile preprocessFileLineNumbers "scripts\dms\fn_spawnCrate.sqf"];
DMS set ["cleanupMission", compile preprocessFileLineNumbers "scripts\dms\fn_cleanupMission.sqf"];
DMS set ["rewardPlayer",   compile preprocessFileLineNumbers "scripts\dms\fn_rewardPlayer.sqf"];

DMS set ["activeMissions", []];

// ✅ Scheduler hook
["registerQueue", ["DMS", 120]] call (UMC get "scheduler");
["setFunction",  ["DMS", { [] call (DMS get "spawnMission") }]] call (UMC get "scheduler");

diag_log "[UMC][DMS] Ready.";
