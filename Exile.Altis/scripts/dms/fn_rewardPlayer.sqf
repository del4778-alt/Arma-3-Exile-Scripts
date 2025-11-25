/*
    Extra reward for completing mission objective
*/

params ["_player"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "DMS");
private _res  = getNumber (_cfg >> "rewardRespect");
private _tabs = getNumber (_cfg >> "rewardPoptabs");

[_player, _res, _tabs] call (UMC get "reward");
