/*
    Shadow Hunter System - Server Initialization
    Pre-compiles all functions and initializes global variables
*/

if (!isServer) exitWith {};

// Initialize global evolution stats with caps
if (isNil "SHW_phase") then { SHW_phase = 1; };
if (isNil "SHW_accuracy") then { SHW_accuracy = 0.15; };
if (isNil "SHW_aggression") then { SHW_aggression = 300; };
if (isNil "SHW_stealth") then { SHW_stealth = 0; };
if (isNil "SHW_loadoutTier") then { SHW_loadoutTier = 1; };
if (isNil "SHW_lastKnownHotspots") then { SHW_lastKnownHotspots = []; };

// Define stat caps for game balance
SHW_MAX_ACCURACY = 0.95;
SHW_MAX_AGGRESSION = 800;
SHW_MAX_STEALTH = 0.8;
SHW_MAX_LOADOUT_TIER = 3;

// Pre-compile all functions once (performance optimization)
SHW_fnc_spawnHunter = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_spawnHunter.sqf";
SHW_fnc_assignLoadout = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_assignLoadout.sqf";
SHW_fnc_escortLoop = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_escortLoop.sqf";
SHW_fnc_huntLoop = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_huntLoop.sqf";
SHW_fnc_evolveOnKill = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_evolveOnKill.sqf";
SHW_fnc_evolveOnDeath = compileFinal preprocessFileLineNumbers "rmg_shadowhunter\fn_evolveOnDeath.sqf";

// Publish functions and variables to all clients
publicVariable "SHW_fnc_spawnHunter";
publicVariable "SHW_fnc_assignLoadout";
publicVariable "SHW_fnc_escortLoop";
publicVariable "SHW_fnc_huntLoop";
publicVariable "SHW_fnc_evolveOnKill";
publicVariable "SHW_fnc_evolveOnDeath";

publicVariable "SHW_phase";
publicVariable "SHW_accuracy";
publicVariable "SHW_aggression";
publicVariable "SHW_stealth";
publicVariable "SHW_loadoutTier";
publicVariable "SHW_lastKnownHotspots";
publicVariable "SHW_MAX_ACCURACY";
publicVariable "SHW_MAX_AGGRESSION";
publicVariable "SHW_MAX_STEALTH";
publicVariable "SHW_MAX_LOADOUT_TIER";

diag_log "[Shadow Hunter] System initialized - Functions compiled";
