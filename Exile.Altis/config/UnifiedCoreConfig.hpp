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
        minAI = 3;
        maxAI = 6;
        spawnInterval = 45;
        spawnRadius   = 300;
        despawnRadius = 800;
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
