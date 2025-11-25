/*
    VEMF Spawn Wave - Spawns an invasion wave
*/

params ["_id"];

private _active = VEMF get "activeInvasions";
private _entry = _active select { (_x select 0) == _id } param [0, []];
if (_entry isEqualTo []) exitWith {};

_entry params ["_missionId", "_pos", "_townName", "_cur", "_max", "_startTime"];

if (_cur >= _max) exitWith {
    // Invasion complete
    diag_log format ["[UMC][VEMF] Invasion %1 complete at %2", _id, _townName];
    
    // Notification
    private _msg = format ["<t color='#00FF00' size='1.2'>✓ INVASION REPELLED</t><br/><t color='#FFFFFF'>%1 is now secure!</t>", _townName];
    [_msg, 0, 0.2, 6, 1] remoteExec ["BIS_fnc_dynamicText", 0];
    [format ["✓ INVASION REPELLED: %1 is secure!", _townName]] remoteExec ["systemChat", 0];
    
    // Cleanup markers
    private _markers = VEMF getOrDefault [_id + "_markers", []];
    { deleteMarker _x } forEach _markers;
};

private _cfg = (missionConfigFile >> "UMC_Master" >> "VEMFr");
private _min = getNumber (_cfg >> "waveSizeMin");
private _maxSize = getNumber (_cfg >> "waveSizeMax");
private _size = _min + floor random (_maxSize - _min + 1);

private _grp = ["EAST"] call (UMC get "createSafeGroup");

// Wave notification
private _waveNum = _cur + 1;
[format ["⚔️ Wave %1/%2 attacking %3!", _waveNum, _max, _townName]] remoteExec ["systemChat", 0];

for "_i" from 1 to _size do {
    private _p = _pos getPos [random 60, random 360];
    private _unitType = selectRandom ["O_G_Soldier_F", "O_G_Soldier_AR_F", "O_G_Soldier_M_F", "O_G_Soldier_GL_F"];
    private _u = _grp createUnit [_unitType, _p, [], 5, "NONE"];
    [_u] call (UMC get "applySkill");
    private _loot = ["Tier3"] call (UMC get "getLoot");
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 4];
    _u addEventHandler ["Killed", {
        params ["_unit","_killer"];
        [_killer, 15, 30] call (UMC get "reward");
    }];
};

// Set aggressive behavior
_grp setBehaviour "COMBAT";
_grp setCombatMode "RED";

// Waypoints toward center
private _wp = _grp addWaypoint [_pos, 30];
_wp setWaypointType "SAD";

// 10% chance for helicopter reinforcement
if (random 1 < 0.1) then {
    [_pos] call (VEMF get "spawnHeli");
    ["🚁 Enemy helicopter inbound!"] remoteExec ["systemChat", 0];
};

// Update wave counter
_entry set [3, _cur + 1];
_active = _active - [_entry];
_active pushBack _entry;
VEMF set ["activeInvasions", _active];

// Schedule next wave
if (_cur + 1 < _max) then {
    [_id] spawn {
        params ["_id"];
        sleep (60 + random 60);  // 60-120 seconds between waves
        [_id] call (VEMF get "spawnWave");
    };
};
