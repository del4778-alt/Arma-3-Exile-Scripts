/*
    Spawns an aircraft crash event
*/

if (!isServer) exitWith {};

private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");

if (random 1 > getNumber (_cfg >> "crashChance")) exitWith {};

// random map pos
private _pos = [random 12000, random 12000, 0];

// wreck selection
private _wrecks = [
    "Land_Wreck_Plane_Transport_01_F",
    "Land_Wreck_Plane_Fighter_03_F",
    "Land_Wreck_Heli_Attack_01_F"
];

private _wreckClass = selectRandom _wrecks;

// create wreck
private _wreck = createVehicle [_wreckClass, _pos, [], 0, "CAN_COLLIDE"];
_wreck setDir random 360;
_wreck setVariable ["UMC_timestamp", time];

// smoke & fire
private _smoke = createVehicle ["Smoke_120mm_AMOS_White", _pos, [], 0, "CAN_COLLIDE"];
private _fire  = createVehicle ["test_EmptyObjectForSmoke", _pos, [], 0, "CAN_COLLIDE"];

_smoke setVariable ["UMC_timestamp", time];
_fire  setVariable ["UMC_timestamp", time];

// AI guards
private _grp = [_pos] call (DYCE get "spawnAI");

// loot crate
private _crate = [_pos] call (DYCE get "spawnLoot");

// mark event
private _id = format ["DYCE_%1", diag_tickTime];

private _active = DYCE get "activeCrashes";
_active pushBack [_id, _pos, time];
DYCE set ["activeCrashes", _active];

diag_log format ["[UMC][DyCE] Crash Event Spawned: %1 at %2", _id, _pos];

_id
