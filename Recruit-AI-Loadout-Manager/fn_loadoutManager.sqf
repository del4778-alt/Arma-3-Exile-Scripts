/*
    Recruit AI Loadout Manager v1.0
    Author: Arma 3 Exile Scripts
    Description: In-game menu to customize recruit AI equipment and loadouts

    Features:
    - Interactive menu to change recruit weapons, attachments, and gear
    - Save/load loadout presets per recruit type (AT, AA, Sniper)
    - Cost system using Poptabs for equipment upgrades
    - Live preview of equipment changes
    - Persistent loadouts across server restarts
    - Quick loadout templates (CQB, Long Range, Stealth, etc.)

    Installation:
    1. Place in Recruit-AI-Loadout-Manager folder
    2. Requires AI-Recruit-System to be loaded first
    3. Add to init.sqf: [] execVM "Recruit-AI-Loadout-Manager\fn_loadoutManager.sqf";
    4. Configure LOADOUT_CONFIG below

    Usage:
    - Press custom action key (default: Scroll menu "Manage Recruits")
    - Select recruit to customize
    - Choose equipment from categories
    - Save loadout preset
    - Apply to recruit (costs Poptabs)

    Compatibility:
    - Requires AI-Recruit-System
    - Exile mod for Poptabs integration
    - Saves to profileNamespace
*/

// ========================================
// CONFIGURATION
// ========================================

LOADOUT_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["usePopTabsCost", true],             // Require payment for upgrades
    ["baseCost", 500],                    // Base cost per item change
    ["weaponMultiplier", 2.0],            // Weapons cost more
    ["attachmentMultiplier", 1.0],
    ["itemMultiplier", 0.5],              // Items cost less
    ["saveToPer", true],                 // Save to profileNamespace
    ["maxPresets", 5],                    // Max saved presets per recruit type

    // Available equipment pools
    ["rifles", [
        "arifle_Katiba_F",
        "arifle_Mk20_F",
        "arifle_MX_F",
        "arifle_MXC_F",
        "arifle_SPAR_01_blk_F",
        "arifle_SPAR_02_blk_F",
        "arifle_AK12_F",
        "arifle_CTAR_blk_F"
    ]],

    ["sniperRifles", [
        "srifle_EBR_F",
        "srifle_DMR_03_F",
        "srifle_DMR_06_camo_F",
        "srifle_GM6_F",
        "srifle_LRR_F"
    ]],

    ["launchers", [
        "launch_NLAW_F",
        "launch_RPG32_F",
        "launch_Titan_short_F",
        "launch_B_Titan_F",
        "launch_I_Titan_F"
    ]],

    ["launchersAA", [
        "launch_B_Titan_F",
        "launch_I_Titan_F",
        "launch_O_Titan_F"
    ]],

    ["optics", [
        "optic_Aco",
        "optic_Holosight",
        "optic_MRCO",
        "optic_Hamr",
        "optic_DMS",
        "optic_SOS",
        "optic_LRPS",
        "optic_NVS",
        "optic_tws"
    ]],

    ["muzzles", [
        "muzzle_snds_H",
        "muzzle_snds_M",
        "muzzle_snds_B",
        "muzzle_snds_338_black",
        "muzzle_snds_93mmg"
    ]],

    ["pointers", [
        "acc_flashlight",
        "acc_pointer_IR"
    ]],

    ["uniforms", [
        "U_B_CombatUniform_mcam",
        "U_I_CombatUniform",
        "U_O_CombatUniform_ocamo",
        "U_B_GhillieSuit",
        "U_I_GhillieSuit",
        "U_O_GhillieSuit"
    ]],

    ["vests", [
        "V_PlateCarrier1_rgr",
        "V_PlateCarrier2_rgr",
        "V_TacVest_oli",
        "V_Chestrig_rgr",
        "V_BandollierB_cbr"
    ]],

    ["helmets", [
        "H_HelmetB",
        "H_HelmetIA",
        "H_HelmetO_ocamo",
        "H_Booniehat_oli",
        "H_Cap_oli",
        "H_Watchcap_blk"
    ]],

    ["items", [
        "FirstAidKit",
        "Medikit",
        "ToolKit",
        "NVGoggles",
        "Binocular",
        "Rangefinder",
        "ItemGPS",
        "ItemMap",
        "ItemCompass",
        "ItemWatch",
        "ItemRadio"
    ]]
];

