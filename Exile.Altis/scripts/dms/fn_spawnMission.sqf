if (!isServer) exitWith {};

private _cfg = (missionConfigFile >> "UMC_Master" >> "DMS");

private _active = DMS get "activeMissions";
private _limit = getNumber (_cfg >> "maxActiveMissions");
if ((count _active) >= _limit) exitWith {};

private _templates = [
    "scripts\dms\missions\banditCamp.sqf"
];

private _template = selectRandom _templates;
private _missionID = call compile preprocessFileLineNumbers _template;

_active pushBack _missionID;
DMS set ["activeMissions", _active];

diag_log format ["[UMC][DMS] mission %1 spawned", _missionID];
