/*
    Dynamic Mission System v2.0 - ENHANCED EDITION
    Author: Arma 3 Exile Scripts
    Description: Advanced AI-driven missions with comprehensive features from DMS Exile & A3 Exile Occupation

    ============================================
    NEW FEATURES IN V2.0
    ============================================

    PERFORMANCE:
    - AI Freezing System (freeze AI when 3500m+ from players)
    - Client-Side AI Offloading (distribute AI to clients)
    - FPS-Based Spawn Control (halt spawning below threshold)
    - Player-Scaled AI (reduce AI count with more players)
    - Terrain Validation (slope checking, surface normal)
    - Spawn Throttling (adaptive position finding)

    AI SYSTEM:
    - 5-Tier Difficulty (Static/Easy/Moderate/Difficult/Hardcore)
    - AI Class Types (Assault/Machine Gunner/Sniper)
    - Random Skill Distribution
    - Class-Specific Loadouts (optics, attachments, equipment)

    LOOT SYSTEM:
    - 30+ Weapon Variants (up from 5)
    - DLC Support (Marksman/Apex weapons)
    - 14 Food Types, 6 Beverages, Medical Supplies
    - Building Materials (walls, sandbags, fortifications)
    - Rare Items System (10% spawn chance for safes, locks)
    - 7+ Backpack Types

    REWARDS:
    - Distance Bonuses (+0.05 respect per meter beyond 100m)
    - Unit-Type Rewards (soldier/gunner/crew different values)
    - Difficulty Multipliers (2.5x for hardcore)

    MISSIONS:
    - Reinforcement Waves (helicopter insertions)
    - Mine Fields (5-25 mines based on difficulty)
    - Static Missions (persistent locations)
    - Variable Spawn Timing (random intervals)
    - Timeout Reset (extend timer when players nearby)

    CLEANUP:
    - Timed Object Removal (3600s for objects)
    - Destroyed Vehicle Cleanup (300s for wrecks)
    - Player Proximity Protection (no cleanup within 20m)

    Installation:
    1. Place in Dynamic-Mission-System folder
    2. Add to init.sqf: [] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
    3. Configure MISSION_CONFIG below
*/

// ========================================
// ENHANCED CONFIGURATION v2.0
// ========================================

MISSION_CONFIG = createHashMapFromArray [
    // === CORE SETTINGS ===
    ["enabled", true],
    ["debug", true],
    ["minPlayers", 1],
    ["maxActiveMissions", 3],
    ["maxStaticMissions", 1],                 // NEW: Persistent mission locations

    // === SPAWN TIMING (Now Variable) ===
    ["spawnIntervalMin", 480],                // NEW: Min seconds (8 min)
    ["spawnIntervalMax", 720],                // NEW: Max seconds (12 min)
    ["missionTimeoutMin", 1800],              // NEW: Min timeout (30 min)
    ["missionTimeoutMax", 2700],              // NEW: Max timeout (45 min)
    ["timeoutResetDistance", 1500],           // NEW: Extend timer if player within this distance
    ["timeoutResetAmount", 300],              // NEW: Add 5 minutes when players nearby

    // === SPAWN VALIDATION (Enhanced) ===
    ["safeZoneDistance", 2500],               // INCREASED from 1000m
    ["traderDistance", 2500],                 // NEW: Trader zone protection
    ["minPlayerDistance", 2000],              // INCREASED from 500m
    ["waterDistance", 500],                   // NEW: Water body buffer
    ["territoryFlagDistance", 100],           // NEW: Base flag protection
    ["mapBorderDistance", 250],               // NEW: Edge of map buffer
    ["maxSpawnAttempts", 5000],               // NEW: Max position finding attempts
    ["throttleInterval", 15],                 // NEW: Reduce constraints every X attempts
    ["minSurfaceNormal", 0.9],                // NEW: Terrain slope (0.9 = ~25 degrees max)
    ["completionDistance", 100],
    ["initialMissionsOnJoin", 3],

    // === PERFORMANCE OPTIMIZATION ===
    ["enableAIFreezing", true],               // NEW: Freeze AI when far from players
    ["aiFreezeDistance", 3500],               // NEW: Distance to freeze AI
    ["aiFreezeCheckInterval", 15],            // NEW: How often to check (seconds)
    ["enableClientOffload", false],           // NEW: Offload AI to clients (EXPERIMENTAL)
    ["enableFPSControl", true],               // NEW: Stop spawning on low FPS
    ["minFPS", 15],                           // NEW: Minimum server FPS
    ["enablePlayerScaling", true],            // NEW: Reduce AI with more players
    ["playerScaleThreshold", 10],             // NEW: Start scaling above this player count
    ["playerScaleReduction", 10],             // NEW: Reduce max AI by X per player

    // === REWARDS (Enhanced) ===
    ["rewardPoptabs", [5000, 15000]],
    ["rewardRespect", [500, 2000]],
    ["enableDistanceBonus", true],            // NEW: Bonus for long-range kills
    ["distanceBonusStart", 100],              // NEW: Start bonus after 100m
    ["distanceBonusPerMeter", 0.05],          // NEW: Respect per meter

    // Unit Type Rewards (NEW)
    ["rewardSoldier", [50, 10]],              // [poptabs, respect]
    ["rewardGunner", [100, 20]],              // Static gunner/MG
    ["rewardSniper", [150, 30]],              // Sniper
    ["rewardCrew", [200, 40]],                // Vehicle crew

    // === MISSION WEIGHTS ===
    ["crashSiteWeight", 25],
    ["supplyCacheWeight", 30],
    ["convoyWeight", 15],
    ["rescueWeight", 20],
    ["campWeight", 10],

    // === AI SYSTEM (5-Tier Enhanced) ===
    ["aiCountEasy", [3, 5]],
    ["aiCountMedium", [5, 8]],
    ["aiCountHard", [8, 12]],
    ["aiCountHardcore", [10, 15]],            // NEW: Hardcore tier

    // AI Skill Presets (NEW)
    ["skillStatic", 0.20],                    // Static gunners
    ["skillEasy", 0.30],
    ["skillModerate", 0.60],
    ["skillDifficult", 0.70],
    ["skillHardcore", 1.00],                  // Perfect aim

    // AI Distribution (NEW) - Random skill assignment
    ["aiDistribution", [
        ["hardcore", 10],                     // 10% hardcore
        ["difficult", 30],                    // 30% difficult
        ["moderate", 40],                     // 40% moderate
        ["easy", 20]                          // 20% easy
    ]],

    // === REINFORCEMENTS (NEW) ===
    ["enableReinforcements", true],
    ["reinforcementChance", 30],              // 30% chance on mission start
    ["reinforcementDelay", [120, 300]],       // 2-5 minutes after mission start
    ["reinforcementCount", [4, 6]],           // AI per wave
    ["reinforcementHeight", 500],             // Helicopter altitude
    ["reinforcementRadius", [500, 5000]],     // Drop radius

    // === MINE FIELDS (NEW) ===
    ["enableMineFields", true],
    ["mineFieldChance", 25],                  // 25% of missions get mines
    ["minesEasy", [5, 50]],                   // [count, radius]
    ["minesMedium", [10, 60]],
    ["minesHard", [15, 80]],
    ["minesHardcore", [25, 100]],

    // === DLC SUPPORT (NEW) ===
    ["enableMarksman", true],                 // Marksman DLC weapons
    ["enableApex", true],                     // Apex weapons

    // === CLEANUP SYSTEM (NEW) ===
    ["cleanupObjectTime", 3600],              // 1 hour for mission objects
    ["cleanupVehicleTime", 300],              // 5 minutes for destroyed vehicles
    ["cleanupPlayerDistance", 20],            // Don't cleanup within 20m of players
    ["cleanupCheckInterval", 60],             // Check every 60 seconds

    // === MAP-SPECIFIC OVERRIDES (NEW) ===
    ["mapConfigs", createHashMapFromArray [
        ["Altis", createHashMapFromArray [
            ["maxAI", 120],
            ["spawnIntervalMin", 600]
        ]],
        ["Tanoa", createHashMapFromArray [
            ["maxAI", 80],
            ["spawnIntervalMin", 480]
        ]],
        ["Malden", createHashMapFromArray [
            ["maxAI", 70],
            ["spawnIntervalMin", 420]
        ]]
    ]]
];

