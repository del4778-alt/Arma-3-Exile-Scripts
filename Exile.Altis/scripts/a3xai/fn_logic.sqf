/*
    A3XAI Logic - Location-Based Spawn System
    
    This runs periodically to:
    1. Check if players are near any spawn locations
    2. Spawn AI at locations that have players nearby but no active AI
    3. Despawn AI at locations where players have left
    4. Optionally spawn dynamic/ambient AI
*/

// Bail if no players
if (count allPlayers == 0) exitWith {};

private _spawnRadius = A3XAI get "spawnRadius";
private _despawnRadius = A3XAI get "despawnRadius";
private _maxGroups = A3XAI get "maxActiveGroups";
private _despawnDelay = A3XAI get "despawnDelay";
private _locations = A3XAI get "locations";
private _activeGroups = A3XAI get "activeGroups";
private _currentTime = time;

// ===== CLEANUP DEAD/EMPTY GROUPS =====
private _validGroups = [];
{
    if (!isNull _x && {count units _x > 0}) then {
        _validGroups pushBack _x;
    } else {
        if (!isNull _x) then { deleteGroup _x };
    };
} forEach _activeGroups;
A3XAI set ["activeGroups", _validGroups];
_activeGroups = _validGroups;

// ===== PROCESS EACH SPAWN LOCATION =====
private _updatedLocations = [];

{
    _x params ["_pos", "_name", "_radius", "_tier", "_isActive", "_lastPlayerTime"];
    
    // Check if any player is near this location
    private _nearestPlayerDist = 99999;
    {
        private _d = _x distance2D _pos;
        if (_d < _nearestPlayerDist) then { _nearestPlayerDist = _d };
    } forEach allPlayers;
    
    private _playerNear = _nearestPlayerDist < _spawnRadius;
    private _playerFar = _nearestPlayerDist > _despawnRadius;
    
    // Find if we have an active group at this location
    private _locationGroup = grpNull;
    {
        private _grp = _x;
        private _grpPos = _grp getVariable ["A3XAI_spawnPos", [0,0,0]];
        if (_grpPos distance2D _pos < 100) exitWith {
            _locationGroup = _grp;
        };
    } forEach _activeGroups;
    
    private _hasActiveAI = !isNull _locationGroup && {count units _locationGroup > 0};
    
    // === SPAWN LOGIC ===
    if (_playerNear && !_hasActiveAI && {count _activeGroups < _maxGroups}) then {
        // Player is near, no AI here, and we haven't hit the cap - SPAWN
        diag_log format ["[UMC][A3XAI] Player near %1, spawning patrol (Tier %2)", _name, _tier];
        
        private _grp = [_pos, _tier] call (A3XAI get "spawnPatrol");
        
        if (!isNull _grp) then {
            _grp setVariable ["A3XAI_spawnPos", _pos, true];
            _grp setVariable ["A3XAI_spawnName", _name, true];
            _grp setVariable ["A3XAI_tier", _tier, true];
            
            _activeGroups pushBack _grp;
            _isActive = true;
            _lastPlayerTime = _currentTime;
        };
    };
    
    // === DESPAWN LOGIC ===
    if (_hasActiveAI) then {
        if (_playerNear) then {
            // Player still nearby, update timer
            _lastPlayerTime = _currentTime;
        } else {
            // No player nearby
            if (_playerFar && {(_currentTime - _lastPlayerTime) > _despawnDelay}) then {
                // Players have been gone long enough - despawn
                diag_log format ["[UMC][A3XAI] Despawning patrol at %1 (no players for %2s)", _name, _despawnDelay];
                
                { deleteVehicle _x } forEach units _locationGroup;
                deleteGroup _locationGroup;
                
                _activeGroups = _activeGroups - [_locationGroup];
                _isActive = false;
            };
        };
    };
    
    // Store updated location data
    _updatedLocations pushBack [_pos, _name, _radius, _tier, _isActive, _lastPlayerTime];
    
} forEach _locations;

A3XAI set ["locations", _updatedLocations];
A3XAI set ["activeGroups", _activeGroups];

// ===== DYNAMIC/AMBIENT SPAWNS =====
// Occasionally spawn a patrol near a random player (ambient threat)
if (count _activeGroups < _maxGroups) then {
    private _dynamicChance = A3XAI get "dynamicSpawnChance";
    
    if (random 1 < _dynamicChance) then {
        private _player = selectRandom allPlayers;
        private _playerPos = getPosATL _player;
        
        // Check we're not spawning too close to existing AI
        private _tooClose = false;
        {
            private _grpPos = _x getVariable ["A3XAI_spawnPos", [0,0,0]];
            if (_playerPos distance2D _grpPos < 500) exitWith { _tooClose = true };
        } forEach _activeGroups;
        
        if (!_tooClose) then {
            // Spawn at a random offset from player (400-800m away)
            private _spawnDist = 400 + random 400;
            private _spawnDir = random 360;
            private _spawnPos = _playerPos getPos [_spawnDist, _spawnDir];
            
            // Find safe position
            _spawnPos = _spawnPos findEmptyPosition [0, 50, "O_G_Soldier_F"];
            if (_spawnPos isEqualTo []) then { _spawnPos = _playerPos getPos [_spawnDist, _spawnDir] };
            
            diag_log format ["[UMC][A3XAI] Spawning dynamic patrol near player at %1", _spawnPos];
            
            private _grp = [_spawnPos, 1] call (A3XAI get "spawnPatrol");  // Tier 1 for dynamic
            
            if (!isNull _grp) then {
                _grp setVariable ["A3XAI_spawnPos", _spawnPos, true];
                _grp setVariable ["A3XAI_spawnName", "Dynamic Patrol", true];
                _grp setVariable ["A3XAI_tier", 1, true];
                _grp setVariable ["A3XAI_dynamic", true, true];
                
                // Give dynamic patrols a "hunt" waypoint toward the player
                private _wp = _grp addWaypoint [_playerPos, 100];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "AWARE";
                
                _activeGroups pushBack _grp;
            };
        };
    };
};

// ===== VEHICLE PATROL SPAWNS =====
if (count _activeGroups < _maxGroups) then {
    private _vehChance = A3XAI get "vehiclePatrolChance";
    
    if (random 1 < _vehChance) then {
        private _player = selectRandom allPlayers;
        private _playerPos = getPosATL _player;
        
        // Find a road near the player
        private _roads = _playerPos nearRoads 800;
        
        if (count _roads > 0) then {
            private _road = selectRandom _roads;
            private _roadPos = getPosATL _road;
            
            diag_log format ["[UMC][A3XAI] Spawning vehicle patrol near %1", _roadPos];
            [_roadPos] call (A3XAI get "spawnVehiclePatrol");
        };
    };
};

// ===== DESPAWN CHECK FOR ALL GROUPS =====
[] call (A3XAI get "despawn");

// Debug output
diag_log format ["[UMC][A3XAI] Active groups: %1/%2", count _activeGroups, _maxGroups];
