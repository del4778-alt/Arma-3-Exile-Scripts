params ["_pos","_count"];

private _grp = ["EAST"] call (UMC get "createSafeGroup");

// Ensure we're spawning at ATL (above terrain level)
private _centerPos = ATLToASL [_pos select 0, _pos select 1, 0];
_centerPos = ASLToATL _centerPos;

for "_i" from 1 to _count do {
    // Find safe position near center (not in water, not underground)
    private _spawnPos = _centerPos;
    private _attempts = 0;
    
    while {_attempts < 20} do {
        private _testPos = _centerPos getPos [5 + random 15, random 360];
        _testPos set [2, 0];  // Ground level
        
        // Check for valid position
        if (!surfaceIsWater _testPos) exitWith {
            _spawnPos = _testPos;
        };
        _attempts = _attempts + 1;
    };
    
    // Create unit at safe position
    private _u = _grp createUnit ["O_Soldier_F", _spawnPos, [], 0, "NONE"];
    
    if (isNull _u) then {
        diag_log format ["[UMC][DMS] ERROR: Failed to spawn AI at %1", _spawnPos];
    } else {
        // Move to exact ATL position
        _u setPosATL [_spawnPos select 0, _spawnPos select 1, 0.1];
        
        [_u] call (UMC get "applySkill");
        private _loot = ["Tier3"] call (UMC get "getLoot");
        _u addWeapon (_loot select 0);
        _u addMagazines [(_loot select 1), 4];
        
        // Set AI behavior
        _u setBehaviour "AWARE";
        _u setCombatMode "RED";
        
        _u addEventHandler ["Killed", {
            params ["_unit","_killer"];
            [_killer,15,25] call (UMC get "reward");
        }];
    };
};

// Set up patrol behavior
if (count units _grp > 0) then {
    _grp setBehaviour "AWARE";
    _grp setCombatMode "RED";
    _grp setSpeedMode "NORMAL";
    
    // Create patrol waypoints
    private _wp1 = _grp addWaypoint [_centerPos getPos [30, 0], 0];
    _wp1 setWaypointType "MOVE";
    
    private _wp2 = _grp addWaypoint [_centerPos getPos [30, 90], 0];
    _wp2 setWaypointType "MOVE";
    
    private _wp3 = _grp addWaypoint [_centerPos getPos [30, 180], 0];
    _wp3 setWaypointType "MOVE";
    
    private _wp4 = _grp addWaypoint [_centerPos getPos [30, 270], 0];
    _wp4 setWaypointType "CYCLE";
    
    diag_log format ["[UMC][DMS] Spawned %1 AI at %2", count units _grp, _centerPos];
};

_grp
