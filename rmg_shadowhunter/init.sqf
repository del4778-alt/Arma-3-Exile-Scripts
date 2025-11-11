
// Default values (first run)
if (isNil "SHW_phase") then { SHW_phase = 1; };
if (isNil "SHW_accuracy") then { SHW_accuracy = 0.15; };
if (isNil "SHW_aggression") then { SHW_aggression = 300; };
if (isNil "SHW_stealth") then { SHW_stealth = 0; };
if (isNil "SHW_loadoutTier") then { SHW_loadoutTier = 1; };
if (isNil "SHW_lastKnownHotspots") then { SHW_lastKnownHotspots = []; };

[] call compile preprocessFileLineNumbers "rmg_shadowhunter\fn_spawnHunter.sqf";
