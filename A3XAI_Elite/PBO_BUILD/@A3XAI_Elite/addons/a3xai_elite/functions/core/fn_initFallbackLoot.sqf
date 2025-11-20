/*
    A3XAI Elite - Initialize Fallback Loot Tables
    Creates hardcoded loot arrays when Exile tables unavailable
*/

A3XAI_fallbackLoot = createHashMapFromArray [
    // Primary Weapons
    ["rifles", [
        "arifle_MX_F", "arifle_MX_GL_F", "arifle_MXC_F", "arifle_MXM_F",
        "arifle_Katiba_F", "arifle_Katiba_GL_F", "arifle_Katiba_C_F",
        "arifle_TRG21_F", "arifle_TRG20_F", "arifle_TRG21_GL_F",
        "arifle_Mk20_F", "arifle_Mk20_GL_F", "arifle_Mk20C_F",
        "arifle_SDAR_F", "arifle_AKM_F", "arifle_AKS_F", "arifle_AK12_F"
    ]],

    // LMGs
    ["lmg", [
        "LMG_Mk200_F", "LMG_Zafir_F", "MMG_02_black_F", "MMG_01_tan_F"
    ]],

    // Sniper Rifles
    ["snipers", [
        "srifle_EBR_F", "srifle_DMR_01_F", "srifle_GM6_F", "srifle_LRR_F"
    ]],

    // Pistols
    ["pistols", [
        "hgun_P07_F", "hgun_Rook40_F", "hgun_ACPC2_F", "hgun_Pistol_heavy_01_F"
    ]],

    // Launchers
    ["launchers", [
        "launch_NLAW_F", "launch_RPG32_F", "launch_B_Titan_short_F"
    ]],

    // Uniforms
    ["uniforms", [
        "U_B_CombatUniform_mcam", "U_B_CombatUniform_mcam_vest",
        "U_O_CombatUniform_ocamo", "U_O_CombatUniform_oucamo",
        "U_I_CombatUniform", "U_I_CombatUniform_shortsleeve",
        "U_B_GhillieSuit", "U_O_GhillieSuit", "U_I_GhillieSuit"
    ]],

    // Vests
    ["vests", [
        "V_PlateCarrier1_rgr", "V_PlateCarrier2_rgr", "V_PlateCarrierSpec_rgr",
        "V_TacVest_khk", "V_TacVest_oli", "V_TacVest_camo",
        "V_Chestrig_khk", "V_Chestrig_oli", "V_BandollierB_khk"
    ]],

    // Headgear
    ["headgear", [
        "H_HelmetB", "H_HelmetB_camo", "H_HelmetB_light",
        "H_HelmetSpecB", "H_HelmetSpecB_blk", "H_HelmetSpecB_paint1",
        "H_MilCap_mcamo", "H_MilCap_ocamo", "H_Bandanna_khk",
        "H_Shemag_olive", "H_ShemagOpen_tan"
    ]],

    // Items
    ["items", [
        "FirstAidKit", "ItemMap", "ItemCompass", "ItemWatch", "ItemRadio",
        "Binocular", "Rangefinder", "ItemGPS", "NVGoggles", "NVGoggles_OPFOR",
        "acc_flashlight", "acc_pointer_IR", "optic_Aco", "optic_Holosight",
        "optic_Hamr", "optic_DMS", "optic_LRPS", "muzzle_snds_H", "muzzle_snds_B"
    ]],

    // Magazines (generic)
    ["magazines", [
        "30Rnd_65x39_caseless_mag", "30Rnd_556x45_Stanag",
        "30Rnd_65x39_caseless_green", "20Rnd_556x45_UW_mag",
        "200Rnd_65x39_cased_Box", "150Rnd_762x54_Box",
        "9Rnd_45ACP_Mag", "16Rnd_9x21_Mag", "11Rnd_45ACP_Mag",
        "HandGrenade", "SmokeShell", "SmokeShellGreen", "Chemlight_green"
    ]],

    // Backpacks
    ["backpacks", [
        "B_AssaultPack_khk", "B_AssaultPack_rgr", "B_AssaultPack_mcamo",
        "B_Kitbag_mcamo", "B_Kitbag_sgg", "B_TacticalPack_oli",
        "B_FieldPack_khk", "B_Carryall_oli", "B_Carryall_khk"
    ]]
];

// Create weighted loot pools for different difficulty levels
A3XAI_fallbackLootPools = createHashMapFromArray [
    ["easy", createHashMapFromArray [
        ["weapons", ["arifle_TRG20_F", "arifle_Mk20C_F", "hgun_P07_F"]],
        ["items", ["FirstAidKit", "ItemMap", "ItemCompass", "ItemWatch"]],
        ["magazines", ["30Rnd_556x45_Stanag", "30Rnd_65x39_caseless_mag", "16Rnd_9x21_Mag"]]
    ]],

    ["medium", createHashMapFromArray [
        ["weapons", ["arifle_MX_F", "arifle_Katiba_F", "arifle_TRG21_F", "hgun_ACPC2_F"]],
        ["items", ["FirstAidKit", "ItemGPS", "Binocular", "optic_Aco", "muzzle_snds_H"]],
        ["magazines", ["30Rnd_65x39_caseless_mag", "30Rnd_65x39_caseless_green", "11Rnd_45ACP_Mag", "HandGrenade"]]
    ]],

    ["hard", createHashMapFromArray [
        ["weapons", ["arifle_MXM_F", "LMG_Mk200_F", "srifle_EBR_F", "hgun_Pistol_heavy_01_F", "launch_NLAW_F"]],
        ["items", ["FirstAidKit", "NVGoggles", "Rangefinder", "optic_Hamr", "optic_DMS", "muzzle_snds_B", "acc_pointer_IR"]],
        ["magazines", ["30Rnd_65x39_caseless_mag", "200Rnd_65x39_cased_Box", "20Rnd_762x51_Mag", "HandGrenade", "SmokeShellGreen"]]
    ]],

    ["extreme", createHashMapFromArray [
        ["weapons", ["arifle_MX_GL_F", "LMG_Zafir_F", "srifle_GM6_F", "srifle_LRR_F", "launch_RPG32_F"]],
        ["items", ["FirstAidKit", "NVGoggles_OPFOR", "Rangefinder", "optic_LRPS", "optic_DMS", "muzzle_snds_B", "acc_pointer_IR"]],
        ["magazines", ["30Rnd_65x39_caseless_mag", "150Rnd_762x54_Box", "5Rnd_127x108_Mag", "HandGrenade", "SmokeShell"]]
    ]]
];

[3, "Fallback loot tables initialized"] call A3XAI_fnc_log;

true
