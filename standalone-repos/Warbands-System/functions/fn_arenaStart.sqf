if (!isServer) exitWith {};
params ["_player","_buyIn","_purse"];
if (isNull _player) exitWith {};

private _pos = getPosWorld _player;
private _grp = createGroup [east, true];
private _opp = _grp createUnit ["O_Soldier_F", _pos getPos [25, random 360], [], 2, "FORM"];
_opp setSkill 0.75;
_opp addEventHandler ["Killed", {
    params ["_unit","_killer"];
    if (!isNull _killer && isPlayer _killer) then {
        diag_log format ["[WB] Arena: %1 won a duel.", name _killer];
    };
}];
_opp doTarget _player; _opp doFire _player;
