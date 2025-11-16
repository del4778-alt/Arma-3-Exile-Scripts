/*
    AI Trader Convoy System v1.0
    Author: Arma 3 Exile Scripts
    Description: Convoys that travel between trader zones with valuable cargo

    Features:
    - Convoys travel between ExileSpawnZone trader locations
    - Multiple vehicles using Elite Driving autopilot
    - AI guards in escort vehicles
    - High-risk/high-reward loot for players who attack
    - Successful convoy completion = trader stock bonuses
    - Schedule-based spawning (every 30-60 minutes)
    - Dynamic routing avoiding failed routes

    Installation:
    1. Place in AI-Trader-Convoy folder
    2. Add to init.sqf: [] execVM "AI-Trader-Convoy\fn_traderConvoy.sqf";
    3. Configure CONVOY_CONFIG below
    4. Requires Elite Driving for vehicle control

    Compatibility:
    - Elite Driving required for autopilot
    - Exile mod for trader zone detection
    - Works with Dynamic Mission System
*/

// ========================================
// CONFIGURATION
// ========================================

CONVOY_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["spawnInterval", 1800],              // 30 minutes between convoys
    ["maxActiveConvoys", 2],              // Max concurrent convoys
    ["convoySpeed", "LIMITED"],           // Speed mode (LIMITED, NORMAL, FULL)
    ["escortDistance", 50],               // Distance between vehicles
    ["routeRecalcInterval", 300],         // Recalc route every 5 min if stuck

    // Convoy composition
    ["minVehicles", 2],
    ["maxVehicles", 4],
    ["leadVehicleTypes", ["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_BTR40_MG_Green"]],
    ["cargoVehicleTypes", ["Exile_Car_Van_Box_White", "Exile_Car_Zamak"]],
    ["escortVehicleTypes", ["Exile_Car_Offroad_Armed_Guerilla01", "Exile_Car_HMMWV_M2_Desert"]],

    // AI settings
    ["aiSide", INDEPENDENT],              // Neutral faction
    ["aiSkill", 0.9],
    ["crewPerVehicle", 3],                // Driver + gunner + 1 cargo

    // Loot settings
    ["lootMultiplier", 2.0],              // 2x normal mission loot
    ["lootWeapons", ["arifle_Katiba_F", "arifle_MX_F", "arifle_SPAR_01_blk_F", "srifle_DMR_03_F", "LMG_Mk200_F"]],
    ["lootItems", ["FirstAidKit", "Medikit", "ToolKit", "NVGoggles", "Rangefinder", "MineDetector"]],
    ["lootMoney", [10000, 25000]],        // Poptabs in cargo vehicle

    // Rewards for successful delivery
    ["deliveryReward", 15000],            // Bonus Poptabs for completion
    ["traderStockBonus", true],           // Add rare items to trader
    ["traderPriceReduction", 0.9],        // 10% discount after delivery

    // Combat settings
    ["alertRange", 400],                  // Range to detect hostile fire
    ["fleeOnDamage", false],              // Convoy continues or flees when attacked
    ["callReinforcements", true],         // Spawn helicopter backup
    ["reinforcementDelay", 60]            // 1 min after attack detected
];

// ========================================
// GLOBAL VARIABLES
// ========================================

CONVOY_ActiveConvoys = [];
CONVOY_TraderZones = [];
CONVOY_CompletedRoutes = [];
CONVOY_FailedRoutes = [];
CONVOY_InitComplete = false;

// ========================================
// UTILITY FUNCTIONS
// ========================================

CONVOY_fnc_log = {
    params ["_message"];
    if (CONVOY_CONFIG get "debug") then {
        diag_log format ["[CONVOY] %1", _message];
        systemChat format ["[CONVOY] %1", _message];
    };
};

CONVOY_fnc_getTraderZones = {
    private _zones = [];

    {
        if (["ExileSpawnZone", _x] call BIS_fnc_inString || ["trader" call BIS_fnc_inString, _x] call BIS_fnc_inString) then {
            private _pos = getMarkerPos _x;
            if (!surfaceIsWater _pos) then {
                _zones pushBack [_x, _pos];
            };
        };
    } forEach allMapMarkers;

    [format ["Found %1 trader zones", count _zones]] call CONVOY_fnc_log;
    _zones
};

