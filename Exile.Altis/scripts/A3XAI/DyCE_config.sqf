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
    ["maxTroopConvoys", 1],             // Max troop transports
    ["maxHeliPatrols", 2],              // Max helicopter patrols
    ["maxHighwayPatrols", 4],           // Max highway patrols (integrated)
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
    ["aiSkillMin", 0.5],                // Minimum AI skill
    ["aiSkillMax", 0.9],                // Maximum AI skill
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
    ["enableNotifications", true],      // Send spawn notifications
    ["enableMarkers", false],           // Show markers (false = surprise attacks)
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
        ["speedLimit", 60],
        ["spawnAltitude", 0],
        ["alertMessage", "Enemy patrol detected in the area!"],
        ["vehicleCount", [2, 3]],       // 2-3 vehicles
        ["crewPerVehicle", [2, 3]],     // 2-3 crew
        ["vehicles", [
            "Exile_Car_Offroad_Armed_Guerilla01",
            "Exile_Car_Offroad_Armed_Guerilla02",
            "Exile_Car_SUV_Armed_Black",
            "ivory_charger_marked",
            "ivory_challenger_marked"
        ]],
        ["uniforms", [
            "U_IG_Guerilla1_1",
            "U_IG_Guerilla2_1",
            "U_IG_Guerilla3_1"
        ]],
        ["vests", [
            "V_TacVest_khk",
            "V_Chestrig_khk",
            "V_BandollierB_khk"
        ]],
        ["lootRange", [50, 150]],       // Poptabs range
        ["difficulty", "medium"]
    ]],

    // ----------------------------------------
    // TROOP CONVOY - Heavy military transport
    // ----------------------------------------
    ["troopConvoy", createHashMapFromArray [
        ["name", "Military Convoy"],
        ["markerColor", "ColorBlack"],
        ["markerType", "mil_destroy"],
        ["speedLimit", 50],
        ["spawnAltitude", 0],
        ["alertMessage", "Military convoy spotted - high value target!"],
        ["vehicleCount", [3, 4]],       // 3-4 vehicles
        ["crewPerVehicle", [3, 4]],     // 3-4 crew (more troops)
        ["vehicles", [
            "Exile_Car_BTR40_MG_Green",
            "Exile_Car_BRDM2_HQ",
            "Exile_Car_Offroad_Armed_Guerilla01",
            "ivory_suburban_marked"
        ]],
        ["uniforms", [
            "U_B_CTRG_1",
            "U_B_CTRG_2",
            "U_B_CTRG_3"
        ]],
        ["vests", [
            "V_PlateCarrier1_rgr",
            "V_PlateCarrier2_rgr"
        ]],
        ["lootRange", [100, 250]],
        ["difficulty", "hard"]
    ]],

    // ----------------------------------------
    // HELICOPTER PATROL - Air reconnaissance
    // ----------------------------------------
    ["heliPatrol", createHashMapFromArray [
        ["name", "Helicopter Patrol"],
        ["markerColor", "ColorBlue"],
        ["markerType", "mil_dot"],
        ["speedLimit", 150],
        ["spawnAltitude", 150],         // Spawn at altitude
        ["alertMessage", "Enemy helicopter patrol detected!"],
        ["vehicleCount", [1, 2]],       // 1-2 helicopters
        ["crewPerVehicle", [2, 3]],     // Pilot + gunners
        ["vehicles", [
            "Exile_Chopper_Huey_Armed_Green",
            "Exile_Chopper_Orca_BlackCustom",
            "Exile_Chopper_Mohawk_FIA"
        ]],
        ["uniforms", [
            "U_B_CombatUniform_mcam",
            "U_B_HeliPilotCoveralls"
        ]],
        ["vests", [
            "V_TacVest_blk",
            "V_Chestrig_blk"
        ]],
        ["lootRange", [75, 200]],
        ["difficulty", "extreme"]
    ]],

    // ----------------------------------------
    // HIGHWAY PATROL - Road interception
    // ----------------------------------------
    ["highwayPatrol", createHashMapFromArray [
        ["name", "Highway Patrol"],
        ["markerColor", "ColorOrange"],
        ["markerType", "mil_triangle"],
        ["speedLimit", 80],
        ["spawnAltitude", 0],
        ["alertMessage", ""],           // No alert - surprise encounter
        ["vehicleCount", [1, 2]],
        ["crewPerVehicle", [2, 3]],
        ["vehicles", [
            "ivory_charger_marked",
            "ivory_taurus_marked",
            "ivory_cv_marked",
            "ivory_challenger_marked",
            "Exile_Car_Offroad_Armed_Guerilla01"
        ]],
        ["uniforms", [
            "U_O_CombatUniform_ocamo",
            "U_O_CombatUniform_oucamo"
        ]],
        ["vests", [
            "V_TacVest_oli",
            "V_BandollierB_oli"
        ]],
        ["lootRange", [25, 100]],
        ["difficulty", "medium"]
    ]],

    // ----------------------------------------
    // SUPPLY TRUCK - Slow but high value
    // ----------------------------------------
    ["supplyTruck", createHashMapFromArray [
        ["name", "Supply Truck"],
        ["markerColor", "ColorYellow"],
        ["markerType", "mil_box"],
        ["speedLimit", 40],
        ["spawnAltitude", 0],
        ["alertMessage", "Enemy supply truck intercepted on radar!"],
        ["vehicleCount", [2, 2]],       // 2 vehicles (escort + truck)
        ["crewPerVehicle", [2, 2]],
        ["vehicles", [
            "Exile_Car_Van_Box_Guerilla01",
            "Exile_Car_Offroad_Armed_Guerilla02"
        ]],
        ["uniforms", [
            "U_IG_Guerilla2_2",
            "U_IG_Guerilla3_2"
        ]],
        ["vests", [
            "V_Chestrig_khk"
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
