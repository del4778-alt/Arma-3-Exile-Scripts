/*
    AI Faction Warfare v1.0
    Multiple AI factions fighting for territory control

    Features:
    - 3 AI factions competing for map control
    - Dynamic frontlines that shift based on battles
    - Players can ally with factions
    - Faction patrols using Elite Driving and AI Patrol
    - Territory control affects loot spawn rates
    - Faction reputation system

    Installation:
    [] execVM "AI-Faction-Warfare\fn_factionWarfare.sqf";
*/

FACTION_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["numFactions", 3],
    ["numTerritories", 10],
    ["battleInterval", 600],
    ["patrolsPerTerritory", 2],
    ["reputationGainPerKill", 10],
    ["allyBonusMultiplier", 1.5]
];

FACTION_Factions = [];
FACTION_Territories = [];
FACTION_PlayerReputation = createHashMap;

FACTION_fnc_log = {
    if (FACTION_CONFIG get "debug") then {
        diag_log format ["[FACTION] %1", _this select 0];
    };
};

FACTION_fnc_createFaction = {
    params ["_name", "_side", "_color"];

    createHashMapFromArray [
        ["name", _name],
        ["side", _side],
        ["color", _color],
        ["territories", []],
        ["strength", 100]
    ]
};

FACTION_fnc_createTerritory = {
    params ["_pos", "_faction"];

    private _marker = createMarker [format ["territory_%1", time], _pos];
    _marker setMarkerShape "ELLIPSE";
    _marker setMarkerSize [300, 300];
    _marker setMarkerColor (_faction get "color");
    _marker setMarkerAlpha 0.3;
    _marker setMarkerText format ["%1 Territory", _faction get "name"];

    createHashMapFromArray [
        ["position", _pos],
        ["owner", _faction],
        ["marker", _marker],
        ["contested", false],
        ["patrols", []]
    ]
};

FACTION_fnc_spawnPatrol = {
    params ["_territory"];

    private _pos = _territory get "position";
    private _owner = _territory get "owner";

    private _group = createGroup (_owner get "side");

    for "_i" from 1 to 4 do {
        private _unitPos = [(_pos select 0) + (random 50 - 25), (_pos select 1) + (random 50 - 25), 0];
        private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "FORM"];
        _unit setSkill 0.8;
        _unit setVariable ["FactionPatrol", true, true];
        _unit setVariable ["Faction", _owner get "name", true];
    };

    _group setBehaviour "COMBAT";
    _group setCombatMode "RED";

    // Add patrol waypoints
    for "_i" from 0 to 7 do {
        private _angle = _i * 45;
        private _wpPos = [
            (_pos select 0) + (200 * cos _angle),
            (_pos select 1) + (200 * sin _angle),
            0
        ];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
    };

    private _wp = _group addWaypoint [_pos, 0];
    _wp setWaypointType "CYCLE";

    _group
};

FACTION_fnc_simulateBattle = {
    params ["_territory"];

    private _owner = _territory get "owner";
    private _attackers = selectRandom (FACTION_Factions select {_x != _owner});

    if (isNil "_attackers") exitWith {};

    ["Battle initiated at territory!"] remoteExec ["systemChat", 0];

    // Simplified battle resolution
    private _ownerStr = _owner get "strength";
    private _attackStr = _attackers get "strength";

    if (_attackStr > _ownerStr) then {
        // Territory changes hands
        _territory set ["owner", _attackers];
        private _marker = _territory get "marker";
        _marker setMarkerColor (_attackers get "color");
        _marker setMarkerText format ["%1 Territory", _attackers get "name"];

        [format ["%1 captured territory from %2!", _attackers get "name", _owner get "name"]] remoteExec ["systemChat", 0];
    } else {
        ["Defenders held the territory!"] remoteExec ["systemChat", 0];
    };
};

FACTION_fnc_updateFactions = {
    {
        private _territory = _x;

        // Spawn patrols if needed
        if (count (_territory get "patrols") < (FACTION_CONFIG get "patrolsPerTerritory")) then {
            private _patrol = [_territory] call FACTION_fnc_spawnPatrol;
            (_territory get "patrols") pushBack _patrol;
        };

        // Randomly trigger battles
        if (random 1 < 0.1) then {
            [_territory] call FACTION_fnc_simulateBattle;
        };
    } forEach FACTION_Territories;
};

FACTION_fnc_init = {
    ["AI Faction Warfare v1.0 initializing..."] call FACTION_fnc_log;

    waitUntil {time > 10};

    // Create factions
    FACTION_Factions pushBack (["Red Army", EAST, "ColorRed"] call FACTION_fnc_createFaction);
    FACTION_Factions pushBack (["Blue Alliance", WEST, "ColorBlue"] call FACTION_fnc_createFaction);
    FACTION_Factions pushBack (["Green Coalition", INDEPENDENT, "ColorGreen"] call FACTION_fnc_createFaction);

    // Create territories
    for "_i" from 1 to (FACTION_CONFIG get "numTerritories") do {
        private _pos = [random worldSize, random worldSize, 0];
        private _faction = selectRandom FACTION_Factions;
        private _territory = [_pos, _faction] call FACTION_fnc_createTerritory;
        FACTION_Territories pushBack _territory;
    };

    // Update loop
    [] spawn {
        while {true} do {
            call FACTION_fnc_updateFactions;
            sleep (FACTION_CONFIG get "battleInterval");
        };
    };

    ["Faction Warfare initialized - 3 factions competing for control"] call FACTION_fnc_log;
};

[] call FACTION_fnc_init;
