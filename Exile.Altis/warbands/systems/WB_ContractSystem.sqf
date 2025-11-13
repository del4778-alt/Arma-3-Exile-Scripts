/**
 * Warbands Contract System
 * Dynamic mission generation for faction members
 * Based on Mount & Blade quest system
 */

if (!isServer) exitWith {};

WB_ActiveContracts = [];
WB_ContractTypes = [
    "escort_caravan",
    "capture_officer",
    "clear_bandit_camp",
    "raid_village",
    "defend_fortress",
    "assassinate_target",
    "deliver_message",
    "collect_taxes",
    "patrol_territory",
    "rescue_prisoner"
];

/**
 * Generate a new contract
 */
WB_fnc_generateContract = {
    params [["_factionID", ""], ["_difficulty", 1]];

    if (_factionID == "") exitWith {nil};

    _contractType = selectRandom WB_ContractTypes;
    _reward = (500 + (random 1000)) * _difficulty;
    _renownReward = 5 * _difficulty;
    _expiryTime = time + (3600 * 24); // 24 hours

    _contract = switch (_contractType) do {
        case "escort_caravan": {
            _startPos = [getMarkerPos "respawn_west", 0, 3000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _endPos = [getMarkerPos "respawn_east", 0, 3000, 10, 0, 20, 0] call BIS_fnc_findSafePos;

            [
                _contractType,
                "Escort Caravan",
                format["Escort a trade caravan from %1 to %2. Protect it from bandits and hostile forces.", mapGridPosition _startPos, mapGridPosition _endPos],
                _reward,
                _renownReward,
                _expiryTime,
                _factionID,
                _difficulty,
                [_startPos, _endPos]
            ]
        };

        case "capture_officer": {
            _targetPos = [getMarkerPos "respawn_west", 0, 5000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _enemyFaction = selectRandom (["WEST", "EAST", "GUER", "CIV"] - [_factionID]);

            [
                _contractType,
                "Capture Enemy Officer",
                format["Locate and capture a %1 officer near %2. Bring them back alive for interrogation.", _enemyFaction, mapGridPosition _targetPos],
                _reward * 1.5,
                _renownReward * 2,
                _expiryTime,
                _factionID,
                _difficulty,
                [_targetPos, _enemyFaction]
            ]
        };

        case "clear_bandit_camp": {
            _campPos = [getMarkerPos "respawn_west", 0, 4000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _bandits = 5 + (3 * _difficulty);

            [
                _contractType,
                "Clear Bandit Camp",
                format["A bandit camp near %1 is raiding our trade routes. Eliminate all %2 bandits.", mapGridPosition _campPos, _bandits],
                _reward,
                _renownReward,
                _expiryTime,
                _factionID,
                _difficulty,
                [_campPos, _bandits]
            ]
        };

        case "raid_village": {
            _villagePos = [getMarkerPos "respawn_east", 0, 3000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _enemyFaction = selectRandom (["WEST", "EAST", "GUER", "CIV"] - [_factionID]);
            _lootTarget = 1000 * _difficulty;

            [
                _contractType,
                "Raid Enemy Village",
                format["Raid the %1 village at %2. Collect at least %3 supplies and return.", _enemyFaction, mapGridPosition _villagePos, _lootTarget],
                _reward * 1.2,
                -(_renownReward), // Negative honor for raiding
                _expiryTime,
                _factionID,
                _difficulty,
                [_villagePos, _enemyFaction, _lootTarget]
            ]
        };

        case "defend_fortress": {
            _fortressID = selectRandom (missionNamespace getVariable ["WB_fortressPositions", []]);
            if (isNil "_fortressID") exitWith {[]};

            _fortressID params ["_fid", "_pos"];

            [
                _contractType,
                "Defend Fortress",
                format["Enemy forces are gathering to attack fortress %1. Reinforce the garrison and repel the assault.", _fid],
                _reward * 2,
                _renownReward * 3,
                _expiryTime,
                _factionID,
                _difficulty,
                [_pos, _fid]
            ]
        };

        case "assassinate_target": {
            _targetPos = [getMarkerPos "respawn_west", 0, 4000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _enemyFaction = selectRandom (["WEST", "EAST", "GUER", "CIV"] - [_factionID]);

            [
                _contractType,
                "Assassinate Target",
                format["Eliminate the %1 commander at %2. This is a black operation - leave no witnesses.", _enemyFaction, mapGridPosition _targetPos],
                _reward * 3,
                -(_renownReward * 2), // Assassination is dishonorable
                _expiryTime,
                _factionID,
                _difficulty,
                [_targetPos, _enemyFaction]
            ]
        };

        case "deliver_message": {
            _targetPos = [getMarkerPos "respawn_west", 0, 3000, 10, 0, 20, 0] call BIS_fnc_findSafePos;

            [
                _contractType,
                "Deliver Message",
                format["Deliver an urgent message to our outpost at %1. Speed is essential.", mapGridPosition _targetPos],
                _reward * 0.5,
                _renownReward,
                time + 1800, // 30 minute time limit
                _factionID,
                _difficulty,
                [_targetPos]
            ]
        };

        case "collect_taxes": {
            _villagePos = [getMarkerPos "respawn_west", 0, 2000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _taxAmount = 500 * _difficulty;

            [
                _contractType,
                "Collect Taxes",
                format["Collect %1 in taxes from the village at %2. Return with the funds.", _taxAmount, mapGridPosition _villagePos],
                _reward,
                _renownReward,
                _expiryTime,
                _factionID,
                _difficulty,
                [_villagePos, _taxAmount]
            ]
        };

        case "patrol_territory": {
            _patrolPoints = [];
            for "_i" from 0 to (2 + _difficulty) do {
                _pos = [getMarkerPos "respawn_west", 0, 2000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
                _patrolPoints pushBack _pos;
            };

            [
                _contractType,
                "Patrol Territory",
                format["Patrol our territory and check %1 locations for enemy activity.", count _patrolPoints],
                _reward,
                _renownReward,
                _expiryTime,
                _factionID,
                _difficulty,
                [_patrolPoints]
            ]
        };

        case "rescue_prisoner": {
            _prisonPos = [getMarkerPos "respawn_east", 0, 3000, 10, 0, 20, 0] call BIS_fnc_findSafePos;
            _enemyFaction = selectRandom (["WEST", "EAST", "GUER", "CIV"] - [_factionID]);

            [
                _contractType,
                "Rescue Prisoner",
                format["One of our officers is held prisoner by %1 at %2. Rescue them and bring them home.", _enemyFaction, mapGridPosition _prisonPos],
                _reward * 1.5,
                _renownReward * 2,
                _expiryTime,
                _factionID,
                _difficulty,
                [_prisonPos, _enemyFaction]
            ]
        };

        default {[]};
    };

    if (count _contract == 0) exitWith {nil};

    // Add unique ID
    _contractID = format["WB_Contract_%1_%2", floor time, floor random 10000];
    _contract pushBack _contractID;

    // Store contract
    WB_ActiveContracts pushBack _contract;
    publicVariable "WB_ActiveContracts";

    _contract
};

/**
 * Accept a contract
 */
WB_fnc_acceptContract = {
    params ["_contractID", "_player"];

    private _contract = [_contractID] call WB_fnc_getContract;
    if (isNil "_contract") exitWith {
        ["ErrorTitleAndText", ["Contract Error", "Contract not found or already taken"]] call ExileClient_gui_toaster_addTemplateToast;
    };

    _contract params ["_type", "_title", "_desc", "_reward", "_renown", "_expiry", "_faction", "_difficulty", "_data", "_id"];

    // Check if player is in correct faction
    private _playerFaction = _player getVariable ["WB_Faction", ""];
    if (_playerFaction != _faction) exitWith {
        ["ErrorTitleAndText", ["Contract Error", "You must be a member of this faction"]] call ExileClient_gui_toaster_addTemplateToast;
    };

    // Assign contract to player
    _player setVariable ["WB_CurrentContract", _contract, true];

    // Start contract mission
    [_player, _contract] call WB_fnc_startContractMission;

    ["SuccessTitleAndText", ["Contract Accepted", format["%1 - Reward: %2 poptabs", _title, _reward]]] call ExileClient_gui_toaster_addTemplateToast;

    true
};

/**
 * Complete a contract
 */
WB_fnc_completeContract = {
    params ["_player", ["_success", true]];

    private _contract = _player getVariable ["WB_CurrentContract", []];
    if (count _contract == 0) exitWith {false};

    _contract params ["_type", "_title", "_desc", "_reward", "_renown", "_expiry", "_faction", "_difficulty", "_data", "_id"];

    if (_success) then {
        // Award poptabs (Exile currency)
        private _playerMoney = _player getVariable ["ExileMoney", 0];
        _player setVariable ["ExileMoney", _playerMoney + _reward, true];

        // Award renown
        private _playerRenown = _player getVariable ["WB_Renown", 0];
        _player setVariable ["WB_Renown", _playerRenown + _renown, true];

        // Award honor (if applicable)
        if (_renown > 0) then {
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor + floor(_renown / 2), true];
        } else {
            private _playerHonor = _player getVariable ["WB_Honor", 0];
            _player setVariable ["WB_Honor", _playerHonor + _renown, true]; // Negative for dishonorable acts
        };

        // Increase faction treasury
        private _treasuryVar = format["WB_Treasury_%1", _faction];
        private _treasury = missionNamespace getVariable [_treasuryVar, 0];
        missionNamespace setVariable [_treasuryVar, _treasury + (_reward * 0.1), true]; // 10% goes to faction

        ["SuccessTitleAndText", ["Contract Complete", format["Earned %1 poptabs and %2 renown", _reward, _renown]]] call ExileClient_gui_toaster_addTemplateToast;
    } else {
        // Failed contract
        private _playerRenown = _player getVariable ["WB_Renown", 0];
        _player setVariable ["WB_Renown", _playerRenown - (abs _renown), true];

        ["ErrorTitleAndText", ["Contract Failed", format["Lost %1 renown", abs _renown]]] call ExileClient_gui_toaster_addTemplateToast;
    };

    // Clear contract
    _player setVariable ["WB_CurrentContract", nil, true];

    // Remove from active contracts
    WB_ActiveContracts = WB_ActiveContracts - [_contract];
    publicVariable "WB_ActiveContracts";

    true
};

/**
 * Get contract by ID
 */
WB_fnc_getContract = {
    params ["_contractID"];

    private _contract = nil;
    {
        if ((_x select (count _x - 1)) == _contractID) exitWith {
            _contract = _x;
        };
    } forEach WB_ActiveContracts;

    _contract
};

/**
 * Start contract mission
 */
WB_fnc_startContractMission = {
    params ["_player", "_contract"];

    _contract params ["_type", "_title", "_desc", "_reward", "_renown", "_expiry", "_faction", "_difficulty", "_data", "_id"];

    switch (_type) do {
        case "escort_caravan": {
            _data params ["_startPos", "_endPos"];
            [_player, _startPos, _endPos, _id] spawn WB_fnc_mission_escortCaravan;
        };

        case "capture_officer": {
            _data params ["_targetPos", "_enemyFaction"];
            [_player, _targetPos, _enemyFaction, _id] spawn WB_fnc_mission_captureOfficer;
        };

        case "clear_bandit_camp": {
            _data params ["_campPos", "_bandits"];
            [_player, _campPos, _bandits, _id] spawn WB_fnc_mission_clearBandits;
        };

        case "raid_village": {
            _data params ["_villagePos", "_enemyFaction", "_lootTarget"];
            [_player, _villagePos, _enemyFaction, _lootTarget, _id] spawn WB_fnc_mission_raidVillage;
        };

        case "defend_fortress": {
            _data params ["_pos", "_fid"];
            [_player, _pos, _fid, _id] spawn WB_fnc_mission_defendFortress;
        };

        case "deliver_message": {
            _data params ["_targetPos"];
            [_player, _targetPos, _id] spawn WB_fnc_mission_deliverMessage;
        };

        case "collect_taxes": {
            _data params ["_villagePos", "_taxAmount"];
            [_player, _villagePos, _taxAmount, _id] spawn WB_fnc_mission_collectTaxes;
        };

        case "patrol_territory": {
            _data params ["_patrolPoints"];
            [_player, _patrolPoints, _id] spawn WB_fnc_mission_patrol;
        };

        case "rescue_prisoner": {
            _data params ["_prisonPos", "_enemyFaction"];
            [_player, _prisonPos, _enemyFaction, _id] spawn WB_fnc_mission_rescuePrisoner;
        };
    };
};

/**
 * Contract generation loop
 */
WB_fnc_contractLoop = {
    while {true} do {
        sleep 600; // Every 10 minutes

        // Generate new contracts for each faction
        {
            _factionID = _x select 0;
            _difficulty = 1 + floor(random 3);

            // Generate 2-3 contracts per faction
            _contractCount = 2 + floor(random 2);
            for "_i" from 1 to _contractCount do {
                [_factionID, _difficulty] call WB_fnc_generateContract;
            };

        } forEach (missionNamespace getVariable ["WB_fortressPositions", []]);

        // Remove expired contracts
        WB_ActiveContracts = WB_ActiveContracts select {(_x select 5) > time};
        publicVariable "WB_ActiveContracts";
    };
};

// Start contract generation
[] spawn WB_fnc_contractLoop;

diag_log "[WB] Contract system initialized";