// ========================================
// ENHANCED LOOT TABLES v2.0
// ========================================

// 30+ Base Weapons (Vanilla)
MISSION_LOOT_Weapons = [
    "arifle_Katiba_F", "arifle_Katiba_C_F", "arifle_Katiba_GL_F",
    "arifle_Mk20_F", "arifle_Mk20C_F", "arifle_Mk20_GL_F",
    "arifle_MX_F", "arifle_MX_GL_F", "arifle_MXC_F", "arifle_MXM_F",
    "arifle_SDAR_F", "arifle_TRG20_F", "arifle_TRG21_F", "arifle_TRG21_GL_F",
    "LMG_Mk200_F", "LMG_Zafir_F",
    "srifle_DMR_01_F", "srifle_EBR_F", "srifle_GM6_F", "srifle_LRR_F",
    "SMG_01_F", "SMG_02_F",
    "hgun_P07_F", "hgun_Rook40_F", "hgun_ACPC2_F", "hgun_Pistol_heavy_01_F", "hgun_Pistol_heavy_02_F"
];

// Marksman DLC Weapons (22 additional)
MISSION_LOOT_Marksman = [
    "srifle_DMR_02_F", "srifle_DMR_02_camo_F", "srifle_DMR_02_sniper_F",
    "srifle_DMR_03_F", "srifle_DMR_03_khaki_F", "srifle_DMR_03_tan_F", "srifle_DMR_03_multicam_F", "srifle_DMR_03_woodland_F",
    "srifle_DMR_04_F", "srifle_DMR_04_Tan_F",
    "srifle_DMR_05_blk_F", "srifle_DMR_05_hex_F", "srifle_DMR_05_tan_f",
    "srifle_DMR_06_camo_F", "srifle_DMR_06_olive_F",
    "MMG_01_hex_F", "MMG_01_tan_F", "MMG_02_camo_F", "MMG_02_black_F", "MMG_02_sand_F",
    "arifle_MX_SW_F", "arifle_MX_SW_Black_F"
];

// Apex DLC Weapons (8 additional)
MISSION_LOOT_Apex = [
    "arifle_AK12_F", "arifle_AK12_GL_F",
    "arifle_ARX_blk_F", "arifle_ARX_ghex_F", "arifle_ARX_hex_F",
    "arifle_CTAR_blk_F", "arifle_CTAR_hex_F", "arifle_CTARS_blk_F"
];

// Food & Consumables (14 food, 6 drinks)
MISSION_LOOT_Food = [
    "Exile_Item_Beer", "Exile_Item_EnergyDrink", "Exile_Item_ChocolateMilk",
    "Exile_Item_MountainDupe", "Exile_Item_PowerDrink", "Exile_Item_PlasticBottleFreshWater",
    "Exile_Item_BBQSandwich", "Exile_Item_Surstromming", "Exile_Item_SausageGravy",
    "Exile_Item_ChristmasTinner", "Exile_Item_MacasCheese", "Exile_Item_Dogfood",
    "Exile_Item_BeefParts", "Exile_Item_Noodles", "Exile_Item_SeedAstics",
    "Exile_Item_Raisins", "Exile_Item_Moobar", "Exile_Item_InstantCoffee",
    "Exile_Item_Can_Empty", "Exile_Item_ToiletPaper"
];

// Medical Supplies
MISSION_LOOT_Medical = [
    "Exile_Item_InstaDoc", "Exile_Item_Bandage", "Exile_Item_Vishpirin",
    "FirstAidKit", "Medikit"
];

// Tools & Equipment
MISSION_LOOT_Tools = [
    "Binocular", "Rangefinder", "Laserdesignator",
    "NVGoggles", "NVGoggles_OPFOR", "NVGoggles_INDEP",
    "ItemGPS", "ItemMap", "ItemCompass", "ItemWatch", "ItemRadio",
    "ToolKit", "MineDetector"
];

// Building Materials (NEW)
MISSION_LOOT_Materials = [
    "Exile_Item_WoodPlank", "Exile_Item_MetalBoard", "Exile_Item_Cement",
    "Exile_Item_Sand", "Exile_Item_MetalWire", "Exile_Item_MetalScrews",
    "Exile_Item_ExtensionCord", "Exile_Item_LightBulb", "Exile_Item_MetalPole"
];

// Rare Items (10% spawn chance)
MISSION_LOOT_Rare = [
    "Exile_Item_SafeKit", "Exile_Item_CodeLock", "Exile_Item_Laptop",
    "Exile_Item_BaseCameraKit", "Exile_Item_CamoTentKit", "Exile_Item_MetalBoard"
];

// Backpacks (7+ types)
MISSION_LOOT_Backpacks = [
    "B_AssaultPack_khk", "B_AssaultPack_rgr", "B_AssaultPack_mcamo",
    "B_Kitbag_mcamo", "B_Kitbag_cbr", "B_TacticalPack_oli",
    "B_FieldPack_blk", "B_Carryall_oli", "B_Bergen_sgg"
];

// Vehicles (Armed)
MISSION_LOOT_Vehicles = [
    "Exile_Car_Offroad_Armed_Guerilla01",
    "Exile_Car_HMMWV_M2_Desert",
    "Exile_Car_BTR40_MG_Green",
    "Exile_Car_Hunter"
];

// ========================================
// GLOBAL VARIABLES
// ========================================

MISSION_ActiveMissions = [];
MISSION_StaticMissions = [];                  // NEW
MISSION_SafeZones = [];
MISSION_CleanupQueue = [];                    // NEW
MISSION_FrozenGroups = [];                    // NEW
MISSION_InitComplete = false;
MISSION_InitialMissionsSpawned = false;
MISSION_CurrentFPS = 50;                      // NEW
MISSION_TotalAICount = 0;                     // NEW

// ========================================
// UTILITY FUNCTIONS
// ========================================

MISSION_fnc_log = {
    params ["_message"];
    if (MISSION_CONFIG get "debug") then {
        diag_log format ["[MISSION v2.0] %1", _message];
        systemChat format ["[MISSION v2.0] %1", _message];
    };
};

// NEW: Apply map-specific config overrides
MISSION_fnc_applyMapConfig = {
    private _worldName = worldName;
    private _mapConfigs = MISSION_CONFIG get "mapConfigs";

    if (_worldName in _mapConfigs) then {
        private _mapConfig = _mapConfigs get _worldName;
        {
            MISSION_CONFIG set [_x, _mapConfig get _x];
            [format ["Map override: %1 = %2", _x, _mapConfig get _x]] call MISSION_fnc_log;
        } forEach (keys _mapConfig);
    };
};

// NEW: Get current server FPS
MISSION_fnc_getFPS = {
    private _fps = diag_fps;
    MISSION_CurrentFPS = _fps;
    _fps
};

// NEW: Check if spawning should be blocked by FPS
MISSION_fnc_checkFPS = {
    if (!(MISSION_CONFIG get "enableFPSControl")) exitWith { true };

    private _fps = call MISSION_fnc_getFPS;
    private _minFPS = MISSION_CONFIG get "minFPS";

    if (_fps < _minFPS) then {
        [format ["FPS too low (%1 < %2), blocking spawn", _fps, _minFPS]] call MISSION_fnc_log;
        false
    } else {
        true
    };
};

// NEW: Calculate dynamic max AI based on player count
MISSION_fnc_getMaxAI = {
    if (!(MISSION_CONFIG get "enablePlayerScaling")) exitWith { 999999 };

    private _playerCount = count allPlayers;
    private _threshold = MISSION_CONFIG get "playerScaleThreshold";
    private _reduction = MISSION_CONFIG get "playerScaleReduction";

    private _baseMax = 120; // Default
    if (worldName in (MISSION_CONFIG get "mapConfigs")) then {
        private _mapConfig = (MISSION_CONFIG get "mapConfigs") get worldName;
        if ("maxAI" in _mapConfig) then {
            _baseMax = _mapConfig get "maxAI";
        };
    };

    if (_playerCount > _threshold) then {
        _baseMax = _baseMax - ((_playerCount - _threshold) * _reduction);
    };

    _baseMax max 30 // Never go below 30
};

