if (!isServer) exitWith {};
params ["_player","_factionId","_role"];
if (isNull _player) exitWith {};

_player setVariable ["WB_faction", _factionId, true];
_player setVariable ["WB_role", _role, true];
diag_log format ["[WB] %1 joined %2 as %3", getPlayerUID _player, _factionId, _role];
