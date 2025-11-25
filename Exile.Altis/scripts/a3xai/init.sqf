/*
    A3XAI (UMC Version) - Proper Location-Based AI Spawning
    
    This version properly mimics real A3XAI behavior:
    - Reads map locations (towns, cities, military bases, etc.)
    - Only spawns AI when players are NEAR those locations
    - Limits total active spawns
    - Despawns when players leave the area
*/

if (!isServer) exitWith {};

if (isNil "UMC") exitWith {
    diag_log "[UMC][A3XAI] ERROR: UMC not initialized, aborting A3XAI init.";
};

diag_log "[UMC][A3XAI] Initializing...";

// Namespace
if (isNil "A3XAI") then { A3XAI = createHashMap; };

// ===== CONFIGURATION =====
private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");

A3XAI set ["minAI",           getNumber (_cfg >> "minAI")];
A3XAI set ["maxAI",           getNumber (_cfg >> "maxAI")];
A3XAI set ["spawnRadius",     getNumber (_cfg >> "spawnRadius")];      // Player must be this close to trigger spawn
A3XAI set ["despawnRadius",   getNumber (_cfg >> "despawnRadius")];    // Despawn if all players beyond this
A3XAI set ["maxActiveGroups", 15];                                      // Maximum simultaneous AI groups
A3XAI set ["dynamicSpawnChance", 0.15];                                 // Chance for dynamic (non-location) spawn
A3XAI set ["vehiclePatrolChance", 0.08];                                // Chance to spawn vehicle patrol
A3XAI set ["despawnDelay", 120];                                        // Seconds with no players before despawn

// Load functions
A3XAI set ["spawnUnit",          compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnUnit.sqf"];
A3XAI set ["spawnGroup",         compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnGroup.sqf"];
A3XAI set ["spawnPatrol",        compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnPatrol.sqf"];
A3XAI set ["spawnVehiclePatrol", compile preprocessFileLineNumbers "scripts\a3xai\fn_spawnVehiclePatrol.sqf"];
A3XAI set ["registerGroup",      compile preprocessFileLineNumbers "scripts\a3xai\fn_registerGroup.sqf"];
A3XAI set ["despawn",            compile preprocessFileLineNumbers "scripts\a3xai\fn_despawn.sqf"];
A3XAI set ["logic",              compile preprocessFileLineNumbers "scripts\a3xai\fn_logic.sqf"];

// Active groups tracking
A3XAI set ["activeGroups", []];

// ===== BUILD LOCATION DATABASE =====
// Find all named locations on the map (universal map support)
private _mapCenter = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");

// Location types and their difficulty tiers
private _locationTypes = [
    // Tier 0 - Easy (small settlements)
    ["NameLocal", 0],
    
    // Tier 1 - Medium (villages)  
    ["NameVillage", 1],
    
    // Tier 2 - Hard (cities)
    ["NameCity", 2],
    ["NameCityCapital", 2],
    
    // Tier 3 - Military (highest difficulty)
    ["NameMarine", 3],
    ["Airport", 3],
    ["Strategic", 3]
];

private _spawnLocations = [];

{
    _x params ["_type", "_tier"];
    private _locs = nearestLocations [_mapCenter, [_type], _mapSize];
    
    {
        private _pos = locationPosition _x;
        private _name = text _x;
        private _size = size _x;
        private _radius = ((_size select 0) max (_size select 1)) max 150; // Minimum 150m radius
        
        _spawnLocations pushBack [
            _pos,           // Position
            _name,          // Name
            _radius,        // Patrol radius
            _tier,          // Difficulty tier
            false,          // Currently active?
            -9999           // Last player presence time
        ];
    } forEach _locs;
} forEach _locationTypes;

A3XAI set ["locations", _spawnLocations];

diag_log format ["[UMC][A3XAI] Found %1 spawn locations on %2", count _spawnLocations, worldName];

// ===== SCHEDULER REGISTRATION =====
["registerQueue", ["A3XAI", 30]] call (UMC get "scheduler");  // Check every 30 seconds
["setFunction",  ["A3XAI", { [] call (A3XAI get "logic") }]] call (UMC get "scheduler");

diag_log "[UMC][A3XAI] Ready.";
