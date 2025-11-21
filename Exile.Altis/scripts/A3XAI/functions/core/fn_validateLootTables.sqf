/*
    A3XAI Elite - Validate Exile Loot Tables
    Checks if Exile trader tables are available, sets up fallbacks

    NOTE: Exile CfgExileArsenal uses a FLAT structure where all items
    are direct children with classname prefixes:
        - arifle_ = Assault rifles
        - srifle_ = Sniper rifles
        - LMG_ = Light machine guns
        - hgun_ = Handguns/pistols
        - U_ = Uniforms
        - V_ = Vests
        - H_ = Headgear
        - B_ = Backpacks

    Returns:
        BOOL - True if Exile tables valid, false if using fallbacks
*/

private _valid = true;

// Check if CfgExileArsenal exists in mission config (description.ext -> config.cpp)
if (!isClass (missionConfigFile >> "CfgExileArsenal")) exitWith {
    [1, "CfgExileArsenal not found in mission config - using fallback loot tables"] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = true;
    [] call A3XAI_fnc_initFallbackLoot;
    false
};

// Get ALL item classes from the flat CfgExileArsenal structure
private _arsenalConfig = missionConfigFile >> "CfgExileArsenal";
private _allItems = (configProperties [_arsenalConfig, "isClass _x", true]) apply {configName _x};

if (count _allItems == 0) exitWith {
    [1, "CfgExileArsenal is empty - using fallback loot tables"] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = true;
    [] call A3XAI_fnc_initFallbackLoot;
    false
};

// Filter items by prefix to validate each category exists
// IMPORTANT: Filter out abstract _base_ classes that can't be created as real items
private _isValidItem = {
    private _item = _x;
    !("_base_" in _item) && !("_Base_" in _item) && !("_BASE_" in _item)
};

private _rifles = _allItems select {(_x select [0, 7] == "arifle_") && (call _isValidItem)};
private _lmgs = _allItems select {((_x select [0, 4] == "LMG_") || ("_SW_" in _x)) && (call _isValidItem)};
private _snipers = _allItems select {(_x select [0, 7] == "srifle_") && (call _isValidItem)};
private _pistols = _allItems select {(_x select [0, 5] == "hgun_") && (call _isValidItem)};
private _uniforms = _allItems select {(_x select [0, 2] == "U_") && (call _isValidItem)};
private _vests = _allItems select {(_x select [0, 2] == "V_") && (call _isValidItem)};
private _headgear = _allItems select {(_x select [0, 2] == "H_") && (call _isValidItem)};
private _backpacks = _allItems select {(_x select [0, 2] == "B_") && (call _isValidItem)};

// Check what categories are missing
private _missingCategories = [];

if (count _rifles == 0) then { _missingCategories pushBack "Rifles"; _valid = false; };
if (count _lmgs == 0) then { _missingCategories pushBack "LMG"; _valid = false; };
if (count _snipers == 0) then { _missingCategories pushBack "Sniperrifles"; _valid = false; };
if (count _pistols == 0) then { _missingCategories pushBack "Pistols"; _valid = false; };
if (count _uniforms == 0) then { _missingCategories pushBack "Uniforms"; _valid = false; };
if (count _vests == 0) then { _missingCategories pushBack "Vests"; _valid = false; };
if (count _headgear == 0) then { _missingCategories pushBack "Headgear"; _valid = false; };

// Log what we found
[3, format ["CfgExileArsenal scan: %1 total items - Rifles:%2 LMG:%3 Snipers:%4 Pistols:%5 Uniforms:%6 Vests:%7 Headgear:%8 Backpacks:%9",
    count _allItems, count _rifles, count _lmgs, count _snipers, count _pistols,
    count _uniforms, count _vests, count _headgear, count _backpacks]] call A3XAI_fnc_log;

if (!_valid) then {
    [2, format ["Exile loot categories missing: %1", _missingCategories joinString ", "]] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = true;
    [] call A3XAI_fnc_initFallbackLoot;
    [2, "Using fallback loot tables"] call A3XAI_fnc_log;
} else {
    // Cache the item lists for faster equipment selection
    A3XAI_exileRifles = _rifles;
    A3XAI_exileLMGs = _lmgs;
    A3XAI_exileSnipers = _snipers;
    A3XAI_exilePistols = _pistols;
    A3XAI_exileUniforms = _uniforms;
    A3XAI_exileVests = _vests;
    A3XAI_exileHeadgear = _headgear;
    A3XAI_exileBackpacks = _backpacks;

    [3, "Exile trader tables validated and cached successfully"] call A3XAI_fnc_log;
    A3XAI_useFallbackLoot = false;
};

_valid
