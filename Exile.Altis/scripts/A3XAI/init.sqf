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

// Load configuration from description.ext CfgA3XAI
A3XAI_configLoaded = false;

if (isClass (missionConfigFile >> "CfgA3XAI")) then {
    private _cfg = missionConfigFile >> "CfgA3XAI";

    // Load all configuration values
    if (isNumber (_cfg >> "A3XAI_enabled")) then {A3XAI_enabled = getNumber (_cfg >> "A3XAI_enabled") > 0};
    if (isNumber (_cfg >> "A3XAI_debugLevel")) then {A3XAI_debugLevel = getNumber (_cfg >> "A3XAI_debugLevel")};
    if (isNumber (_cfg >> "A3XAI_logLevel")) then {A3XAI_logLevel = getNumber (_cfg >> "A3XAI_logLevel")};
    if (isNumber (_cfg >> "A3XAI_gridSize")) then {A3XAI_gridSize = getNumber (_cfg >> "A3XAI_gridSize")};
    if (isNumber (_cfg >> "A3XAI_maxAIGlobal")) then {A3XAI_maxAIGlobal = getNumber (_cfg >> "A3XAI_maxAIGlobal")};
    if (isNumber (_cfg >> "A3XAI_minServerFPS")) then {A3XAI_minServerFPS = getNumber (_cfg >> "A3XAI_minServerFPS")};
    if (isNumber (_cfg >> "A3XAI_spawnDistanceMin")) then {A3XAI_spawnDistanceMin = getNumber (_cfg >> "A3XAI_spawnDistanceMin")};
    if (isNumber (_cfg >> "A3XAI_spawnDistanceMax")) then {A3XAI_spawnDistanceMax = getNumber (_cfg >> "A3XAI_spawnDistanceMax")};
    if (isNumber (_cfg >> "A3XAI_spawnCooldownTime")) then {A3XAI_spawnCooldownTime = getNumber (_cfg >> "A3XAI_spawnCooldownTime")};
    // v3.13: Town spawn limit settings
    if (isNumber (_cfg >> "A3XAI_maxGroupsPerTown")) then {A3XAI_maxGroupsPerTown = getNumber (_cfg >> "A3XAI_maxGroupsPerTown")};
    if (isNumber (_cfg >> "A3XAI_maxAIPerGroup")) then {A3XAI_maxAIPerGroup = getNumber (_cfg >> "A3XAI_maxAIPerGroup")};
    if (isNumber (_cfg >> "A3XAI_townRespawnCooldown")) then {A3XAI_townRespawnCooldown = getNumber (_cfg >> "A3XAI_townRespawnCooldown")};
    // v3.14: Town trigger system settings
    if (isNumber (_cfg >> "A3XAI_townTriggerEnabled")) then {A3XAI_townTriggerEnabled = getNumber (_cfg >> "A3XAI_townTriggerEnabled") > 0};
    if (isNumber (_cfg >> "A3XAI_townTriggerRadius")) then {A3XAI_townTriggerRadius = getNumber (_cfg >> "A3XAI_townTriggerRadius")};
    if (isNumber (_cfg >> "A3XAI_townDespawnRadius")) then {A3XAI_townDespawnRadius = getNumber (_cfg >> "A3XAI_townDespawnRadius")};
    if (isNumber (_cfg >> "A3XAI_townDespawnDelay")) then {A3XAI_townDespawnDelay = getNumber (_cfg >> "A3XAI_townDespawnDelay")};
    if (isNumber (_cfg >> "A3XAI_townSpawnChance")) then {A3XAI_townSpawnChance = getNumber (_cfg >> "A3XAI_townSpawnChance")};
    if (isNumber (_cfg >> "A3XAI_lootDespawnTime")) then {A3XAI_lootDespawnTime = getNumber (_cfg >> "A3XAI_lootDespawnTime")};
    if (isNumber (_cfg >> "A3XAI_enableMissionMarkers")) then {A3XAI_enableMissionMarkers = getNumber (_cfg >> "A3XAI_enableMissionMarkers") > 0};
    if (isNumber (_cfg >> "A3XAI_enableMissionNotifications")) then {A3XAI_enableMissionNotifications = getNumber (_cfg >> "A3XAI_enableMissionNotifications") > 0};
    if (isNumber (_cfg >> "A3XAI_missionCooldownEnabled")) then {A3XAI_missionCooldownEnabled = getNumber (_cfg >> "A3XAI_missionCooldownEnabled") > 0};
    if (isNumber (_cfg >> "A3XAI_missionCooldownTime")) then {A3XAI_missionCooldownTime = getNumber (_cfg >> "A3XAI_missionCooldownTime")};
    if (isNumber (_cfg >> "A3XAI_missionCleanupDelay")) then {A3XAI_missionCleanupDelay = getNumber (_cfg >> "A3XAI_missionCleanupDelay")};
    if (isNumber (_cfg >> "A3XAI_roadMinWidth")) then {A3XAI_roadMinWidth = getNumber (_cfg >> "A3XAI_roadMinWidth")};
    if (isNumber (_cfg >> "A3XAI_maxRecoveryAttempts")) then {A3XAI_maxRecoveryAttempts = getNumber (_cfg >> "A3XAI_maxRecoveryAttempts")};
    if (isNumber (_cfg >> "A3XAI_vehicleRespawnTime")) then {A3XAI_vehicleRespawnTime = getNumber (_cfg >> "A3XAI_vehicleRespawnTime")};
    if (isNumber (_cfg >> "A3XAI_EAD_enabled")) then {A3XAI_EAD_enabled = getNumber (_cfg >> "A3XAI_EAD_enabled") > 0};
    if (isNumber (_cfg >> "A3XAI_waterMinDepth")) then {A3XAI_waterMinDepth = getNumber (_cfg >> "A3XAI_waterMinDepth")};
    if (isNumber (_cfg >> "A3XAI_showHunterMarkers")) then {A3XAI_showHunterMarkers = getNumber (_cfg >> "A3XAI_showHunterMarkers") > 0};
    if (isNumber (_cfg >> "A3XAI_hunterTargetClosest")) then {A3XAI_hunterTargetClosest = getNumber (_cfg >> "A3XAI_hunterTargetClosest") > 0};
    if (isNumber (_cfg >> "A3XAI_hostagesJoinRescuer")) then {A3XAI_hostagesJoinRescuer = getNumber (_cfg >> "A3XAI_hostagesJoinRescuer") > 0};

    // v3.11: Arma 3 2.20+ optimizations
    if (isNumber (_cfg >> "A3XAI_useAIThinkOnlyLocal")) then {A3XAI_useAIThinkOnlyLocal = getNumber (_cfg >> "A3XAI_useAIThinkOnlyLocal") > 0};

    // Load blacklist zones
    if (isArray (_cfg >> "A3XAI_blacklistZones")) then {
        A3XAI_blacklistZones = getArray (_cfg >> "A3XAI_blacklistZones");
    };

    A3XAI_configLoaded = true;
    diag_log "[A3XAI] Configuration loaded from CfgA3XAI (description.ext)";
    diag_log format ["[A3XAI] - Debug Level: %1 | Log Level: %2", A3XAI_debugLevel, A3XAI_logLevel];
    diag_log format ["[A3XAI] - Grid Size: %1m | Max AI: %2", A3XAI_gridSize, A3XAI_maxAIGlobal];
} else {
    diag_log "[A3XAI] WARNING: CfgA3XAI not found in description.ext, using defaults";
};

