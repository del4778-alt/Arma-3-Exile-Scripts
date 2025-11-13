/**
 * Warbands Client Post-Init
 * Called automatically by CfgFunctions postInit
 */

if (!hasInterface) exitWith {};

// Load client initialization
call compile preprocessFileLineNumbers "warbands\WB_Init_Client.sqf";

diag_log "[WB] Profession/Client init complete";