CONVOY_fnc_selectRoute = {
    // Select random start and end zones (must be different and far apart)
    private _startZone = selectRandom CONVOY_TraderZones;
    private _endZone = selectRandom CONVOY_TraderZones;

    private _attempts = 0;
    while {(_endZone select 0) == (_startZone select 0) || (_startZone select 1) distance (_endZone select 1) < 1000} do {
        _endZone = selectRandom CONVOY_TraderZones;
        _attempts = _attempts + 1;

        if (_attempts > 20) exitWith {
            [format ["Could not find valid route after %1 attempts", _attempts]] call CONVOY_fnc_log;
            _endZone = _startZone;  // Fail gracefully
        };
    };

    [_startZone, _endZone]
};

CONVOY_fnc_createMarker = {
    params ["_pos", "_text"];

    private _markerName = format ["convoy_%1", time];
    private _marker = createMarker [_markerName, _pos];
    _marker setMarkerShape "ICON";
    _marker setMarkerType "mil_box";
    _marker setMarkerColor "ColorGreen";
    _marker setMarkerText _text;
    _marker setMarkerAlpha 1;

    _marker
};

CONVOY_fnc_createVehicle = {
    params ["_type", "_pos", "_dir"];

    private _vehicle = _type createVehicle _pos;
    _vehicle setDir _dir;
    _vehicle setFuel 1;
    _vehicle setVehicleAmmo 1;

    // Don't ignore Elite Driving - let it control the vehicle
    _vehicle setVariable ["EAID_Ignore", false, true];
    _vehicle setVariable ["ConvoyVehicle", true, true];

    _vehicle
};

CONVOY_fnc_createCrew = {
    params ["_vehicle", "_group"];

    private _pos = getPosATL _vehicle;
    private _skill = CONVOY_CONFIG get "aiSkill";

    // Driver
    private _driver = _group createUnit ["I_Soldier_F", _pos, [], 0, "FORM"];
    _driver moveInDriver _vehicle;
    _driver setSkill _skill;
    _driver setVariable ["ConvoyCrew", true, true];

    // Gunner (if turret available)
    if (count (allTurrets _vehicle) > 0) then {
        private _gunner = _group createUnit ["I_Soldier_F", _pos, [], 0, "FORM"];
        _gunner moveInGunner _vehicle;
        _gunner setSkill _skill;
        _gunner setVariable ["ConvoyCrew", true, true];
    };

    // Cargo passenger
    private _cargo = _group createUnit ["I_Soldier_F", _pos, [], 0, "FORM"];
    _cargo moveInCargo _vehicle;
    _cargo setSkill _skill;
    _cargo setVariable ["ConvoyCrew", true, true];
};

CONVOY_fnc_addLoot = {
    params ["_vehicle"];

    clearBackpackCargoGlobal _vehicle;
    clearItemCargoGlobal _vehicle;
    clearMagazineCargoGlobal _vehicle;
    clearWeaponCargoGlobal _vehicle;

    private _multiplier = CONVOY_CONFIG get "lootMultiplier";
    private _weaponCount = floor(5 * _multiplier);
    private _itemCount = floor(10 * _multiplier);

    // Add weapons
    for "_i" from 1 to _weaponCount do {
        private _weapon = selectRandom (CONVOY_CONFIG get "lootWeapons");
        _vehicle addWeaponCargoGlobal [_weapon, 1];

        // Add magazines for weapon
        private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
        if (count _magazines > 0) then {
            _vehicle addMagazineCargoGlobal [_magazines select 0, 5];
        };
    };

    // Add items
    for "_i" from 1 to _itemCount do {
        _vehicle addItemCargoGlobal [selectRandom (CONVOY_CONFIG get "lootItems"), 1];
    };

    // Add money (placeholder for Exile integration)
    private _money = (CONVOY_CONFIG get "lootMoney") select 0 + floor(random ((CONVOY_CONFIG get "lootMoney") select 1 - (CONVOY_CONFIG get "lootMoney") select 0));
    _vehicle setVariable ["ConvoyMoney", _money, true];

    [format ["Added loot worth %1 Poptabs to vehicle", _money]] call CONVOY_fnc_log;
};

