/**
 * Warbands Skill System
 * Mount & Blade style character progression for Arma 3 Exile
 */

if (!hasInterface) exitWith {};

// Initialize player skills
WB_PlayerSkills = player getVariable ["WB_Skills", createHashMap];
WB_SkillPoints = player getVariable ["WB_SkillPoints", 0];
WB_PlayerLevel = player getVariable ["WB_Level", 1];
WB_PlayerXP = player getVariable ["WB_Experience", 0];

/**
 * Add experience to player
 */
WB_fnc_addExperience = {
    params ["_amount"];

    WB_PlayerXP = WB_PlayerXP + _amount;
    player setVariable ["WB_Experience", WB_PlayerXP, true];

    // Check for level up
    private _xpNeeded = [WB_PlayerLevel] call WB_fnc_getXPForLevel;

    if (WB_PlayerXP >= _xpNeeded) then {
        [1] call WB_fnc_levelUp;
    };

    ["InfoTitleAndText", ["Experience Gained", format["+%1 XP", _amount]]] call ExileClient_gui_toaster_addTemplateToast;
};

/**
 * Level up player
 */
WB_fnc_levelUp = {
    params [["_levels", 1]];

    WB_PlayerLevel = WB_PlayerLevel + _levels;
    WB_SkillPoints = WB_SkillPoints + _levels;

    player setVariable ["WB_Level", WB_PlayerLevel, true];
    player setVariable ["WB_SkillPoints", WB_SkillPoints, true];

    ["SuccessTitleAndText", ["Level Up!", format["You are now level %1. You have %2 skill points.", WB_PlayerLevel, WB_SkillPoints]]] call ExileClient_gui_toaster_addTemplateToast;

    playSound "FD_Finish_F";
};

/**
 * Get XP needed for next level
 */
WB_fnc_getXPForLevel = {
    params ["_level"];

    private _baseXP = 100;
    private _multiplier = 1.5;

    floor(_baseXP * (_level ^ _multiplier))
};

/**
 * Improve a skill
 */
WB_fnc_improveSkill = {
    params ["_skillName"];

    if (WB_SkillPoints <= 0) exitWith {
        ["ErrorTitleAndText", ["No Skill Points", "You need skill points to improve skills"]] call ExileClient_gui_toaster_addTemplateToast;
        false
    };

    private _currentLevel = WB_PlayerSkills getOrDefault [_skillName, 0];

    if (_currentLevel >= 10) exitWith {
        ["ErrorTitleAndText", ["Max Level", "This skill is already at maximum level"]] call ExileClient_gui_toaster_addTemplateToast;
        false
    };

    // Increase skill
    WB_PlayerSkills set [_skillName, _currentLevel + 1];
    WB_SkillPoints = WB_SkillPoints - 1;

    player setVariable ["WB_Skills", WB_PlayerSkills, true];
    player setVariable ["WB_SkillPoints", WB_SkillPoints, true];

    ["SuccessTitleAndText", ["Skill Improved", format["%1 is now level %2", _skillName, _currentLevel + 1]]] call ExileClient_gui_toaster_addTemplateToast;

    // Apply skill effects
    [_skillName, _currentLevel + 1] call WB_fnc_applySkillEffects;

    true
};

/**
 * Apply skill effects to player
 */
WB_fnc_applySkillEffects = {
    params ["_skillName", "_level"];

    switch (_skillName) do {
        case "IronFlesh": {
            // Increase player health
            private _healthBonus = 10 * _level;
            player setVariable ["WB_HealthBonus", _healthBonus, true];
        };

        case "Marksmanship": {
            // Improved accuracy - handled in hit event handler
            player setVariable ["WB_AccuracyBonus", 0.05 * _level, true];
        };

        case "Athletics": {
            // Movement speed bonus
            private _speedBonus = 0.05 * _level;
            player setVariable ["WB_SpeedBonus", _speedBonus, true];
            player setAnimSpeedCoef (1 + _speedBonus);
        };

        case "InventoryManagement": {
            // Increase load capacity
            player setVariable ["WB_LoadCapacityBonus", 6 * _level, true];
        };

        case "Leadership": {
            // Increase max party size
            private _partySizeBonus = 5 * _level;
            player setVariable ["WB_PartySizeBonus", _partySizeBonus, true];
        };

        case "Trade": {
            // Reduce trade penalties
            player setVariable ["WB_TradePenaltyReduction", 0.05 * _level, true];
        };

        case "Looting": {
            // Increase loot multiplier
            player setVariable ["WB_LootMultiplier", 1 + (0.10 * _level), true];
        };

        case "Medicine": {
            // Increase healing effectiveness
            player setVariable ["WB_HealingBonus", 0.50 * _level, true];
        };
    };
};

/**
 * View skills menu
 */
WB_fnc_viewSkills = {
    private _dialog = createDialog "WB_SkillsDialog";

    if (!_dialog) exitWith {
        hint "Failed to open skills dialog";
    };

    // Populate skills list
    [] call WB_fnc_populateSkillsList;
};

/**
 * Populate skills list in dialog
 */
