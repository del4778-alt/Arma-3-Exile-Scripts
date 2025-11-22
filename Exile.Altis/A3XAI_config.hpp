/*
    A3XAI Elite Edition - Mission Folder Configuration

    This file defines all A3XAI functions for mission-based loading.
    Include this in description.ext
*/

class CfgFunctions {
    class A3XAI {
        tag = "A3XAI";

        class Core {
            file = "scripts\A3XAI\functions\core";
            class safeCall {};
            class validateLootTables {};
            class initFallbackLoot {};
            class isValidSpawnPos {};
            class log {};
            class getCellID {};
            class getMapCenter {};
            class getRandomPos {};
            class inBlacklist {};
            class findSafePos {};
        };

        class Spawn {
            file = "scripts\A3XAI\functions\spawn";
            class canSpawn {};
            class registerSpawn {};
            class removeSpawn {};
            class spawnInfantry {};
            class spawnVehicle {};
            class spawnHeli {};
            class spawnBoat {};
        };

        class AI {
            file = "scripts\A3XAI\functions\ai";
            class initAI {};
            class setAISkill {};
            class equipAI {};
            class addAIEventHandlers {};
            class setGroupBehavior {};
            class refreshAI {};          // Sarge-AI style ammo/fuel refresh loop
        };

        class Vehicle {
            file = "scripts\A3XAI\functions\vehicle";
            class initVehicle {};
            class addVehicleEventHandlers {};
            class isVehicleStuck {};
            class unstuckVehicle {};
            class getRoadQuality {};
            class findValidRoad {};
            class generateRoute {};
            class getVehicleTurrets {};  // Sarge-AI style recursive turret exploration
        };

        class Mission {
            file = "scripts\A3XAI\functions\missions";
            class selectMission {};
            class spawnMission {};
            class spawnLoot {};
            class checkMissionComplete {};
            class completeMission {};
        };

        class MissionTypes {
            file = "scripts\A3XAI\functions\missions\types";
            class convoy {};
            class crash {};
            class camp {};
            class hunter {};
            class cache {};          // Weapons cache mission (replaces rescue)
            class outpost {};        // Military outpost mission
            class supplyDrop {};     // Supply drop mission
            class invasion {};       // Town invasion mission (VEMF-style)
            class highwayPatrol {};  // Highway patrol between spawn zones
            class DyCE_spawn {};     // DyCE unified convoy spawner
        };

        class HC {
            file = "scripts\A3XAI\functions\hc";
            class initHC {};
            class offloadGroup {};
            class balanceHC {};
        };

        class Utility {
            file = "scripts\A3XAI\functions\utility";
            class setTimeout {};
            class generateDefensePositions {};
        };
    };
};

// A3XAI Configuration Settings
class CfgA3XAI {
    // ================================================================
    // CORE SYSTEM SETTINGS
    // ================================================================

    A3XAI_enabled = 1;                          // Enable/disable entire system (1=on, 0=off)
    A3XAI_debugLevel = 4;                       // Debug level: 0=off, 1=error, 2=warn, 3=info, 4=debug
    A3XAI_logLevel = 4;                         // Log level (same as debug)

    // ================================================================
    // PERFORMANCE SETTINGS
    // ================================================================

    A3XAI_gridSize = 1000;                      // Spatial grid cell size (meters) - NEW FEATURE
    A3XAI_maxAIGlobal = 150;                    // Maximum AI units globally
    A3XAI_minServerFPS = 20;                    // Minimum FPS before spawning stops

    A3XAI_spawnDistanceMin = 500;               // Min spawn distance from players (meters)
    A3XAI_spawnDistanceMax = 2000;              // Max spawn distance from players (meters)

    // ================================================================
    // SPAWN COOLDOWN SETTINGS
    // ================================================================

    A3XAI_spawnCooldownTime = 300;              // Location cooldown time (seconds)

    // ================================================================
    // AI DIFFICULTY SETTINGS
    // ================================================================

    // Default difficulty level for random spawns
    A3XAI_defaultDifficulty = "medium";         // "easy", "medium", "hard", "extreme"

    // ================================================================
    // LOOT SETTINGS
    // ================================================================

    A3XAI_lootDespawnTime = 1800;               // Loot despawn time (seconds)
    A3XAI_removeLaunchers = 0;                  // Remove launchers from dead AI (1=yes, 0=no)
    A3XAI_removeNVG = 0;                        // Remove NVGs from dead AI (1=yes, 0=no)

    // ================================================================
    // REWARD SETTINGS
    // ================================================================

    A3XAI_poptabsReward = 1;                    // Award poptabs for kills (1=yes, 0=no)

    // ================================================================
    // MISSION SYSTEM SETTINGS
    // ================================================================

    A3XAI_enableMissionMarkers = 1;             // Show mission markers on map (1=yes, 0=no)
    A3XAI_enableMissionNotifications = 1;       // Send mission notifications (1=yes, 0=no)
    A3XAI_showHunterMarkers = 0;                // Show hunter squad markers (1=yes, 0=no)

    A3XAI_missionCooldownEnabled = 1;           // Enable mission location cooldown (1=yes, 0=no)
    A3XAI_missionCooldownTime = 1800;           // Mission cooldown time (seconds)
    A3XAI_missionCleanupDelay = 300;            // Cleanup delay after mission completion (seconds)

    // ================================================================
    // VEHICLE SETTINGS
    // ================================================================

    A3XAI_roadMinWidth = 4;                     // Minimum road width (meters)
    A3XAI_maxRecoveryAttempts = 3;              // Max vehicle unstuck attempts
    A3XAI_vehicleRespawnTime = 900;             // Vehicle respawn time after abandonment (seconds)

    // ================================================================
    // EAD (Elite AI Driving) INTEGRATION
    // ================================================================

    A3XAI_EAD_enabled = 1;                      // Enable EAD integration if available (1=yes, 0=no)

    // ================================================================
    // SPECIAL FEATURES
    // ================================================================

    A3XAI_zombieResurrection = 0;               // Convert dead AI to zombies (requires RyanZombies)
    A3XAI_hostagesJoinRescuer = 0;              // Rescued hostages join player group (1=yes, 0=no)
    A3XAI_hunterTargetClosest = 1;              // Hunter squads target closest player (1=yes, 0=no)

    // ================================================================
    // WATER SPAWN SETTINGS
    // ================================================================

    A3XAI_waterMinDepth = 5;                    // Minimum water depth for boat spawns (meters)

    // ================================================================
    // BLACKLIST ZONES
    // ================================================================

    // Format: {name, {x,y,z}, radius}
    // Add your trader cities and safe zones here
    A3XAI_blacklistZones[] = {
        // Trader City South
        {"TraderCity", {14599, 16797, 0}, 750},
        // Trader North
        {"TraderNorth", {23334, 24188, 0}, 500},
        // Trader East
        {"TraderEast", {2988, 18173, 0}, 500}
    };
};