// ============================================
// INITIALIZE GLOBAL VARIABLES
// ============================================

// Core system (use config values if loaded, otherwise defaults)
if (isNil "A3XAI_enabled") then {A3XAI_enabled = true};
A3XAI_version = "1.0.0 Elite Edition";
if (isNil "A3XAI_debugLevel") then {A3XAI_debugLevel = 4};
if (isNil "A3XAI_logLevel") then {A3XAI_logLevel = 4};
if (isNil "A3XAI_debugMode") then {A3XAI_debugMode = (A3XAI_logLevel > 2)};  // Auto-enable if log level high

// Performance settings
if (isNil "A3XAI_gridSize") then {A3XAI_gridSize = 1000};
if (isNil "A3XAI_spawnDistanceMin") then {A3XAI_spawnDistanceMin = 500};
if (isNil "A3XAI_spawnDistanceMax") then {A3XAI_spawnDistanceMax = 2000};
// ✅ v3.20: REDUCED AI - Max 50 AI total to prevent 144 group limit issues
// With 5 AI per mission, you can have ~10 active missions safely
// WARNING: Arma 3 has 144 GROUP limit per side! Keep total AI low.
if (isNil "A3XAI_maxAIGlobal") then {A3XAI_maxAIGlobal = 30};       // Base max AI for solo play
if (isNil "A3XAI_maxAIPerPlayer") then {A3XAI_maxAIPerPlayer = 5};  // Only +5 AI per additional player
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

