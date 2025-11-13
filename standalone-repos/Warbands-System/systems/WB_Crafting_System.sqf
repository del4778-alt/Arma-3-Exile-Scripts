/**
 * Warbands Crafting & Modding System
 * Fallout 4 weapon and armor modification
 */

if (!hasInterface) exitWith {};

/**
 * Weapon Mod Categories
 */
WB_WeaponMods = createHashMapFromArray [
    ["Optics", [
        ["Red Dot Sight", "optic_Aco", 1, 50],
        ["Holographic Sight", "optic_Holosight", 2, 150],
        ["ACOG Scope", "optic_Hamr", 2, 200],
        ["Long Range Scope", "optic_SOS", 3, 350],
        ["Thermal Scope", "optic_tws", 4, 750]
    ]],

    ["Muzzle", [
        ["Flash Hider", "muzzle_snds_H", 1, 75],
        ["Suppressor", "muzzle_snds_B", 2, 250],
        ["Advanced Suppressor", "muzzle_snds_H_MG", 3, 400],
        ["Tactical Suppressor", "muzzle_snds_H_SW", 4, 650]
    ]],

    ["Underbarrel", [
        ["Vertical Grip", "bipod_01_F_snd", 1, 100],
        ["Tactical Flashlight", "acc_flashlight", 1, 50],
        ["Laser Pointer", "acc_pointer_IR", 2, 150],
        ["Bipod", "bipod_02_F_hex", 3, 300]
    ]],

    ["Magazine", [
        ["Extended Mag", "", 2, 200],
        ["Fast Mag", "", 2, 175],
        ["Drum Magazine", "", 3, 400],
        ["Quad Stack Mag", "", 4, 600]
    ]]
];

/**
 * Armor Mod Categories
 */
WB_ArmorMods = createHashMapFromArray [
    ["Chest", [
        ["Ballistic Weave Mk1", "+10% damage resistance", 1, 150],
        ["Ballistic Weave Mk2", "+20% damage resistance", 2, 300],
        ["Ballistic Weave Mk3", "+30% damage resistance", 3, 500],
        ["Ballistic Weave Mk4", "+40% damage resistance", 4, 850]
    ]],

    ["Helmet", [
        ["Reinforced Padding", "+5% headshot protection", 1, 100],
        ["Tactical Helmet Liner", "+10% headshot protection", 2, 250],
        ["Combat Helmet Upgrade", "+15% headshot protection", 3, 450],
        ["Master Helmet Mod", "+20% headshot protection, thermal vision", 4, 900]
    ]],

    ["Special", [
        ["Pocketed", "+10 carry weight", 1, 125],
        ["Deep Pocketed", "+20 carry weight", 2, 275],
        ["Lightweight", "-25% armor weight", 2, 200],
        ["Stealth", "+15% harder to detect", 3, 400],
        ["Lead Lined", "+25 rad resistance", 2, 300]
    ]]
];

/**
 * Crafting materials
 */
WB_CraftingMaterials = createHashMapFromArray [
    ["Steel", 0],
    ["Aluminum", 0],
    ["Copper", 0],
    ["Circuitry", 0],
    ["Adhesive", 0],
    ["Screws", 0],
    ["Gears", 0],
    ["Springs", 0],
    ["Nuclear Material", 0],
    ["Fiber Optics", 0]
];

/**
 * Open weapon workbench
 */
WB_fnc_openWeaponWorkbench = {
    createDialog "WB_WeaponWorkbench";

    // Populate weapon list
    private _weaponList = [];
    {
        private _weapon = _x;
        _weaponList pushBack [getText(configFile >> "CfgWeapons" >> _weapon >> "displayName"), _weapon];
    } forEach (weapons player);

    // Display UI
    private _display = findDisplay 24100;
    if (!isNull _display) then {
        private _listbox = _display displayCtrl 1500;

        {
            _x params ["_name", "_className"];
            private _index = lbAdd [1500, _name];
            lbSetData [1500, _index, _className];
        } forEach _weaponList;
    };
};

/**
 * Apply weapon mod
 */
WB_fnc_applyWeaponMod = {
    params ["_weapon", "_modCategory", "_modIndex"];

    private _mods = WB_WeaponMods get _modCategory;
    if (isNil "_mods") exitWith {false};

    private _mod = _mods select _modIndex;
    _mod params ["_modName", "_modClass", "_rankRequired", "_cost"];

    // Check Gun Nut rank
    private _gunNutRank = player getVariable ["WB_Perk_GunNut", 0];
    if (_gunNutRank < _rankRequired) exitWith {
        ["ErrorTitleAndText", ["Insufficient Skill", format["You need Gun Nut Rank %1", _rankRequired]]] call ExileClient_gui_toaster_addTemplateToast;
        false
    };

    // Check materials
    private _playerMoney = player getVariable ["ExileMoney", 0];
    if (_playerMoney < _cost) exitWith {
        ["ErrorTitleAndText", ["Insufficient Caps", format["You need %1 caps", _cost]]] call ExileClient_gui_toaster_addTemplateToast;
        false
    };

    // Apply mod
    player removePrimaryWeaponItem _weapon;

    switch (_modCategory) do {
        case "Optics": {
            player addPrimaryWeaponItem _modClass;
        };
        case "Muzzle": {
            player addPrimaryWeaponItem _modClass;
        };
        case "Underbarrel": {
            player addPrimaryWeaponItem _modClass;
        };
        case "Magazine": {
            // Magazine capacity bonus (handled via event handler)
            _weapon setVariable ["WB_MagazineMod", _modName, true];
        };
    };

    // Deduct cost
    player setVariable ["ExileMoney", _playerMoney - _cost, true];

    ["SuccessTitleAndText", ["Mod Applied", format["Installed %1 on %2", _modName, _weapon]]] call ExileClient_gui_toaster_addTemplateToast;
    playSound "FD_Finish_F";

    true
};

