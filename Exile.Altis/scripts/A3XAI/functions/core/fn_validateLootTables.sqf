/*
    A3XAI Elite - Validate Exile Loot Tables
    Checks if Exile trader tables are available, sets up fallbacks

    Returns:
        BOOL - True if Exile tables valid, false if using fallbacks
*/

private _valid = true;

// ✅ FIX: Check missionConfigFile (description.ext) instead of configFile
if (!isClass (missionConfigFile >> "CfgExileArsenal")) exitWith {
    [1, "CfgExileArsenal not found in mission config - using fallback loot tables"] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = true;
    [] call A3XAI_fnc_initFallbackLoot;
    false
};

// Check specific categories we need
private _requiredCategories = ["Rifles", "LMG", "Sniperrifles", "Pistols", "Uniforms", "Vests", "Headgear", "Items"];
private _missingCategories = [];

{
    // ✅ FIX: Use missionConfigFile for mission-defined configs
    if (!isClass (missionConfigFile >> "CfgExileArsenal" >> _x)) then {
        _missingCategories pushBack _x;
        _valid = false;
    };
} forEach _requiredCategories;

if (!_valid) then {
    [2, format ["Exile loot categories missing: %1", _missingCategories joinString ", "]] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = true;
    [] call A3XAI_fnc_initFallbackLoot;
    [2, "Using fallback loot tables"] call A3XAI_fnc_log;
} else {
    [3, "Exile trader tables validated successfully"] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = false;
};

_valid
