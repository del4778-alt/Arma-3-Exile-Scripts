/**
 * Warbands Client Initialization
 * Client-side systems for Exile Warbands
 */

if (!hasInterface) exitWith {};

diag_log "[WB] Client initialization starting...";

// Load Fallout 4 systems
call compile preprocessFileLineNumbers "warbands\systems\WB_VATS_System.sqf";
diag_log "[WB] VATS system loaded (client)";

call compile preprocessFileLineNumbers "warbands\systems\WB_LegendaryWeapons.sqf";
diag_log "[WB] Legendary weapons loaded (client)";

call compile preprocessFileLineNumbers "warbands\systems\WB_Crafting_System.sqf";
diag_log "[WB] Crafting system loaded (client)";

// Load skill system (now with SPECIAL)
call compile preprocessFileLineNumbers "warbands\systems\WB_SkillSystem.sqf";
diag_log "[WB] SPECIAL system loaded (client)";

// Load player data from server
[] spawn {
    waitUntil {!isNull player && alive player};
    sleep 1;

    private _uid = getPlayerUID player;

    // Load saved data
    private _savedData = profileNamespace getVariable [format["WB_PlayerData_%1", _uid], createHashMap];

    if (count _savedData > 0) then {
        // Restore player data
        player setVariable ["WB_Faction", _savedData getOrDefault ["faction", ""], true];
        player setVariable ["WB_Rank", _savedData getOrDefault ["rank", 0], true];
        player setVariable ["WB_Renown", _savedData getOrDefault ["renown", 0], true];
        player setVariable ["WB_Honor", _savedData getOrDefault ["honor", 0], true];
        player setVariable ["WB_Level", _savedData getOrDefault ["level", 1], true];
        player setVariable ["WB_Experience", _savedData getOrDefault ["experience", 0], true];
        player setVariable ["WB_Skills", _savedData getOrDefault ["skills", createHashMap], true];
        player setVariable ["WB_SkillPoints", _savedData getOrDefault ["skillPoints", 0], true];

        hint "Warbands data loaded";
        diag_log "[WB] Player data restored from save";
    } else {
        // New player - initialize
        player setVariable ["WB_Faction", "", true];
        player setVariable ["WB_Rank", 0, true];
        player setVariable ["WB_Renown", 0, true];
        player setVariable ["WB_Honor", 0, true];
        player setVariable ["WB_Level", 1, true];
        player setVariable ["WB_Experience", 0, true];
        player setVariable ["WB_Skills", createHashMap, true];
        player setVariable ["WB_SkillPoints", 0, true];
        player setVariable ["WB_Companions", [], true];

        diag_log "[WB] New player initialized";
    };

    // Welcome message
    sleep 5;
    [
        "Warbands System",
        "Welcome to Exile Warbands! Open XM8 to join a faction and begin your conquest."
    ] call ExileClient_gui_notification_event_addNotification;
};

// Register XM8 app
[] spawn {
    waitUntil {!isNil "ExileClientXM8CurrentSlide"};

    // Add Warbands app to XM8
    ExileClientXM8Apps pushBack [
        "Warbands",
        "warbands\xm8\WB_XM8_App.sqf",
        "warbands\xm8\icon_warbands.paa"  // Custom icon
    ];

    diag_log "[WB] XM8 app registered";
};

// HUD updates
[] spawn {
    waitUntil {!isNull (findDisplay 46)};

    while {true} do {
        sleep 5;

        // Update HUD with faction info
        private _faction = player getVariable ["WB_Faction", ""];

        if (_faction != "") then {
            private _renown = player getVariable ["WB_Renown", 0];
            private _honor = player getVariable ["WB_Honor", 0];
            private _level = player getVariable ["WB_Level", 1];

            // Could display on custom HUD element
            // For now just store for XM8
        };
    };
};

// Keypress handlers for quick actions
[] spawn {
    waitUntil {!isNil "ExileClientXM8CurrentSlide"};

    // Register custom key handler
    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_display", "_key", "_shift", "_ctrl", "_alt"];

        // Shift+K = Open Warbands XM8
        if (_shift && _key == 37) then { // K key
            [] call ExileClient_gui_xm8_show;
            // Switch to Warbands slide
            true
        };

        false
    }];
};

