/**
 * Warbands Companion System
 * Mount & Blade style hero companions
 */

// Available companion templates
WB_CompanionTemplates = [
    [
        "Marksman Viktor",
        "Former sniper turned mercenary",
        "B_Soldier_SL_F",
        createHashMapFromArray [["Marksmanship", 8], ["Spotting", 6], ["Tactics", 4]],
        3000
    ],
    [
        "Engineer Sofia",
        "Expert in fortifications and explosives",
        "B_Engineer_F",
        createHashMapFromArray [["Engineer", 9], ["Explosives", 7], ["InventoryManagement", 5]],
        3500
    ],
    [
        "Medic Andreas",
        "Battlefield surgeon with extensive experience",
        "B_medic_F",
        createHashMapFromArray [["Medicine", 9], ["FirstAid", 8], ["Surgery", 7]],
        4000
    ],
    [
        "Sergeant Dimitri",
        "Veteran squad leader and trainer",
        "B_Soldier_TL_F",
        createHashMapFromArray [["Leadership", 8], ["Trainer", 9], ["Tactics", 6]],
        4500
    ],
    [
        "Scout Elena",
        "Expert tracker and pathfinder",
        "B_recon_F",
        createHashMapFromArray [["Tracking", 9], ["Spotting", 8], ["Pathfinding", 7]],
        3000
    ],
    [
        "Trader Marcus",
        "Shrewd merchant with wide connections",
        "C_man_polo_2_F_asia",
        createHashMapFromArray [["Trade", 9], ["Persuasion", 7], ["InventoryManagement", 6]],
        2500
    ],
    [
        "Driver Ivan",
        "Ace driver and mechanic",
        "B_crew_F",
        createHashMapFromArray [["Driving", 9], ["Piloting", 6], ["Engineer", 4]],
        3000
    ],
    [
        "Grenadier Hassan",
        "Explosives expert and heavy weapons specialist",
        "B_soldier_LAT_F",
        createHashMapFromArray [["Explosives", 9], ["PowerStrike", 7], ["IronFlesh", 6]],
        3500
    ]
];

/**
 * Spawn a companion in the world
 */
WB_fnc_spawnCompanion = {
    params ["_templateIndex", "_spawnPos"];

    if (_templateIndex >= count WB_CompanionTemplates) exitWith {nil};

    private _template = WB_CompanionTemplates select _templateIndex;
    _template params ["_name", "_bio", "_unitClass", "_skills", "_hireCost"];

    // Create companion unit
    private _group = createGroup civilian;
    private _companion = _group createUnit [_unitClass, _spawnPos, [], 0, "NONE"];

    // Set companion data
    _companion setVariable ["WB_IsCompanion", true, true];
    _companion setVariable ["WB_CompanionName", _name, true];
    _companion setVariable ["WB_CompanionBio", _bio, true];
    _companion setVariable ["WB_CompanionSkills", _skills, true];
    _companion setVariable ["WB_HireCost", _hireCost, true];
    _companion setVariable ["WB_Hired", false, true];
    _companion setVariable ["WB_Level", 5 + floor(random 5), true]; // Level 5-9

    // Set companion stats
    _companion setSkill 0.7 + (random 0.3);
    _companion setBehaviour "SAFE";
    _companion setCombatMode "YELLOW";

    // Add custom name
    _companion setName _name;

    _companion
};

/**
 * Hire a companion
 */