// v3.13: Per-town spawn tracking
// Tracks active groups and cooldowns per town for proper spawn limiting
A3XAI_townSpawns = createHashMap;          // {townName -> [group1, group2, ...]}
A3XAI_townCooldowns = createHashMap;       // {townName -> lastSpawnTime}
// v3.14: Town trigger tracking
A3XAI_townDespawnTimers = createHashMap;   // {townName -> timeWhenPlayersLeft}

// Statistics
A3XAI_stats = createHashMapFromArray [
    ["startTime", time],
    ["totalSpawns", 0],
    ["totalKills", 0],
    ["missionsCompleted", 0],
    ["playersKilled", 0]
];

// ============================================
// ARMA 3 2.20+ PERFORMANCE OPTIMIZATIONS
// ============================================

// AIThinkOnlyLocal: Disables processing targeting data for remote AI units
// This improves client performance since they don't calculate all AI targeting
// Trade-off: knowsAbout, targets, etc. won't work on remote units (fine for dedicated server)
if (missionNamespace getVariable ["A3XAI_useAIThinkOnlyLocal", true]) then {
    setMissionOptions createHashMapFromArray [
        ["AIThinkOnlyLocal", true]
    ];
    diag_log "[A3XAI] Arma 3 2.20+: AIThinkOnlyLocal enabled (client performance optimization)";
};

// Log Arma version for debugging
private _armaVersion = productVersion;
diag_log format ["[A3XAI] Running on Arma 3 v%1.%2.%3", _armaVersion select 2, _armaVersion select 3, _armaVersion select 4];

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
if (isNil "A3XAI_spawnCooldownTime") then {A3XAI_spawnCooldownTime = 900};  // v3.13: Increased to 15 minutes
// ✅ v3.20: Reduced AI per group - max 5 total per mission/town
if (isNil "A3XAI_maxGroupsPerTown") then {A3XAI_maxGroupsPerTown = 1};      // Max 1 group per town
if (isNil "A3XAI_maxAIPerGroup") then {A3XAI_maxAIPerGroup = 3};            // 3 AI per group (max 5 per town)
if (isNil "A3XAI_townRespawnCooldown") then {A3XAI_townRespawnCooldown = 900}; // 15 min cooldown per town
// v3.14: Town trigger system (spawn only when players enter)
// Based on original A3XAI balance by TheGrayJacket/ispan55
if (isNil "A3XAI_townTriggerEnabled") then {A3XAI_townTriggerEnabled = true};  // Enable by default
if (isNil "A3XAI_townTriggerRadius") then {A3XAI_townTriggerRadius = 350};     // 350m trigger radius
if (isNil "A3XAI_townDespawnRadius") then {A3XAI_townDespawnRadius = 600};     // 600m despawn radius
if (isNil "A3XAI_townDespawnDelay") then {A3XAI_townDespawnDelay = 120};       // 2 min despawn delay (original A3XAI)
if (isNil "A3XAI_townSpawnChance") then {A3XAI_townSpawnChance = 60};          // 60% spawn chance (not guaranteed)
if (isNil "A3XAI_showHunterMarkers") then {A3XAI_showHunterMarkers = false};
if (isNil "A3XAI_hunterTargetClosest") then {A3XAI_hunterTargetClosest = true};
if (isNil "A3XAI_hostagesJoinRescuer") then {A3XAI_hostagesJoinRescuer = false};
if (isNil "A3XAI_waterMinDepth") then {A3XAI_waterMinDepth = 5};

// Distance thresholds (Exile Occupation style)
if (isNil "A3XAI_minDistanceToSpawnZones") then {A3XAI_minDistanceToSpawnZones = 750};
if (isNil "A3XAI_minDistanceToTraders") then {A3XAI_minDistanceToTraders = 750};
if (isNil "A3XAI_minDistanceToTerritory") then {A3XAI_minDistanceToTerritory = 350};
if (isNil "A3XAI_minDistanceToPlayer") then {A3XAI_minDistanceToPlayer = 250};
if (isNil "A3XAI_minDistanceToMarkers") then {A3XAI_minDistanceToMarkers = 350};

