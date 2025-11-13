/**
 * Warbands Siege System
 * Mount & Blade style castle sieges
 */

if (!isServer) exitWith {};

WB_ActiveSieges = [];

/**
 * Start a siege event
 */
WB_fnc_siegeEvent = {
    params ["_fortressID", "_attackerFaction", "_defenderFaction"];

    private _fortress = [_fortressID] call WB_fnc_getFortress;
    if (isNil "_fortress") exitWith {
        diag_log format["[WB] Siege failed: Fortress %1 not found", _fortressID];
        false
    };

    _fortress params ["_fid", "_pos", "_dir", "_template"];

    // Create siege data
    private _siegeData = [
        _fid,                           // Fortress ID
        _pos,                           // Position
        _attackerFaction,               // Attacker
        _defenderFaction,               // Defender
        time,                           // Start time
        time + 3600,                    // End time (1 hour)
        0,                              // Attacker strength
        0,                              // Defender strength
        "preparation",                  // Phase: preparation, assault, victory, defeat
        []                              // Participating players
    ];

    WB_ActiveSieges pushBack _siegeData;
    publicVariable "WB_ActiveSieges";

    // Spawn attacker camp
    [_pos, _attackerFaction] call WB_fnc_spawnSiegeCamp;

    // Reinforce defenders
    [_pos, _defenderFaction, 20] call WB_fnc_reinforceFortress;

    // Notify all players
    [
        "Siege Warning",
        format["%1 is besieging fortress %2! The battle begins in 5 minutes.", _attackerFaction, _fid]
    ] remoteExec ["ExileClient_gui_notification_event_addNotification", -2];

    // Start siege timer
    [_siegeData] spawn WB_fnc_siegeTimer;

    diag_log format["[WB] Siege started: %1 attacking %2 at fortress %3", _attackerFaction, _defenderFaction, _fid];

    true
};

/**
 * Spawn attacker siege camp
 */
WB_fnc_spawnSiegeCamp = {
    params ["_fortressPos", "_faction"];

    // Find suitable position for camp (300-500m from fortress)
    private _campPos = _fortressPos getPos [400, random 360];

    // Create camp marker
    private _marker = createMarker [format["siege_camp_%1", time], _campPos];
    _marker setMarkerType "mil_objective";
    _marker setMarkerColor ([_faction] call WB_fnc_getFactionColor);
    _marker setMarkerText format["%1 Siege Camp", _faction];

    // Spawn camp objects
    private _campObjects = [];

    // Command tent
    private _tent = createVehicle ["Land_MedicalTent_01_NATO_generic_open_F", _campPos, [], 0, "NONE"];
    _campObjects pushBack _tent;

    // Supply crates
    for "_i" from 0 to 4 do {
        private _cratePos = _campPos getPos [5 + random 10, random 360];
        private _crate = createVehicle ["Box_NATO_Ammo_F", _cratePos, [], 0, "NONE"];
        _campObjects pushBack _crate;
    };

    // Spawn siege equipment
    for "_i" from 0 to 2 do {
        private _vehiclePos = _campPos getPos [15 + random 15, random 360];
        private _vehicle = createVehicle ["B_MRAP_01_hmg_F", _vehiclePos, [], 0, "NONE"];
        _campObjects pushBack _vehicle;
    };

    // Spawn attacker troops
    private _attackGroup = [_campPos, _faction, 25] call WB_fnc_spawnWarband;

    // Set camp guard behavior
    {
        _x setUnitPos "MIDDLE";
    } forEach (units _attackGroup);

    [_campObjects, _attackGroup, _marker]
};

/**
 * Reinforce fortress garrison
 */
WB_fnc_reinforceFortress = {
    params ["_fortressPos", "_faction", "_count"];

    private _defenderGroup = [_fortressPos, _faction, _count] call WB_fnc_spawnWarband;

    // Position defenders inside fortress
    {
        private _defPos = _fortressPos getPos [random 30, random 360];
        _x setPos _defPos;
        _x setUnitPos "UP";
    } forEach (units _defenderGroup);

    _defenderGroup setBehaviour "COMBAT";
    _defenderGroup setCombatMode "RED";

    _defenderGroup
};

/**
 * Siege timer and phase management
 */
