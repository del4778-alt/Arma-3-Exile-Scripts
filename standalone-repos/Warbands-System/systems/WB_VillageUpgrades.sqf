/**
 * Warbands Village Upgrade System
 * Mount & Blade style settlement development
 */

if (!isServer) exitWith {};

WB_Villages = [];

/**
 * Initialize village system
 */
WB_fnc_initVillages = {
    // Define villages with positions and initial states
    WB_Villages = [
        ["Kavala", [3563,12949,0], "WEST", 1, []],       // [Name, Position, Faction, Level, Upgrades]
        ["Athira", [13943,18730,0], "GUER", 1, []],
        ["Pyrgos", [16850,12850,0], "EAST", 1, []],
        ["Sofia", [25500,21300,0], "CIV", 1, []],
        ["Agios Dionysios", [12881,14511,0], "", 1, []],
        ["Zaros", [26218,21193,0], "", 1, []],
        ["Poliakko", [21596,19821,0], "", 1, []],
        ["Katalaki", [23061,20594,0], "", 1, []],
        ["Panagia", [16849,15969,0], "", 1, []],
        ["Selakano", [15768,18824,0], "", 1, []]
    ];

    publicVariable "WB_Villages";

    // Create village markers
    {
        _x params ["_name", "_pos", "_faction", "_level", "_upgrades"];
        [_name, _pos, _faction, _level] call WB_fnc_createVillageMarker;
    } forEach WB_Villages;

    diag_log "[WB] Village system initialized with 10 villages";
};

/**
 * Create village marker
 */
WB_fnc_createVillageMarker = {
    params ["_name", "_pos", "_faction", "_level"];

    private _marker = createMarker [format["village_%1", _name], _pos];
    _marker setMarkerType "loc_settlement";
    _marker setMarkerText format["%1 (Lvl %2)", _name, _level];

    if (_faction != "") then {
        _marker setMarkerColor ([_faction] call WB_fnc_getFactionColor);
    } else {
        _marker setMarkerColor "ColorGrey";
    };
};

/**
 * Upgrade village
 */