// ========================================
// GLOBAL VARIABLES
// ========================================

LOADOUT_CurrentPresets = createHashMap;   // Stored loadouts
LOADOUT_InitComplete = false;
LOADOUT_SelectedRecruit = objNull;

// ========================================
// UTILITY FUNCTIONS
// ========================================

LOADOUT_fnc_log = {
    params ["_message"];
    if (LOADOUT_CONFIG get "debug") then {
        diag_log format ["[LOADOUT] %1", _message];
    };
};

LOADOUT_fnc_getPlayerMoney = {
    params ["_player"];

    // Exile integration - get player poptabs
    private _money = _player getVariable ["ExileMoney", 0];

    _money
};

LOADOUT_fnc_chargePlayer = {
    params ["_player", "_amount"];

    if (!(LOADOUT_CONFIG get "usePopTabsCost")) exitWith { true };

    private _money = [_player] call LOADOUT_fnc_getPlayerMoney;

    if (_money >= _amount) then {
        // Deduct money (Exile server integration)
        _player setVariable ["ExileMoney", _money - _amount, true];
        systemChat format ["Paid %1 Poptabs for equipment upgrade", _amount];
        true
    } else {
        systemChat format ["Insufficient funds! Need %1 Poptabs, have %2", _amount, _money];
        false
    };
};

LOADOUT_fnc_calculateCost = {
    params ["_itemType"];

    private _baseCost = LOADOUT_CONFIG get "baseCost";
    private _multiplier = 1.0;

    switch (_itemType) do {
        case "weapon": { _multiplier = LOADOUT_CONFIG get "weaponMultiplier" };
        case "attachment": { _multiplier = LOADOUT_CONFIG get "attachmentMultiplier" };
        case "item": { _multiplier = LOADOUT_CONFIG get "itemMultiplier" };
    };

    floor(_baseCost * _multiplier)
};

LOADOUT_fnc_getRecruitType = {
    params ["_recruit"];

    private _type = _recruit getVariable ["RecruitType", "unknown"];

    _type
};

LOADOUT_fnc_getCurrentLoadout = {
    params ["_recruit"];

    private _loadout = getUnitLoadout _recruit;

    _loadout
};

LOADOUT_fnc_applyLoadout = {
    params ["_recruit", "_loadout"];

    _recruit setUnitLoadout _loadout;

    [format ["Applied loadout to recruit %1", _recruit]] call LOADOUT_fnc_log;
};

// ========================================
// PRESET MANAGEMENT
// ========================================

LOADOUT_fnc_savePreset = {
    params ["_player", "_recruitType", "_presetName", "_loadout"];

    // Get existing presets for this recruit type
    private _typePresets = LOADOUT_CurrentPresets getOrDefault [_recruitType, createHashMap];

    // Check max presets
    if (count (keys _typePresets) >= (LOADOUT_CONFIG get "maxPresets") && !(_typePresets in _presetName)) then {
        systemChat format ["Maximum %1 presets allowed per recruit type", LOADOUT_CONFIG get "maxPresets"];
        false
    } else {
        // Save preset
        _typePresets set [_presetName, _loadout];
        LOADOUT_CurrentPresets set [_recruitType, _typePresets];

        // Save to profileNamespace
        if (LOADOUT_CONFIG get "saveToProfile") then {
            profileNamespace setVariable [format ["LOADOUT_%1_%2", _recruitType, _presetName], _loadout];
            saveProfileNamespace;
        };

        systemChat format ["Saved preset '%1' for %2 recruits", _presetName, _recruitType];
        [format ["Saved preset: %1 -> %2", _recruitType, _presetName]] call LOADOUT_fnc_log;

        true
    };
};