WB_fnc_siegeTimer = {
    params ["_siegeData"];

    _siegeData params ["_fid", "_pos", "_attacker", "_defender", "_startTime", "_endTime", "_atkStr", "_defStr", "_phase", "_players"];

    // Preparation phase (5 minutes)
    sleep 300;

    // Update phase to assault
    _siegeData set [8, "assault"];
    publicVariable "WB_ActiveSieges";

    [
        "Siege Alert",
        format["The siege of fortress %1 has begun! Join the battle!", _fid]
    ] remoteExec ["ExileClient_gui_notification_event_addNotification", -2];

    // Monitor siege progress
    private _attackersAlive = {alive _x && side _x == ([_attacker] call WB_fnc_getFactionSide)} count allUnits;
    private _defendersAlive = {alive _x && side _x == ([_defender] call WB_fnc_getFactionSide)} count allUnits;

    while {time < _endTime && _attackersAlive > 0 && _defendersAlive > 0} do {
        sleep 30;

        // Recount forces
        _attackersAlive = {alive _x && side _x == ([_attacker] call WB_fnc_getFactionSide)} count allUnits;
        _defendersAlive = {alive _x && side _x == ([_defender] call WB_fnc_getFactionSide)} count allUnits;

        // Update siege strength
        _siegeData set [6, _attackersAlive];
        _siegeData set [7, _defendersAlive];
        publicVariable "WB_ActiveSieges";
    };

    // Determine winner
    private _winner = if (_attackersAlive > _defendersAlive) then {_attacker} else {_defender};
    private _newPhase = if (_winner == _attacker) then {"victory"} else {"defeat"};

    _siegeData set [8, _newPhase];
    publicVariable "WB_ActiveSieges";

    // Award siege outcome
    if (_winner == _attacker) then {
        // Attackers win - transfer fortress control
        [_fid, _attacker] call WB_fnc_captureFortress;

        [
            "Siege Complete",
            format["%1 has captured fortress %2!", _attacker, _fid]
        ] remoteExec ["ExileClient_gui_notification_event_addNotification", -2];

        // Award participants
        {
            if (side _x == ([_attacker] call WB_fnc_getFactionSide)) then {
                [_x, 500, 50] remoteExec ["WB_fnc_awardSiegeVictory", _x];
            };
        } forEach allPlayers;

    } else {
        // Defenders win
        [
            "Siege Failed",
            format["%1 has successfully defended fortress %2!", _defender, _fid]
        ] remoteExec ["ExileClient_gui_notification_event_addNotification", -2];

        // Award participants
        {
            if (side _x == ([_defender] call WB_fnc_getFactionSide)) then {
                [_x, 750, 75] remoteExec ["WB_fnc_awardSiegeVictory", _x];
            };
        } forEach allPlayers;
    };

    // Clean up siege
    sleep 600; // Keep siege marker for 10 minutes
    WB_ActiveSieges = WB_ActiveSieges - [_siegeData];
    publicVariable "WB_ActiveSieges";

    deleteMarker format["siege_camp_%1", _startTime];

    diag_log format["[WB] Siege ended: %1 won at fortress %2", _winner, _fid];
};

/**
 * Capture fortress
 */
WB_fnc_captureFortress = {
    params ["_fortressID", "_newFaction"];

    // Update fortress ownership
    private _fortressIndex = (missionNamespace getVariable ["WB_fortressPositions", []]) findIf {(_x select 0) == _fortressID};

    if (_fortressIndex != -1) then {
        private _fortressData = (missionNamespace getVariable ["WB_fortressPositions", []]) select _fortressIndex;
        _fortressData set [4, _newFaction]; // Assume index 4 stores faction

        publicVariable "WB_fortressPositions";

        // Update markers
        [_fortressID, _newFaction] call WB_fnc_updateFortressMarker;

        // Transfer treasury portion
        private _oldFaction = _fortressData select 4;
        if (!isNil "_oldFaction") then {
            private _oldTreasury = missionNamespace getVariable [format["WB_Treasury_%1", _oldFaction], 0];
            private _transferAmount = floor(_oldTreasury * 0.3); // 30% of treasury

            missionNamespace setVariable [format["WB_Treasury_%1", _oldFaction], _oldTreasury - _transferAmount, true];
            missionNamespace setVariable [format["WB_Treasury_%1", _newFaction], (missionNamespace getVariable [format["WB_Treasury_%1", _newFaction], 0]) + _transferAmount, true];
        };

        diag_log format["[WB] Fortress %1 captured by %2", _fortressID, _newFaction];
        true
    } else {
        diag_log format["[WB] Failed to capture fortress %1 - not found", _fortressID];
        false
    };
};

/**
 * Award siege victory to player
 */
WB_fnc_awardSiegeVictory = {
    params ["_player", "_poptabs", "_renown"];

    if (!hasInterface) exitWith {};

    // Award poptabs
    private _playerMoney = _player getVariable ["ExileMoney", 0];
    _player setVariable ["ExileMoney", _playerMoney + _poptabs, true];

    // Award renown
    private _playerRenown = _player getVariable ["WB_Renown", 0];
    _player setVariable ["WB_Renown", _playerRenown + _renown, true];

    // Award experience
    [_renown * 10] call WB_fnc_addExperience;

    ["SuccessTitleAndText", ["Siege Victory", format["Earned %1 poptabs and %2 renown", _poptabs, _renown]]] call ExileClient_gui_toaster_addTemplateToast;
};

/**
 * Get fortress data by ID
 */
WB_fnc_getFortress = {
    params ["_fortressID"];

    private _fortress = nil;
    {
        if ((_x select 0) == _fortressID) exitWith {
            _fortress = _x;
        };
    } forEach (missionNamespace getVariable ["WB_fortressPositions", []]);

    _fortress
};

/**
 * Get faction color for markers
 */
WB_fnc_getFactionColor = {
    params ["_faction"];

    switch (_faction) do {
        case "WEST": {"ColorBlue"};
        case "EAST": {"ColorRed"};
        case "GUER": {"ColorGreen"};
        case "CIV": {"ColorYellow"};
        default {"ColorBlack"};
    };
};

/**
 * Get faction side
 */
WB_fnc_getFactionSide = {
    params ["_faction"];

    switch (_faction) do {
        case "WEST": {west};
        case "EAST": {east};
        case "GUER": {independent};
        case "CIV": {civilian};
        default {sideUnknown};
    };
};

diag_log "[WB] Siege system initialized";