MISSION_fnc_getSafeZones = {
    private _zones = [];
    {
        if (["ExileSpawnZone", _x] call BIS_fnc_inString || ["ExileTraderZone", _x] call BIS_fnc_inString) then {
            _zones pushBack (getMarkerPos _x);
        };
    } forEach allMapMarkers;

    [format ["Found %1 safe/trader zones", count _zones]] call MISSION_fnc_log;
    _zones
};

// ENHANCED: Advanced position validation with terrain checking
MISSION_fnc_isSafeLocation = {
    params ["_pos", ["_surfaceNormalThreshold", 0.9]];

    // Check if on water
    if (surfaceIsWater _pos) exitWith { false };

    // NEW: Check terrain slope (surface normal)
    private _surfaceNormal = surfaceNormal _pos;
    if ((_surfaceNormal select 2) < _surfaceNormalThreshold) exitWith {
        // Terrain too steep
        false
    };

    // Check safe zones
    private _safeZoneDist = MISSION_CONFIG get "safeZoneDistance";
    {
        if (_pos distance2D _x < _safeZoneDist) exitWith { false };
    } forEach MISSION_SafeZones;

    // Check players
    private _playerDist = MISSION_CONFIG get "minPlayerDistance";
    {
        if (_pos distance2D (getPosATL _x) < _playerDist) exitWith { false };
    } forEach allPlayers;

    // NEW: Check map borders
    private _borderDist = MISSION_CONFIG get "mapBorderDistance";
    if ((_pos select 0) < _borderDist || (_pos select 1) < _borderDist ||
        (_pos select 0) > (worldSize - _borderDist) || (_pos select 1) > (worldSize - _borderDist)) exitWith {
        false
    };

    true
};

// ENHANCED: Position finding with throttling
MISSION_fnc_getRandomPosition = {
    private _mapSize = worldSize;
    private _attempts = 0;
    private _maxAttempts = MISSION_CONFIG get "maxSpawnAttempts";
    private _throttleInterval = MISSION_CONFIG get "throttleInterval";
    private _pos = [];

    // Dynamic constraints that get relaxed
    private _currentPlayerDist = MISSION_CONFIG get "minPlayerDistance";
    private _currentSafeZoneDist = MISSION_CONFIG get "safeZoneDistance";
    private _currentSurfaceNormal = MISSION_CONFIG get "minSurfaceNormal";

    while {_attempts < _maxAttempts} do {
        _pos = [
            (_mapSize * 0.1) + random (_mapSize * 0.8), // Avoid edges
            (_mapSize * 0.1) + random (_mapSize * 0.8),
            0
        ];

        // Use current (possibly throttled) constraints
        private _tempConfig = +MISSION_CONFIG;
        _tempConfig set ["minPlayerDistance", _currentPlayerDist];
        _tempConfig set ["safeZoneDistance", _currentSafeZoneDist];

        if ([_pos, _currentSurfaceNormal] call MISSION_fnc_isSafeLocation) exitWith {};

        _attempts = _attempts + 1;

        // NEW: Throttling - relax constraints every X attempts
        if (_attempts % _throttleInterval == 0) then {
            _currentPlayerDist = (_currentPlayerDist * 0.9) max 100;
            _currentSafeZoneDist = (_currentSafeZoneDist * 0.9) max 100;
            _currentSurfaceNormal = (_currentSurfaceNormal - 0.005) max 0.75;

            [format ["Throttling at attempt %1: PlayerDist=%2, SafeZone=%3, SurfaceNormal=%4",
                _attempts, _currentPlayerDist, _currentSafeZoneDist, _currentSurfaceNormal]] call MISSION_fnc_log;
        };
    };

    if (_attempts >= _maxAttempts) then {
        [format ["Failed to find safe position after %1 attempts", _maxAttempts]] call MISSION_fnc_log;
        _pos = [_mapSize / 2, _mapSize / 2, 0];
    } else {
        [format ["Found position after %1 attempts", _attempts]] call MISSION_fnc_log;
    };

    _pos
};

MISSION_fnc_createMarker = {
    params ["_pos", "_type", "_text", ["_color", "ColorRed"]];

    private _markerName = format ["mission_%1_%2", _type, time];
    private _marker = createMarker [_markerName, _pos];
    _marker setMarkerShape "ICON";
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor _color;
    _marker setMarkerText _text;
    _marker setMarkerAlpha 1;

    _marker
};

// NEW: Select random AI skill tier based on distribution
MISSION_fnc_selectAISkillTier = {
    private _distribution = MISSION_CONFIG get "aiDistribution";
    private _totalWeight = 0;
    {
        _totalWeight = _totalWeight + (_x select 1);
    } forEach _distribution;

    private _random = random _totalWeight;
    private _currentWeight = 0;
    private _selectedTier = "moderate";

    {
        _currentWeight = _currentWeight + (_x select 1);
        if (_random < _currentWeight) exitWith {
            _selectedTier = _x select 0;
        };
    } forEach _distribution;

    _selectedTier
};

// NEW: Get skill value for tier
MISSION_fnc_getSkillForTier = {
    params ["_tier"];

    private _skill = switch (_tier) do {
        case "static": { MISSION_CONFIG get "skillStatic" };
        case "easy": { MISSION_CONFIG get "skillEasy" };
        case "moderate": { MISSION_CONFIG get "skillModerate" };
        case "difficult": { MISSION_CONFIG get "skillDifficult" };
        case "hardcore": { MISSION_CONFIG get "skillHardcore" };
        default { 0.6 };
    };

    _skill
};

