/*
    A3XAI Elite - Equip AI Unit
    Equips AI with weapons and gear based on difficulty

    NOTE: Uses cached item lists from fn_validateLootTables.sqf which
    scans Exile's flat CfgExileArsenal structure by classname prefix.

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

// Get weapon from cached lists (populated by fn_validateLootTables.sqf)
private _weapon = "";
if (_useExile) then {
    // Select weapon category based on difficulty
    private _weapons = switch (_difficulty) do {
        case "easy": {
            // Just rifles
            if (!isNil "A3XAI_exileRifles" && {count A3XAI_exileRifles > 0}) then {
                A3XAI_exileRifles
            } else {[]};
        };
        case "medium": {
            // Rifles + LMGs
            private _pool = [];
            if (!isNil "A3XAI_exileRifles") then {_pool append A3XAI_exileRifles};
            if (!isNil "A3XAI_exileLMGs" && {random 1 < 0.3}) then {_pool append A3XAI_exileLMGs};
            _pool
        };
        case "hard": {
            // Rifles + LMGs + Snipers
            private _pool = [];
            if (!isNil "A3XAI_exileRifles") then {_pool append A3XAI_exileRifles};
            if (!isNil "A3XAI_exileLMGs" && {random 1 < 0.4}) then {_pool append A3XAI_exileLMGs};
            if (!isNil "A3XAI_exileSnipers" && {random 1 < 0.3}) then {_pool append A3XAI_exileSnipers};
            _pool
        };
        case "extreme": {
            // Heavy focus on LMGs + Snipers
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
    // Use fallback loot
    private _lootPool = A3XAI_fallbackLootPools getOrDefault [_difficulty, A3XAI_fallbackLootPools get "medium"];
    private _weapons = _lootPool getOrDefault ["weapons", []];
    if (count _weapons > 0) then {
        _weapon = selectRandom _weapons;
    };
};

// Add weapon and magazines
if (_weapon != "") then {
    // Get compatible magazines from game config
    private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
    if (count _magazines > 0) then {
        private _magazine = _magazines select 0;
        // Add magazines BEFORE weapon so weapon auto-loads first mag
        for "_i" from 0 to 5 do {
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
        // Use cached pistol list
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
            // Add pistol mags BEFORE pistol
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
        // Use cached launcher list (if available)
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

// Add uniform from cached list
private _uniforms = if (_useExile && {!isNil "A3XAI_exileUniforms"}) then {
    A3XAI_exileUniforms
} else {
    A3XAI_fallbackLoot getOrDefault ["uniforms", []]
};

if (count _uniforms > 0) then {
    _unit forceAddUniform (selectRandom _uniforms);
};

// Add vest from cached list
private _vests = if (_useExile && {!isNil "A3XAI_exileVests"}) then {
    A3XAI_exileVests
} else {
    A3XAI_fallbackLoot getOrDefault ["vests", []]
};

if (count _vests > 0) then {
    _unit addVest (selectRandom _vests);
};

// Add headgear from cached list
private _headgear = if (_useExile && {!isNil "A3XAI_exileHeadgear"}) then {
    A3XAI_exileHeadgear
} else {
    A3XAI_fallbackLoot getOrDefault ["headgear", []]
};

if (count _headgear > 0) then {
    _unit addHeadgear (selectRandom _headgear);
};

// Add backpack for hard+ difficulty
if (_difficulty in ["hard", "extreme"]) then {
    private _backpacks = if (_useExile && {!isNil "A3XAI_exileBackpacks"}) then {
        A3XAI_exileBackpacks
    } else {
        A3XAI_fallbackLoot getOrDefault ["backpacks", []]
    };

    if (count _backpacks > 0) then {
        _unit addBackpack (selectRandom _backpacks);
    };
};

// Add items
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
