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
        init = "call compile preprocessFileLineNumbers '\A3XAI_Elite\init.sqf'";
    };
};

class CfgFunctions {
    class A3XAI {
        class Core {
            file = "\A3XAI_Elite\functions\core";
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
            file = "\A3XAI_Elite\functions\spawn";
            class canSpawn {};
            class registerSpawn {};
            class removeSpawn {};
            class spawnInfantry {};
            class spawnVehicle {};
            class spawnHeli {};
            class spawnBoat {};
        };

        class AI {
            file = "\A3XAI_Elite\functions\ai";
            class initAI {};
            class setAISkill {};
            class equipAI {};
            class addAIEventHandlers {};
            class setGroupBehavior {};
        };

        class Vehicle {
            file = "\A3XAI_Elite\functions\vehicle";
            class initVehicle {};
            class addVehicleEventHandlers {};
            class isVehicleStuck {};
            class unstuckVehicle {};
            class getRoadQuality {};
            class findValidRoad {};
            class generateRoute {};
        };

        class Mission {
            file = "\A3XAI_Elite\functions\missions";
            class selectMission {};
            class spawnMission {};
            class spawnLoot {};
            class checkMissionComplete {};
            class completeMission {};
        };

        class MissionTypes {
            file = "\A3XAI_Elite\functions\missions\types";
            class convoy {};
            class crash {};
            class camp {};
            class hunter {};
            class rescue {};
        };

        class HC {
            file = "\A3XAI_Elite\functions\hc";
            class initHC {};
            class offloadGroup {};
            class balanceHC {};
        };

        class Utility {
            file = "\A3XAI_Elite\functions\utility";
            class setTimeout {};
            class generateDefensePositions {};
        };
    };
};