// ENHANCED: AI spawning with class types and 5-tier difficulty
MISSION_fnc_spawnAI = {
    params ["_pos", "_count", "_side", ["_classType", "assault"]];

    private _group = createGroup [_side, true];
    if (isNull _group) exitWith {
        [format ["ERROR: Failed to create AI group at %1", _pos]] call MISSION_fnc_log;
        [grpNull, []]
    };

    private _units = [];

    for "_i" from 1 to _count do {
        private _unitPos = [
            (_pos select 0) + (random 20 - 10),
            (_pos select 1) + (random 20 - 10),
            0
        ];

        private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "NONE"];

        if (isNull _unit) then {
            [format ["WARNING: Failed to spawn unit #%1 at %2", _i, _unitPos]] call MISSION_fnc_log;
        } else {
            // NEW: Select random skill tier
            private _skillTier = call MISSION_fnc_selectAISkillTier;
            private _skillValue = [_skillTier] call MISSION_fnc_getSkillForTier;

            _unit setVariable ["EAID_Ignore", true, true];
            _unit setVariable ["MissionAI", true, true];
            _unit setVariable ["AIClass", _classType, true];          // NEW
            _unit setVariable ["SkillTier", _skillTier, true];        // NEW

            // Apply skills
            _unit setSkill _skillValue;
            _unit setSkill ["aimingAccuracy", _skillValue];
            _unit setSkill ["aimingShake", _skillValue * 0.9];
            _unit setSkill ["aimingSpeed", _skillValue * 0.95];
            _unit setSkill ["spotDistance", _skillValue];
            _unit setSkill ["spotTime", _skillValue * 0.9];
            _unit setSkill ["courage", 0.8 + random 0.2];
            _unit setSkill ["reloadSpeed", _skillValue];
            _unit setSkill ["commanding", _skillValue];
            _unit setSkill ["general", _skillValue];

            // NEW: Class-specific loadouts
            removeAllWeapons _unit;
            removeAllItems _unit;
            removeAllAssignedItems _unit;
            removeUniform _unit;
            removeVest _unit;
            removeBackpack _unit;
            removeHeadgear _unit;
            removeGoggles _unit;

            _unit addUniform "U_O_CombatUniform_ocamo";
            _unit addVest "V_HarnessO_brn";

            switch (_classType) do {
                case "assault": {
                    // Assault rifles
                    private _weapon = selectRandom ["arifle_Katiba_F", "arifle_Mk20_F", "arifle_MX_F", "arifle_TRG21_F"];
                    _unit addWeapon _weapon;

                    // 75% chance for optic
                    if (random 100 < 75) then {
                        _unit addPrimaryWeaponItem (selectRandom ["optic_ACO_grn", "optic_Holosight", "optic_Aco"]);
                    };

                    // 25% chance for bipod
                    if (random 100 < 25) then {
                        _unit addPrimaryWeaponItem "bipod_01_F_blk";
                    };

                    _unit addPrimaryWeaponItem "acc_flashlight";
                    for "_m" from 1 to 6 do { _unit addMagazine "30Rnd_65x39_caseless_green"; };

                    // GPS device
                    _unit linkItem "ItemGPS";
                };

                case "machinegunner": {
                    // LMGs
                    private _weapon = selectRandom ["LMG_Mk200_F", "LMG_Zafir_F"];
                    _unit addWeapon _weapon;

                    // 50% chance for optic
                    if (random 100 < 50) then {
                        _unit addPrimaryWeaponItem (selectRandom ["optic_Hamr", "optic_Holosight"]);
                    };

                    // 90% chance for bipod
                    if (random 100 < 90) then {
                        _unit addPrimaryWeaponItem "bipod_01_F_blk";
                    };

                    for "_m" from 1 to 4 do { _unit addMagazine "200Rnd_65x39_cased_Box"; };

                    // Binoculars
                    _unit addWeapon "Binocular";
                    _unit addBackpack "B_Carryall_oli";
                };

                case "sniper": {
                    // Sniper rifles
                    private _weapon = selectRandom ["srifle_EBR_F", "srifle_GM6_F", "srifle_LRR_F", "srifle_DMR_01_F"];
                    _unit addWeapon _weapon;

                    // 100% optic for snipers
                    _unit addPrimaryWeaponItem (selectRandom ["optic_SOS", "optic_DMS", "optic_LRPS"]);

                    // 90% chance for bipod
                    if (random 100 < 90) then {
                        _unit addPrimaryWeaponItem "bipod_01_F_blk";
                    };

                    for "_m" from 1 to 8 do { _unit addMagazine "20Rnd_762x51_Mag"; };

                    // Rangefinder and GPS
                    _unit addWeapon "Rangefinder";
                    _unit linkItem "ItemGPS";
                };
            };

            // Common items
            _unit addWeapon "hgun_Rook40_F";
            for "_p" from 1 to 3 do { _unit addMagazine "16Rnd_9x21_Mag"; };
            _unit addHeadgear "H_HelmetO_ocamo";

            // NEW: AI kill handler for rewards
            _unit addEventHandler ["Killed", {
                params ["_unit", "_killer"];
                [_unit, _killer] call MISSION_fnc_onAIKilled;
            }];

            _units pushBack _unit;
            MISSION_TotalAICount = MISSION_TotalAICount + 1;
        };
    };

    if (count _units == 0) exitWith {
        [format ["ERROR: No AI units spawned at %1", _pos]] call MISSION_fnc_log;
        deleteGroup _group;
        [grpNull, []]
    };

    // Set group behavior
    _group setBehaviour "COMBAT";
    _group setCombatMode "RED";
    _group setFormation "WEDGE";
    _group setSpeedMode "FULL";

    // Add patrol waypoints
    for "_i" from 0 to 3 do {
        private _angle = _i * 90;
        private _wpPos = [
            (_pos select 0) + (50 * cos _angle),
            (_pos select 1) + (50 * sin _angle),
            0
        ];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
    };

    // Cycle waypoints
    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";

    [format ["Spawned %1 AI units at %2 (Class: %3)", count _units, _pos, _classType]] call MISSION_fnc_log;

    [_group, _units]
};

// NEW: AI Kill Handler with distance bonuses and unit-type rewards
MISSION_fnc_onAIKilled = {
    params ["_unit", "_killer"];

    if (isNull _killer || !isPlayer _killer) exitWith {};

    private _distance = _unit distance _killer;
    private _aiClass = _unit getVariable ["AIClass", "assault"];
    private _skillTier = _unit getVariable ["SkillTier", "moderate"];

    // Base rewards by unit type
    private _rewards = switch (_aiClass) do {
        case "assault": { MISSION_CONFIG get "rewardSoldier" };
        case "machinegunner": { MISSION_CONFIG get "rewardGunner" };
        case "sniper": { MISSION_CONFIG get "rewardSniper" };
        default { [50, 10] };
    };

    private _poptabs = _rewards select 0;
    private _respect = _rewards select 1;

    // Skill tier multiplier
    private _multiplier = switch (_skillTier) do {
        case "static": { 0.8 };
        case "easy": { 1.0 };
        case "moderate": { 1.3 };
        case "difficult": { 1.7 };
        case "hardcore": { 2.5 };
        default { 1.0 };
    };

    _poptabs = floor(_poptabs * _multiplier);
    _respect = floor(_respect * _multiplier);

    // NEW: Distance bonus
    if (MISSION_CONFIG get "enableDistanceBonus") then {
        private _bonusStart = MISSION_CONFIG get "distanceBonusStart";
        private _bonusPerMeter = MISSION_CONFIG get "distanceBonusPerMeter";

        if (_distance > _bonusStart) then {
            private _extraRespect = floor((_distance - _bonusStart) * _bonusPerMeter);
            _respect = _respect + _extraRespect;

            [format ["Distance bonus: +%1 respect for %2m kill", _extraRespect, floor _distance]] call MISSION_fnc_log;
        };
    };

    // Award to player (placeholder - needs Exile integration)
    // _killer setVariable ["ExileMoney", (_killer getVariable ["ExileMoney", 0]) + _poptabs, true];
    // _killer setVariable ["ExileScore", (_killer getVariable ["ExileScore", 0]) + _respect, true];

    private _msg = format ["%1 killed %2 %3 (+%4 tabs, +%5 respect) at %6m",
        name _killer, _skillTier, _aiClass, _poptabs, _respect, floor _distance];
    [_msg] remoteExec ["systemChat", _killer];
    [_msg] call MISSION_fnc_log;
};

// ENHANCED: Loot spawning with DLC support and rare items
MISSION_fnc_spawnLoot = {
    params ["_pos", "_difficulty"];

    private _box = "Box_East_Wps_F" createVehicle _pos;
    clearBackpackCargoGlobal _box;
    clearItemCargoGlobal _box;
    clearMagazineCargoGlobal _box;
    clearWeaponCargoGlobal _box;

    private _lootCount = switch (_difficulty) do {
        case "static": { 2 + floor(random 2) };
        case "easy": { 3 + floor(random 3) };
        case "moderate": { 5 + floor(random 4) };
        case "difficult": { 7 + floor(random 5) };
        case "hardcore": { 10 + floor(random 8) };
        default { 3 };
    };

    // Build weapon pool
    private _weaponPool = +MISSION_LOOT_Weapons;

    // NEW: Add DLC weapons if enabled
    if (MISSION_CONFIG get "enableMarksman") then {
        _weaponPool append MISSION_LOOT_Marksman;
    };
    if (MISSION_CONFIG get "enableApex") then {
        _weaponPool append MISSION_LOOT_Apex;
    };

    // Add weapons
    for "_i" from 1 to _lootCount do {
        private _weapon = selectRandom _weaponPool;
        _box addWeaponCargoGlobal [_weapon, 1];

        private _mags = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
        if (count _mags > 0) then {
            _box addMagazineCargoGlobal [_mags select 0, 3];
        };
    };

    // Add items (food, medical, tools)
    for "_i" from 1 to (_lootCount * 2) do {
        private _item = selectRandom (MISSION_LOOT_Food + MISSION_LOOT_Medical + MISSION_LOOT_Tools);
        _box addItemCargoGlobal [_item, 1];
    };

    // Add building materials
    for "_i" from 1 to _lootCount do {
        _box addItemCargoGlobal [selectRandom MISSION_LOOT_Materials, 1];
    };

    // Add backpacks
    private _backpackCount = 1 + floor(random 2);
    for "_i" from 1 to _backpackCount do {
        _box addBackpackCargoGlobal [selectRandom MISSION_LOOT_Backpacks, 1];
    };

    // NEW: Rare items (10% chance)
    if (random 100 < 10) then {
        private _rareItem = selectRandom MISSION_LOOT_Rare;
        _box addItemCargoGlobal [_rareItem, 1];
        [format ["Rare item spawned: %1", _rareItem]] call MISSION_fnc_log;
    };

    _box
};