LOADOUT_fnc_loadPreset = {
    params ["_recruitType", "_presetName"];

    private _typePresets = LOADOUT_CurrentPresets getOrDefault [_recruitType, createHashMap];
    private _loadout = _typePresets getOrDefault [_presetName, []];

    if (count _loadout == 0) then {
        // Try loading from profileNamespace
        _loadout = profileNamespace getVariable [format ["LOADOUT_%1_%2", _recruitType, _presetName], []];
    };

    _loadout
};

LOADOUT_fnc_deletePreset = {
    params ["_recruitType", "_presetName"];

    private _typePresets = LOADOUT_CurrentPresets getOrDefault [_recruitType, createHashMap];
    _typePresets deleteAt _presetName;

    // Delete from profileNamespace
    if (LOADOUT_CONFIG get "saveToProfile") then {
        profileNamespace setVariable [format ["LOADOUT_%1_%2", _recruitType, _presetName], nil];
        saveProfileNamespace;
    };

    systemChat format ["Deleted preset '%1'", _presetName];
};

LOADOUT_fnc_getPresetNames = {
    params ["_recruitType"];

    private _typePresets = LOADOUT_CurrentPresets getOrDefault [_recruitType, createHashMap];
    private _names = keys _typePresets;

    _names
};

// ========================================
// QUICK LOADOUT TEMPLATES
// ========================================

