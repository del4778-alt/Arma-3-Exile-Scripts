/*
    DyCE - Dynamic Crash Events
    Spawns aircraft crash sites with AI guards and loot
*/

if (!isServer) exitWith {};

private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");

if (random 1 > getNumber (_cfg >> "crashChance")) exitWith {};

// Find position near a player but not too close
if (count allPlayers == 0) exitWith {};

private _player = selectRandom allPlayers;
private _playerPos = getPosATL _player;

// Spawn 800-2000m from player
private _dist = 800 + random 1200;
private _dir = random 360;
private _pos = _playerPos getPos [_dist, _dir];

// Ensure on land
private _attempts = 0;
while {(surfaceIsWater _pos || _pos distance2D [0,0] < 500) && _attempts < 20} do {
    _pos = _playerPos getPos [_dist, random 360];
    _attempts = _attempts + 1;
};

if (surfaceIsWater _pos) exitWith {
    diag_log "[UMC][DyCE] Could not find valid land position";
};

// Wreck selection
private _wrecks = [
    ["Land_Wreck_Plane_Transport_01_F", "Transport Plane"],
    ["Land_Wreck_Plane_Fighter_03_F", "Fighter Jet"],
    ["Land_Wreck_Heli_Attack_01_F", "Attack Helicopter"],
    ["Land_Wreck_Heli_Attack_02_F", "Military Helicopter"]
];

private _wreckData = selectRandom _wrecks;
private _wreckClass = _wreckData select 0;
private _wreckName = _wreckData select 1;

// Create wreck
private _wreck = createVehicle [_wreckClass, _pos, [], 0, "CAN_COLLIDE"];
_wreck setDir random 360;
_wreck setVariable ["UMC_timestamp", time];

// Smoke & fire effects
private _smoke = createVehicle ["Smoke_120mm_AMOS_White", _pos, [], 0, "CAN_COLLIDE"];
private _fire = createVehicle ["test_EmptyObjectForSmoke", _pos, [], 0, "CAN_COLLIDE"];

_smoke setVariable ["UMC_timestamp", time];
_fire setVariable ["UMC_timestamp", time];

// ============================================
// CREATE MARKERS
// ============================================
private _id = format ["DYCE_%1", floor diag_tickTime];

private _markerName = format ["DYCE_marker_%1", _id];
private _marker = createMarker [_markerName, _pos];
_marker setMarkerType "hd_destroy";
_marker setMarkerColor "ColorYellow";
_marker setMarkerText format ["Crash: %1", _wreckName];
_marker setMarkerSize [0.8, 0.8];

private _areaMarker = createMarker [_markerName + "_area", _pos];
_areaMarker setMarkerShape "ELLIPSE";
_areaMarker setMarkerSize [100, 100];
_areaMarker setMarkerColor "ColorYellow";
_areaMarker setMarkerAlpha 0.2;
_areaMarker setMarkerBrush "SolidBorder";

// ============================================
// NOTIFICATIONS
// ============================================
private _gridRef = mapGridPosition _pos;
private _msg = format ["<t color='#FFFF00' size='1.2'>✈️ CRASH SITE DETECTED</t><br/><t color='#FFFFFF'>%1 down at grid %2</t><br/><t color='#AAAAAA'>Survivors may be hostile - valuable cargo reported</t>", _wreckName, _gridRef];
[_msg, 0, 0.2, 7, 1] remoteExec ["BIS_fnc_dynamicText", 0];

[format ["✈️ CRASH SITE: %1 reported down at grid %2", _wreckName, _gridRef]] remoteExec ["systemChat", 0];

// ============================================
// AI GUARDS
// ============================================
private _grp = [_pos] call (DYCE get "spawnAI");

// ============================================
// LOOT CRATE
// ============================================
private _crate = [_pos] call (DYCE get "spawnLoot");

// ============================================
// STORE EVENT DATA
// ============================================
private _active = DYCE get "activeCrashes";
_active pushBack [_id, _pos, time, [_markerName, _areaMarker], _wreck, _smoke, _fire, _crate];
DYCE set ["activeCrashes", _active];

diag_log format ["[UMC][DyCE] Crash Event: %1 (%2) at %3", _id, _wreckName, _pos];

_id
