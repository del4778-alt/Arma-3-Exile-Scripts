params ["_id"];

private _active = VEMF get "activeInvasions";
private _entry = _active select { (_x select 0) == _id } param [0, []];
if (_entry isEqualTo []) exitWith {};

private _pos = _entry select 1;
private _cur = _entry select 2;
private _max = _entry select 3;

if (_cur >= _max) exitWith {
    diag_log format ["[UMC][VEMF] invasion %1 complete", _id];
};

private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
private _min = getNumber (_cfg >> "waveSizeMin");
private _maxSize = getNumber (_cfg >> "waveSizeMax");
private _size = _min + floor random (_maxSize - _min + 1);

private _grp = ["EAST"] call (UMC get "createSafeGroup");

for "_i" from 1 to _size do {
    private _p = _pos getPos [random 60, random 360];
    private _u = _grp createUnit ["O_Soldier_F", _p, [], 5, "NONE"];
    [_u] call (UMC get "applySkill");
    private _loot = ["Tier3"] call (UMC get "getLoot");
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 4];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer,15,30] call (UMC get "reward");
    }];
};

if (random 1 < 0.1) then {
    [_pos] call (VEMF get "spawnHeli");
};

_entry set [2, _cur + 1];
_active = _active - [_entry];
_active pushBack _entry;
VEMF set ["activeInvasions", _active];
