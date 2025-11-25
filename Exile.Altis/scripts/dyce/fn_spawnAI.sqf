/*
    DyCE Spawn AI - Creates crash site guards
*/

params ["_pos"];

private _cfg = (missionConfigFile >> "UMC_Master" >> "DyCE");
private _min = getNumber (_cfg >> "aiCountMin");
private _max = getNumber (_cfg >> "aiCountMax");
private _count = _min + floor random (_max - _min + 1);

private _grp = ["EAST"] call (UMC get "createSafeGroup");

if (isNull _grp) exitWith {
    diag_log "[UMC][DyCE] ERROR: Failed to create AI group";
    grpNull
};

// Unit types for crash guards
private _unitTypes = [
    "O_G_Soldier_F",
    "O_G_Soldier_AR_F",
    "O_G_Soldier_M_F",
    "O_G_medic_F"
];

for "_i" from 1 to _count do {
    private _p = _pos getPos [5 + random 25, random 360];
    private _unitType = selectRandom _unitTypes;
    private _u = _grp createUnit [_unitType, _p, [], 2, "NONE"];
    
    [_u] call (UMC get "applySkill");
    
    private _loot = ["Tier2"] call (UMC get "getLoot");
    if (count _loot >= 2) then {
        _u addWeapon (_loot select 0);
        _u addMagazines [(_loot select 1), 4];
    };
    
    _u addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        [_killer, 8, 15] call (UMC get "reward");
    }];
};

// Set defensive behavior around crash
_grp setBehaviour "AWARE";
_grp setCombatMode "RED";

// Patrol around crash site
for "_i" from 1 to 3 do {
    private _wpPos = _pos getPos [30 + random 30, _i * 120];
    private _wp = _grp addWaypoint [_wpPos, 15];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "AWARE";
};

private _cycleWP = _grp addWaypoint [_pos, 20];
_cycleWP setWaypointType "CYCLE";

diag_log format ["[UMC][DyCE] Spawned %1 crash guards at %2", _count, _pos];

_grp
