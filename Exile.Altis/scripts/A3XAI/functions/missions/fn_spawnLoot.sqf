/*
    A3XAI Elite - Spawn Loot
    Creates and fills a loot crate

    Parameters:
        0: OBJECT - Loot container
        1: STRING - Difficulty level (default: "medium")
        2: STRING - Mission type (optional, affects loot table)

    Returns:
        BOOL - Success
*/

params ["_container", ["_difficulty", "medium"], ["_missionType", ""]];

if (isNull _container) exitWith {false};

// Clear container first
clearWeaponCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearItemCargoGlobal _container;
clearBackpackCargoGlobal _container;

// Determine loot quantity based on difficulty
private _lootMultiplier = switch (_difficulty) do {
    case "easy": {0.7};
    case "medium": {1.0};
    case "hard": {1.5};
    case "extreme": {2.0};
    default {1.0};
};

// Use Exile trader tables if available
private _useExile = !A3XAI_useFallbackLoot;

// Add weapons (2-6 based on difficulty)
private _weaponCount = floor((2 + random 4) * _lootMultiplier);

for "_i" from 1 to _weaponCount do {
    private _weapon = "";

    if (_useExile) then {
        private _category = selectRandom ["Rifles", "LMG", "Sniperrifles"];
        // ✅ FIX: Use missionConfigFile for mission-defined configs
        private _weapons = getArray (missionConfigFile >> "CfgExileArsenal" >> _category);
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

    if (_weapon != "") then {
        _container addWeaponCargoGlobal [_weapon, 1];

        // Add magazines for weapon
        private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
        if (count _magazines > 0) then {
            _container addMagazineCargoGlobal [_magazines select 0, 3 + floor(random 3)];
        };
    };
};

// Add items (4-10 based on difficulty)
private _itemCount = floor((4 + random 6) * _lootMultiplier);

private _itemCategories = if (_useExile) then {
    // ✅ FIX: Use missionConfigFile for mission-defined configs
    getArray (missionConfigFile >> "CfgExileArsenal" >> "Items")
} else {
    A3XAI_fallbackLoot getOrDefault ["items", []]
};

for "_i" from 1 to _itemCount do {
    if (count _itemCategories > 0) then {
        private _item = selectRandom _itemCategories;
        _container addItemCargoGlobal [_item, 1];
    };
};

// Add backpacks (1-3)
private _backpackCount = 1 + floor(random 2 * _lootMultiplier);

private _backpacks = if (_useExile) then {
    // ✅ FIX: Use missionConfigFile for mission-defined configs
    getArray (missionConfigFile >> "CfgExileArsenal" >> "Backpacks")
} else {
    A3XAI_fallbackLoot getOrDefault ["backpacks", []]
};

for "_i" from 1 to _backpackCount do {
    if (count _backpacks > 0) then {
        _container addBackpackCargoGlobal [selectRandom _backpacks, 1];
    };
};

// Add medical supplies
_container addItemCargoGlobal ["FirstAidKit", 3 + floor(random 5 * _lootMultiplier)];

// Add grenades/explosives for higher difficulties
if (_difficulty in ["hard", "extreme"]) then {
    _container addMagazineCargoGlobal ["HandGrenade", 2 + floor(random 3)];
    _container addMagazineCargoGlobal ["SmokeShell", 2];
};

// Add special loot based on mission type
switch (_missionType) do {
    case "convoy": {
        // More ammo
        _container addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 10];
        _container addMagazineCargoGlobal ["200Rnd_65x39_cased_Box", 3];
    };

    case "crash": {
        // Pilot gear, flares
        _container addItemCargoGlobal ["NVGoggles", 1];
        _container addMagazineCargoGlobal ["Chemlight_green", 5];
    };

    case "camp": {
        // Building supplies, tools
        _container addItemCargoGlobal ["ToolKit", 1];
        _container addItemCargoGlobal ["Binocular", 1];
    };

    case "rescue": {
        // Medical supplies
        _container addItemCargoGlobal ["Medikit", 2];
        _container addItemCargoGlobal ["FirstAidKit", 10];
    };
};

// Make container lootable
_container setVariable ["A3XAI_lootCrate", true, true];

true