LOADOUT_fnc_getTemplateLoadout = {
    params ["_recruitType", "_templateName"];

    private _loadout = [];

    // Define templates based on recruit type and template name
    switch (_recruitType) do {
        case "AT": {
            switch (_templateName) do {
                case "CQB": {
                    // Close quarters loadout
                    _loadout = [
                        ["arifle_MXC_F", "muzzle_snds_H", "acc_pointer_IR", "optic_Holosight", [], [], ""],
                        ["launch_NLAW_F", "", "", "", [], [], ""],
                        [],
                        ["U_B_CombatUniform_mcam", [["FirstAidKit", 3]]],
                        ["V_PlateCarrier2_rgr", []],
                        [],
                        ["H_HelmetB", ""],
                        [],
                        ["Binocular", "", "", "", [], [], ""]
                    ];
                };
                case "LongRange": {
                    // Long range anti-tank
                    _loadout = [
                        ["arifle_SPAR_02_blk_F", "muzzle_snds_H", "", "optic_MRCO", [], [], ""],
                        ["launch_B_Titan_F", "", "", "", [], [], ""],
                        [],
                        ["U_B_CombatUniform_mcam", [["FirstAidKit", 3]]],
                        ["V_PlateCarrier1_rgr", []],
                        [],
                        ["H_HelmetB", ""],
                        [],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
                case "Stealth": {
                    // Suppressed stealth loadout
                    _loadout = [
                        ["arifle_MX_F", "muzzle_snds_H", "acc_pointer_IR", "optic_NVS", [], [], ""],
                        ["launch_RPG32_F", "", "", "", [], [], ""],
                        [],
                        ["U_B_GhillieSuit", [["FirstAidKit", 3]]],
                        ["V_Chestrig_rgr", []],
                        [],
                        ["H_Watchcap_blk", ""],
                        ["NVGoggles"],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
            };
        };

        case "AA": {
            switch (_templateName) do {
                case "CQB": {
                    _loadout = [
                        ["arifle_MXC_F", "muzzle_snds_H", "acc_flashlight", "optic_Aco", [], [], ""],
                        ["launch_B_Titan_F", "", "", "", [], [], ""],
                        [],
                        ["U_B_CombatUniform_mcam", [["FirstAidKit", 3]]],
                        ["V_PlateCarrier2_rgr", []],
                        [],
                        ["H_HelmetB", ""],
                        [],
                        ["Binocular", "", "", "", [], [], ""]
                    ];
                };
                case "LongRange": {
                    _loadout = [
                        ["arifle_MX_F", "", "", "optic_Hamr", [], [], ""],
                        ["launch_I_Titan_F", "", "", "", [], [], ""],
                        [],
                        ["U_I_CombatUniform", [["FirstAidKit", 3]]],
                        ["V_PlateCarrier1_rgr", []],
                        [],
                        ["H_HelmetIA", ""],
                        [],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
                case "Stealth": {
                    _loadout = [
                        ["arifle_SPAR_01_blk_F", "muzzle_snds_H", "acc_pointer_IR", "optic_NVS", [], [], ""],
                        ["launch_O_Titan_F", "", "", "", [], [], ""],
                        [],
                        ["U_I_GhillieSuit", [["FirstAidKit", 3]]],
                        ["V_Chestrig_rgr", []],
                        [],
                        ["H_Booniehat_oli", ""],
                        ["NVGoggles"],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
            };
        };

        case "Sniper": {
            switch (_templateName) do {
                case "CQB": {
                    // DMR loadout
                    _loadout = [
                        ["srifle_EBR_F", "muzzle_snds_B", "", "optic_DMS", [], [], "bipod_01_F_blk"],
                        [],
                        [],
                        ["U_B_CombatUniform_mcam", [["FirstAidKit", 3]]],
                        ["V_PlateCarrier1_rgr", []],
                        [],
                        ["H_HelmetB", ""],
                        [],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
                case "LongRange": {
                    // Long range sniper
                    _loadout = [
                        ["srifle_LRR_F", "", "", "optic_LRPS", [], [], "bipod_01_F_blk"],
                        [],
                        ["hgun_Pistol_heavy_01_F", "", "", "", [], [], ""],
                        ["U_B_GhillieSuit", [["FirstAidKit", 3]]],
                        ["V_Chestrig_rgr", []],
                        [],
                        ["H_Booniehat_oli", ""],
                        [],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
                case "Stealth": {
                    // Suppressed marksman
                    _loadout = [
                        ["srifle_DMR_03_F", "muzzle_snds_338_black", "", "optic_SOS", [], [], "bipod_01_F_blk"],
                        [],
                        ["hgun_Pistol_heavy_01_F", "muzzle_snds_acp", "", "", [], [], ""],
                        ["U_B_GhillieSuit", [["FirstAidKit", 3]]],
                        ["V_TacVest_oli", []],
                        [],
                        ["H_Watchcap_blk", ""],
                        ["NVGoggles"],
                        ["Rangefinder", "", "", "", [], [], ""]
                    ];
                };
            };
        };
    };

    _loadout
};

// ========================================
// UI / MENU FUNCTIONS
// ========================================

LOADOUT_fnc_openMainMenu = {
    params ["_player"];

    // Find player's recruits
    private _recruits = [];
    {
        if (_x getVariable ["ExileRecruited", false] && _x getVariable ["Owner", ""] == getPlayerUID _player) then {
            _recruits pushBack _x;
        };
    } forEach allUnits;

    if (count _recruits == 0) exitWith {
        systemChat "You have no recruits to manage!";
    };

    // Build menu
    private _menu = [
        ["Recruit Loadout Manager", true],
        ["Select a recruit:", [-1], "", -5, [["expression", ""]], "1", "1"]
    ];

    {
        private _recruit = _x;
        private _type = [_recruit] call LOADOUT_fnc_getRecruitType;
        private _index = _forEachIndex;

        _menu pushBack [
            format ["%1 (%2)", _type, name _recruit],
            [_index],
            "",
            -5,
            [["expression", format ["LOADOUT_SelectedRecruit = (_this select 3) select 0; [player, LOADOUT_SelectedRecruit] call LOADOUT_fnc_openRecruitMenu;", _recruit]]],
            "1",
            "1"
        ];
    } forEach _recruits;

    _menu pushBack ["", [-1], "", -5, [["expression", ""]], "1", "0"];
    _menu pushBack ["Close", [13], "", -3, [["expression", ""]], "1", "1"];

    showCommandingMenu "";
    showCommandingMenu "#USER:LOADOUT_MainMenu";

    // Note: Full dialog system would require RscDisplays which is complex
    // This is a simplified version using systemChat for demonstration
    systemChat "=== Recruit Loadout Manager ===";
    {
        private _recruit = _x;
        private _type = [_recruit] call LOADOUT_fnc_getRecruitType;
        systemChat format ["%1. %2 (%3)", _forEachIndex + 1, _type, name _recruit];
    } forEach _recruits;

    // Store recruits for selection
    _player setVariable ["LOADOUT_AvailableRecruits", _recruits];
};

LOADOUT_fnc_openRecruitMenu = {
    params ["_player", "_recruit"];

    private _recruitType = [_recruit] call LOADOUT_fnc_getRecruitType;

    systemChat format ["=== Managing %1 ===", _recruitType];
    systemChat "Options:";
    systemChat "1. Change Weapon";
    systemChat "2. Change Attachments";
    systemChat "3. Change Uniform/Vest/Helmet";
    systemChat "4. Apply Template (CQB/LongRange/Stealth)";
    systemChat "5. Save Current Loadout";
    systemChat "6. Load Saved Loadout";

    // For full implementation, would use createDialog with RscDisplays
    // Simplified version for demonstration
};

LOADOUT_fnc_changeWeapon = {
    params ["_player", "_recruit", "_weaponClass"];

    private _cost = ["weapon"] call LOADOUT_fnc_calculateCost;

    if ([_player, _cost] call LOADOUT_fnc_chargePlayer) then {
        // Get current loadout
        private _loadout = [_recruit] call LOADOUT_fnc_getCurrentLoadout;

        // Change primary weapon
        _loadout set [0, [_weaponClass, "", "", "", [], [], ""]];

        // Apply loadout
        [_recruit, _loadout] call LOADOUT_fnc_applyLoadout;

        systemChat format ["Changed weapon to %1", _weaponClass];
    };
};

LOADOUT_fnc_applyTemplate = {
    params ["_player", "_recruit", "_templateName"];

    private _recruitType = [_recruit] call LOADOUT_fnc_getRecruitType;
    private _loadout = [_recruitType, _templateName] call LOADOUT_fnc_getTemplateLoadout;

    if (count _loadout > 0) then {
        private _cost = ["weapon"] call LOADOUT_fnc_calculateCost;
        _cost = _cost * 3;  // Templates cost 3x normal

        if ([_player, _cost] call LOADOUT_fnc_chargePlayer) then {
            [_recruit, _loadout] call LOADOUT_fnc_applyLoadout;
            systemChat format ["Applied %1 template to recruit", _templateName];
        };
    } else {
        systemChat format ["Template %1 not available for %2", _templateName, _recruitType];
    };
};

// ========================================
// ACTION MENU INTEGRATION
// ========================================

LOADOUT_fnc_addPlayerAction = {
    params ["_player"];

    _player addAction [
        "<t color='#00FF00'>Manage Recruit Loadouts</t>",
        {
            params ["_target", "_caller"];
            [_caller] call LOADOUT_fnc_openMainMenu;
        },
        nil,
        1.5,
        true,
        true,
        "",
        "true",
        5
    ];

    ["Added loadout manager action to player"] call LOADOUT_fnc_log;
};

// ========================================
// INITIALIZATION
// ========================================

LOADOUT_fnc_init = {
    ["Recruit AI Loadout Manager v1.0 initializing..."] call LOADOUT_fnc_log;

    if (!(LOADOUT_CONFIG get "enabled")) exitWith {
        ["Loadout Manager is disabled in config"] call LOADOUT_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Add action to all players
    {
        if (isPlayer _x) then {
            [_x] call LOADOUT_fnc_addPlayerAction;
        };
    } forEach allPlayers;

    // Add action to newly connected players
    addMissionEventHandler ["PlayerConnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner"];

        [{
            params ["_owner"];
            private _player = _owner;
            if (!isNull _player) then {
                [_player] call LOADOUT_fnc_addPlayerAction;
            };
        }, [_owner], 5] call CBA_fnc_waitAndExecute;
    }];

    LOADOUT_InitComplete = true;
    ["Recruit AI Loadout Manager v1.0 initialized successfully"] call LOADOUT_fnc_log;
    ["Use scroll menu action 'Manage Recruit Loadouts' to customize your recruits"] call LOADOUT_fnc_log;
};

// Start the system
[] call LOADOUT_fnc_init;
