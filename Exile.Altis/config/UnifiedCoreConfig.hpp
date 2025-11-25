class UMC_Master
{
    class Difficulty
    {
        aimAccuracy = 0.15;
        aimShake    = 0.30;
        aimSpeed    = 0.40;
        spotDistance = 0.75;
        spotTime     = 0.75;
        courage      = 1.00;
        commanding   = 1.00;
        reloadSpeed  = 1.00;
    };

    class Loot
    {
        class Tier1
        {
            weapons[] = {"SMG_05_F","hgun_P07_F"};
            mags[]    = {"30Rnd_9x21_Mag","16Rnd_9x21_Mag"};
            items[]   = {"Exile_Item_PlasticBottleFreshWater"};
        };
        class Tier2
        {
            weapons[] = {"arifle_Katiba_F","arifle_TRG20_F"};
            mags[]    = {"30Rnd_65x39_caseless_green","30Rnd_556x45_Stanag"};
            items[]   = {"Exile_Item_EnergyDrink"};
        };
        class Tier3
        {
            weapons[] = {"arifle_AK12_F","LMG_Zafir_F"};
            mags[]    = {"30Rnd_762x39_Mag_F","150Rnd_762x54_Box"};
            items[]   = {"Exile_Item_InstaDoc"};
        };
    };

    class A3XAI
    {
        // AI group size
        minAI = 3;
        maxAI = 6;
        
        // Spawn triggers
        spawnRadius   = 400;   // Player must be this close to a location to trigger spawn
        despawnRadius = 1000;  // Despawn AI if all players are beyond this distance
        despawnDelay  = 120;   // Seconds to wait before despawning (after players leave)
        
        // Limits
        maxActiveGroups = 15;  // Maximum simultaneous AI groups
        
        // Dynamic spawns (ambient threat near players)
        dynamicSpawnChance  = 0.12;  // 12% chance per cycle to spawn near a player
        vehiclePatrolChance = 0.06;  // 6% chance per cycle for vehicle patrol
        
        // Debug
        debugMode = 0;  // 0=off, 1=basic, 2=verbose
    };

    class DMS
    {
        aiMin = 6;
        aiMax = 12;
        missionIntervalMin = 120;
        missionIntervalMax = 300;
        maxActiveMissions = 3;
        rewardPoptabs = 300;
        rewardRespect = 50;
    };

    class Occupation
    {
        patrolSizeMin = 2;
        patrolSizeMax = 4;
        roadblockChance = 0.20;
        roamVehicleChance = 0.10;
    };

    class VEMFr
    {
        invasionChance = 0.25;
        minWaves = 2;
        maxWaves = 4;
        waveSizeMin = 6;
        waveSizeMax = 12;
        despawnDelay = 1200;
    };

    class DyCE
    {
        crashChance = 0.20;
        aiCountMin = 3;
        aiCountMax = 6;
        despawnDelay = 1800;
    };
};