WB_fnc_upgradeVillage = {
    params ["_villageName", "_upgradeType", "_player"];

    private _village = [_villageName] call WB_fnc_getVillage;
    if (isNil "_village") exitWith {
        ["ErrorTitleAndText", ["Village Not Found", "Could not find village"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    _village params ["_name", "_pos", "_faction", "_level", "_upgrades"];

    // Check if player has required rank
    private _playerRank = _player getVariable ["WB_Rank", 0];
    if (_playerRank < 3) exitWith {
        ["ErrorTitleAndText", ["Insufficient Rank", "You must be at least Rank 3 to upgrade villages"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    // Check if upgrade already exists
    if (_upgradeType in _upgrades) exitWith {
        ["ErrorTitleAndText", ["Upgrade Exists", "This upgrade is already built"]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    // Get upgrade cost
    private _cost = [_upgradeType, _level] call WB_fnc_getUpgradeCost;

    // Check faction treasury
    private _treasuryVar = format["WB_Treasury_%1", _faction];
    private _treasury = missionNamespace getVariable [_treasuryVar, 0];

    if (_treasury < _cost) exitWith {
        ["ErrorTitleAndText", ["Insufficient Funds", format["This upgrade costs %1 poptabs. Faction treasury: %2", _cost, _treasury]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
        false
    };

    // Deduct cost from treasury
    missionNamespace setVariable [_treasuryVar, _treasury - _cost, true];

    // Add upgrade
    _upgrades pushBack _upgradeType;
    _village set [4, _upgrades];

    // Build upgrade
    [_name, _pos, _upgradeType] call WB_fnc_buildUpgrade;

    // Check if level should increase
    if (count _upgrades >= (3 * _level)) then {
        _level = _level + 1;
        _village set [3, _level];
        [_villageName, _pos, _faction, _level] call WB_fnc_createVillageMarker;

        ["SuccessTitleAndText", ["Village Level Up!", format["%1 is now Level %2", _name, _level]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];
    };

    publicVariable "WB_Villages";

    ["SuccessTitleAndText", ["Upgrade Complete", format["Built %1 in %2 for %3 poptabs", _upgradeType, _name, _cost]]] remoteExec ["ExileClient_gui_toaster_addTemplateToast", _player];

    true
};

/**
 * Get upgrade cost
 */
WB_fnc_getUpgradeCost = {
    params ["_upgradeType", "_villageLevel"];

    private _baseCost = switch (_upgradeType) do {
        case "walls": {5000};
        case "watchtower": {2500};
        case "market": {3000};
        case "warehouse": {4000};
        case "barracks": {6000};
        case "training_ground": {3500};
        case "workshop": {4500};
        case "inn": {2000};
        case "stable": {3000};
        case "mill": {2500};
        case "smithy": {5000};
        case "school": {8000};
        default {1000};
    };

    // Cost increases with village level
    floor(_baseCost * (1 + (0.3 * _villageLevel)))
};

/**
 * Build upgrade structures
 */
WB_fnc_buildUpgrade = {
    params ["_villageName", "_pos", "_upgradeType"];

    private _objects = [];

    switch (_upgradeType) do {
        case "walls": {
            // Create defensive walls around village
            for "_i" from 0 to 7 do {
                private _wallPos = _pos getPos [50, 45 * _i];
                private _wall = createVehicle ["Land_HBarrier_Big_F", _wallPos, [], 0, "NONE"];
                _wall setDir (45 * _i);
                _objects pushBack _wall;
            };
        };

        case "watchtower": {
            // Create watchtower
            private _tower = createVehicle ["Land_Cargo_Tower_V1_F", _pos getPos [40, 0], [], 0, "NONE"];
            _objects pushBack _tower;

            // Add guards
            private _guardGroup = createGroup civilian;
            for "_i" from 1 to 2 do {
                private _guard = _guardGroup createUnit ["C_man_1", _pos getPos [40, 10 * _i], [], 0, "NONE"];
                _guard setUnitPos "UP";
            };
        };

        case "market": {
            // Create market stalls
            for "_i" from 0 to 4 do {
                private _stall = createVehicle ["Land_Market_stall_F", _pos getPos [20 + (5 * _i), 90], [], 0, "NONE"];
                _objects pushBack _stall;
            };

            // Add trader NPC
            private _traderGroup = createGroup civilian;
            private _trader = _traderGroup createUnit ["C_man_polo_1_F", _pos getPos [25, 90], [], 0, "NONE"];
        };

        case "warehouse": {
            // Create warehouse building
            private _warehouse = createVehicle ["Land_i_Shed_Ind_F", _pos getPos [30, 180], [], 0, "NONE"];
            _objects pushBack _warehouse;

            // Add storage crates
            for "_i" from 1 to 5 do {
                private _crate = createVehicle ["Box_NATO_Ammo_F", _warehouse getPos [random 10, random 360], [], 0, "NONE"];
                _objects pushBack _crate;
            };
        };

        case "barracks": {
            // Create barracks
            private _barracks = createVehicle ["Land_Cargo_House_V1_F", _pos getPos [35, 270], [], 0, "NONE"];
            _objects pushBack _barracks;

            // Add recruits
            private _recruitGroup = createGroup civilian;
            for "_i" from 1 to 5 do {
                private _recruit = _recruitGroup createUnit ["C_man_1", _barracks getPos [random 10, random 360], [], 0, "NONE"];
            };
        };

        case "training_ground": {
            // Create training area
            for "_i" from 0 to 3 do {
                private _target = createVehicle ["TargetP_Inf_F", _pos getPos [50, 30 * _i], [], 0, "NONE"];
                _objects pushBack _target;
            };
        };

        case "workshop": {
            // Create workshop
            private _workshop = createVehicle ["Land_CarService_F", _pos getPos [25, 45], [], 0, "NONE"];
            _objects pushBack _workshop;

            // Add workbench
            private _bench = createVehicle ["Land_Workbench_01_F", _workshop getPos [5, 0], [], 0, "NONE"];
            _objects pushBack _bench;
        };

        case "inn": {
            // Create inn/tavern
            private _inn = createVehicle ["Land_i_Shop_01_V1_F", _pos getPos [20, 135], [], 0, "NONE"];
            _objects pushBack _inn;

            // Add tables and chairs
            for "_i" from 1 to 3 do {
                private _table = createVehicle ["Land_CampingTable_F", _inn getPos [random 10, random 360], [], 0, "NONE"];
                _objects pushBack _table;
            };
        };

        case "stable": {
            // Create stable (vehicle garage)
            private _stable = createVehicle ["Land_i_Garage_V1_F", _pos getPos [40, 225], [], 0, "NONE"];
            _objects pushBack _stable;
        };

        case "mill": {
            // Create mill
            private _mill = createVehicle ["Land_dp_smallFactory_F", _pos getPos [60, 315], [], 0, "NONE"];
            _objects pushBack _mill;
        };

        case "smithy": {
            // Create smithy
            private _smithy = createVehicle ["Land_i_Stone_HouseSmall_V1_F", _pos getPos [30, 90], [], 0, "NONE"];
            _objects pushBack _smithy;

            // Add anvil and forge
            private _forge = createVehicle ["Land_FirePlace_F", _smithy getPos [5, 0], [], 0, "NONE"];
            _objects pushBack _forge;
        };

        case "school": {
            // Create school
            private _school = createVehicle ["Land_School_01_F", _pos getPos [50, 180], [], 0, "NONE"];
            _objects pushBack _school;
        };
    };

    // Store objects for cleanup
    private _villageObjects = missionNamespace getVariable [format["WB_Village_%1_Objects", _villageName], []];
    _villageObjects append _objects;
    missionNamespace setVariable [format["WB_Village_%1_Objects", _villageName], _villageObjects];

    diag_log format["[WB] Built %1 in village %2", _upgradeType, _villageName];

    _objects
};

/**
 * Get village by name
 */
WB_fnc_getVillage = {
    params ["_name"];

    private _village = nil;
    {
        if ((_x select 0) == _name) exitWith {
            _village = _x;
        };
    } forEach WB_Villages;

    _village
};

/**
 * Get village production
 * Based on upgrades and level
 */
WB_fnc_getVillageProduction = {
    params ["_villageName"];

    private _village = [_villageName] call WB_fnc_getVillage;
    if (isNil "_village") exitWith {0};

    _village params ["_name", "_pos", "_faction", "_level", "_upgrades"];

    private _baseProduction = 100 * _level;
    private _upgradeBonus = 0;

    {
        _upgradeBonus = _upgradeBonus + (switch (_x) do {
            case "market": {200};
            case "mill": {150};
            case "workshop": {100};
            case "warehouse": {50};
            default {0};
        });
    } forEach _upgrades;

    _baseProduction + _upgradeBonus
};

/**
 * Village production tick
 */
WB_fnc_villageProductionTick = {
    while {true} do {
        sleep 600; // Every 10 minutes

        {
            _x params ["_name", "_pos", "_faction", "_level", "_upgrades"];

            if (_faction != "") then {
                private _production = [_name] call WB_fnc_getVillageProduction;

                // Add to faction treasury
                private _treasuryVar = format["WB_Treasury_%1", _faction];
                private _treasury = missionNamespace getVariable [_treasuryVar, 0];
                missionNamespace setVariable [_treasuryVar, _treasury + _production, true];

                diag_log format["[WB] Village %1 produced %2 poptabs for %3", _name, _production, _faction];
            };
        } forEach WB_Villages;
    };
};

// Initialize villages on server start
[] call WB_fnc_initVillages;

// Start production tick
[] spawn WB_fnc_villageProductionTick;

diag_log "[WB] Village upgrade system initialized";