WB_fnc_populateSkillsList = {
    private _display = findDisplay 24000; // Custom dialog ID
    if (isNull _display) exitWith {};

    private _skillsList = _display displayCtrl 1500;
    lbClear _skillsList;

    // Combat Skills
    lbAdd [1500, format["[Combat] Iron Flesh - Level %1/10", WB_PlayerSkills getOrDefault ["IronFlesh", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "IronFlesh"];

    lbAdd [1500, format["[Combat] Marksmanship - Level %1/10", WB_PlayerSkills getOrDefault ["Marksmanship", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Marksmanship"];

    lbAdd [1500, format["[Combat] Weapon Master - Level %1/10", WB_PlayerSkills getOrDefault ["WeaponMaster", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "WeaponMaster"];

    lbAdd [1500, format["[Combat] Explosives - Level %1/10", WB_PlayerSkills getOrDefault ["Explosives", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Explosives"];

    // Tactical Skills
    lbAdd [1500, format["[Tactical] Athletics - Level %1/10", WB_PlayerSkills getOrDefault ["Athletics", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Athletics"];

    lbAdd [1500, format["[Tactical] Driving - Level %1/10", WB_PlayerSkills getOrDefault ["Driving", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Driving"];

    lbAdd [1500, format["[Tactical] Piloting - Level %1/10", WB_PlayerSkills getOrDefault ["Piloting", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Piloting"];

    lbAdd [1500, format["[Tactical] Looting - Level %1/10", WB_PlayerSkills getOrDefault ["Looting", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Looting"];

    lbAdd [1500, format["[Tactical] Lockpicking - Level %1/10", WB_PlayerSkills getOrDefault ["Lockpicking", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Lockpicking"];

    // Leadership Skills
    lbAdd [1500, format["[Leadership] Leadership - Level %1/10", WB_PlayerSkills getOrDefault ["Leadership", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Leadership"];

    lbAdd [1500, format["[Leadership] Tactics - Level %1/10", WB_PlayerSkills getOrDefault ["Tactics", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Tactics"];

    lbAdd [1500, format["[Leadership] Trainer - Level %1/10", WB_PlayerSkills getOrDefault ["Trainer", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Trainer"];

    lbAdd [1500, format["[Leadership] Medicine - Level %1/10", WB_PlayerSkills getOrDefault ["Medicine", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Medicine"];

    lbAdd [1500, format["[Leadership] Engineer - Level %1/10", WB_PlayerSkills getOrDefault ["Engineer", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Engineer"];

    // Social Skills
    lbAdd [1500, format["[Social] Trade - Level %1/10", WB_PlayerSkills getOrDefault ["Trade", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Trade"];

    lbAdd [1500, format["[Social] Persuasion - Level %1/10", WB_PlayerSkills getOrDefault ["Persuasion", 0]]];
    lbSetData [1500, lbSize 1500 - 1, "Persuasion"];

    // Update skill points display
    private _skillPointsText = _display displayCtrl 1001;
    _skillPointsText ctrlSetText format["Skill Points: %1 | Level: %2 | XP: %3/%4",
        WB_SkillPoints,
        WB_PlayerLevel,
        WB_PlayerXP,
        [WB_PlayerLevel] call WB_fnc_getXPForLevel
    ];
};

/**
 * Event handlers for skill effects
 */
WB_fnc_initSkillEventHandlers = {
    // Damage reduction (Iron Flesh)
    player addEventHandler ["HandleDamage", {
        params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

        private _ironFleshLevel = (player getVariable ["WB_Skills", createHashMap]) getOrDefault ["IronFlesh", 0];
        if (_ironFleshLevel > 0) then {
            _damage = _damage * (1 - (0.02 * _ironFleshLevel)); // 2% reduction per level
        };

        _damage
    }];

    // Damage bonus (Marksmanship/Power Strike)
    player addEventHandler ["FiredMan", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

        private _marksmanshipLevel = (player getVariable ["WB_Skills", createHashMap]) getOrDefault ["Marksmanship", 0];
        if (_marksmanshipLevel > 0) then {
            _projectile setVariable ["WB_DamageBonus", 1 + (0.07 * _marksmanshipLevel)]; // 7% per level
        };
    }];

    // Experience gain from kills
    player addEventHandler ["EntityKilled", {
        params ["_unit", "_killer", "_instigator", "_useEffects"];

        if (_killer == player) then {
            private _xpGain = 50; // Base XP
            if (_unit isKindOf "Man") then {
                _xpGain = 100;
            };

            [_xpGain] call WB_fnc_addExperience;
        };
    }];

    // Looting bonus
    player addEventHandler ["InventoryOpened", {
        params ["_unit", "_container"];

        private _lootingLevel = (player getVariable ["WB_Skills", createHashMap]) getOrDefault ["Looting", 0];
        if (_lootingLevel > 0) then {
            // Chance to find extra items
            private _bonusChance = 0.10 * _lootingLevel;
            if (random 1 < _bonusChance) then {
                // Add random loot
                private _lootItems = ["Exile_Item_ZipTie", "Exile_Item_Can_Empty", "Exile_Item_PowerDrink"];
                private _bonusItem = selectRandom _lootItems;
                _container addItemCargoGlobal [_bonusItem, 1];
            };
        };
    }];
};

// Initialize event handlers
[] call WB_fnc_initSkillEventHandlers;

diag_log "[WB] Skill system initialized";
