/*
    A3XAI CUSTOM SPAWN EXAMPLES
    ============================

    Place these in: @A3XAI/addons/A3XAI_config/a3xai_custom_defs.sqf

    IMPORTANT: Set loadCustomFile = 1; in config.cpp

    Syntax References:
    -----------------

    INFANTRY:
    [name, position, patrolRadius, aiCount, aiLevel, respawn, respawnTime] call A3XAI_createCustomInfantryQueue;

    VEHICLE:
    [name, position, vehicleClass, patrolRadius, [cargoCount,gunnerCount], aiLevel, respawn, respawnTime] call A3XAI_createCustomVehicleQueue;

    BLACKLIST:
    [name, position, radius] call A3XAI_createBlacklistAreaQueue;
*/

// ============================================
// TRADER SAFE ZONES (Blacklist Areas)
// ============================================

// Example: Main Trader City (Altis)
["TraderCity_MainSafe",[14599.2,16797.5,0],750] call A3XAI_createBlacklistAreaQueue;

// Example: Trader Outpost
["TraderOutpost_North",[23334.9,24188.4,0],500] call A3XAI_createBlacklistAreaQueue;

// Example: Spawn Zone Protection
["SpawnArea_South",[2998.31,18175.3,0],300] call A3XAI_createBlacklistAreaQueue;


// ============================================
// LOW DIFFICULTY AREAS (Beginner Zones)
// ============================================

// Small Coastal Village - Easy
["CoastalVillage_1",[15234.5,18765.2,0.00],75,2,0,true,600] call A3XAI_createCustomInfantryQueue;
// 2 AI, Level 0 (low), 75m patrol, respawns every 10min

// Abandoned Farm - Easy
["Farm_Northwest",[8456.7,21345.1,0.00],50,3,0,true,480] call A3XAI_createCustomInfantryQueue;
// 3 AI, Level 0, 50m patrol, respawns every 8min

// Small Checkpoint - Medium
["Checkpoint_Highway1",[12876.3,14234.8,0.00],60,3,1,true,720] call A3XAI_createCustomInfantryQueue;
// 3 AI, Level 1 (medium), 60m patrol, respawns every 12min


// ============================================
// MEDIUM DIFFICULTY AREAS
// ============================================

// Factory Complex - Medium-High
["Factory_Industrial",[18765.2,9234.5,0.00],120,5,2,true,900] call A3XAI_createCustomInfantryQueue;
// 5 AI, Level 2 (high), 120m patrol, respawns every 15min

// Police Station - Medium
["PoliceStation_Central",[14532.1,16987.4,0.00],80,4,2,true,600] call A3XAI_createCustomInfantryQueue;
// 4 AI, Level 2, 80m patrol, respawns every 10min

// Fuel Depot - Medium
["FuelDepot_East",[20345.6,15678.9,0.00],100,4,2,true,720] call A3XAI_createCustomInfantryQueue;
// 4 AI, Level 2, 100m patrol, respawns every 12min


// ============================================
// HIGH DIFFICULTY AREAS (Expert/PvP Zones)
// ============================================

// Military Airbase - Very High
["Airbase_Military",[3745.21,13284.7,0.00],250,8,3,true,1200] call A3XAI_createCustomInfantryQueue;
// 8 AI, Level 3 (expert), 250m patrol, respawns every 20min

// Research Facility - Very High
["ResearchLab_Alpha",[10234.8,7865.3,0.00],150,6,3,true,900] call A3XAI_createCustomInfantryQueue;
// 6 AI, Level 3, 150m patrol, respawns every 15min

// Harbor Complex - High
["Harbor_MainPort",[21876.4,19234.1,0.00],200,7,3,true,1200] call A3XAI_createCustomInfantryQueue;
// 7 AI, Level 3, 200m patrol, respawns every 20min


// ============================================
// SPECIAL MISSION AREAS (High Value Targets)
// ============================================

// Drug Lab (High Loot)
["DrugLab_Hidden",[6543.2,12987.6,0.00],100,6,3,true,1800] call A3XAI_createCustomInfantryQueue;
// 6 AI, Level 3, 100m patrol, respawns every 30min

// Weapons Cache
["WeaponsCache_Mountain",[17234.5,8976.2,0.00],80,5,3,false,0] call A3XAI_createCustomInfantryQueue;
// 5 AI, Level 3, 80m patrol, NO RESPAWN (one-time loot)

// Bandit Stronghold
["BanditCamp_Forest",[9876.5,18234.7,0.00],120,8,3,true,2400] call A3XAI_createCustomInfantryQueue;
// 8 AI, Level 3, 120m patrol, respawns every 40min


// ============================================
// VEHICLE PATROLS - LAND
// ============================================

// Light Patrol - Offroad Armed
["PatrolVeh_Highway1",[15678.9,14234.5,0.00],"Exile_Car_Offroad_Armed_Guerilla01",300,[2,1],1,true,900] call A3XAI_createCustomVehicleQueue;
// Offroad Armed, 300m patrol, 2 cargo + 1 gunner, Level 1, respawns every 15min

