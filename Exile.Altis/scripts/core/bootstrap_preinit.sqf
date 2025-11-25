/*
    UMC PreInit — NO config includes here
*/

if (!isServer) exitWith {};

diag_log "[UMC] PreInit starting";

// Create namespace
if (isNil "UMC") then { UMC = createHashMap; };

// Load core functions
UMC set ["setSides",       compile preprocessFileLineNumbers "scripts\core\fn_setSides.sqf"];
UMC set ["applySkill",     compile preprocessFileLineNumbers "scripts\core\fn_applySkill.sqf"];
UMC set ["getLoot",        compile preprocessFileLineNumbers "scripts\core\fn_getLoot.sqf"];
UMC set ["reward",         compile preprocessFileLineNumbers "scripts\core\fn_reward.sqf"];
UMC set ["cleanupGlobal",  compile preprocessFileLineNumbers "scripts\core\fn_cleanupGlobal.sqf"];
UMC set ["createSafeGroup",compile preprocessFileLineNumbers "scripts\core\fn_createSafeGroup.sqf"];

// Apply side relations
call (UMC get "setSides");

// Initialize scheduler (executes and self-registers in UMC)
call compile preprocessFileLineNumbers "scripts\core\fn_safeScheduler.sqf";

diag_log "[UMC] PreInit complete";
