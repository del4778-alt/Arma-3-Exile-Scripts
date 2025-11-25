/*
    DMS Cleanup Mission - Removes all mission objects and markers
*/

params ["_missionID"];

diag_log format ["[UMC][DMS] Cleaning up mission %1", _missionID];

// Delete markers
private _markers = DMS getOrDefault [_missionID + "_markers", []];
{ deleteMarker _x } forEach _markers;

// Delete crate
private _crate = DMS getOrDefault [_missionID + "_crate", objNull];
if (!isNull _crate) then { deleteVehicle _crate };

// Delete any remaining AI
private _grp = DMS getOrDefault [_missionID + "_group", grpNull];
if (!isNull _grp) then {
    { deleteVehicle _x } forEach (units _grp);
    deleteGroup _grp;
};

// Clean up dead bodies near mission
private _pos = DMS getOrDefault [_missionID + "_pos", [0,0,0]];
if !(_pos isEqualTo [0,0,0]) then {
    {
        if (_x distance _pos < 150) then { deleteVehicle _x };
    } forEach allDeadMen;
};

// Remove from active missions
private _active = DMS get "activeMissions";
_active = _active - [_missionID];
DMS set ["activeMissions", _active];

// Clean up stored data
DMS deleteAt (_missionID + "_markers");
DMS deleteAt (_missionID + "_group");
DMS deleteAt (_missionID + "_crate");
DMS deleteAt (_missionID + "_pos");
DMS deleteAt (_missionID + "_aiCount");

diag_log format ["[UMC][DMS] Mission %1 cleanup complete", _missionID];
