/*
    A3XAI Elite - Equip AI Unit (POLICE FORCE EDITION)
    Equips AI with police/gendarmerie gear - hunting escaped prisoners!

    All A3XAI units are dressed as police/gendarmerie since:
    - Player side is RESISTANCE (escaped prisoners)
    - AI side is EAST (police hunting them down)

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit) exitWith {false};

// Remove all gear first (v3.11: Using optimized 2.20 commands where available)
removeAllWeapons _unit;
removeAllItems _unit;
removeAllAssignedItems _unit;
removeAllMagazines _unit;  // v3.11: Arma 2.20 command - faster than looping
removeUniform _unit;
removeVest _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeGoggles _unit;

// ============================================================
// POLICE FORCE UNIFORMS (All black/dark blue)
// ============================================================
private _policeUniforms = [
    // Gendarmerie (primary police force)
    "U_B_GEN_Commander_F",          // Gendarmerie Commander - black
    "U_B_GEN_Soldier_F",            // Gendarmerie Soldier - black

    // CTRG Black Ops (tactical police)
    "U_B_CTRG_Soldier_F",           // CTRG Black uniform
    "U_B_CTRG_Soldier_2_F",         // CTRG Black variant
    "U_B_CTRG_Soldier_3_F",         // CTRG Black variant

    // Combat uniforms (dark variants)
    "U_B_CombatUniform_mcam_vest",  // Combat with vest
    "U_I_CombatUniform_shortsleeve", // Short sleeve dark

    // Special units
    "U_B_Wetsuit",                  // Tactical wetsuit (SWAT style)
    "U_B_survival_uniform"          // Survival uniform dark
];

// ============================================================
// POLICE VESTS (Tactical/Plate carriers - black)
// ============================================================
private _policeVests = [
    // Plate carriers (heavy tactical)
    "V_PlateCarrier1_blk",          // Plate Carrier Black
    "V_PlateCarrier2_blk",          // Plate Carrier Black v2
    "V_PlateCarrierSpec_blk",       // Special Plate Carrier Black
    "V_PlateCarrierGL_blk",         // Plate Carrier GL Black

    // Tactical vests
    "V_TacVest_blk",                // Tactical Vest Black
    "V_TacVestIR_blk",              // Tactical Vest IR Black
    "V_TacVestCamo_khk",            // Tactical Vest (fallback)

    // Chest rigs
    "V_Chestrig_blk",               // Chest Rig Black
    "V_HarnessO_brn",               // Harness (tactical)
    "V_HarnessOGL_brn"              // Harness with GL
];

// ============================================================
// POLICE HEADGEAR (Caps, berets, helmets)
// ============================================================
private _policeHeadgear = [
    // Berets (classic police/military)
    "H_Beret_blk",                  // Black Beret
    "H_Beret_gen_F",                // Gendarmerie Beret

    // Caps
    "H_Cap_blk",                    // Black Cap
    "H_Cap_blk_Raven",              // Black Cap Raven
    "H_Cap_headphones",             // Cap with headphones

    // Military caps
    "H_MilCap_gen_F",               // Gendarmerie Military Cap
    "H_MilCap_blue",                // Blue Military Cap

    // Combat helmets (tactical units)
    "H_HelmetB_plain_blk",          // Combat Helmet Black
    "H_HelmetSpecB_blk",            // Special Helmet Black
    "H_HelmetB_TI_tna_F",           // Tactical Helmet

    // Balaclavas (SWAT style)
    "H_Booniehat_khk_hs",           // Boonie (undercover)
    "H_Watchcap_blk"                // Watch Cap Black
];

// ============================================================
// POLICE GLASSES (Tactical/Aviator)
// ============================================================
private _policeGlasses = [
    "G_Aviator",                    // Aviator Sunglasses (classic cop)
    "G_Tactical_Clear",             // Tactical Glasses Clear
    "G_Tactical_Black",             // Tactical Glasses Black
    "G_Combat",                     // Combat Goggles
    "G_Lowprofile",                 // Low Profile Glasses
    "G_Shades_Black",               // Black Shades
    "G_Balaclava_blk"               // Balaclava (SWAT)
];

// ============================================================
// POLICE BACKPACKS (Tactical black)
// ============================================================
private _policeBackpacks = [
    "B_AssaultPack_blk",            // Assault Pack Black
    "B_Kitbag_cbr",                 // Kitbag
    "B_TacticalPack_blk",           // Tactical Pack Black
    "B_FieldPack_blk",              // Field Pack Black
    "B_Carryall_cbr",               // Carryall
    "B_Bergen_blk"                  // Bergen Black
];

// ============================================================
// APPLY POLICE UNIFORM
// ============================================================
private _uniform = selectRandom _policeUniforms;
_unit forceAddUniform _uniform;

// Add vest
private _vest = selectRandom _policeVests;
_unit addVest _vest;

// Add headgear
private _headgear = selectRandom _policeHeadgear;
_unit addHeadgear _headgear;

// Add glasses (70% chance)
if (random 1 < 0.7) then {
    private _glasses = selectRandom _policeGlasses;
    _unit addGoggles _glasses;
};

// Add backpack for hard+ difficulty
if (_difficulty in ["hard", "extreme"]) then {
    private _backpack = selectRandom _policeBackpacks;
    _unit addBackpack _backpack;
};

// ============================================================
// WEAPONS (Use Exile trader tables or fallback)
// ============================================================
private _useExile = !A3XAI_useFallbackLoot;

// Get weapon from cached lists
private _weapon = "";
if (_useExile) then {
    private _weapons = switch (_difficulty) do {
        case "easy": {
            if (!isNil "A3XAI_exileRifles" && {count A3XAI_exileRifles > 0}) then {
                A3XAI_exileRifles
            } else {[]};
        };
        case "medium": {
            private _pool = [];
            if (!isNil "A3XAI_exileRifles") then {_pool append A3XAI_exileRifles};
            if (!isNil "A3XAI_exileLMGs" && {random 1 < 0.3}) then {_pool append A3XAI_exileLMGs};
            _pool
        };
        case "hard": {
            private _pool = [];
            if (!isNil "A3XAI_exileRifles") then {_pool append A3XAI_exileRifles};
            if (!isNil "A3XAI_exileLMGs" && {random 1 < 0.4}) then {_pool append A3XAI_exileLMGs};
            if (!isNil "A3XAI_exileSnipers" && {random 1 < 0.3}) then {_pool append A3XAI_exileSnipers};
            _pool
        };
        case "extreme": {
            private _pool = [];
            if (!isNil "A3XAI_exileLMGs") then {_pool append A3XAI_exileLMGs};
            if (!isNil "A3XAI_exileSnipers") then {_pool append A3XAI_exileSnipers};
            if (!isNil "A3XAI_exileRifles" && {random 1 < 0.3}) then {_pool append A3XAI_exileRifles};
            _pool
        };
        default {
            if (!isNil "A3XAI_exileRifles") then {A3XAI_exileRifles} else {[]}
        };
    };

    if (count _weapons > 0) then {
        _weapon = selectRandom _weapons;
    };
} else {
    private _lootPool = A3XAI_fallbackLootPools getOrDefault [_difficulty, A3XAI_fallbackLootPools get "medium"];
    private _weapons = _lootPool getOrDefault ["weapons", []];
    if (count _weapons > 0) then {
        _weapon = selectRandom _weapons;
    };
};

// Add weapon and magazines
if (_weapon != "") then {
    private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
    if (count _magazines > 0) then {
        private _magazine = _magazines select 0;
        for "_i" from 0 to 5 do {
            _unit addMagazine _magazine;
        };
    };
    _unit addWeapon _weapon;
};

// Add pistol for higher difficulties
if (_difficulty in ["medium", "hard", "extreme"]) then {
    private _pistol = "";

    if (_useExile) then {
        if (!isNil "A3XAI_exilePistols" && {count A3XAI_exilePistols > 0}) then {
            _pistol = selectRandom A3XAI_exilePistols;
        };
    } else {
        private _pistols = A3XAI_fallbackLoot getOrDefault ["pistols", []];
        if (count _pistols > 0) then {
            _pistol = selectRandom _pistols;
        };
    };

    if (_pistol != "") then {
        private _pistolMags = getArray (configFile >> "CfgWeapons" >> _pistol >> "magazines");
        if (count _pistolMags > 0) then {
            for "_i" from 0 to 2 do {
                _unit addMagazine (_pistolMags select 0);
            };
        };
        _unit addWeapon _pistol;
    };
};

// Add launcher for extreme difficulty (low chance)
if (_difficulty == "extreme" && random 1 < 0.2) then {
    private _launcher = "";

    if (_useExile) then {
        if (!isNil "A3XAI_exileLaunchers" && {count A3XAI_exileLaunchers > 0}) then {
            _launcher = selectRandom A3XAI_exileLaunchers;
        };
    } else {
        private _launchers = A3XAI_fallbackLoot getOrDefault ["launchers", []];
        if (count _launchers > 0) then {
            _launcher = selectRandom _launchers;
        };
    };

    if (_launcher != "") then {
        private _launcherMags = getArray (configFile >> "CfgWeapons" >> _launcher >> "magazines");
        if (count _launcherMags > 0) then {
            _unit addMagazine (_launcherMags select 0);
        };
        _unit addWeapon _launcher;
    };
};

// ============================================================
// POLICE EQUIPMENT
// ============================================================

// FirstAidKit
_unit addItem "FirstAidKit";

// Map/GPS for hard+ (police have better equipment)
if (_difficulty in ["hard", "extreme"]) then {
    _unit linkItem "ItemMap";
    _unit linkItem "ItemGPS";
    _unit linkItem "NVGoggles_OPFOR";  // Police have NVGs
} else {
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
};

// Radio (all police have radios)
_unit linkItem "ItemRadio";

// Grenades (flashbangs for police)
_unit addMagazine "HandGrenade";
if (_difficulty in ["hard", "extreme"]) then {
    _unit addMagazine "SmokeShell";
    _unit addMagazine "SmokeShellGreen";
};

// Mark as police unit
_unit setVariable ["A3XAI_policeUnit", true];

true