/**
 * Scrap item for materials
 */
WB_fnc_scrapItem = {
    params ["_item"];

    private _scrapperRank = player getVariable ["WB_Perk_Scrapper", 0];
    private _baseYield = 1;
    private _bonusYield = 0;

    if (_scrapperRank >= 1) then {
        _bonusYield = 1; // Double materials
    };

    if (_scrapperRank >= 2) then {
        // Chance for rare components
        if (random 100 < 25) then {
            private _rareMaterial = selectRandom ["Circuitry", "Nuclear Material", "Fiber Optics"];
            private _currentAmount = WB_CraftingMaterials get _rareMaterial;
            WB_CraftingMaterials set [_rareMaterial, _currentAmount + 1];

            hint format["Found rare component: %1", _rareMaterial];
        };
    };

    // Standard materials
    private _materials = ["Steel", "Aluminum", "Screws"];
    {
        private _currentAmount = WB_CraftingMaterials get _x;
        WB_CraftingMaterials set [_x, _currentAmount + _baseYield + _bonusYield];
    } forEach _materials;

    // Remove item
    player removeItem _item;

    ["InfoTitleAndText", ["Item Scrapped", format["Gained %1 materials", _baseYield + _bonusYield]]] call ExileClient_gui_toaster_addTemplateToast;

    true
};

/**
 * Craft weapon from scratch
 */
WB_fnc_craftWeapon = {
    params ["_weaponClass"];

    private _gunNutRank = player getVariable ["WB_Perk_GunNut", 0];
    if (_gunNutRank < 3) exitWith {
        hint "You need Gun Nut Rank 3 to craft weapons";
        false
    };

    // Material requirements (example)
    private _required = createHashMapFromArray [
        ["Steel", 15],
        ["Screws", 8],
        ["Springs", 4],
        ["Gears", 3]
    ];

    // Check materials
    private _canCraft = true;
    {
        private _need = _y;
        private _have = WB_CraftingMaterials get _x;

        if (_have < _need) then {
            _canCraft = false;
            hint format["Not enough %1 (need %2, have %3)", _x, _need, _have];
        };
    } forEach _required;

    if (!_canCraft) exitWith {false};

    // Consume materials
    {
        private _need = _y;
        private _have = WB_CraftingMaterials get _x;
        WB_CraftingMaterials set [_x, _have - _need];
    } forEach _required;

    // Give weapon
    player addWeapon _weaponClass;

    ["SuccessTitleAndText", ["Weapon Crafted", _weaponClass]] call ExileClient_gui_toaster_addTemplateToast;

    true
};

/**
 * Repair weapon (restore durability)
 */
WB_fnc_repairWeapon = {
    params ["_weapon"];

    private _gunNutRank = player getVariable ["WB_Perk_GunNut", 0];
    private _cost = 100 / (1 + (_gunNutRank * 0.2)); // Gun Nut reduces repair cost

    private _playerMoney = player getVariable ["ExileMoney", 0];
    if (_playerMoney < _cost) exitWith {
        hint format["Need %1 caps to repair", floor _cost];
        false
    };

    player setVariable ["ExileMoney", _playerMoney - _cost, true];

    // Restore weapon (Arma 3 weapons don't degrade, but we can simulate)
    _weapon setVariable ["WB_WeaponCondition", 100, true];

    hint "Weapon repaired!";
    true
};

/**
 * Add crafting bench interaction
 */
[] spawn {
    while {true} do {
        sleep 1;

        private _nearWorkbenches = nearestObjects [player, ["Land_Workbench_01_F", "Land_Workbench_01_F"], 5];

        {
            if (player distance _x < 3 && !(_x getVariable ["WB_ActionAdded", false])) then {
                _x addAction [
                    "<t color='#00FF00'>Open Weapon Workbench</t>",
                    {[] call WB_fnc_openWeaponWorkbench},
                    [],
                    6,
                    true,
                    true,
                    "",
                    "true",
                    3
                ];

                _x addAction [
                    "<t color='#00BFFF'>Scrap Weapons</t>",
                    {
                        private _weapons = weapons player;
                        if (count _weapons == 0) exitWith {hint "No weapons to scrap"};

                        {
                            [_x] call WB_fnc_scrapItem;
                        } forEach _weapons;
                    },
                    [],
                    5,
                    true,
                    true,
                    "",
                    "true",
                    3
                ];

                _x setVariable ["WB_ActionAdded", true];
            };
        } forEach _nearWorkbenches;
    };
};

diag_log "[WB] Crafting system initialized";