// Medium Patrol - MRAP
["PatrolVeh_City",[12345.6,17890.2,0.00],"I_MRAP_03_gmg_F",400,[2,1],2,true,1200] call A3XAI_createCustomVehicleQueue;
// Strider GMG, 400m patrol, 2 cargo + 1 gunner, Level 2, respawns every 20min

// Heavy Patrol - APC (Rare)
["PatrolVeh_Military",[8765.4,21345.8,0.00],"I_APC_Wheeled_03_cannon_F",500,[3,2],3,true,1800] call A3XAI_createCustomVehicleQueue;
// Gorgon, 500m patrol, 3 cargo + 2 gunners, Level 3, respawns every 30min


// ============================================
// VEHICLE PATROLS - AIR
// ============================================

// Scout Helicopter - Rare
["PatrolAir_Coastal",[16789.3,12456.7,0.00],"B_Heli_Light_01_armed_F",2000,[1,1],2,true,2400] call A3XAI_createCustomVehicleQueue;
// Pawnee, 2000m patrol, 1 cargo + 1 gunner, Level 2, respawns every 40min

// Transport Helicopter - Very Rare
["PatrolAir_Central",[13456.8,15678.2,0.00],"B_Heli_Transport_01_F",3000,[4,2],3,true,3600] call A3XAI_createCustomVehicleQueue;
// Ghost Hawk, 3000m patrol, 4 cargo + 2 gunners, Level 3, respawns every 60min


// ============================================
// ROAMING PATROLS (Large Areas)
// ============================================

// Forest Ranger Patrol
["RoamPatrol_Forest",[10000.0,10000.0,0.00],500,4,1,true,1200] call A3XAI_createCustomInfantryQueue;
// 4 AI, Level 1, 500m roaming patrol, respawns every 20min

// Desert Nomads
["RoamPatrol_Desert",[18000.0,8000.0,0.00],800,3,2,true,1500] call A3XAI_createCustomInfantryQueue;
// 3 AI, Level 2, 800m roaming patrol, respawns every 25min


// ============================================
// EVENT-BASED SPAWNS (Temporary)
// ============================================

// Convoy Ambush (No Respawn)
["Event_ConvoyAmbush",[14567.8,16234.5,0.00],150,6,3,false,0] call A3XAI_createCustomInfantryQueue;
// 6 AI, Level 3, 150m patrol, NO RESPAWN (admin triggered event)

// Supply Drop Defense (No Respawn)
["Event_SupplyDrop",[11234.6,13567.8,0.00],100,8,3,false,0] call A3XAI_createCustomInfantryQueue;
// 8 AI, Level 3, 100m patrol, NO RESPAWN


// ============================================
// DYNAMIC DIFFICULTY ZONES
// ============================================

// Progressive Difficulty - Outer Zone (Easy)
["Zone_Outer_North",[5000.0,5000.0,0.00],200,3,1,true,600] call A3XAI_createCustomInfantryQueue;

// Progressive Difficulty - Mid Zone (Medium)
["Zone_Mid_North",[5000.0,5500.0,0.00],200,5,2,true,900] call A3XAI_createCustomInfantryQueue;

// Progressive Difficulty - Inner Zone (Hard)
["Zone_Inner_North",[5000.0,6000.0,0.00],200,7,3,true,1200] call A3XAI_createCustomInfantryQueue;


// ============================================
// NOTES & TIPS
// ============================================

/*
    AI LEVELS:
    ----------
    Level 0 (Low):    Villages, beginner areas
    Level 1 (Medium): Cities, checkpoints
    Level 2 (High):   Factories, police stations, fuel depots
    Level 3 (Expert): Military bases, high-value targets

    RESPAWN TIMES:
    --------------
    300-600s   (5-10min):  Common patrols
    600-900s   (10-15min): Standard POIs
    900-1800s  (15-30min): High-value areas
    1800-3600s (30-60min): Rare/special spawns

    PATROL RADIUS:
    --------------
    50-100m:   Buildings, small compounds
    100-200m:  Medium facilities, towns
    200-400m:  Large bases, industrial areas
    400-1000m: Roaming patrols, vehicle routes
    1000m+:    Air patrols, wide area coverage

    VEHICLE SELECTION:
    ------------------
    Light:  Offroad Armed, Hunter, Prowler
    Medium: MRAP (Strider, Hunter, Ifrit)
    Heavy:  APC (Gorgon, Marshall, Kamysh)
    Air:    Pawnee, Ghost Hawk, Huron

    BLACKLIST RADIUS:
    -----------------
    200-400m:  Small trader outposts
    400-700m:  Medium trader zones
    700-1000m: Main trader cities
    300-500m:  Spawn protection zones

    PERFORMANCE TIPS:
    -----------------
    • Limit total custom spawns to 30-50 for best performance
    • Use larger respawn timers for vehicle patrols
    • Blacklist trader zones to prevent spawn overlap
    • Set higher-tier zones to no-respawn for one-time loot
    • Balance AI count vs patrol radius (more AI = smaller radius)
    • Use ExileSpawnZone markers for your patrol system
    • Let A3XAI handle cities/towns, use custom spawns for special locations
*/
