/*
    ================================================================
    A3XAI ELITE EDITION - EXTERNAL CONFIGURATION
    ================================================================

    Place this file in: @A3XAI_Elite/A3XAI_Elite_config.sqf

    The init.sqf will automatically load this file on server start.

    ================================================================
*/

// ================================================================
// CORE SYSTEM SETTINGS
// ================================================================

A3XAI_enabled = true;                       // Enable/disable entire system
A3XAI_debugMode = false;                     // Enable debug logging (performance impact)
A3XAI_logLevel = 2;                          // 0=none, 1=error, 2=warn, 3=info, 4=debug

// ================================================================
// PERFORMANCE SETTINGS
// ================================================================

A3XAI_gridSize = 1000;                       // Spatial grid cell size (meters)
A3XAI_maxAIGlobal = 150;                     // Maximum AI units globally
A3XAI_minServerFPS = 20;                     // Minimum FPS before spawning stops

A3XAI_spawnDistanceMin = 500;                // Min spawn distance from players
A3XAI_spawnDistanceMax = 2000;               // Max spawn distance from players

// ================================================================
// SPAWN SETTINGS
// ================================================================

A3XAI_spawnCooldownTime = 300;               // Location cooldown (seconds)

// Spawn weights (0.0-1.0, higher = more frequent)
A3XAI_infantrySpawnWeight = 0.60;            // 60% chance
A3XAI_vehicleSpawnWeight = 0.25;             // 25% chance
A3XAI_airSpawnWeight = 0.10;                 // 10% chance
A3XAI_seaSpawnWeight = 0.05;                 // 5% chance

// ================================================================
// AI DIFFICULTY SETTINGS
// ================================================================

// Skill levels: [aimAccuracy, aimSpeed, spotDistance, spotTime]
A3XAI_skillLevels = createHashMapFromArray [
    ["easy",    [0.25, 0.35, 0.20, 0.30]],
    ["medium",  [0.45, 0.55, 0.45, 0.50]],
    ["hard",    [0.65, 0.75, 0.65, 0.70]],
    ["extreme", [0.85, 0.95, 0.85, 0.90]]
];

// ================================================================
// LOOT SETTINGS
// ================================================================

A3XAI_lootDespawnTime = 1800;                // Loot despawn time (seconds)
A3XAI_removeLaunchers = false;               // Remove launchers from dead AI
A3XAI_removeNVG = false;                     // Remove NVGs from dead AI

// ================================================================
// REWARDS
// ================================================================

A3XAI_poptabsReward = true;                  // Award poptabs for kills

// Respect rewards (base values, distance multiplier up to 2x)
A3XAI_respectRewards = createHashMapFromArray [
    ["easy", 10],
    ["medium", 20],
    ["hard", 35],
    ["extreme", 50]
];

// ================================================================
// MISSION SYSTEM
// ================================================================

A3XAI_enableMissionMarkers = true;           // Show mission markers on map
A3XAI_enableMissionNotifications = true;     // Send mission notifications
A3XAI_showHunterMarkers = false;             // Show hunter squad markers

A3XAI_missionCooldownEnabled = true;         // Enable mission location cooldown
A3XAI_missionCooldownTime = 1800;            // Mission cooldown (seconds)
A3XAI_missionCleanupDelay = 300;             // Cleanup delay after completion

// Mission type weights (0.0-1.0)
A3XAI_missionWeights = createHashMapFromArray [
    ["convoy", 0.25],
    ["crash", 0.30],
    ["camp", 0.20],
    ["hunter", 0.15],
    ["rescue", 0.10]
];

// ================================================================
// VEHICLE SETTINGS
// ================================================================

A3XAI_roadMinWidth = 4;                      // Minimum road width (meters)
A3XAI_roadBlacklist = ["TRAIL"];             // Road types to exclude

A3XAI_maxRecoveryAttempts = 3;               // Max vehicle unstuck attempts
A3XAI_vehicleRespawnTime = 900;              // Vehicle respawn time (seconds)

// ================================================================
// EAD (Elite AI Driving) INTEGRATION
// ================================================================

A3XAI_EAD_enabled = true;                    // Enable EAD if available
// EAD is auto-detected, this just enables/disables integration

// ================================================================
// HEADLESS CLIENT
// ================================================================

// HC is auto-detected and auto-configured
// No manual settings required

// ================================================================
// SPECIAL FEATURES
// ================================================================

A3XAI_zombieResurrection = false;            // Convert dead AI to zombies (requires RyanZombies)
A3XAI_hostagesJoinRescuer = false;           // Rescued hostages join player group
A3XAI_hunterTargetClosest = true;            // Hunter squads target closest player

// Kill streak tracking
A3XAI_killStreaks = createHashMap;           // Auto-initialized

// ================================================================
// WATER SPAWN SETTINGS
// ================================================================

A3XAI_waterMinDepth = 5;                     // Minimum water depth for boat spawns

// ================================================================
// BLACKLIST ZONES
// ================================================================

// Format: [name, [x,y,z], radius]
A3XAI_blacklistZones = [
    // Example trader zones (edit coordinates for your map):
    // ["TraderCity", [14599, 16797, 0], 750],
    // ["TraderNorth", [23334, 24188, 0], 500],
    // ["SpawnSouth", [2998, 18175, 0], 300]
];

// Auto-blacklist Exile trader zones (requires Exile mission config access)
A3XAI_autoBlacklistTraders = false;

// ================================================================
// MAP-SPECIFIC OVERRIDES
// ================================================================

// Automatically adjust settings based on world name
switch (toLower worldName) do {
    case "altis": {
        A3XAI_maxAIGlobal = 150;
        A3XAI_spawnDistanceMax = 2000;
    };

    case "tanoa": {
        A3XAI_maxAIGlobal = 150;
        A3XAI_roadBlacklist = ["TRAIL", "TRACK"];  // Tanoa has many trails
    };

    case "malden": {
        A3XAI_maxAIGlobal = 100;
        A3XAI_spawnDistanceMax = 1500;
    };

    case "stratis": {
        A3XAI_maxAIGlobal = 80;
        A3XAI_spawnDistanceMax = 1000;
    };

    case "chernarus": {
        A3XAI_maxAIGlobal = 120;
        A3XAI_spawnDistanceMax = 1800;
    };

    case "esseker": {
        A3XAI_maxAIGlobal = 120;
        A3XAI_spawnDistanceMax = 1500;
    };

    default {
        // Use defaults for unknown maps
    };
};

// ================================================================
// DEVELOPER OPTIONS
// ================================================================

// These should stay false in production
A3XAI_disableCleanup = false;                // Disable cleanup scheduler
A3XAI_disableMonitoring = false;             // Disable performance monitor
A3XAI_disableSpawning = false;               // Disable all spawning (for testing)

// ================================================================
// END OF CONFIGURATION
// ================================================================

diag_log "[A3XAI] External configuration loaded successfully";

true
