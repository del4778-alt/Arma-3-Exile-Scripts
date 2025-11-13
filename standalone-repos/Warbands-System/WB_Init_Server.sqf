/**
 * Warbands Server Initialization
 * Loads all Warbands systems for Exile
 * Mount & Blade inspired faction warfare
 */

if (!isServer) exitWith {};

diag_log "[WB] ================================================";
diag_log "[WB] Warbands Server Initialization Starting...";
diag_log "[WB] ================================================";

// Load contract system
call compile preprocessFileLineNumbers "warbands\systems\WB_ContractSystem.sqf";
diag_log "[WB] Contract system loaded";

// Load siege system
call compile preprocessFileLineNumbers "warbands\systems\WB_SiegeSystem.sqf";
diag_log "[WB] Siege system loaded";

// Load ransom/prisoner system
call compile preprocessFileLineNumbers "warbands\systems\WB_RansomSystem.sqf";
diag_log "[WB] Ransom and prisoner system loaded";

// Load village upgrades
call compile preprocessFileLineNumbers "warbands\systems\WB_VillageUpgrades.sqf";
diag_log "[WB] Village upgrade system loaded";

// Load companion system
call compile preprocessFileLineNumbers "warbands\systems\WB_CompanionSystem.sqf";
diag_log "[WB] Companion system loaded";

// Initialize faction treasuries
WB_Treasury_WEST = 10000;
WB_Treasury_EAST = 10000;
WB_Treasury_GUER = 10000;
WB_Treasury_CIV = 10000;

publicVariable "WB_Treasury_WEST";
publicVariable "WB_Treasury_EAST";
publicVariable "WB_Treasury_GUER";
publicVariable "WB_Treasury_CIV";

diag_log "[WB] Faction treasuries initialized at 10000 each";

// Initialize faction relations
WB_FactionRelations = createHashMapFromArray [
    ["WEST_EAST", -50],
    ["WEST_GUER", 0],
    ["WEST_CIV", 25],
    ["EAST_WEST", -50],
    ["EAST_GUER", -25],
    ["EAST_CIV", 0],
    ["GUER_WEST", 0],
    ["GUER_EAST", -25],
    ["GUER_CIV", 10],
    ["CIV_WEST", 25],
    ["CIV_EAST", 0],
    ["CIV_GUER", 10]
];

publicVariable "WB_FactionRelations";

diag_log "[WB] Faction relations initialized";

// Start random siege events
[] spawn {
    sleep 600; // Wait 10 minutes before first siege

    while {true} do {
        sleep 3600 + (random 3600); // Every 1-2 hours

        // Random chance for siege
        if (random 1 < 0.3) then { // 30% chance
            private _fortresses = missionNamespace getVariable ["WB_fortressPositions", []];

            if (count _fortresses > 0) then {
                private _targetFortress = selectRandom _fortresses;
                _targetFortress params ["_fid", "_pos", "_dir", "_template"];

                // Determine factions (defender vs attacker)
                private _defenderFaction = selectRandom ["WEST", "EAST", "GUER", "CIV"];
                private _attackerFaction = selectRandom (["WEST", "EAST", "GUER", "CIV"] - [_defenderFaction]);

                // Check if factions are hostile
                private _relationKey = format["%1_%2", _attackerFaction, _defenderFaction];
                private _relation = WB_FactionRelations getOrDefault [_relationKey, 0];

                if (_relation < -20) then { // Only attack if hostile
                    [_fid, _attackerFaction, _defenderFaction] call WB_fnc_siegeEvent;
                    diag_log format["[WB] Random siege event: %1 attacking %2 at %3", _attackerFaction, _defenderFaction, _fid];
                };
            };
        };
    };
};

diag_log "[WB] Random siege events started";

// Treasury passive income system
[] spawn {
    while {true} do {
        sleep 600; // Every 10 minutes

        // Each faction gets passive income based on owned territories
        {
            _x params ["_factionID"];

            // Count controlled zones
            private _zones = missionNamespace getVariable ["WB_Zones", []];
            private _controlledZones = {(_x select 2) == _factionID} count _zones;

            // Income per zone
            private _income = _controlledZones * 100;

            // Add to treasury
            private _treasuryVar = format["WB_Treasury_%1", _factionID];
            private _treasury = missionNamespace getVariable [_treasuryVar, 0];
            missionNamespace setVariable [_treasuryVar, _treasury + _income, true];

            if (_income > 0) then {
                diag_log format["[WB] Faction %1 earned %2 from %3 zones", _factionID, _income, _controlledZones];
            };

        } forEach [["WEST"], ["EAST"], ["GUER"], ["CIV"]];
    };
};

diag_log "[WB] Treasury passive income started";

// Player persistence system
[] spawn {
    while {true} do {
        sleep 300; // Every 5 minutes

        {
            private _player = _x;
            private _uid = getPlayerUID _player;

            // Save player warbands data to profileNamespace
            // This would integrate with extDB3 in production
            private _wbData = createHashMapFromArray [
                ["faction", _player getVariable ["WB_Faction", ""]],
                ["rank", _player getVariable ["WB_Rank", 0]],
                ["renown", _player getVariable ["WB_Renown", 0]],
                ["honor", _player getVariable ["WB_Honor", 0]],
                ["level", _player getVariable ["WB_Level", 1]],
                ["experience", _player getVariable ["WB_Experience", 0]],
                ["skills", _player getVariable ["WB_Skills", createHashMap]],
                ["skillPoints", _player getVariable ["WB_SkillPoints", 0]]
            ];

            // In production, save to database
            // ["saveWarbandsData", [_uid, _wbData]] call ExileServer_system_database_query_insertSingle;

            profileNamespace setVariable [format["WB_PlayerData_%1", _uid], _wbData];

        } forEach allPlayers;

        saveProfileNamespace;
    };
};

diag_log "[WB] Player persistence system started";

// Companion AI enhancement
[] spawn {
    while {true} do {
        sleep 10;

        // Update all hired companions
        {
            private _companions = _x getVariable ["WB_Companions", []];

            {
                if (alive _x) then {
                    // Apply skill bonuses to companion stats
                    private _skills = _x getVariable ["WB_CompanionSkills", createHashMap];

                    // Marksmanship affects accuracy
                    private _marksmanship = _skills getOrDefault ["Marksmanship", 0];
                    if (_marksmanship > 0) then {
                        _x setSkill ["aimingAccuracy", 0.3 + (_marksmanship * 0.07)];
                    };

                    // IronFlesh affects courage
                    private _ironFlesh = _skills getOrDefault ["IronFlesh", 0];
                    if (_ironFlesh > 0) then {
                        _x setSkill ["courage", 0.5 + (_ironFlesh * 0.05)];
                    };

                    // Tactics affects commanding
                    private _tactics = _skills getOrDefault ["Tactics", 0];
                    if (_tactics > 0) then {
                        _x setSkill ["commanding", 0.3 + (_tactics * 0.07)];
                    };
                };
            } forEach _companions;

        } forEach allPlayers;
    };
};

diag_log "[WB] Companion AI enhancement started";

diag_log "[WB] ================================================";
diag_log "[WB] Warbands Server Initialization Complete!";
diag_log "[WB] All systems operational";
diag_log "[WB] ================================================";
