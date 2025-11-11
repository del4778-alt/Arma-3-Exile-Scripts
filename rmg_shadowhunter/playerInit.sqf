
if (!hasInterface || !isMultiplayer) exitWith {};

waitUntil { !isNull player && player == player && time > 1 };

[player] remoteExec ["compile preprocessFileLineNumbers 'rmg_shadowhunter\fn_spawnHunter.sqf'", 2];
