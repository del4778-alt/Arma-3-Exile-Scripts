// Four core factions mapped to vanilla sides
WB_factions = [
  ["KAV","Kingdom of Kavala",[0.00,0.55,1.00,1],["Kavala","KavalaOutskirts"],west,"\A3\Data_F\Flags\Flag_blue_CO.paa","WB_LOOT_WEST"],
  ["PYR","Pyrgos League",      [1.00,0.30,0.30,1],["Pyrgos","PyrgosIndustrial"],east,"\A3\Data_F\Flags\Flag_red_CO.paa","WB_LOOT_EAST"],
  ["ATH","Athira Compact",     [0.20,1.00,0.50,1],["Athira","AthiraFarm"],independent,"\A3\Data_F\Flags\Flag_green_CO.paa","WB_LOOT_IND"],
  ["CIV","Civilian Union",     [1.00,1.00,0.30,1],["Sofia","SofiaMine"],resistance,"\A3\Data_F\Flags\Flag_yellow_CO.paa","WB_LOOT_RES"]
];

WB_generals = createHashMap;
WB_officers = createHashMap;