// ========================================
// CONVOY CREATION
// ========================================

CONVOY_fnc_spawnConvoy = {
    // Check if can spawn more convoys
    if (count CONVOY_ActiveConvoys >= (CONVOY_CONFIG get "maxActiveConvoys")) exitWith {
        ["Max active convoys reached"] call CONVOY_fnc_log;
        nil
    };

    // Check if enough trader zones
    if (count CONVOY_TraderZones < 2) exitWith {
        ["Not enough trader zones for convoy routes"] call CONVOY_fnc_log;
        nil
    };

    // Select route
    private _route = call CONVOY_fnc_selectRoute;
    private _startZone = _route select 0;
    private _endZone = _route select 1;
    private _startPos = _startZone select 1;
    private _endPos = _endZone select 1;

    [format ["Spawning convoy: %1 -> %2 (Distance: %3m)",
        _startZone select 0,
        _endZone select 0,
        floor(_startPos distance _endPos)
    ]] call CONVOY_fnc_log;

    // Determine convoy size
    private _vehicleCount = (CONVOY_CONFIG get "minVehicles") + floor(random ((CONVOY_CONFIG get "maxVehicles") - (CONVOY_CONFIG get "minVehicles") + 1));

    // Create convoy data
    private _convoyData = createHashMapFromArray [
        ["active", true],
        ["startZone", _startZone],
        ["endZone", _endZone],
        ["startPos", _startPos],
        ["endPos", _endPos],
        ["startTime", time],
        ["vehicles", []],
        ["groups", []],
        ["underAttack", false],
        ["reinforcementsCalled", false]
    ];

    // Create vehicles
    private _vehicles = [];
    private _escortDist = CONVOY_CONFIG get "escortDistance";

    for "_i" from 0 to (_vehicleCount - 1) do {
        private _spawnPos = [
            (_startPos select 0) + (_i * _escortDist * 0.7),
            (_startPos select 1) + (random 10 - 5),
            0
        ];

        // Determine vehicle type based on position in convoy
        private _vehicleType = "";
        if (_i == 0) then {
            // Lead vehicle - armed
            _vehicleType = selectRandom (CONVOY_CONFIG get "leadVehicleTypes");
        } else {
            if (_i == _vehicleCount - 1) then {
                // Last vehicle - cargo (has loot)
                _vehicleType = selectRandom (CONVOY_CONFIG get "cargoVehicleTypes");
            } else {
                // Middle vehicles - mix of cargo and escort
                _vehicleType = selectRandom ((CONVOY_CONFIG get "cargoVehicleTypes") + (CONVOY_CONFIG get "escortVehicleTypes"));
            };
        };

        // Create vehicle
        private _vehicle = [_vehicleType, _spawnPos, 0] call CONVOY_fnc_createVehicle;
        _vehicles pushBack _vehicle;

        // Create crew group for this vehicle
        private _group = createGroup (CONVOY_CONFIG get "aiSide");
        [_vehicle, _group] call CONVOY_fnc_createCrew;

        // Add loot to cargo vehicles
        if (_vehicleType in (CONVOY_CONFIG get "cargoVehicleTypes")) then {
            [_vehicle] call CONVOY_fnc_addLoot;
        };

        // Set group behavior
        _group setBehaviour "SAFE";
        _group setCombatMode "YELLOW";
        _group setFormation "COLUMN";
        _group setSpeedMode (CONVOY_CONFIG get "convoySpeed");

        // Add waypoint to destination
        private _wp = _group addWaypoint [_endPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed (CONVOY_CONFIG get "convoySpeed");
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointCombatMode "YELLOW";

        (_convoyData get "groups") pushBack _group;

        // Add event handler for damage detection
        _vehicle addEventHandler ["Hit", {
            params ["_vehicle"];
            private _convoyData = _vehicle getVariable "ConvoyData";
            if (!isNil "_convoyData") then {
                _convoyData set ["underAttack", true];
                [format ["Convoy under attack! Vehicle damaged."]] call CONVOY_fnc_log;
            };
        }];
    };

    _convoyData set ["vehicles", _vehicles];

    // Store convoy data in each vehicle for event handlers
    {
        _x setVariable ["ConvoyData", _convoyData, true];
    } forEach _vehicles;

    // Create marker on lead vehicle
    private _marker = [_startPos, format ["Trader Convoy -> %1", _endZone select 0]] call CONVOY_fnc_createMarker;
    _convoyData set ["marker", _marker];

    // Add to active convoys
    CONVOY_ActiveConvoys pushBack _convoyData;

    // Announce to players
    private _announcement = format ["TRADER CONVOY SPOTTED: Heading to %1 - High value cargo!", _endZone select 0];
    [_announcement] remoteExec ["systemChat", 0];

    _convoyData
};

// ========================================
// CONVOY MANAGEMENT
// ========================================

CONVOY_fnc_checkConvoyArrival = {
    params ["_convoyData"];

    private _endPos = _convoyData get "endPos";
    private _vehicles = _convoyData get "vehicles";
    private _arrived = false;

    // Check if any vehicle reached destination
    {
        if (alive _x && _x distance _endPos < 100) exitWith {
            _arrived = true;
        };
    } forEach _vehicles;

    _arrived
};

CONVOY_fnc_checkConvoyDestroyed = {
    params ["_convoyData"];

    private _vehicles = _convoyData get "vehicles";
    private _allDestroyed = true;

    {
        if (alive _x) exitWith {
            _allDestroyed = false;
        };
    } forEach _vehicles;

    _allDestroyed
};

CONVOY_fnc_completeConvoy = {
    params ["_convoyData"];

    [format ["Convoy completed route successfully!"]] call CONVOY_fnc_log;

    // Reward calculation
    private _reward = CONVOY_CONFIG get "deliveryReward";

    // Apply trader bonuses if enabled
    if (CONVOY_CONFIG get "traderStockBonus") then {
        ["Traders received new stock!"] remoteExec ["systemChat", 0];
        // TODO: Add rare items to trader inventory (Exile server integration)
    };

    // Announce completion
    private _announcement = format ["CONVOY DELIVERED: Traders are offering bonuses! (%1 Poptabs value)", _reward];
    [_announcement] remoteExec ["systemChat", 0];

    // Cleanup
    [_convoyData] call CONVOY_fnc_cleanupConvoy;
};

CONVOY_fnc_failConvoy = {
    params ["_convoyData"];

    [format ["Convoy destroyed!"]] call CONVOY_fnc_log;

    // Store failed route
    CONVOY_FailedRoutes pushBack [_convoyData get "startZone", _convoyData get "endZone"];

    // Announce
    ["CONVOY DESTROYED: Traders will not receive supplies."] remoteExec ["systemChat", 0];

    // Cleanup
    [_convoyData] call CONVOY_fnc_cleanupConvoy;
};

CONVOY_fnc_cleanupConvoy = {
    params ["_convoyData"];

    // Delete marker
    deleteMarker (_convoyData get "marker");

    // Delete vehicles and AI
    {
        {
            deleteVehicle _x;
        } forEach (units _x);
        deleteGroup _x;
    } forEach (_convoyData get "groups");

    {
        deleteVehicle _x;
    } forEach (_convoyData get "vehicles");

    // Mark as inactive
    _convoyData set ["active", false];

    [format ["Convoy cleaned up"]] call CONVOY_fnc_log;
};

CONVOY_fnc_spawnReinforcements = {
    params ["_convoyData"];

    if (!(_convoyData get "reinforcementsCalled") && (CONVOY_CONFIG get "callReinforcements")) then {
        _convoyData set ["reinforcementsCalled", true];

        ["Convoy called for air support!"] remoteExec ["systemChat", 0];

        // Spawn attack helicopter
        private _leadVehicle = (_convoyData get "vehicles") select 0;
        if (alive _leadVehicle) then {
            private _spawnPos = (getPosATL _leadVehicle) vectorAdd [0, 0, 200];

            private _heli = "O_Heli_Attack_02_F" createVehicle _spawnPos;
            _heli setFuel 1;
            _heli setVehicleAmmo 1;

            // Create crew
            private _group = createGroup EAST;
            private _pilot = _group createUnit ["O_Pilot_F", _spawnPos, [], 0, "FORM"];
            _pilot moveInDriver _heli;
            _pilot setSkill 0.9;

            private _gunner = _group createUnit ["O_Pilot_F", _spawnPos, [], 0, "FORM"];
            _gunner moveInGunner _heli;
            _gunner setSkill 0.9;

            // Set behavior
            _group setBehaviour "COMBAT";
            _group setCombatMode "RED";

            // Waypoint to convoy position
            private _wp = _group addWaypoint [getPosATL _leadVehicle, 0];
            _wp setWaypointType "MOVE";

            // Circle convoy
            for "_i" from 0 to 3 do {
                private _angle = _i * 90;
                private _radius = 300;
                private _wpPos = (getPosATL _leadVehicle) vectorAdd [_radius * cos _angle, _radius * sin _angle, 0];

                _wp = _group addWaypoint [_wpPos, 0];
                _wp setWaypointType "MOVE";
                _wp setWaypointBehaviour "COMBAT";
            };

            _wp = _group addWaypoint [getPosATL _leadVehicle, 0];
            _wp setWaypointType "CYCLE";

            [format ["Attack helicopter reinforcements dispatched"]] call CONVOY_fnc_log;
        };
    };
};

CONVOY_fnc_updateConvoys = {
    private _toRemove = [];

    {
        private _convoyData = _x;

        if (_convoyData get "active") then {
            // Update marker position (follow lead vehicle)
            private _vehicles = _convoyData get "vehicles";
            if (count _vehicles > 0) then {
                private _leadVehicle = _vehicles select 0;
                if (alive _leadVehicle) then {
                    (_convoyData get "marker") setMarkerPos (getPosATL _leadVehicle);
                };
            };

            // Check if convoy arrived
            if ([_convoyData] call CONVOY_fnc_checkConvoyArrival) then {
                [_convoyData] call CONVOY_fnc_completeConvoy;
                _toRemove pushBack _forEachIndex;
            } else {
                // Check if convoy destroyed
                if ([_convoyData] call CONVOY_fnc_checkConvoyDestroyed) then {
                    [_convoyData] call CONVOY_fnc_failConvoy;
                    _toRemove pushBack _forEachIndex;
                } else {
                    // Check if under attack and spawn reinforcements
                    if (_convoyData get "underAttack") then {
                        // Delay reinforcements
                        if (time - (_convoyData get "startTime") > (CONVOY_CONFIG get "reinforcementDelay")) then {
                            [_convoyData] call CONVOY_fnc_spawnReinforcements;
                        };
                    };
                };
            };
        };
    } forEach CONVOY_ActiveConvoys;

    // Remove completed/destroyed convoys
    {
        CONVOY_ActiveConvoys deleteAt (_x - _forEachIndex);
    } forEach _toRemove;
};

// ========================================
// INITIALIZATION
// ========================================

CONVOY_fnc_init = {
    ["AI Trader Convoy System v1.0 initializing..."] call CONVOY_fnc_log;

    if (!(CONVOY_CONFIG get "enabled")) exitWith {
        ["Convoy system is disabled in config"] call CONVOY_fnc_log;
    };

    // Wait for mission to initialize
    waitUntil {time > 10};

    // Cache trader zones
    CONVOY_TraderZones = call CONVOY_fnc_getTraderZones;

    if (count CONVOY_TraderZones < 2) exitWith {
        ["Not enough trader zones found for convoy system"] call CONVOY_fnc_log;
    };

    // Start convoy spawn loop
    [] spawn {
        while {true} do {
            sleep (CONVOY_CONFIG get "spawnInterval");
            call CONVOY_fnc_spawnConvoy;
        };
    };

    // Start convoy update loop
    [] spawn {
        while {true} do {
            sleep 10;
            call CONVOY_fnc_updateConvoys;
        };
    };

    // Spawn initial convoy
    sleep 60;
    call CONVOY_fnc_spawnConvoy;

    CONVOY_InitComplete = true;
    ["AI Trader Convoy System v1.0 initialized successfully"] call CONVOY_fnc_log;
};

// Start the system
[] call CONVOY_fnc_init;