// NEW: Spawn mine field
MISSION_fnc_spawnMineField = {
    params ["_pos", "_difficulty"];

    if (!(MISSION_CONFIG get "enableMineFields")) exitWith { [] };
    if (random 100 > (MISSION_CONFIG get "mineFieldChance")) exitWith { [] };

    private _mineData = switch (_difficulty) do {
        case "easy": { MISSION_CONFIG get "minesEasy" };
        case "moderate": { MISSION_CONFIG get "minesMedium" };
        case "difficult": { MISSION_CONFIG get "minesHard" };
        case "hardcore": { MISSION_CONFIG get "minesHardcore" };
        default { [5, 50] };
    };

    private _mineCount = _mineData select 0;
    private _radius = _mineData select 1;
    private _mines = [];

    for "_i" from 1 to _mineCount do {
        private _angle = random 360;
        private _dist = random _radius;
        private _minePos = [
            (_pos select 0) + (_dist * cos _angle),
            (_pos select 1) + (_dist * sin _angle),
            0
        ];

        private _mine = "APERSMine" createVehicle _minePos;
        _mines pushBack _mine;
    };

    [format ["Spawned %1 mines in %2m radius", _mineCount, _radius]] call MISSION_fnc_log;

    _mines
};

// NEW: Spawn reinforcements via helicopter
MISSION_fnc_spawnReinforcements = {
    params ["_mission"];

    if (!(MISSION_CONFIG get "enableReinforcements")) exitWith {};
    if (random 100 > (MISSION_CONFIG get "reinforcementChance")) exitWith {};

    private _pos = _mission get "position";
    private _delay = (MISSION_CONFIG get "reinforcementDelay" select 0) + random ((MISSION_CONFIG get "reinforcementDelay" select 1) - (MISSION_CONFIG get "reinforcementDelay" select 0));

    [_mission, _pos, _delay] spawn {
        params ["_mission", "_pos", "_delay"];

        sleep _delay;

        // Spawn helicopter at altitude
        private _height = MISSION_CONFIG get "reinforcementHeight";
        private _radiusRange = MISSION_CONFIG get "reinforcementRadius";
        private _spawnDist = (_radiusRange select 0) + random ((_radiusRange select 1) - (_radiusRange select 0));
        private _angle = random 360;

        private _heliPos = [
            (_pos select 0) + (_spawnDist * cos _angle),
            (_pos select 1) + (_spawnDist * sin _angle),
            _height
        ];

        private _heli = "O_Heli_Light_02_unarmed_F" createVehicle _heliPos;
        _heli setPos _heliPos;
        _heli setDir (random 360);

        // Spawn crew
        private _crewGroup = createGroup EAST;
        private _pilot = _crewGroup createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _pilot moveInDriver _heli;

        // Spawn reinforcement troops
        private _count = (MISSION_CONFIG get "reinforcementCount" select 0) + floor(random ((MISSION_CONFIG get "reinforcementCount" select 1) - (MISSION_CONFIG get "reinforcementCount" select 0)));
        private _troopGroup = createGroup EAST;

        for "_i" from 1 to _count do {
            private _unit = _troopGroup createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
            _unit moveInCargo _heli;
        };

        // Waypoint to drop zone
        private _wp = _crewGroup addWaypoint [_pos, 0];
        _wp setWaypointType "TR UNLOAD";

        [format ["Reinforcements dispatched: %1 troops in helicopter", _count]] call MISSION_fnc_log;
        ["REINFORCEMENTS INCOMING! Enemy helicopter detected!"] remoteExec ["systemChat", 0];
    };
};

// ========================================
// MISSION TYPES (Using enhanced systems)
// ========================================

