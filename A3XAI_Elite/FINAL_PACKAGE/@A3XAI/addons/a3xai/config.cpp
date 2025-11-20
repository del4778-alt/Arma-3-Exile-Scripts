/*
    A3XAI Elite Edition - Config.cpp
    CfgPatches definition for PBO addon system
*/

class CfgPatches {
    class A3XAI_Elite {
        units[] = {};
        weapons[] = {};
        requiredVersion = 1.64;
        requiredAddons[] = {"exile_server"};
        version = "1.0.0";
        author = "A3XAI Community + Elite Edition Enhancements";
        name = "A3XAI Elite Edition";

        // Auto-execute init on server start
        init = "call compile preprocessFileLineNumbers '\a3xai\init.sqf'";
    };
};

class CfgFunctions {
    class A3XAI {
        class Core {
            file = "\a3xai\functions\core";
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
            file = "\a3xai\functions\spawn";
            class canSpawn {};
            class registerSpawn {};
            class removeSpawn {};
            class spawnInfantry {};
            class spawnVehicle {};
            class spawnHeli {};
            class spawnBoat {};
        };

        class AI {
            file = "\a3xai\functions\ai";
            class initAI {};
            class setAISkill {};
            class equipAI {};
            class addAIEventHandlers {};
            class setGroupBehavior {};
        };

        class Vehicle {
            file = "\a3xai\functions\vehicle";
            class initVehicle {};
            class addVehicleEventHandlers {};
            class isVehicleStuck {};
            class unstuckVehicle {};
            class getRoadQuality {};
            class findValidRoad {};
            class generateRoute {};
        };

        class Mission {
            file = "\a3xai\functions\missions";
            class selectMission {};
            class spawnMission {};
            class spawnLoot {};
            class checkMissionComplete {};
            class completeMission {};
        };

        class MissionTypes {
            file = "\a3xai\functions\missions\types";
            class convoy {};
            class crash {};
            class camp {};
            class hunter {};
            class rescue {};
        };

        class HC {
            file = "\a3xai\functions\hc";
            class initHC {};
            class offloadGroup {};
            class balanceHC {};
        };

        class Utility {
            file = "\a3xai\functions\utility";
            class setTimeout {};
            class generateDefensePositions {};
        };
    };
};