WB_fnc_hireCompanion = {
    params ["_player", "_companion"];

    private _hired = _companion getVariable ["WB_Hired", false];
    if (_hired) exitWith {
        ["ErrorTitleAndText", ["Already Hired", "This companion has already been hired"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    private _hireCost = _companion getVariable ["WB_HireCost", 0];
    private _playerMoney = _player getVariable ["ExileMoney", 0];

    if (_playerMoney < _hireCost) exitWith {
        ["ErrorTitleAndText", ["Insufficient Funds", format["You need %1 poptabs to hire this companion", _hireCost]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    // Deduct cost
    _player setVariable ["ExileMoney", _playerMoney - _hireCost, true];

    // Mark as hired
    _companion setVariable ["WB_Hired", true, true];
    _companion setVariable ["WB_HiredBy", getPlayerUID _player, true];

    // Add to player's companions
    private _companions = _player getVariable ["WB_Companions", []];
    _companions pushBack _companion;
    _player setVariable ["WB_Companions", _companions, true];

    // Join player's group
    [_companion] joinSilent (group _player);

    // Set companion behavior
    _companion setBehaviour "AWARE";
    _companion setCombatMode "YELLOW";

    private _companionName = _companion getVariable ["WB_CompanionName", "Companion"];
    ["SuccessTitleAndText", ["Companion Hired", format["%1 has joined your party for %2 poptabs", _companionName, _hireCost]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

    diag_log format["[WB] Player %1 hired companion %2", name _player, _companionName];

    true
};

/**
 * Dismiss a companion
 */
WB_fnc_dismissCompanion = {
    params ["_player", "_companion"];

    private _companionName = _companion getVariable ["WB_CompanionName", "Companion"];

    // Remove from companions list
    private _companions = _player getVariable ["WB_Companions", []];
    _companions = _companions - [_companion];
    _player setVariable ["WB_Companions", _companions, true];

    // Leave group
    [_companion] joinSilent grpNull;

    // Reset companion
    _companion setVariable ["WB_Hired", false, true];
    _companion setVariable ["WB_HiredBy", nil, true];
    _companion setBehaviour "SAFE";

    ["InfoTitleAndText", ["Companion Dismissed", format["%1 has left your party", _companionName]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

    true
};

/**
 * View companions menu
 */
WB_fnc_viewCompanions = {
    if (!hasInterface) exitWith {};

    private _companions = player getVariable ["WB_Companions", []];

    if (count _companions == 0) exitWith {
        ["InfoTitleAndText", ["No Companions", "You have no companions. Find and hire them in towns"]] call ExileClient_gui_toaster_addTemplateToast;
    };

    // Create dialog showing companions
    private _text = "<t size='1.2' color='#ff8c00'>Your Companions</t><br/><br/>";

    {
        private _name = _x getVariable ["WB_CompanionName", "Unknown"];
        private _level = _x getVariable ["WB_Level", 1];
        private _bio = _x getVariable ["WB_CompanionBio", ""];
        private _skills = _x getVariable ["WB_CompanionSkills", createHashMap];

        _text = _text + format["<t size='1.1' color='#4CAF50'>%1 (Level %2)</t><br/>", _name, _level];
        _text = _text + format["<t size='0.8' color='#cccccc'>%1</t><br/>", _bio];

        // Show top skills
        _text = _text + "<t size='0.8' color='#FFD700'>Skills: </t>";
        {
            _text = _text + format["<t size='0.7' color='#ffffff'>%1(%2) </t>", _x, _y];
        } forEach _skills;

        _text = _text + "<br/><br/>";
    } forEach _companions;

    hint parseText _text;
};

/**
 * Companion skill contribution
 * Party skills use highest level from all party members
 */
WB_fnc_getPartySkill = {
    params ["_player", "_skillName"];

    private _companions = _player getVariable ["WB_Companions", []];
    private _playerSkills = _player getVariable ["WB_Skills", createHashMap];
    private _playerLevel = _playerSkills getOrDefault [_skillName, 0];

    private _highestLevel = _playerLevel;

    // Check all companions
    {
        private _companionSkills = _x getVariable ["WB_CompanionSkills", createHashMap];
        private _companionLevel = _companionSkills getOrDefault [_skillName, 0];

        if (_companionLevel > _highestLevel) then {
            _highestLevel = _companionLevel;
        };
    } forEach _companions;

    // Apply leader bonus (from Mount & Blade)
    private _leaderBonus = switch (true) do {
        case (_playerLevel == 0 || _playerLevel == 1): {0};
        case (_playerLevel >= 2 && _playerLevel <= 4): {1};
        case (_playerLevel >= 5 && _playerLevel <= 7): {2};
        case (_playerLevel >= 8 && _playerLevel <= 9): {3};
        case (_playerLevel == 10): {4};
        default {0};
    };

    (_highestLevel + _leaderBonus) min 14 // Max effective level is 14
};

/**
 * Companion experience gain
 * Companions gain experience from battles
 */
WB_fnc_companionGainExperience = {
    params ["_companion", "_xp"];

    if (!isServer) exitWith {};

    private _companionLevel = _companion getVariable ["WB_Level", 1];
    private _companionXP = _companion getVariable ["WB_Experience", 0];

    _companionXP = _companionXP + _xp;
    _companion setVariable ["WB_Experience", _companionXP, true];

    // Check for level up
    private _xpNeeded = 100 * (_companionLevel ^ 1.5);

    if (_companionXP >= _xpNeeded) then {
        _companionLevel = _companionLevel + 1;
        _companion setVariable ["WB_Level", _companionLevel, true];

        // Improve a random skill
        private _skills = _companion getVariable ["WB_CompanionSkills", createHashMap];
        private _skillNames = keys _skills;

        if (count _skillNames > 0) then {
            private _randomSkill = selectRandom _skillNames;
            private _currentLevel = _skills get _randomSkill;
            if (_currentLevel < 10) then {
                _skills set [_randomSkill, _currentLevel + 1];
                _companion setVariable ["WB_CompanionSkills", _skills, true];
            };
        };

        private _companionName = _companion getVariable ["WB_CompanionName", "Companion"];
        diag_log format["[WB] Companion %1 leveled up to %2", _companionName, _companionLevel];
    };
};

/**
 * Spawn companions in world at random taverns/towns
 */
WB_fnc_spawnWorldCompanions = {
    if (!isServer) exitWith {};

    // Spawn locations (taverns/towns)
    private _spawnLocations = [
        [3616,13110,0],  // Kavala
        [14000,18700,0], // Athira
        [16900,12700,0], // Pyrgos
        [25500,21100,0]  // Sofia
    ];

    // Spawn 2-3 companions per location
    {
        private _location = _x;
        private _numCompanions = 2 + floor(random 2);

        for "_i" from 0 to _numCompanions do {
            private _templateIndex = floor(random (count WB_CompanionTemplates));
            private _companion = [_templateIndex, _location getPos [20 + random 30, random 360]] call WB_fnc_spawnCompanion;

            if (!isNil "_companion") then {
                // Make companion wander around
                [_companion] spawn {
                    params ["_unit"];

                    while {alive _unit && !(_unit getVariable ["WB_Hired", false])} do {
                        _unit doMove (_unit getPos [10 + random 20, random 360]);
                        sleep 30 + random 30;
                    };
                };
            };
        };
    } forEach _spawnLocations;

    diag_log "[WB] World companions spawned";
};

// Spawn companions on server start
if (isServer) then {
    [] call WB_fnc_spawnWorldCompanions;
};

diag_log "[WB] Companion system initialized";
