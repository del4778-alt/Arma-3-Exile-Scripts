if (!isServer) exitWith {};
params ["_player","_markerName","_bannerId"];

private _idx = WB_zoneIndex getOrDefault [_markerName,-1];
if (_idx < 0) exitWith {};

private _zone = WB_zones select _idx;
if ((_zone select 2) > 1) exitWith {};
if ((_zone select 3) != "" && (_zone select 3) != (_player getVariable ["WB_faction",""])) exitWith {};

private _myId = toUpper format ["PLY_%1", getPlayerUID _player];
private _display = format ["%1's Realm", name _player];

WB_factions pushBack [_myId,_display,[0.8,0.8,1,1],[ _markerName ], resistance, "\A3\Data_F\Flags\Flag_white_CO.paa","WB_LOOT_RES"];
WB_officers set [_myId, []];
WB_generals set [_myId, objNull];
WB_treasury set [_myId, 10000];
WB_troopTrees set [_myId, WB_troopTrees get "PLAYER_DEFAULT"];

WB_zones set [_idx, [_zone select 0, _zone select 1, _zone select 2, _myId, 20]];
_player setVariable ["WB_faction", _myId, true];
_player setVariable ["WB_role", "GENERAL", true];

// Build a small fortress at the claim
private _p = getMarkerPos _markerName;
[_p, 0, _myId, "warbands\fortress\fortress_templates\fortress_civilian.sqf"] call WB_fnc_buildFortress;
