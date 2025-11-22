/*
    A3XAI Elite - Spawn Loot
    Creates and fills a loot crate

    NOTE: Uses cached item lists from fn_validateLootTables.sqf which
    scans Exile's flat CfgExileArsenal structure by classname prefix.

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
        // Build weapon pool from cached lists
        private _weaponPool = [];
        if (!isNil "A3XAI_exileRifles") then {_weaponPool append A3XAI_exileRifles};
        if (!isNil "A3XAI_exileLMGs") then {_weaponPool append A3XAI_exileLMGs};
        if (!isNil "A3XAI_exileSnipers" && {_difficulty in ["hard", "extreme"]}) then {
            _weaponPool append A3XAI_exileSnipers
        };

        if (count _weaponPool > 0) then {
            _weapon = selectRandom _weaponPool;
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

// Add pistols (1-2)
private _pistolCount = 1 + floor(random 1 * _lootMultiplier);
for "_i" from 1 to _pistolCount do {
    private _pistol = "";

    if (_useExile && {!isNil "A3XAI_exilePistols"} && {count A3XAI_exilePistols > 0}) then {
        _pistol = selectRandom A3XAI_exilePistols;
    } else {
        private _pistols = A3XAI_fallbackLoot getOrDefault ["pistols", []];
        if (count _pistols > 0) then {
            _pistol = selectRandom _pistols;
        };
    };

    if (_pistol != "") then {
        _container addWeaponCargoGlobal [_pistol, 1];
        private _magazines = getArray (configFile >> "CfgWeapons" >> _pistol >> "magazines");
        if (count _magazines > 0) then {
            _container addMagazineCargoGlobal [_magazines select 0, 2 + floor(random 2)];
        };
    };
};

// Add vests (1-3)
private _vestCount = 1 + floor(random 2 * _lootMultiplier);
if (_useExile && {!isNil "A3XAI_exileVests"} && {count A3XAI_exileVests > 0}) then {
    for "_i" from 1 to _vestCount do {
        _container addItemCargoGlobal [selectRandom A3XAI_exileVests, 1];
    };
} else {
    private _vests = A3XAI_fallbackLoot getOrDefault ["vests", []];
    if (count _vests > 0) then {
        for "_i" from 1 to _vestCount do {
            _container addItemCargoGlobal [selectRandom _vests, 1];
        };
    };
};

// Add uniforms (1-2)
private _uniformCount = 1 + floor(random 1 * _lootMultiplier);
if (_useExile && {!isNil "A3XAI_exileUniforms"} && {count A3XAI_exileUniforms > 0}) then {
    for "_i" from 1 to _uniformCount do {
        _container addItemCargoGlobal [selectRandom A3XAI_exileUniforms, 1];
    };
} else {
    private _uniforms = A3XAI_fallbackLoot getOrDefault ["uniforms", []];
    if (count _uniforms > 0) then {
        for "_i" from 1 to _uniformCount do {
            _container addItemCargoGlobal [selectRandom _uniforms, 1];
        };
    };
};

// Add backpacks (1-3)
private _backpackCount = 1 + floor(random 2 * _lootMultiplier);
if (_useExile && {!isNil "A3XAI_exileBackpacks"} && {count A3XAI_exileBackpacks > 0}) then {
    for "_i" from 1 to _backpackCount do {
        _container addBackpackCargoGlobal [selectRandom A3XAI_exileBackpacks, 1];
    };
} else {
    private _backpacks = A3XAI_fallbackLoot getOrDefault ["backpacks", []];
    if (count _backpacks > 0) then {
        for "_i" from 1 to _backpackCount do {
            _container addBackpackCargoGlobal [selectRandom _backpacks, 1];
        };
    };
};

// Add medical supplies
_container addItemCargoGlobal ["FirstAidKit", 3 + floor(random 5 * _lootMultiplier)];

// Add grenades/explosives for higher difficulties
if (_difficulty in ["hard", "extreme"]) then {
    _container addMagazineCargoGlobal ["HandGrenade", 2 + floor(random 3)];
    _container addMagazineCargoGlobal ["SmokeShell", 2];
};

// ============================================================
// EXILE CONCRETE BUILDING KITS (high value items for convoys)
// ============================================================
private _exileConcreteKits = [
    "Exile_Item_ConcreteDoorKit",
    "Exile_Item_ConcreteDoorwayKit",
    "Exile_Item_ConcreteFloorKit",
    "Exile_Item_ConcreteFloorPortKit",
    "Exile_Item_ConcreteGateKit",
    "Exile_Item_ConcreteStairsKit",
    "Exile_Item_ConcreteSupportKit",
    "Exile_Item_ConcreteWallKit",
    "Exile_Item_ConcreteWindowKit"
];

// Add special loot based on mission type
switch (_missionType) do {
    case "convoy": {
        // Police convoy loot - ammo + Exile construction kits
        _container addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 10];
        _container addMagazineCargoGlobal ["200Rnd_65x39_cased_Box", 3];

        // Add 1-3 random concrete kits (valuable building supplies)
        private _concreteCount = 1 + floor(random 2 * _lootMultiplier);
        for "_i" from 1 to _concreteCount do {
            private _kit = selectRandom _exileConcreteKits;
            _container addItemCargoGlobal [_kit, 1];
        };

        // Chance for high-tier concrete kit
        if (random 1 < 0.3) then {
            _container addItemCargoGlobal ["Exile_Item_ConcreteGateKit", 1];
        };
    };

    case "crash": {
        // Pilot gear, flares
        _container addItemCargoGlobal ["NVGoggles", 1];
        _container addMagazineCargoGlobal ["Chemlight_green", 5];
    };

    case "camp": {
        // Building supplies, tools + basic concrete kits
        _container addItemCargoGlobal ["ToolKit", 1];
        _container addItemCargoGlobal ["Binocular", 1];

        // Add 1 random concrete kit
        _container addItemCargoGlobal [selectRandom _exileConcreteKits, 1];
    };

    case "rescue": {
        // Medical supplies
        _container addItemCargoGlobal ["Medikit", 2];
        _container addItemCargoGlobal ["FirstAidKit", 10];
    };

    case "supplyDrop": {
        // Extra weapons and high value items + concrete kits
        _container addItemCargoGlobal ["NVGoggles", 2];
        _container addItemCargoGlobal ["Rangefinder", 1];

        // Supply drops have more building supplies (2-4 kits)
        private _concreteCount = 2 + floor(random 2 * _lootMultiplier);
        for "_i" from 1 to _concreteCount do {
            _container addItemCargoGlobal [selectRandom _exileConcreteKits, 1];
        };
    };

    case "outpost": {
        // Military supplies + construction materials
        _container addItemCargoGlobal ["NVGoggles", 3];
        _container addMagazineCargoGlobal ["HandGrenade", 5];
        _container addMagazineCargoGlobal ["200Rnd_65x39_cased_Box", 5];

        // Outposts have concrete building supplies (2-4 kits)
        private _concreteCount = 2 + floor(random 2 * _lootMultiplier);
        for "_i" from 1 to _concreteCount do {
            _container addItemCargoGlobal [selectRandom _exileConcreteKits, 1];
        };
    };

    case "dyce";
    case "armedConvoy";
    case "troopConvoy";
    case "highwayPatrol";
    case "supplyTruck": {
        // DyCE Police convoy loot - heavy on building supplies
        _container addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 8];
        _container addMagazineCargoGlobal ["200Rnd_65x39_cased_Box", 2];

        // Police convoys transport confiscated building materials (2-5 kits)
        private _concreteCount = 2 + floor(random 3 * _lootMultiplier);
        for "_i" from 1 to _concreteCount do {
            private _kit = selectRandom _exileConcreteKits;
            _container addItemCargoGlobal [_kit, 1];
        };

        // supplyTruck gets extra kits
        if (_missionType == "supplyTruck") then {
            for "_i" from 1 to 3 do {
                _container addItemCargoGlobal [selectRandom _exileConcreteKits, 1];
            };
            // Guaranteed high-value items
            _container addItemCargoGlobal ["Exile_Item_ConcreteGateKit", 1];
            _container addItemCargoGlobal ["Exile_Item_ConcreteStairsKit", 1];
        };
    };
};

// Make container lootable
_container setVariable ["A3XAI_lootCrate", true, true];

true