// Notification for nearby companions
[] spawn {
    while {true} do {
        sleep 15;

        private _nearbyCompanions = (player nearEntities [["Man"], 50]) select {
            _x getVariable ["WB_IsCompanion", false] &&
            !(_x getVariable ["WB_Hired", false])
        };

        if (count _nearbyCompanions > 0) then {
            private _companion = _nearbyCompanions select 0;
            private _companionName = _companion getVariable ["WB_CompanionName", "Companion"];
            private _hireCost = _companion getVariable ["WB_HireCost", 0];

            [
                format["%1 Available", _companionName],
                format["Companion for hire: %1 poptabs. Press T to interact.", _hireCost]
            ] call ExileClient_gui_notification_event_addNotification;

            sleep 60; // Don't spam notifications
        };
    };
};

// Custom addAction for companions
[] spawn {
    while {true} do {
        sleep 1;

        {
            if (_x getVariable ["WB_IsCompanion", false] && !(_x getVariable ["WB_Hired", false])) then {
                if (player distance _x < 5 && !(_x getVariable ["WB_ActionAdded", false])) then {
                    _x addAction [
                        format["<t color='#00FF00'>Hire %1</t>", _x getVariable ["WB_CompanionName", "Companion"]],
                        {
                            params ["_target", "_caller", "_actionId", "_arguments"];
                            [_caller, _target] remoteExec ["WB_fnc_hireCompanion", 2];
                        },
                        [],
                        6,
                        true,
                        true,
                        "",
                        "true",
                        5
                    ];

                    _x addAction [
                        "<t color='#00BFFF'>Talk</t>",
                        {
                            params ["_target", "_caller", "_actionId", "_arguments"];

                            private _bio = _target getVariable ["WB_CompanionBio", ""];
                            private _skills = _target getVariable ["WB_CompanionSkills", createHashMap];

                            private _text = format["<t size='1.2'>%1</t><br/><br/>", _target getVariable ["WB_CompanionName", "Companion"]];
                            _text = _text + format["<t size='0.9'>%1</t><br/><br/>", _bio];
                            _text = _text + "<t size='1' color='#FFD700'>Skills:</t><br/>";

                            {
                                _text = _text + format["<t size='0.8'>%1: %2/10</t><br/>", _x, _y];
                            } forEach _skills;

                            hint parseText _text;
                        },
                        [],
                        5,
                        true,
                        true,
                        "",
                        "true",
                        5
                    ];

                    _x setVariable ["WB_ActionAdded", true];
                };
            };
        } forEach (player nearEntities [["Man"], 10]);
    };
};

// Apply skill effects continuously
[] spawn {
    while {true} do {
        sleep 1;

        // Athletics speed bonus
        private _athletics = (player getVariable ["WB_Skills", createHashMap]) getOrDefault ["Athletics", 0];
        if (_athletics > 0) then {
            private _speedBonus = 0.05 * _athletics;
            player setAnimSpeedCoef (1 + _speedBonus);
        };

        // Get effective party skills from companions
        private _effectiveLooting = [player, "Looting"] call WB_fnc_getPartySkill;
        player setVariable ["WB_EffectiveLootingSkill", _effectiveLooting];

        private _effectiveSpotting = [player, "Spotting"] call WB_fnc_getPartySkill;
        player setVariable ["WB_EffectiveSpottingSkill", _effectiveSpotting];
    };
};

diag_log "[WB] Client initialization complete";

// Show welcome hint
[] spawn {
    sleep 10;

    private _text = "<t size='1.5' color='#ff8c00'>EXILE WARBANDS</t><br/><br/>";
    _text = _text + "<t size='1.1'>Mount & Blade Warfare System</t><br/><br/>";
    _text = _text + "<t size='0.9'>Features:</t><br/>";
    _text = _text + "• Join factions and wage war<br/>";
    _text = _text + "• Skills and character progression<br/>";
    _text = _text + "• Hire companions and build armies<br/>";
    _text = _text + "• Complete contracts for rewards<br/>";
    _text = _text + "• Siege fortresses and control territory<br/>";
    _text = _text + "• Trade, craft, and manage prisoners<br/><br/>";
    _text = _text + "<t size='0.8' color='#4CAF50'>Open XM8 to access Warbands</t><br/>";
    _text = _text + "<t size='0.8' color='#2196F3'>Shift+K for quick access</t>";

    hint parseText _text;
};
