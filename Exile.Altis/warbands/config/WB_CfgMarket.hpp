// Stock split by faction (enforce: ONLY their stock)
WB_factionStock = createHashMapFromArray [
    ["KAV", ["arifle_MX_F","SMG_01_F","B_MRAP_01_F","U_B_CombatUniform_mcam"]],
    ["PYR", ["arifle_Katiba_F","LMG_Zafir_F","O_MRAP_02_F","U_O_CombatUniform_ocamo"]],
    ["ATH", ["arifle_TRG21_F","MMG_01_hex_F","I_MRAP_03_F","U_I_CombatUniform"]],
    ["CIV", ["hgun_P07_F","SMG_05_F","C_Offroad_01_F","U_C_Man_casual_1_F"]]
];

WB_blackmarketItems = [
    "arifle_AK12_F","arifle_ARX_blk_F","srifle_DMR_05_blk_F",
    "U_O_R_Gorka_01_F","V_PlateCarrierSpec_blk","H_HelmetO_ViperSP_hex_F",
    "B_Heli_Transport_01_F","O_Heli_Light_02_unarmed_F"
];

WB_marketPrices = createHashMapFromArray [
    ["arifle_MX_F",6000],["SMG_01_F",2500],["B_MRAP_01_F",80000],
    ["arifle_Katiba_F",5500],["LMG_Zafir_F",30000],["O_MRAP_02_F",78000],
    ["arifle_TRG21_F",4500],["MMG_01_hex_F",32000],["I_MRAP_03_F",76000],
    ["hgun_P07_F",800],["SMG_05_F",2300],["C_Offroad_01_F",15000],
    ["arifle_AK12_F",7000],["srifle_DMR_05_blk_F",38000],["B_Heli_Transport_01_F",420000]
];
