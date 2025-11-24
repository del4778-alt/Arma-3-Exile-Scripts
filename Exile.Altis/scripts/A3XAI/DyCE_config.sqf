/*
    A3XAI Elite - DyCE Integration (Dynamic Convoy Events)
    Integrated from: https://github.com/ExiledHeisenberg/DyCE

    This configuration merges DyCE's dynamic convoy system with A3XAI Elite.
    All convoys, patrols, and dynamic events are managed through A3XAI's
    mission system for unified control.

    v1.0 - Initial DyCE integration
*/

if (!isServer) exitWith {};

// ============================================================
// DyCE GLOBAL CONFIGURATION
// ============================================================
DyCE_Config = createHashMapFromArray [

    // ========================================
    // TIMING & SPAWN SETTINGS
    // ========================================
    ["heartbeat", 5],                   // Script check interval (seconds)
    ["delayBetweenConvoys", 60],        // Minimum delay between convoy spawns
    ["startupDelay", 180],              // Initial delay before spawning (3 min)
    ["maxIdleTime", 120],               // Remove stuck convoy after 2 min
    ["maxStoppedTime", 180],            // Remove completely stopped convoy after 3 min

    // ========================================
    // CONVOY LIMITS
    // ========================================
    ["maxArmedConvoys", 2],             // Max armed ground convoys
    ["maxTroopConvoys", 2],             // Max troop transports
    ["maxHighwayPatrols", 4],           // Max highway patrols (integrated)
    ["maxSupplyTrucks", 2],             // Max supply truck convoys
    ["maxTotalDynamicEvents", 8],       // Max combined dynamic events

    // ========================================
    // SPAWN CONDITIONS
    // ========================================
    ["minPlayersOnline", 1],            // Minimum players to spawn events
    ["playerProximityCheck", 1000],     // Spawn within Xm of a player
    ["vehicleSpawnSearchRadius", 200],  // Search radius for road spawns
    ["minDistanceFromPlayers", 500],    // Don't spawn too close

    // ========================================
    // AI CONFIGURATION
    // ========================================
    ["aiSide", EAST],                   // All DyCE AI are EAST (enemies)
    ["aiSkillMin", 0.7],                // ✅ v3.20: Increased from 0.5 (fewer but tougher AI)
    ["aiSkillMax", 0.95],               // ✅ v3.20: Increased from 0.9
    ["aiHuntRadius", 200],              // AI engagement/hunt radius
    ["itemsPerAI", [3, 6]],             // Random loot items per AI

    // ========================================
    // VEHICLE LOOT
    // ========================================
    ["backpacksPerVehicle", [1, 3]],    // Random backpacks
    ["itemsPerVehicle", [3, 6]],        // Random items
    ["weaponsPerVehicle", [2, 4]],      // Random weapons

    // ========================================
    // NOTIFICATIONS & MARKERS
    // ========================================
    ["enableNotifications", true],      // Send Exile toast notifications
    ["enableMarkers", true],            // Show markers on map
    ["debugMode", false],               // Debug logging

    // ========================================
    // EXILE INTEGRATION
    // ========================================
    ["exileEnabled", true],             // Enable Exile features
    ["respectReward", 100]              // Respect per AI kill
];

// ============================================================
// CONVOY TYPE DEFINITIONS
// ============================================================
// Each convoy type has specific vehicle compositions and behaviors

