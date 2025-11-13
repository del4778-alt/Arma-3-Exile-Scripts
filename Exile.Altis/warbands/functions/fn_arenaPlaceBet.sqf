if (!isServer) exitWith {};
params ["_player","_amount","_onFighterA"];
_amount = _amount max WB_ARENA_MIN_BET min WB_ARENA_MAX_BET;
private _uid = getPlayerUID _player;
if (isNil "WB_bets") then { WB_bets = createHashMap; };
WB_bets set [_uid, [_amount,_onFighterA]];