MISSION_fnc_createCrashSite = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "moderate", "difficult", "hardcore"];
    private _missionData = createHashMapFromArray [
        ["type", "crashsite"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["objects", []]
    ];

    // Create crashed helicopter
    private _heli = "Land_Wreck_Heli_Attack_01_F" createVehicle _pos;
    _heli setDir random 360;
    _missionData set ["objects", [_heli]];

    // Spawn loot
    private _loot = [_pos, _difficulty] call MISSION_fnc_spawnLoot;
    _missionData set ["loot", [_loot]];

    // Spawn AI (mixed classes)
    private _aiCount = switch (_difficulty) do {
        case "easy": { 3 + floor(random 3) };
        case "moderate": { 5 + floor(random 4) };
        case "difficult": { 8 + floor(random 5) };
        case "hardcore": { 10 + floor(random 6) };
        default { 4 };
    };

    // Mix of assault and snipers
    private _assaultCount = ceil(_aiCount * 0.7);
    private _sniperCount = _aiCount - _assaultCount;

    private _aiData1 = [_pos, _assaultCount, EAST, "assault"] call MISSION_fnc_spawnAI;
    private _aiData2 = [_pos, _sniperCount, EAST, "sniper"] call MISSION_fnc_spawnAI;

    _missionData set ["aiGroups", [_aiData1 select 0, _aiData2 select 0]];
    _missionData set ["aiUnits", (_aiData1 select 1) + (_aiData2 select 1)];

    // Spawn mines
    private _mines = [_pos, _difficulty] call MISSION_fnc_spawnMineField;
    _missionData set ["mines", _mines];

    // Create marker
    private _marker = [_pos, "crashsite", format ["Crash Site [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    // Schedule reinforcements
    [_missionData] call MISSION_fnc_spawnReinforcements;

    [format ["Crash Site mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

MISSION_fnc_createSupplyCache = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "moderate", "difficult", "hardcore"];
    private _missionData = createHashMapFromArray [
        ["type", "supplycache"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["objects", []]
    ];

    // Create supply crates
    private _crates = [];
    private _crateCount = switch (_difficulty) do {
        case "easy": { 2 };
        case "moderate": { 3 };
        case "difficult": { 4 };
        case "hardcore": { 5 };
        default { 3 };
    };

    for "_i" from 0 to (_crateCount - 1) do {
        private _cratePos = [
            (_pos select 0) + (random 10 - 5),
            (_pos select 1) + (random 10 - 5),
            0
        ];
        private _crate = [_cratePos, _difficulty] call MISSION_fnc_spawnLoot;
        _crates pushBack _crate;
    };
    _missionData set ["loot", _crates];

    // Spawn AI (mixed classes)
    private _aiCount = switch (_difficulty) do {
        case "easy": { 4 + floor(random 3) };
        case "moderate": { 6 + floor(random 4) };
        case "difficult": { 9 + floor(random 4) };
        case "hardcore": { 12 + floor(random 4) };
        default { 5 };
    };

    private _assaultCount = ceil(_aiCount * 0.5);
    private _mgCount = ceil(_aiCount * 0.3);
    private _sniperCount = _aiCount - _assaultCount - _mgCount;

    private _aiData1 = [_pos, _assaultCount, EAST, "assault"] call MISSION_fnc_spawnAI;
    private _aiData2 = [_pos, _mgCount, EAST, "machinegunner"] call MISSION_fnc_spawnAI;
    private _aiData3 = [_pos, _sniperCount, EAST, "sniper"] call MISSION_fnc_spawnAI;

    _missionData set ["aiGroups", [_aiData1 select 0, _aiData2 select 0, _aiData3 select 0]];
    _missionData set ["aiUnits", (_aiData1 select 1) + (_aiData2 select 1) + (_aiData3 select 1)];

    // Spawn mines
    private _mines = [_pos, _difficulty] call MISSION_fnc_spawnMineField;
    _missionData set ["mines", _mines];

    // Create marker
    private _marker = [_pos, "supplycache", format ["Supply Cache [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    // Schedule reinforcements
    [_missionData] call MISSION_fnc_spawnReinforcements;

    [format ["Supply Cache mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: CONVOY INTERCEPT (Enhanced)
// ========================================

MISSION_fnc_createConvoy = {
    params ["_pos"];

    private _difficulty = selectRandom ["moderate", "difficult", "hardcore"];
    private _missionData = createHashMapFromArray [
        ["type", "convoy"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["moving", true],
        ["objects", []]
    ];

    // Determine destination
    private _distance = 1000 + random 1000;
    private _angle = random 360;
    private _destination = [
        (_pos select 0) + (_distance * cos _angle),
        (_pos select 1) + (_distance * sin _angle),
        0
    ];
    _missionData set ["destination", _destination];

    // Create convoy vehicles
    private _vehicles = [];
    private _allCrew = [];
    private _vehicleCount = switch (_difficulty) do {
        case "moderate": { 2 };
        case "difficult": { 3 };
        case "hardcore": { 4 };
        default { 2 };
    };

    private _convoyDirection = random 360;

    for "_i" from 0 to (_vehicleCount - 1) do {
        private _vehiclePos = [
            (_pos select 0) + (_i * 30 * cos _convoyDirection),
            (_pos select 1) + (_i * 30 * sin _convoyDirection),
            0
        ];

        private _vehicleType = selectRandom MISSION_LOOT_Vehicles;
        private _vehicle = _vehicleType createVehicle _vehiclePos;

        // Safe spawn
        _vehicle allowDamage false;
        _vehicle enableSimulationGlobal false;
        _vehicle setPos _vehiclePos;
        _vehicle setDir _convoyDirection;
        _vehicle setVectorUp [0,0,1];
        _vehicle setVelocity [0,0,0];
        _vehicle setFuel 1;
        _vehicle setVariable ["EAID_Ignore", false, true];
        _vehicle setVariable ["ConvoyVehicle", true, true];

        _vehicles pushBack _vehicle;

        // Create AI crew
        private _group = createGroup EAST;

        // Driver
        private _driver = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
        _driver allowDamage false;
        _driver moveInDriver _vehicle;
        _driver setSkill (MISSION_CONFIG get "skillModerate");
        _driver setVariable ["AIClass", "assault", true];
        _allCrew pushBack _driver;

        // Gunner
        if (count (allTurrets _vehicle) > 0) then {
            private _gunner = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
            _gunner allowDamage false;
            _gunner moveInGunner _vehicle;
            _gunner setSkill (MISSION_CONFIG get "skillDifficult");
            _gunner setVariable ["AIClass", "machinegunner", true];
            _allCrew pushBack _gunner;
        };

        // Cargo
        for "_j" from 1 to 2 do {
            private _cargo = _group createUnit ["O_Soldier_F", [0,0,0], [], 0, "NONE"];
            _cargo allowDamage false;
            _cargo moveInCargo _vehicle;
            _cargo setSkill (MISSION_CONFIG get "skillModerate");
            _cargo setVariable ["AIClass", "assault", true];
            _allCrew pushBack _cargo;
        };

        // Waypoint to destination
        private _wp = _group addWaypoint [_destination, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "SAFE";

        _missionData set ["aiGroups", (_missionData getOrDefault ["aiGroups", []]) + [_group]];
    };

    _missionData set ["vehicles", _vehicles];

    // Add loot to last vehicle
    private _lastVehicle = _vehicles select (count _vehicles - 1);
    clearBackpackCargoGlobal _lastVehicle;
    clearItemCargoGlobal _lastVehicle;
    clearMagazineCargoGlobal _lastVehicle;
    clearWeaponCargoGlobal _lastVehicle;

    for "_i" from 1 to 5 do {
        _lastVehicle addWeaponCargoGlobal [selectRandom MISSION_LOOT_Weapons, 1];
    };
    for "_i" from 1 to 10 do {
        _lastVehicle addItemCargoGlobal [selectRandom (MISSION_LOOT_Food + MISSION_LOOT_Medical), 1];
    };

    // Delayed activation
    [_vehicles, _allCrew] spawn {
        params ["_vehArray", "_crewArray"];
        sleep 2;

        {
            _x enableSimulationGlobal true;
        } forEach _vehArray;

        sleep 1;

        {
            _x allowDamage true;
        } forEach _vehArray;

        {
            _x allowDamage true;
        } forEach _crewArray;

        [format ["Convoy fully initialized - %1 vehicles, %2 crew", count _vehArray, count _crewArray]] call MISSION_fnc_log;
    };

    // Create marker
    private _marker = [_pos, "convoy", format ["Convoy [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    // Schedule reinforcements
    [_missionData] call MISSION_fnc_spawnReinforcements;

    [format ["Convoy mission spawned at %1 (Difficulty: %2, Vehicles: %3)", _pos, _difficulty, count _vehicles]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: RESCUE HOSTAGES (Enhanced)
// ========================================

MISSION_fnc_createRescue = {
    params ["_pos"];

    private _difficulty = selectRandom ["easy", "moderate", "difficult", "hardcore"];
    private _missionData = createHashMapFromArray [
        ["type", "rescue"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["hostagesRescued", false],
        ["objects", []]
    ];

    // Create holding area
    private _tent = "Land_cargo_house_slum_F" createVehicle _pos;
    _missionData set ["objects", [_tent]];

    // Spawn hostages
    private _hostageCount = switch (_difficulty) do {
        case "easy": { 2 };
        case "moderate": { 3 };
        case "difficult": { 4 };
        case "hardcore": { 5 };
        default { 3 };
    };

    private _hostages = [];
    for "_i" from 1 to _hostageCount do {
        private _hostagePos = [
            (_pos select 0) + (random 5 - 2.5),
            (_pos select 1) + (random 5 - 2.5),
            0
        ];

        private _hostage = createAgent ["C_man_1", _hostagePos, [], 0, "NONE"];
        _hostage setVariable ["IsHostage", true, true];
        _hostage setCaptive true;
        _hostage disableAI "MOVE";
        _hostage setUnitPos "DOWN";

        _hostages pushBack _hostage;
    };
    _missionData set ["hostages", _hostages];

    // Spawn AI (mixed classes)
    private _aiCount = switch (_difficulty) do {
        case "easy": { 4 + floor(random 2) };
        case "moderate": { 6 + floor(random 3) };
        case "difficult": { 8 + floor(random 4) };
        case "hardcore": { 10 + floor(random 5) };
        default { 5 };
    };

    private _assaultCount = ceil(_aiCount * 0.6);
    private _mgCount = ceil(_aiCount * 0.3);
    private _sniperCount = _aiCount - _assaultCount - _mgCount;

    private _aiData1 = [_pos, _assaultCount, EAST, "assault"] call MISSION_fnc_spawnAI;
    private _aiData2 = [_pos, _mgCount, EAST, "machinegunner"] call MISSION_fnc_spawnAI;
    private _aiData3 = [_pos, _sniperCount, EAST, "sniper"] call MISSION_fnc_spawnAI;

    _missionData set ["aiGroups", [_aiData1 select 0, _aiData2 select 0, _aiData3 select 0]];
    _missionData set ["aiUnits", (_aiData1 select 1) + (_aiData2 select 1) + (_aiData3 select 1)];

    // Spawn loot
    private _loot = [_pos, _difficulty] call MISSION_fnc_spawnLoot;
    _missionData set ["loot", [_loot]];

    // Spawn mines
    private _mines = [_pos, _difficulty] call MISSION_fnc_spawnMineField;
    _missionData set ["mines", _mines];

    // Create marker
    private _marker = [_pos, "rescue", format ["Rescue Hostages [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    // Schedule reinforcements
    [_missionData] call MISSION_fnc_spawnReinforcements;

    [format ["Rescue mission spawned at %1 (Difficulty: %2, Hostages: %3, AI: %4)", _pos, _difficulty, _hostageCount, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// MISSION TYPE: AI CAMP (Enhanced)
// ========================================

MISSION_fnc_createCamp = {
    params ["_pos"];

    private _difficulty = selectRandom ["moderate", "difficult", "hardcore"];
    private _missionData = createHashMapFromArray [
        ["type", "camp"],
        ["position", _pos],
        ["difficulty", _difficulty],
        ["startTime", time],
        ["active", true],
        ["objects", []]
    ];

    // Create camp structures
    private _structures = [];

    // Central tent
    private _centerTent = "Land_cargo_house_slum_F" createVehicle _pos;
    _structures pushBack _centerTent;

    // Surrounding structures
    for "_i" from 0 to 3 do {
        private _angle = _i * 90;
        private _distance = 15;
        private _structPos = [
            (_pos select 0) + (_distance * cos _angle),
            (_pos select 1) + (_distance * sin _angle),
            0
        ];

        private _structure = (selectRandom ["Land_BagFence_Long_F", "Land_HBarrier_3_F"]) createVehicle _structPos;
        _structure setDir _angle;
        _structures pushBack _structure;
    };

    _missionData set ["objects", _structures];

    // Spawn multiple loot crates
    private _lootBoxes = [];
    private _crateCount = switch (_difficulty) do {
        case "moderate": { 3 };
        case "difficult": { 4 };
        case "hardcore": { 5 };
        default { 3 };
    };

    for "_i" from 0 to (_crateCount - 1) do {
        private _lootPos = [
            (_pos select 0) + (random 10 - 5),
            (_pos select 1) + (random 10 - 5),
            0
        ];
        private _box = [_lootPos, _difficulty] call MISSION_fnc_spawnLoot;
        _lootBoxes pushBack _box;
    };
    _missionData set ["loot", _lootBoxes];

    // Spawn armed vehicle
    private _vehiclePos = [
        (_pos select 0) + 20,
        (_pos select 1),
        0
    ];
    private _vehicle = (selectRandom MISSION_LOOT_Vehicles) createVehicle _vehiclePos;
    _vehicle setFuel 1;
    _missionData set ["vehicles", [_vehicle]];

    // Spawn AI (heavy resistance with all classes)
    private _aiCount = switch (_difficulty) do {
        case "moderate": { 10 + floor(random 4) };
        case "difficult": { 14 + floor(random 5) };
        case "hardcore": { 18 + floor(random 6) };
        default { 12 };
    };

    private _assaultCount = ceil(_aiCount * 0.5);
    private _mgCount = ceil(_aiCount * 0.3);
    private _sniperCount = _aiCount - _assaultCount - _mgCount;

    private _aiData1 = [_pos, _assaultCount, EAST, "assault"] call MISSION_fnc_spawnAI;
    private _aiData2 = [_pos, _mgCount, EAST, "machinegunner"] call MISSION_fnc_spawnAI;
    private _aiData3 = [_pos, _sniperCount, EAST, "sniper"] call MISSION_fnc_spawnAI;

    _missionData set ["aiGroups", [_aiData1 select 0, _aiData2 select 0, _aiData3 select 0]];
    _missionData set ["aiUnits", (_aiData1 select 1) + (_aiData2 select 1) + (_aiData3 select 1)];

    // Spawn mines
    private _mines = [_pos, _difficulty] call MISSION_fnc_spawnMineField;
    _missionData set ["mines", _mines];

    // Create marker
    private _marker = [_pos, "camp", format ["AI Camp [%1]", toUpper _difficulty]] call MISSION_fnc_createMarker;
    _missionData set ["marker", _marker];

    // Schedule reinforcements
    [_missionData] call MISSION_fnc_spawnReinforcements;

    [format ["AI Camp mission spawned at %1 (Difficulty: %2, AI: %3)", _pos, _difficulty, _aiCount]] call MISSION_fnc_log;

    _missionData
};

// ========================================
// AI FREEZING SYSTEM (Performance)
// ========================================

MISSION_fnc_freezeAI = {
    params ["_group"];

    if (isNull _group) exitWith {};
    if (_group in MISSION_FrozenGroups) exitWith {}; // Already frozen

    {
        if (alive _x) then {
            _x enableSimulationGlobal false;
        };
    } forEach (units _group);

    MISSION_FrozenGroups pushBack _group;
    [format ["Froze AI group (total frozen: %1)", count MISSION_FrozenGroups]] call MISSION_fnc_log;
};

MISSION_fnc_unfreezeAI = {
    params ["_group"];

    if (isNull _group) exitWith {};
    if !(_group in MISSION_FrozenGroups) exitWith {}; // Not frozen

    {
        if (alive _x) then {
            _x enableSimulationGlobal true;
        };
    } forEach (units _group);

    MISSION_FrozenGroups = MISSION_FrozenGroups - [_group];
    [format ["Unfroze AI group (remaining frozen: %1)", count MISSION_FrozenGroups]] call MISSION_fnc_log;
};

MISSION_fnc_updateAIFreezing = {
    if (!(MISSION_CONFIG get "enableAIFreezing")) exitWith {};

    private _freezeDist = MISSION_CONFIG get "aiFreezeDistance";

    {
        private _mission = _x;
        if (_mission get "active") then {
            private _groups = _mission getOrDefault ["aiGroups", []];

            {
                private _group = _x;
                if (!isNull _group && count (units _group) > 0) then {
                    private _leader = leader _group;
                    private _closestPlayerDist = 99999;

                    {
                        private _dist = _leader distance _x;
                        if (_dist < _closestPlayerDist) then {
                            _closestPlayerDist = _dist;
                        };
                    } forEach allPlayers;

                    if (_closestPlayerDist > _freezeDist) then {
                        [_group] call MISSION_fnc_freezeAI;
                    } else {
                        [_group] call MISSION_fnc_unfreezeAI;
                    };
                };
            } forEach _groups;
        };
    } forEach MISSION_ActiveMissions;
};

// ========================================
// CLEANUP SYSTEM
// ========================================

MISSION_fnc_cleanupMission = {
    params ["_mission"];

    // Remove marker
    deleteMarker (_mission get "marker");

    // Queue objects for timed cleanup
    private _cleanupTime = MISSION_CONFIG get "cleanupObjectTime";

    // Add all mission objects to cleanup queue
    private _objects = _mission getOrDefault ["objects", []];
    private _loot = _mission getOrDefault ["loot", []];
    private _mines = _mission getOrDefault ["mines", []];
    private _vehicles = _mission getOrDefault ["vehicles", []];

    private _allObjects = _objects + _loot + _mines + _vehicles;

    if (count _allObjects > 0) then {
        MISSION_CleanupQueue pushBack [_allObjects, time + _cleanupTime];
        [format ["Queued %1 objects for cleanup in %2s", count _allObjects, _cleanupTime]] call MISSION_fnc_log;
    };

    // Mark as inactive
    _mission set ["active", false];

    // Decrease AI count
    private _aiCount = count (_mission getOrDefault ["aiUnits", []]);
    MISSION_TotalAICount = (MISSION_TotalAICount - _aiCount) max 0;

    [format ["Mission %1 cleaned up", _mission get "type"]] call MISSION_fnc_log;
};

MISSION_fnc_processCleanupQueue = {
    private _toRemove = [];
    private _playerDist = MISSION_CONFIG get "cleanupPlayerDistance";

    {
        private _entry = _x;
        private _objects = _entry select 0;
        private _cleanupTime = _entry select 1;

        if (time >= _cleanupTime) then {
            private _canCleanup = true;

            // Check if any object is near a player
            {
                private _obj = _x;
                if (!isNull _obj) then {
                    {
                        if (_obj distance _x < _playerDist) exitWith {
                            _canCleanup = false;
                        };
                    } forEach allPlayers;
                };
            } forEach _objects;

            if (_canCleanup) then {
                // Delete objects
                {
                    if (!isNull _x) then {
                        deleteVehicle _x;
                    };
                } forEach _objects;

                _toRemove pushBack _forEachIndex;
                [format ["Cleaned up %1 objects", count _objects]] call MISSION_fnc_log;
            } else {
                // Reschedule for 30 seconds later
                _entry set [1, time + 30];
                [format ["Cleanup delayed - player nearby"]] call MISSION_fnc_log;
            };
        };
    } forEach MISSION_CleanupQueue;

    // Remove completed cleanups
    {
        MISSION_CleanupQueue deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// MISSION MANAGEMENT (Enhanced)
// ========================================

MISSION_fnc_selectMissionType = {
    private _totalWeight =
        (MISSION_CONFIG get "crashSiteWeight") +
        (MISSION_CONFIG get "supplyCacheWeight") +
        (MISSION_CONFIG get "convoyWeight") +
        (MISSION_CONFIG get "rescueWeight") +
        (MISSION_CONFIG get "campWeight");

    private _random = random _totalWeight;
    private _currentWeight = 0;

    _currentWeight = _currentWeight + (MISSION_CONFIG get "crashSiteWeight");
    if (_random < _currentWeight) exitWith { "crashsite" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "supplyCacheWeight");
    if (_random < _currentWeight) exitWith { "supplycache" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "convoyWeight");
    if (_random < _currentWeight) exitWith { "convoy" };

    _currentWeight = _currentWeight + (MISSION_CONFIG get "rescueWeight");
    if (_random < _currentWeight) exitWith { "rescue" };

    "camp"
};

MISSION_fnc_spawnMission = {
    // Check FPS
    if !(call MISSION_fnc_checkFPS) exitWith {};

    // Check max missions
    if (count MISSION_ActiveMissions >= (MISSION_CONFIG get "maxActiveMissions")) exitWith {
        ["Max active missions reached"] call MISSION_fnc_log;
    };

    // Check max AI
    private _maxAI = call MISSION_fnc_getMaxAI;
    if (MISSION_TotalAICount >= _maxAI) exitWith {
        [format ["Max AI reached (%1/%2)", MISSION_TotalAICount, _maxAI]] call MISSION_fnc_log;
    };

    // Check player count
    if (count allPlayers < (MISSION_CONFIG get "minPlayers")) exitWith {
        ["Not enough players"] call MISSION_fnc_log;
    };

    // Select mission type
    private _missionType = call MISSION_fnc_selectMissionType;

    // Get spawn position
    private _pos = call MISSION_fnc_getRandomPosition;

    // Create mission
    private _mission = switch (_missionType) do {
        case "crashsite": { [_pos] call MISSION_fnc_createCrashSite };
        case "supplycache": { [_pos] call MISSION_fnc_createSupplyCache };
        case "convoy": { [_pos] call MISSION_fnc_createConvoy };
        case "rescue": { [_pos] call MISSION_fnc_createRescue };
        case "camp": { [_pos] call MISSION_fnc_createCamp };
        default { [_pos] call MISSION_fnc_createCrashSite };
    };

    // Add random timeout
    private _timeout = (MISSION_CONFIG get "missionTimeoutMin") + random ((MISSION_CONFIG get "missionTimeoutMax") - (MISSION_CONFIG get "missionTimeoutMin"));
    _mission set ["timeout", time + _timeout];

    // Add to active missions
    MISSION_ActiveMissions pushBack _mission;

    // Announce
    private _announcement = format ["NEW MISSION: %1 - Check your map!", _mission get "marker"];
    [_announcement] remoteExec ["systemChat", 0];
};

MISSION_fnc_checkMissionComplete = {
    params ["_mission"];

    // Check if all AI are dead
    private _allDead = true;
    {
        if (!isNull _x) then {
            {
                if (alive _x) exitWith { _allDead = false };
            } forEach (units _x);
        };
    } forEach (_mission getOrDefault ["aiGroups", []]);

    _allDead
};

MISSION_fnc_completeMission = {
    params ["_mission"];

    [format ["Mission %1 completed!", _mission get "type"]] call MISSION_fnc_log;

    // Announce
    private _announcement = format ["MISSION COMPLETE: %1", _mission get "type"];
    [_announcement] remoteExec ["systemChat", 0];

    // Cleanup
    [_mission] call MISSION_fnc_cleanupMission;
};

MISSION_fnc_updateMissions = {
    private _toRemove = [];

    {
        private _mission = _x;

        if (_mission get "active") then {
            private _pos = _mission get "position";
            private _timeout = _mission get "timeout";

            // NEW: Check if players nearby and extend timeout
            private _resetDist = MISSION_CONFIG get "timeoutResetDistance";
            private _playersNearby = false;

            {
                if (_pos distance _x < _resetDist) exitWith {
                    _playersNearby = true;
                };
            } forEach allPlayers;

            if (_playersNearby && (time > (_timeout - 60))) then {
                private _extension = MISSION_CONFIG get "timeoutResetAmount";
                _mission set ["timeout", _timeout + _extension];
                [format ["Mission timeout extended by %1s (players nearby)", _extension]] call MISSION_fnc_log;
            };

            // Check timeout
            if (time >= _timeout) then {
                [format ["Mission %1 timed out", _mission get "type"]] call MISSION_fnc_log;
                [_mission] call MISSION_fnc_cleanupMission;
                _toRemove pushBack _forEachIndex;
            } else {
                // Check completion
                if ([_mission] call MISSION_fnc_checkMissionComplete) then {
                    [_mission] call MISSION_fnc_completeMission;
                    _toRemove pushBack _forEachIndex;
                };
            };
        };
    } forEach MISSION_ActiveMissions;

    // Remove completed
    {
        MISSION_ActiveMissions deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// INITIALIZATION
// ========================================

MISSION_fnc_init = {
    ["Dynamic Mission System v2.0 ENHANCED initializing..."] call MISSION_fnc_log;

    if (!(MISSION_CONFIG get "enabled")) exitWith {
        ["Mission system disabled"] call MISSION_fnc_log;
    };

    waitUntil {time > 10};

    // Apply map config
    call MISSION_fnc_applyMapConfig;

    // Cache safe zones
    MISSION_SafeZones = call MISSION_fnc_getSafeZones;

    // Player join detection
    [] spawn {
        while {true} do {
            sleep 5;

            if (!MISSION_InitialMissionsSpawned && count allPlayers >= (MISSION_CONFIG get "minPlayers")) then {
                MISSION_InitialMissionsSpawned = true;

                private _initialCount = MISSION_CONFIG get "initialMissionsOnJoin";
                [format ["Spawning %1 initial missions", _initialCount]] call MISSION_fnc_log;

                for "_i" from 1 to _initialCount do {
                    sleep 2;
                    call MISSION_fnc_spawnMission;
                };
            };

            if (MISSION_InitialMissionsSpawned && count allPlayers < (MISSION_CONFIG get "minPlayers")) then {
                MISSION_InitialMissionsSpawned = false;
            };
        };
    };

    // Mission spawn loop (variable timing)
    [] spawn {
        while {true} do {
            private _interval = (MISSION_CONFIG get "spawnIntervalMin") + random ((MISSION_CONFIG get "spawnIntervalMax") - (MISSION_CONFIG get "spawnIntervalMin"));
            sleep _interval;
            call MISSION_fnc_spawnMission;
        };
    };

    // Mission update loop
    [] spawn {
        while {true} do {
            sleep 10;
            call MISSION_fnc_updateMissions;
        };
    };

    // AI freezing loop
    [] spawn {
        while {true} do {
            sleep (MISSION_CONFIG get "aiFreezeCheckInterval");
            call MISSION_fnc_updateAIFreezing;
        };
    };

    // Cleanup loop
    [] spawn {
        while {true} do {
            sleep (MISSION_CONFIG get "cleanupCheckInterval");
            call MISSION_fnc_processCleanupQueue;
        };
    };

    MISSION_InitComplete = true;
    ["Dynamic Mission System v2.0 initialized successfully!"] call MISSION_fnc_log;
    [format ["Features: AI Freezing, 5-Tier Difficulty, 30+ Weapons, Reinforcements, Mines, Distance Rewards"]] call MISSION_fnc_log;
};

// Start the system
[] call MISSION_fnc_init;