// Vehicle settings
if (isNil "A3XAI_roadMinWidth") then {A3XAI_roadMinWidth = 4};
if (isNil "A3XAI_roadBlacklist") then {A3XAI_roadBlacklist = ["TRAIL"]};
if (isNil "A3XAI_maxRecoveryAttempts") then {A3XAI_maxRecoveryAttempts = 3};
if (isNil "A3XAI_vehicleRespawnTime") then {A3XAI_vehicleRespawnTime = 900};

// AI refresh settings (Sarge-AI style)
if (isNil "A3XAI_ammoRefreshInterval") then {A3XAI_ammoRefreshInterval = 120};  // Seconds between ammo/fuel checks

// EAD integration
A3XAI_EAD_available = false;
if (isNil "A3XAI_EAD_enabled") then {A3XAI_EAD_enabled = true};

// HC support
A3XAI_HCConnected = false;
A3XAI_HCClients = [];

diag_log "[A3XAI] Global variables initialized";

// ============================================
// SETUP FACTION RELATIONS
// ============================================

// ✅ FIX: Set faction hostility for all AI systems
// EAST = A3XAI + DyCE (enemy AI)
// WEST = Zombies (Ravage)
// RESISTANCE = Players + Recruited AI + Patrol AI

// EAST (A3XAI) hostile to everyone
EAST setFriend [WEST, 0];          // A3XAI hostile to Zombies
EAST setFriend [RESISTANCE, 0];     // A3XAI hostile to players/recruits
EAST setFriend [INDEPENDENT, 0];    // A3XAI hostile to Independent
EAST setFriend [CIVILIAN, 0];       // A3XAI hostile to civilians

// WEST (Zombies) hostile to everyone
WEST setFriend [EAST, 0];           // Zombies hostile to A3XAI
WEST setFriend [RESISTANCE, 0];     // Zombies hostile to players/recruits
WEST setFriend [INDEPENDENT, 0];    // Zombies hostile to Independent
WEST setFriend [CIVILIAN, 0];       // Zombies hostile to civilians

// RESISTANCE (Players/Recruits) hostile to enemies
RESISTANCE setFriend [EAST, 0];     // Players hostile to A3XAI
RESISTANCE setFriend [WEST, 0];     // Players hostile to Zombies

// Other factions
INDEPENDENT setFriend [EAST, 0];
CIVILIAN setFriend [EAST, 0];

diag_log "[A3XAI] Faction relations: EAST (A3XAI) + WEST (Zombies) hostile to RESISTANCE (Players)";

// ============================================
// DETECT DEPENDENCIES
// ============================================

// Check for Exile
if (isClass (configFile >> "CfgPatches" >> "exile_server")) then {
    diag_log "[A3XAI] Exile server detected";
} else {
    diag_log "[A3XAI] WARNING: Exile server not detected - some features may not work";
};

// Check for Elite AI Driving (delayed check since EAD loads after A3XAI)
[] spawn {
    sleep 10; // Wait for EAD to fully load (execVM is async, needs extra time)

    if (!isNil "EAD_fnc_registerDriver") then {
        A3XAI_EAD_available = true;
        diag_log "[A3XAI] Elite AI Driving (EAD) detected - Enhanced vehicle AI enabled";
    } else {
        diag_log "[A3XAI] EAD not found - Using basic waypoint system for vehicles";
    };
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
[] execVM "scripts\A3XAI\scripts\monitor.sqf";

// Cleanup scheduler
[] execVM "scripts\A3XAI\scripts\cleanup.sqf";

// Master spawn loop
[] execVM "scripts\A3XAI\scripts\A3XAI_masterloop.sqf";

diag_log "[A3XAI] Monitoring systems started";

// ============================================
// v3.9: PERFORMANCE OPTIMIZATIONS (from DMS/VEMF)
// ============================================

// AI Freeze Manager - disables simulation for distant AI
if (missionNamespace getVariable ["A3XAI_freezingEnabled", true]) then {
    [] spawn A3XAI_fnc_freezeManager;
    diag_log "[A3XAI] AI freeze manager started (distant AI will be frozen)";
};

// Safe Cleanup Manager - player proximity checks
[] spawn A3XAI_fnc_cleanupManager;
diag_log "[A3XAI] Safe cleanup manager started";

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
