if (!isServer) exitWith {};

#include "..\config\WB_Settings.hpp"
#include "..\config\WB_CfgFactions.hpp"
#include "..\config\WB_CfgZones.hpp"
#include "..\config\WB_CfgEconomy.hpp"
#include "..\config\WB_CfgMarket.hpp"
#include "..\config\WB_CfgTroops.hpp"
#include "..\config\WB_CfgCompanions.hpp"

diag_log "[WB] init: loading settings, factions, zones.";

WB_zoneIndex = createHashMap;
{ WB_zoneIndex set [ _x select 0, _forEachIndex ]; } forEach WB_zones;

// Strategic/economy loops
[] spawn {
    waitUntil { !isNil "ExileServerIsLoading" && {!ExileServerIsLoading} };
    diag_log "[WB] init: starting cycles.";
    [] call WB_fnc_startStrategicCycle;
    [] spawn WB_fnc_economyTick;
    [] spawn WB_fnc_taxTick;
    [] spawn WB_fnc_troopUpgradeTick;

    // Alliance drift
    [] spawn { while {true} do { [] call WB_fnc_allianceSystem; uiSleep 600; }; };
};
