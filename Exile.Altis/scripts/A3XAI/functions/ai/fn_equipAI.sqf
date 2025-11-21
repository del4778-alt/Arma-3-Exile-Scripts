/*
    A3XAI Elite - Equip AI Unit
    Equips AI with weapons and gear based on difficulty

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit) exitWith {false};

// Remove all gear first
removeAllWeapons _unit;
removeAllItems _unit;
removeAllAssignedItems _unit;
removeUniform _unit;
removeVest _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeGoggles _unit;

// Use Exile trader tables if available, otherwise fallback
private _useExile = !A3XAI_useFallbackLoot;

// Get weapon
private _weapon = "";
if (_useExile) then {
    private _weaponCat = switch (_difficulty) do {
        case "easy": {"Rifles"};
        case "medium": {selectRandom ["Rifles", "LMG"]};
        case "hard": {selectRandom ["Rifles", "LMG", "Sniperrifles"]};
        case "extreme": {selectRandom ["LMG", "Sniperrifles"]};
        default {"Rifles"};
    };

    // ✅ FIX: Extract property names from CfgExileArsenal (Exile uses properties, not arrays!)
    private _weaponsConfig = missionConfigFile >> "CfgExileArsenal" >> _weaponCat;
    private _weapons = ((configProperties [_weaponsConfig, "isNumber _x", true]) apply {configName _x}) select {
        !(_x in ["", "throw", "put"])
    };

    if (count _weapons > 0) then {
        _weapon = selectRandom _weapons;
    };
} else {
    // Use fallback loot
    private _lootPool = A3XAI_fallbackLootPools getOrDefault [_difficulty, A3XAI_fallbackLootPools get "medium"];
    private _weapons = _lootPool getOrDefault ["weapons", []];
    if (count _weapons > 0) then {
        _weapon = selectRandom _weapons;
    };
};

// Add weapon and magazines
if (_weapon != "") then {
    // Add magazines
    private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
    if (count _magazines > 0) then {
        private _magazine = _magazines select 0;
        // ✅ FIX: Add magazines BEFORE weapon so weapon auto-loads first mag
        for "_i" from 0 to 5 do {  // 6 mags total (was 4)
            _unit addMagazine _magazine;
        };
    };

    // Add weapon AFTER magazines (auto-loads first mag)
    _unit addWeapon _weapon;
};

// Add pistol for higher difficulties
if (_difficulty in ["medium", "hard", "extreme"]) then {
    private _pistol = "";

    if (_useExile) then {
        // ✅ FIX: Extract property names from CfgExileArsenal
        private _pistolsConfig = missionConfigFile >> "CfgExileArsenal" >> "Pistols";
        private _pistols = (configProperties [_pistolsConfig, "isNumber _x", true]) apply {configName _x};
        if (count _pistols > 0) then {
            _pistol = selectRandom _pistols;
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
            // ✅ FIX: Add pistol mags BEFORE pistol
            for "_i" from 0 to 2 do {  // 3 pistol mags
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
        // ✅ FIX: Extract property names from CfgExileArsenal
        private _launchersConfig = missionConfigFile >> "CfgExileArsenal" >> "Launchers";
        private _launchers = (configProperties [_launchersConfig, "isNumber _x", true]) apply {configName _x};
        if (count _launchers > 0) then {
            _launcher = selectRandom _launchers;
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
            // ✅ FIX: Add launcher mag BEFORE launcher
            _unit addMagazine (_launcherMags select 0);
        };
        _unit addWeapon _launcher;
    };
};

// Add uniform
private _uniforms = if (_useExile) then {
    // ✅ FIX: Extract property names from CfgExileArsenal
    private _uniformsConfig = missionConfigFile >> "CfgExileArsenal" >> "Uniforms";
    (configProperties [_uniformsConfig, "isNumber _x", true]) apply {configName _x}
} else {
    A3XAI_fallbackLoot getOrDefault ["uniforms", []]
};

if (count _uniforms > 0) then {
    _unit forceAddUniform (selectRandom _uniforms);
};

// Add vest
private _vests = if (_useExile) then {
    // ✅ FIX: Extract property names from CfgExileArsenal
    private _vestsConfig = missionConfigFile >> "CfgExileArsenal" >> "Vests";
    (configProperties [_vestsConfig, "isNumber _x", true]) apply {configName _x}
} else {
    A3XAI_fallbackLoot getOrDefault ["vests", []]
};

if (count _vests > 0) then {
    _unit addVest (selectRandom _vests);
};

// Add headgear
private _headgear = if (_useExile) then {
    // ✅ FIX: Extract property names from CfgExileArsenal
    private _headgearConfig = missionConfigFile >> "CfgExileArsenal" >> "Headgear";
    (configProperties [_headgearConfig, "isNumber _x", true]) apply {configName _x}
} else {
    A3XAI_fallbackLoot getOrDefault ["headgear", []]
};

if (count _headgear > 0) then {
    _unit addHeadgear (selectRandom _headgear);
};

// Add items
private _items = if (_useExile) then {
    // ✅ FIX: Extract property names from CfgExileArsenal
    private _itemsConfig = missionConfigFile >> "CfgExileArsenal" >> "Items";
    (configProperties [_itemsConfig, "isNumber _x", true]) apply {configName _x}
} else {
    A3XAI_fallbackLoot getOrDefault ["items", []]
};

// FirstAidKit
_unit addItem "FirstAidKit";

// Map/GPS for hard+
if (_difficulty in ["hard", "extreme"]) then {
    _unit linkItem "ItemMap";
    _unit linkItem "ItemGPS";
} else {
    _unit linkItem "ItemMap";
    _unit linkItem "ItemCompass";
};

// Radio
_unit linkItem "ItemRadio";

// Grenades
_unit addMagazine "HandGrenade";
if (_difficulty in ["hard", "extreme"]) then {
    _unit addMagazine "HandGrenade";
};

true