DyCE_ConvoyTypes = createHashMapFromArray [

    // ----------------------------------------
    // ARMED CONVOY - Fast attack vehicles
    // ----------------------------------------
    ["armedConvoy", createHashMapFromArray [
        ["name", "Armed Patrol"],
        ["markerColor", "ColorRed"],
        ["markerType", "mil_warning"],
        ["speedLimit", 200],  // v3.18: Increased from 60 for high-speed pursuit
        ["spawnAltitude", 0],
        ["alertMessage", "Enemy patrol detected in the area!"],
        ["vehicleCount", [1, 2]],       // ✅ v3.20: Reduced to 1-2 vehicles (was 2-3)
        ["crewPerVehicle", [2, 2]],     // ✅ v3.20: Fixed at 2 crew (max 4 AI total)
        ["vehicles", [
            "Exile_Car_Offroad_Armed_Guerilla01",
            "Exile_Car_Offroad_Armed_Guerilla02",
            "Exile_Car_SUV_Armed_Black",
            "ivory_charger_marked",
            "ivory_challenger_marked"
        ]],
        ["uniforms", [
            "U_B_GEN_Commander_F",      // Gendarmerie Commander
            "U_B_GEN_Soldier_F",        // Gendarmerie Soldier
            "U_B_CTRG_Soldier_F"        // CTRG Black (tactical police)
        ]],
        ["vests", [
            "V_TacVest_blk",            // Tactical Vest Black
            "V_PlateCarrier1_blk",      // Plate Carrier Black
            "V_Chestrig_blk"            // Chest Rig Black
        ]],
        ["lootRange", [50, 150]],       // Poptabs range
        ["difficulty", "medium"]
    ]],

    // ----------------------------------------
    // TROOP CONVOY - Heavy police transport
    // ----------------------------------------
    ["troopConvoy", createHashMapFromArray [
        ["name", "Police Convoy"],
        ["markerColor", "ColorBlack"],
        ["markerType", "mil_destroy"],
        ["speedLimit", 150],  // v3.18: Increased from 50 for faster transport
        ["spawnAltitude", 0],
        ["alertMessage", "Police convoy spotted - heavy resistance expected!"],
        ["vehicleCount", [1, 2]],       // ✅ v3.20: Reduced to 1-2 vehicles (was 3-4)
        ["crewPerVehicle", [2, 3]],     // ✅ v3.20: Reduced to 2-3 crew (max 5 AI total)
        ["vehicles", [
            "Exile_Car_Offroad_Armed_Guerilla01",
            "Exile_Car_Offroad_Armed_Guerilla02",
            "Exile_Car_SUV_Armed_Black",
            "ivory_suburban_marked",
            "ivory_expedition_marked"
        ]],
        ["uniforms", [
            "U_B_GEN_Commander_F",      // Gendarmerie Commander
            "U_B_GEN_Soldier_F",        // Gendarmerie Soldier
            "U_B_CTRG_Soldier_2_F"      // CTRG Black variant
        ]],
        ["vests", [
            "V_PlateCarrier2_blk",      // Plate Carrier Black v2
            "V_PlateCarrierSpec_blk"    // Special Plate Carrier Black
        ]],
        ["lootRange", [100, 250]],
        ["difficulty", "hard"]
    ]],

    // ----------------------------------------
    // HIGHWAY PATROL - Police Road Interception
    // ----------------------------------------
    ["highwayPatrol", createHashMapFromArray [
        ["name", "Highway Patrol"],
        ["markerColor", "ColorOrange"],
        ["markerType", "mil_triangle"],
        ["speedLimit", 250],  // v3.18: Increased from 80 for high-speed highway pursuit
        ["spawnAltitude", 0],
        ["alertMessage", ""],           // No alert - surprise encounter
        ["vehicleCount", [1, 1]],       // ✅ v3.20: Single vehicle only
        ["crewPerVehicle", [2, 3]],     // ✅ v3.20: 2-3 crew (max 3 AI)
        ["vehicles", [
            "ivory_charger_marked",
            "ivory_taurus_marked",
            "ivory_cv_marked",
            "ivory_challenger_marked",
            "Exile_Car_Offroad_Armed_Guerilla01"
        ]],
        ["uniforms", [
            "U_B_GEN_Commander_F",      // Gendarmerie Commander
            "U_B_GEN_Soldier_F"         // Gendarmerie Soldier
        ]],
        ["vests", [
            "V_TacVest_blk",            // Tactical Vest Black
            "V_TacVestIR_blk"           // Tactical Vest IR Black
        ]],
        ["lootRange", [25, 100]],
        ["difficulty", "medium"]
    ]],

    // ----------------------------------------
    // SUPPLY TRUCK - Police Evidence/Supply Transport
    // ----------------------------------------
    ["supplyTruck", createHashMapFromArray [
        ["name", "Police Supply Truck"],
        ["markerColor", "ColorYellow"],
        ["markerType", "mil_box"],
        ["speedLimit", 120],  // v3.18: Increased from 40 for faster supply runs
        ["spawnAltitude", 0],
        ["alertMessage", "Police supply convoy detected!"],
        ["vehicleCount", [1, 2]],       // ✅ v3.20: Reduced to 1-2 vehicles
        ["crewPerVehicle", [2, 2]],     // ✅ v3.20: Fixed 2 crew (max 4 AI)
        ["vehicles", [
            "Exile_Car_Van_Box_Guerilla01",
            "Exile_Car_Offroad_Armed_Guerilla02"
        ]],
        ["uniforms", [
            "U_B_GEN_Soldier_F",        // Gendarmerie Soldier
            "U_B_CTRG_Soldier_F"        // CTRG Black
        ]],
        ["vests", [
            "V_Chestrig_blk",           // Chest Rig Black
            "V_TacVest_blk"             // Tactical Vest Black
        ]],
        ["lootRange", [150, 300]],      // High value cargo
        ["difficulty", "easy"]
    ]]
];

// ============================================================
// HIGHWAY ROUTES (Altis - between Exile Spawn Zones)
// ============================================================
DyCE_HighwayRoutes = [
    // [Start Zone, End Zone, Midpoint]
    ["Kavala", "Zaros", [6500, 12500, 0]],
    ["Kavala", "Syrta", [6000, 16000, 0]],
    ["Zaros", "Pyrgos", [13500, 12400, 0]],
    ["Pyrgos", "Selekano", [19000, 10000, 0]],
    ["Pyrgos", "Sofia", [21000, 17000, 0]],
    ["Sofia", "Syrta", [17000, 20000, 0]],
    ["Syrta", "Zaros", [9200, 15000, 0]],
    ["Selekano", "Sofia", [23000, 14000, 0]]
];

// ============================================================
// EXILE SPAWN ZONE COORDINATES
// ============================================================
DyCE_SpawnZones = createHashMapFromArray [
    ["Kavala", [3874, 13281, 0]],
    ["Zaros", [9927, 12083, 0]],
    ["Selekano", [20978, 7046, 0]],
    ["Pyrgos", [17138, 12719, 0]],
    ["Sofia", [25713, 21330, 0]],
    ["Syrta", [8613, 18272, 0]]
];

// ============================================================
// DyCE TRACKING VARIABLES
// ============================================================
DyCE_ActiveConvoys = [];
DyCE_LastSpawnTime = 0;
DyCE_TotalSpawned = 0;
DyCE_Initialized = false;

// ============================================================
// INITIALIZATION COMPLETE
// ============================================================
diag_log "==============================================";
diag_log "[DyCE] Dynamic Convoy Events - Configuration Loaded";
diag_log format ["[DyCE] Max Events: %1 | Convoy Delay: %2s",
    DyCE_Config get "maxTotalDynamicEvents",
    DyCE_Config get "delayBetweenConvoys"];
diag_log format ["[DyCE] Convoy Types: %1", count DyCE_ConvoyTypes];
diag_log format ["[DyCE] Highway Routes: %1", count DyCE_HighwayRoutes];
diag_log "==============================================";

DyCE_Initialized = true;
