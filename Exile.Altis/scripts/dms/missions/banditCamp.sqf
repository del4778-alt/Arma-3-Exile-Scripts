/*
    DMS Mission: Bandit Camp
    A group of bandits have set up camp. Clear them out for rewards.
*/

private _missionID = format ["DMS_%1", floor diag_tickTime];

// ============================================
// FIND POSITION
// ============================================
// Find position near a player
private _pos = [0,0,0];

if (count allPlayers > 0) then {
    private _player = selectRandom allPlayers;
    private _playerPos = getPosATL _player;
    
    // 600-1500m from player
    private _dist = 600 + random 900;
    private _dir = random 360;
    _pos = _playerPos getPos [_dist, _dir];
    
    // Validate position
    private _attempts = 0;
    while {(surfaceIsWater _pos || _pos distance2D [0,0] < 500) && _attempts < 30} do {
        _pos = _playerPos getPos [_dist, random 360];
        _attempts = _attempts + 1;
    };
};

// Fallback to random position
if (_pos isEqualTo [0,0,0] || surfaceIsWater _pos) then {
    private _attempts = 0;
    while {_attempts < 50} do {
        private _testPos = [1000 + random 20000, 1000 + random 18000, 0];
        if (!surfaceIsWater _testPos && {_testPos distance2D [0,0] > 500}) exitWith {
            _pos = _testPos;
        };
        _attempts = _attempts + 1;
    };
};

if (_pos isEqualTo [0,0,0]) exitWith {
    diag_log "[UMC][DMS] Failed to find valid position for bandit camp";
    nil
};

// ============================================
// SPAWN AI
// ============================================
private _cfg = (missionConfigFile >> "UMC_Master" >> "DMS");
private _min = getNumber (_cfg >> "aiMin");
private _max = getNumber (_cfg >> "aiMax");
private _count = _min + floor random (_max - _min + 1);

private _grp = [_pos, _count] call (DMS get "spawnAIGroup");
private _crate = [_pos vectorAdd [5, 5, 0]] call (DMS get "spawnCrate");

// ============================================
// CREATE MARKERS
// ============================================
private _markerName = format ["DMS_marker_%1", _missionID];
private _marker = createMarker [_markerName, _pos];
_marker setMarkerType "mil_warning";
_marker setMarkerColor "ColorRed";
_marker setMarkerText "Bandit Camp";
_marker setMarkerSize [1, 1];

private _areaMarker = createMarker [_markerName + "_area", _pos];
_areaMarker setMarkerShape "ELLIPSE";
_areaMarker setMarkerSize [150, 150];
_areaMarker setMarkerColor "ColorRed";
_areaMarker setMarkerAlpha 0.25;
_areaMarker setMarkerBrush "SolidBorder";

// ============================================
// STORE MISSION DATA
// ============================================
DMS set [_missionID + "_markers", [_markerName, _areaMarker]];
DMS set [_missionID + "_group", _grp];
DMS set [_missionID + "_crate", _crate];
DMS set [_missionID + "_pos", _pos];
DMS set [_missionID + "_aiCount", _count];

// ============================================
// NOTIFICATIONS
// ============================================
private _gridRef = mapGridPosition _pos;
private _msg = format ["<t color='#FF4444' size='1.2'>🎯 MISSION: BANDIT CAMP</t><br/><t color='#FFFFFF'>%1 hostiles spotted at grid %2</t><br/><t color='#AAAAAA'>Eliminate the threat and secure the supplies!</t>", _count, _gridRef];
[_msg, 0, 0.2, 7, 1] remoteExec ["BIS_fnc_dynamicText", 0];

[format ["🎯 MISSION: Bandit Camp - %1 hostiles at grid %2. Secure the area for rewards!", _count, _gridRef]] remoteExec ["systemChat", 0];

diag_log format ["[UMC][DMS] Bandit Camp at %1 with %2 AI", _pos, _count];

// ============================================
// MONITOR FOR COMPLETION
// ============================================
[_missionID, _grp, _pos, _crate] spawn {
    params ["_missionID", "_grp", "_pos", "_crate"];
    
    // Wait for all AI dead
    waitUntil {
        sleep 10;
        {alive _x} count (units _grp) == 0
    };
    
    // Mission complete!
    diag_log format ["[UMC][DMS] Mission %1 completed!", _missionID];
    
    // Notification
    private _msg = "<t color='#00FF00' size='1.2'>✓ MISSION COMPLETE</t><br/><t color='#FFFFFF'>Bandit Camp cleared!</t><br/><t color='#AAAAAA'>Loot is available at the site.</t>";
    [_msg, 0, 0.2, 6, 1] remoteExec ["BIS_fnc_dynamicText", 0];
    ["✓ MISSION COMPLETE: Bandit Camp cleared! Claim your rewards."] remoteExec ["systemChat", 0];
    
    // Update marker
    private _markers = DMS getOrDefault [_missionID + "_markers", []];
    if (count _markers > 0) then {
        (_markers select 0) setMarkerColor "ColorGreen";
        (_markers select 0) setMarkerText "Cleared - Loot Available";
    };
    
    // Cleanup after delay
    sleep 300;  // 5 minutes to loot
    [_missionID] call (DMS get "cleanupMission");
};

_missionID
