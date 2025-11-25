params ["_missionID"];

private _active = DMS get "activeMissions";
_active = _active - [_missionID];
DMS set ["activeMissions", _active];
