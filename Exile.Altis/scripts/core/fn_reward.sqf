params ["_player","_respect","_poptabs"];

if (isNull _player) exitWith {};
if (!isPlayer _player) exitWith {};

private _curMoney = _player getVariable ["ExileMoney",0];
_player setVariable ["ExileMoney", _curMoney + _poptabs, true];

_player addScore _respect;

diag_log format ["[UMC][REWARD] %1 +%2 respect +%3 poptabs", name _player, _respect, _poptabs];
