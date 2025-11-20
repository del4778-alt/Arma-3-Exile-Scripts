/*
    A3XAI Elite Edition - Main Initialization
    Auto-executed on server start via CfgPatches

    This script initializes the A3XAI Elite system:
    - Loads configuration
    - Initializes global variables
    - Compiles functions
    - Sets up monitoring systems
    - Starts spawn loops
*/

if (!isServer) exitWith {};

private _startTime = diag_tickTime;
diag_log "==============================================";
diag_log "  A3XAI ELITE EDITION - Initialization Start";
diag_log "==============================================";

// ============================================
// LOAD EXTERNAL CONFIGURATION
// ============================================

// Check for external config file
A3XAI_configLoaded = false;

if (isClass (configFile >> "A3XAI_Elite_Config")) then {
    call compile preprocessFileLineNumbers "A3XAI_Elite_config.sqf";
    A3XAI_configLoaded = true;
    diag_log "[A3XAI] External configuration loaded";
} else {
    diag_log "[A3XAI] WARNING: No external configuration found, using defaults";
};

// ============================================
// INITIALIZE GLOBAL VARIABLES
// ============================================

// Core system
A3XAI_enabled = true;
A3XAI_version = "1.0.0 Elite Edition";
A3XAI_debugMode = true;  // CHANGED: Enable debug to see initialization
A3XAI_logLevel = 4;      // CHANGED: Max debug level (0=none, 1=error, 2=warn, 3=info, 4=debug)

// Performance settings
if (isNil "A3XAI_gridSize") then {A3XAI_gridSize = 1000};
if (isNil "A3XAI_spawnDistanceMin") then {A3XAI_spawnDistanceMin = 500};
if (isNil "A3XAI_spawnDistanceMax") then {A3XAI_spawnDistanceMax = 2000};
if (isNil "A3XAI_maxAIGlobal") then {A3XAI_maxAIGlobal = 150};
if (isNil "A3XAI_minServerFPS") then {A3XAI_minServerFPS = 20};

// Spatial grid for O(1) spawn lookups
A3XAI_spawnGrid = createHashMap;
A3XAI_activeCells = createHashMap;

// Tracking arrays
A3XAI_activeGroups = [];
A3XAI_activeVehicles = [];
A3XAI_activeMissions = [];
A3XAI_spawnCooldowns = createHashMap;
A3XAI_missionCooldowns = createHashMap;

// Statistics
A3XAI_stats = createHashMapFromArray [
    ["startTime", time],
    ["totalSpawns", 0],
    ["totalKills", 0],
    ["missionsCompleted", 0],
    ["playersKilled", 0]
];

// Loot system
A3XAI_useFallbackLoot = false;
if (isNil "A3XAI_lootDespawnTime") then {A3XAI_lootDespawnTime = 1800};

// Mission system
if (isNil "A3XAI_enableMissionMarkers") then {A3XAI_enableMissionMarkers = true};
if (isNil "A3XAI_enableMissionNotifications") then {A3XAI_enableMissionNotifications = true};
if (isNil "A3XAI_missionCooldownEnabled") then {A3XAI_missionCooldownEnabled = true};
if (isNil "A3XAI_missionCooldownTime") then {A3XAI_missionCooldownTime = 1800};
if (isNil "A3XAI_missionCleanupDelay") then {A3XAI_missionCleanupDelay = 300};

// Spawn settings
if (isNil "A3XAI_spawnCooldownTime") then {A3XAI_spawnCooldownTime = 300};
if (isNil "A3XAI_showHunterMarkers") then {A3XAI_showHunterMarkers = false};
if (isNil "A3XAI_hunterTargetClosest") then {A3XAI_hunterTargetClosest = true};
if (isNil "A3XAI_hostagesJoinRescuer") then {A3XAI_hostagesJoinRescuer = false};
if (isNil "A3XAI_waterMinDepth") then {A3XAI_waterMinDepth = 5};

// Vehicle settings
if (isNil "A3XAI_roadMinWidth") then {A3XAI_roadMinWidth = 4};
if (isNil "A3XAI_roadBlacklist") then {A3XAI_roadBlacklist = ["TRAIL"]};
if (isNil "A3XAI_maxRecoveryAttempts") then {A3XAI_maxRecoveryAttempts = 3};
if (isNil "A3XAI_vehicleRespawnTime") then {A3XAI_vehicleRespawnTime = 900};

// EAD integration
A3XAI_EAD_available = false;
if (isNil "A3XAI_EAD_enabled") then {A3XAI_EAD_enabled = true};

// HC support
A3XAI_HCConnected = false;
A3XAI_HCClients = [];

diag_log "[A3XAI] Global variables initialized";

// ============================================
// DETECT DEPENDENCIES
// ============================================

// Check for Elite AI Driving
if (!isNil "EAD_fnc_initVehicle") then {
    A3XAI_EAD_available = true;
    diag_log "[A3XAI] Elite AI Driving (EAD) detected - Enhanced vehicle AI enabled";
} else {
    diag_log "[A3XAI] EAD not found - Using basic waypoint system for vehicles";
};

// Check for Exile
if (isClass (configFile >> "CfgPatches" >> "exile_server")) then {
    diag_log "[A3XAI] Exile server detected";
} else {
    diag_log "[A3XAI] WARNING: Exile server not detected - some features may not work";
};

// ============================================
// VALIDATE CONFIGURATION
// ============================================

// Validate loot tables
call A3XAI_fnc_validateLootTables;

diag_log "[A3XAI] Configuration validated";

// ============================================
// INITIALIZE BLACKLIST ZONES
// ============================================

if (isNil "A3XAI_blacklistZones") then {
    A3XAI_blacklistZones = [];
};

// Add default trader zones if configured
if (!isNil "A3XAI_autoBlacklistTraders" && {A3XAI_autoBlacklistTraders}) then {
    // Auto-detect Exile traders and blacklist them
    // This would require reading Exile mission config
    diag_log "[A3XAI] Auto-blacklisting trader zones...";
};

diag_log format ["[A3XAI] %1 blacklist zones configured", count A3XAI_blacklistZones];

// ============================================
// START MONITORING SYSTEMS
// ============================================

// Performance monitor
[] execVM "\A3XAI_Elite\scripts\monitor.sqf";

// Cleanup scheduler
[] execVM "\A3XAI_Elite\scripts\cleanup.sqf";

// Master spawn loop
[] execVM "\A3XAI_Elite\scripts\A3XAI_masterloop.sqf";

diag_log "[A3XAI] Monitoring systems started";

// ============================================
// HC DETECTION
// ============================================

if (hasInterface) exitWith {};

[] spawn {
    waitUntil {!isNil "HC_SLOT" || time > 60};

    if (!isNil "HC_SLOT") then {
        call A3XAI_fnc_initHC;
        diag_log "[A3XAI] Headless Client mode activated";
    };
};

// ============================================
// INITIALIZATION COMPLETE
// ============================================

private _initTime = (diag_tickTime - _startTime) * 1000;

diag_log "==============================================";
diag_log format ["  A3XAI ELITE EDITION v%1", A3XAI_version];
diag_log format ["  Initialized in %1ms", _initTime toFixed 0];
diag_log format ["  Max AI: %1 | Grid Size: %2m", A3XAI_maxAIGlobal, A3XAI_gridSize];
diag_log format ["  EAD Integration: %1", if (A3XAI_EAD_available && A3XAI_EAD_enabled) then {"ENABLED"} else {"DISABLED"}];
diag_log "==============================================";

A3XAI_initialized = true;
publicVariable "A3XAI_initialized";

true
