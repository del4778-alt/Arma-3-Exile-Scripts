private _missionID = format ["DMS_%1", diag_tickTime];

// Find a valid land position on Altis
private _pos = [0,0,0];
private _attempts = 0;
while {_attempts < 50} do {
    private _testPos = [random 25000, random 20000, 0];
    if (!surfaceIsWater _testPos && {_testPos distance2D [0,0] > 500}) exitWith {
        _pos = _testPos;
    };
    _attempts = _attempts + 1;
};

if (_pos isEqualTo [0,0,0]) exitWith {
    diag_log "[UMC][DMS] Failed to find valid position for bandit camp";
    nil
};

private _cfg = (missionConfigFile >> "UMC_Master" >> "DMS");
private _min = getNumber (_cfg >> "aiMin");
private _max = getNumber (_cfg >> "aiMax");
private _count = _min + floor random (_max - _min + 1);

private _grp = [_pos,_count] call (DMS get "spawnAIGroup");
private _crate = [_pos vectorAdd [5,5,0]] call (DMS get "spawnCrate");

// Create mission marker
private _markerName = format ["DMS_marker_%1", _missionID];
private _marker = createMarker [_markerName, _pos];
_marker setMarkerType "mil_warning";
_marker setMarkerColor "ColorRed";
_marker setMarkerText "Bandit Camp";
_marker setMarkerSize [1, 1];

// Create area marker
private _areaMarker = createMarker [_markerName + "_area", _pos];
_areaMarker setMarkerShape "ELLIPSE";
_areaMarker setMarkerSize [150, 150];
_areaMarker setMarkerColor "ColorRed";
_areaMarker setMarkerAlpha 0.3;
_areaMarker setMarkerBrush "SolidBorder";

// Store marker names for cleanup
DMS set [_missionID + "_markers", [_markerName, _areaMarker]];
DMS set [_missionID + "_group", _grp];
DMS set [_missionID + "_crate", _crate];
DMS set [_missionID + "_pos", _pos];

// Announce mission
[format ["Bandit Camp spotted! Location marked on map."]] remoteExec ["systemChat", 0];

diag_log format ["[UMC][DMS] Bandit camp at %1 with %2 AI", _pos, _count];

_missionID
