/**
 * Warbands Ransom and Prisoner Management System
 * Mount & Blade style prisoner mechanics with Exile currency integration
 */

if (!isServer) exitWith {};

/**
 * Enhanced prisoner management with ransom
 */
WB_fnc_prisonManage = {
    params ["_player", "_prisoner"];

    if (!alive _prisoner) exitWith {false};

    private _prisonerFaction = _prisoner getVariable ["WB_Faction", ""];
    private _playerFaction = _player getVariable ["WB_Faction", ""];

    if (_prisonerFaction == "") exitWith {
        // Regular bandit/enemy - can recruit or sell as slave
        [_player, _prisoner] call WB_fnc_handleRegularPrisoner;
    };

    // Faction member - can ransom or persuade
    [_player, _prisoner, _prisonerFaction] call WB_fnc_handleFactionPrisoner;
};

/**
 * Handle regular prisoners (non-faction)
 */
WB_fnc_handleRegularPrisoner = {
    params ["_player", "_prisoner"];

    private _persuasionLevel = (_player getVariable ["WB_Skills", createHashMap]) getOrDefault ["Persuasion", 0];
    private _recruitChance = 0.25 + (0.04 * _persuasionLevel); // 25% base + 4% per level

    // Options: Recruit, Sell as Slave, Execute, Release
    private _options = [
        format["Recruit (Success Chance: %1%%)", floor(_recruitChance * 100)],
        format["Sell as Slave (%1 poptabs)", 150 + (random 100)],
        "Execute",
        "Release"
    ];

    // Present options via dialog
    private _choice = _options call BIS_fnc_selectRandom; // Simplified for server-side

    switch (_choice) do {
        case 0: { // Recruit
            if (random 1 < _recruitChance) then {
                // Successfully recruited
                [_player, _prisoner] call WB_fnc_recruitPrisoner;
                ["SuccessTitleAndText", ["Recruitment Success", "The prisoner has joined your forces"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
            } else {
                // Failed recruitment
                ["ErrorTitleAndText", ["Recruitment Failed", "The prisoner refused to join you"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
            };
        };

        case 1: { // Sell
            private _sellPrice = 150 + (random 100);
            private _playerMoney = _player getVariable ["ExileMoney", 0];
            _player setVariable ["ExileMoney", _playerMoney + _sellPrice, true];

            deleteVehicle _prisoner;

            ["SuccessTitleAndText", ["Prisoner Sold", format["Received %1 poptabs", floor _sellPrice]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        };

        case 2: { // Execute
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor - 10, true]; // Honor penalty

            deleteVehicle _prisoner;

            ["ErrorTitleAndText", ["Prisoner Executed", "You lost 10 honor"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        };

        case 3: { // Release
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor + 5, true]; // Small honor reward

            _prisoner setVariable ["WB_ReleasedBy", getPlayerUID _player, true];
            deleteVehicle _prisoner; // Or move to safe location

            ["InfoTitleAndText", ["Prisoner Released", "You gained 5 honor"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        };
    };

    true
};

/**
 * Handle faction prisoners
 */
WB_fnc_handleFactionPrisoner = {
    params ["_player", "_prisoner", "_prisonerFaction"];

    private _prisonerRank = _prisoner getVariable ["WB_Rank", 0];
    private _ransomValue = (500 + (250 * _prisonerRank)) max 500; // Higher rank = higher ransom

    // Options: Demand Ransom, Attempt to Persuade, Exchange for Our Prisoners, Execute, Release
    private _options = [
        format["Demand Ransom (%1 poptabs from faction treasury)", _ransomValue],
        format["Persuade to Join (Honor Risk)"],
        format["Exchange for Allied Prisoners"],
        "Execute (Major Honor Loss)",
        "Release (Honor Gain)"
    ];

    private _choice = floor(random (count _options)); // Simplified

    switch (_choice) do {
        case 0: { // Ransom
            [_player, _prisoner, _prisonerFaction, _ransomValue] call WB_fnc_demandRansom;
        };

        case 1: { // Persuade
            [_player, _prisoner] call WB_fnc_persuadePrisoner;
        };

        case 2: { // Exchange
            [_player, _prisoner, _prisonerFaction] call WB_fnc_exchangePrisoner;
        };

        case 3: { // Execute
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor - 25, true]; // Major penalty

            // Faction relations penalty
            [_player, _prisonerFaction, -50] call WB_fnc_modifyFactionRelation;

            deleteVehicle _prisoner;

            ["ErrorTitleAndText", ["Officer Executed", "You lost 25 honor and faction relations"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        };

        case 4: { // Release
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor + 10, true];

            // Improve relations with prisoner's faction
            [_player, _prisonerFaction, 20] call WB_fnc_modifyFactionRelation;

            deleteVehicle _prisoner;

            ["SuccessTitleAndText", ["Officer Released", "You gained 10 honor and improved faction relations"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        };
    };

    true
};

/**
 * Demand ransom from faction treasury
 */
WB_fnc_demandRansom = {
    params ["_player", "_prisoner", "_prisonerFaction", "_ransomValue"];

    private _treasuryVar = format["WB_Treasury_%1", _prisonerFaction];
    private _treasury = missionNamespace getVariable [_treasuryVar, 0];

    if (_treasury >= _ransomValue) then {
        // Faction pays ransom
        missionNamespace setVariable [_treasuryVar, _treasury - _ransomValue, true];

        // Transfer to player's faction treasury (80%) and player (20%)
        private _playerFaction = _player getVariable ["WB_Faction", ""];
        private _factionShare = floor(_ransomValue * 0.8);
        private _playerShare = _ransomValue - _factionShare;

        if (_playerFaction != "") then {
            private _playerTreasuryVar = format["WB_Treasury_%1", _playerFaction];
            private _playerTreasury = missionNamespace getVariable [_playerTreasuryVar, 0];
            missionNamespace setVariable [_playerTreasuryVar, _playerTreasury + _factionShare, true];
        };

        // Award player their share
        private _playerMoney = _player getVariable ["ExileMoney", 0];
        _player setVariable ["ExileMoney", _playerMoney + _playerShare, true];

        // Award renown
        private _playerRenown = _player getVariable ["WB_Renown", 0];
        _player setVariable ["WB_Renown", _playerRenown + 10, true];

        // Release prisoner
        deleteVehicle _prisoner;

        ["SuccessTitleAndText", ["Ransom Paid", format["Received %1 poptabs and 10 renown", _playerShare]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

        diag_log format["[WB] Ransom paid: %1 poptabs from %2 for prisoner", _ransomValue, _prisonerFaction];
    } else {
        // Faction cannot afford ransom
        ["ErrorTitleAndText", ["Ransom Rejected", format["%1 cannot afford the ransom (Treasury: %2)", _prisonerFaction, _treasury]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
    };

    true
};

/**
 * Persuade prisoner to defect
 */
WB_fnc_persuadePrisoner = {
    params ["_player", "_prisoner"];

    private _persuasionLevel = (_player getVariable ["WB_Skills", createHashMap]) getOrDefault ["Persuasion", 0];
    private _prisonerRank = _prisoner getVariable ["WB_Rank", 0];
    private _playerHonor = _player getVariable ["WB_Honor", 0];

    // Success chance based on persuasion, rank difference, and honor
    private _baseChance = 0.15; // 15% base
    private _persuasionBonus = 0.04 * _persuasionLevel;
    private _rankPenalty = 0.05 * _prisonerRank; // Higher rank = harder to persuade
    private _honorBonus = 0.001 * _playerHonor; // Honor helps

    private _successChance = (_baseChance + _persuasionBonus + _honorBonus - _rankPenalty) max 0.05;

    if (random 1 < _successChance) then {
        // Success - prisoner defects
        [_player, _prisoner] call WB_fnc_recruitPrisoner;

        ["SuccessTitleAndText", ["Persuasion Success", "The prisoner has defected to your faction!"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

        // Small honor penalty for "stealing" enemy officer
        _player setVariable ["WB_Honor", _playerHonor - 5, true];
    } else {
        // Failure
        ["ErrorTitleAndText", ["Persuasion Failed", "The prisoner remains loyal to their faction"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

        // Honor penalty for attempting to turn enemy officer
        _player setVariable ["WB_Honor", _playerHonor - 10, true];
    };

    true
};

/**
 * Exchange prisoner for allied prisoners
 */
WB_fnc_exchangePrisoner = {
    params ["_player", "_prisoner", "_prisonerFaction"];

    private _playerFaction = _player getVariable ["WB_Faction", ""];

    // Check if enemy faction has any of our prisoners
    private _alliedPrisoners = allUnits select {
        _x getVariable ["WB_IsPrisoner", false] &&
        _x getVariable ["WB_Faction", ""] == _playerFaction
    };

    if (count _alliedPrisoners > 0) then {
        // Free one allied prisoner
        private _freedPrisoner = selectRandom _alliedPrisoners;
        _freedPrisoner setVariable ["WB_IsPrisoner", false, true];
        deleteVehicle _freedPrisoner; // Or return to base

        // Release enemy prisoner
        deleteVehicle _prisoner;

        // Honor gain
        private _playerHonor = _player getVariable ["WB_Honor", 0];
        _player setVariable ["WB_Honor", _playerHonor + 15, true];

        // Improve faction relations
        [_player, _prisonerFaction, 10] call WB_fnc_modifyFactionRelation;

        ["SuccessTitleAndText", ["Prisoner Exchange", "Successfully exchanged prisoners. Gained 15 honor"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
    } else {
        ["ErrorTitleAndText", ["Exchange Failed", "No allied prisoners available for exchange"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
    };

    true
};

/**
 * Recruit prisoner into player's faction
 */
WB_fnc_recruitPrisoner = {
    params ["_player", "_prisoner"];

    private _playerFaction = _player getVariable ["WB_Faction", ""];

    // Set prisoner's new faction
    _prisoner setVariable ["WB_Faction", _playerFaction, true];
    _prisoner setVariable ["WB_Rank", 0, true]; // Start at recruit rank
    _prisoner setVariable ["WB_IsPrisoner", false, true];

    // Add to player's companions or troops
    private _companions = _player getVariable ["WB_Companions", []];
    _companions pushBack _prisoner;
    _player setVariable ["WB_Companions", _companions, true];

    // Join player's group
    [_prisoner] joinSilent (group _player);

    // Update appearance/gear to match faction
    [_prisoner, _playerFaction] call WB_fnc_equipFactionGear;

    true
};

/**
 * Modify faction relations
 */
WB_fnc_modifyFactionRelation = {
    params ["_player", "_faction", "_amount"];

    private _relationsVar = format["WB_PlayerRelation_%1_%2", getPlayerUID _player, _faction];
    private _currentRelation = missionNamespace getVariable [_relationsVar, 0];

    missionNamespace setVariable [_relationsVar, (_currentRelation + _amount) max -100 min 100, true];

    diag_log format["[WB] Player %1 relation with %2: %3 (%4)", name _player, _faction, _currentRelation + _amount, _amount];
};

diag_log "[WB] Ransom and prisoner management system initialized";
