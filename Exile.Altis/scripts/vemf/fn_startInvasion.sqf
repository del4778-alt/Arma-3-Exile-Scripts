/*
    VEMFr Start Invasion - Town invasion event
    Creates markers and notifications
*/

if (!isServer) exitWith {};

private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
if (random 1 > getNumber (_cfg >> "invasionChance")) exitWith {};

private _townData = call (VEMF get "selectTown");
if (isNil "_townData") exitWith {};

_townData params ["_townPos", "_townName"];

private _min = getNumber (_cfg >> "minWaves");
private _max = getNumber (_cfg >> "maxWaves");
private _waves = _min + floor random (_max - _min + 1);

private _id = format ["VEMF_%1", floor diag_tickTime];

// ============================================
// CREATE MARKERS
// ============================================
private _markerName = format ["VEMF_marker_%1", _id];
private _marker = createMarker [_markerName, _townPos];
_marker setMarkerType "o_inf";
_marker setMarkerColor "ColorOrange";
_marker setMarkerText format ["INVASION: %1", _townName];
_marker setMarkerSize [1, 1];

private _areaMarker = createMarker [_markerName + "_area", _townPos];
_areaMarker setMarkerShape "ELLIPSE";
_areaMarker setMarkerSize [200, 200];
_areaMarker setMarkerColor "ColorOrange";
_areaMarker setMarkerAlpha 0.25;
_areaMarker setMarkerBrush "FDiagonal";

// Store markers for cleanup
VEMF set [_id + "_markers", [_markerName, _areaMarker]];

// ============================================
// NOTIFICATIONS
// ============================================
private _msgStart = format ["<t color='#FF6600' size='1.3'>⚠️ TOWN INVASION</t><br/><t color='#FFFFFF'>%1 is under attack!</t><br/><t color='#AAAAAA'>%2 waves incoming - High-value loot!</t>", _townName, _waves];
[_msgStart, 0, 0.2, 8, 1] remoteExec ["BIS_fnc_dynamicText", 0];

// Also system chat
[format ["⚠️ INVASION: %1 is under attack! %2 enemy waves detected.", _townName, _waves]] remoteExec ["systemChat", 0];

// Sound alert
playSound3D ["A3\Sounds_F\sfx\alarm.wss", objNull, false, _townPos, 3, 1, 1500];

// ============================================
// STORE INVASION DATA
// ============================================
private _entry = [_id, _townPos, _townName, 0, _waves, time];
private _active = VEMF get "activeInvasions";
_active pushBack _entry;
VEMF set ["activeInvasions", _active];

diag_log format ["[UMC][VEMF] Invasion %1 started at %2 (%3 waves)", _id, _townName, _waves];

// ============================================
// SPAWN FIRST WAVE
// ============================================
[_id] call (VEMF get "spawnWave");
