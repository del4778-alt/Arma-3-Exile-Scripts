/*
    A3XAI Elite - Town Invasion Mission
    AI forces occupy a town - players must clear them out

    Features:
        - Selects random town/village location
        - Multiple AI groups patrol streets and hold buildings
        - Snipers on rooftops
        - High-value loot rewards
        - Military vehicle spawn

    Parameters:
        0: ARRAY - Spawn position [x,y,z] (used as search center)
        1: STRING - Difficulty level

    Returns:
        HASHMAP - Mission data
*/

params ["_pos", "_difficulty"];

private _missionName = format ["Invasion_%1", floor(random 9999)];
[3, format ["Spawning town invasion at %1 (difficulty: %2)", _pos, _difficulty]] call A3XAI_fnc_log;

// Find nearby town/village location
private _locations = nearestLocations [_pos, ["NameVillage", "NameCity", "NameCityCapital", "NameLocal"], 3000];

if (count _locations == 0) exitWith {
    [2, "No suitable town found for invasion mission"] call A3XAI_fnc_log;
    createHashMap
};

// Select random town from nearby locations
private _location = selectRandom _locations;
private _townPos = locationPosition _location;
private _townName = text _location;
private _townSize = size _location;
private _townRadius = ((_townSize select 0) max (_townSize select 1)) max 100;

[3, format ["Town invasion: %1 (radius: %2m)", _townName, _townRadius]] call A3XAI_fnc_log;

// Create mission data structure
private _missionData = createHashMapFromArray [
    ["name", _missionName],
    ["type", "invasion"],
    ["status", "active"],
    ["triggerType", "clear"],
    ["position", _townPos],
    ["townName", _townName],
    ["townRadius", _townRadius],
    ["difficulty", _difficulty],
    ["spawnTime", time],
    ["aiGroups", []],
    ["vehicles", []],
    ["lootBoxes", []],
    ["markers", []]
];

private _missionObjects = [];
private _allGroups = [];

// ✅ v3.20: REDUCED AI - Max 5 AI per mission regardless of difficulty
// Fewer but tougher AI to prevent 144 group limit issues
private _baseCount = switch (_difficulty) do {
    case "easy": {3};
    case "medium": {4};
    case "hard": {5};
    case "extreme": {5};
    default {4};
};

// ✅ v3.20: No scaling - fixed count to keep AI low
private _scaledCount = _baseCount;
private _groupCount = 1;  // Single group only

[3, format ["Invasion: Spawning %1 AI in %2 groups", _scaledCount, _groupCount]] call A3XAI_fnc_log;

// Find buildings in town for positioning
private _buildings = _townPos nearObjects ["House", _townRadius];
_buildings = _buildings select {
    private _positions = _x buildingPos -1;
    count _positions > 0
};

// Spawn patrol groups on streets
for "_g" from 0 to (_groupCount - 1) do {
    private _group = createGroup [EAST, true];

    // ✅ v3.12: CRITICAL - Verify group was created as EAST (Arma 3 has 144 group limit per side)
    if (isNull _group) then {
        [1, format ["Invasion group %1 SKIPPED: createGroup returned null - EAST group limit reached", _g]] call A3XAI_fnc_log;
        continue;
    };

    private _groupSide = side _group;
    if (_groupSide != EAST) then {
        private _eastGroups = {side _x == EAST} count allGroups;
        deleteGroup _group;
        [1, format ["Invasion group %1 SKIPPED: Group created as %2 instead of EAST (EAST groups: %3/144)", _g, _groupSide, _eastGroups]] call A3XAI_fnc_log;
        continue;
    };

    private _groupSize = _scaledCount min 5;  // ✅ v3.20: Use scaled count, max 5

    // Random position in town
    private _spawnPos = _townPos getPos [random _townRadius, random 360];
    _spawnPos = [_spawnPos, 5, 30, 3, 0, 0.3, 0] call BIS_fnc_findSafePos;

    for "_i" from 0 to (_groupSize - 1) do {
        private _unitPos = _spawnPos getPos [3 + random 5, random 360];
        private _unit = _group createUnit ["O_Soldier_F", _unitPos, [], 0, "NONE"];

        // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
        _unit allowDamage false;

        [_unit, _difficulty] call A3XAI_fnc_initAI;
        [_unit, _difficulty] call A3XAI_fnc_setAISkill;
        [_unit, _difficulty] call A3XAI_fnc_equipAI;
        [_unit] call A3XAI_fnc_addAIEventHandlers;
    };

    // Set group behavior - patrol the town
    [_group, "patrol"] call A3XAI_fnc_setGroupBehavior;

    // Create patrol waypoints around town
    for "_w" from 0 to 5 do {
        private _wpPos = _townPos getPos [random _townRadius, 60 * _w];
        private _wp = _group addWaypoint [_wpPos, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointBehaviour "AWARE";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointCompletionRadius 15;
        _wp setWaypointTimeout [10, 20, 30];
    };

    // Cycle waypoints
    private _wp = _group addWaypoint [_townPos, 0];
    _wp setWaypointType "CYCLE";

    _allGroups pushBack _group;
};

// ✅ v3.20: DISABLED defenders - all AI in patrol group (max 5 total)
// v3.12: Spawn building defenders in SHARED GROUP (saves ~10-15 groups!)
private _defenderCount = 0;  // ✅ v3.20: Disabled - keep AI count at 5 max
private _usedBuildings = [];

// Create single shared defender group
private _defenderGroup = createGroup [EAST, true];

if (isNull _defenderGroup) then {
    [1, "Invasion defenders SKIPPED: createGroup returned null - EAST group limit reached"] call A3XAI_fnc_log;
} else {
    private _defGroupSide = side _defenderGroup;
    if (_defGroupSide != EAST) then {
        private _eastGroups = {side _x == EAST} count allGroups;
        deleteGroup _defenderGroup;
        [1, format ["Invasion defenders SKIPPED: Group created as %1 instead of EAST (EAST groups: %2/144)", _defGroupSide, _eastGroups]] call A3XAI_fnc_log;
    } else {
        // Spawn all defenders into the shared group
        for "_d" from 0 to (_defenderCount - 1) do {
            if (count _buildings == 0) exitWith {};

            // Find unused building
            private _building = objNull;
            {
                if !(_x in _usedBuildings) exitWith {
                    _building = _x;
                    _usedBuildings pushBack _x;
                };
            } forEach _buildings;

            if (isNull _building) then {continue};

            private _positions = _building buildingPos -1;
            if (count _positions == 0) then {continue};

            private _defPos = selectRandom _positions;

            private _unit = _defenderGroup createUnit ["O_Soldier_F", _defPos, [], 0, "NONE"];

            // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
            _unit allowDamage false;

            _unit setPos _defPos;
            _unit setUnitPos "MIDDLE";  // Crouched/kneeling
            _unit disableAI "PATH";  // Stay in building position

            [_unit, _difficulty] call A3XAI_fnc_initAI;
            [_unit, _difficulty] call A3XAI_fnc_setAISkill;
            [_unit, _difficulty] call A3XAI_fnc_equipAI;
            [_unit] call A3XAI_fnc_addAIEventHandlers;
        };

        // Set shared group behavior
        if (count units _defenderGroup > 0) then {
            [_defenderGroup, "defend"] call A3XAI_fnc_setGroupBehavior;
            _defenderGroup setCombatMode "RED";
            _allGroups pushBack _defenderGroup;
            [4, format ["Invasion: %1 building defenders in 1 shared group", count units _defenderGroup]] call A3XAI_fnc_log;
        } else {
            deleteGroup _defenderGroup;
        };
    };
};

// ✅ v3.20: DISABLED snipers - all AI in patrol group (max 5 total)
// v3.12: Spawn snipers in SHARED GROUP (saves 2-4 groups!)
if (false) then {  // ✅ v3.20: Disabled to keep AI at 5 max
    private _sniperCount = 0;

    // Find tallest buildings
    private _tallBuildings = _buildings select {
        private _positions = _x buildingPos -1;
        if (count _positions == 0) exitWith {false};
        private _topPos = _positions select (count _positions - 1);
        (_topPos select 2) > 5  // At least 5m high
    };

    // Create single shared sniper group
    private _sniperGroup = createGroup [EAST, true];

    if (isNull _sniperGroup) then {
        [1, "Invasion snipers SKIPPED: createGroup returned null - EAST group limit reached"] call A3XAI_fnc_log;
    } else {
        private _sniperGroupSide = side _sniperGroup;
        if (_sniperGroupSide != EAST) then {
            private _eastGroups = {side _x == EAST} count allGroups;
            deleteGroup _sniperGroup;
            [1, format ["Invasion snipers SKIPPED: Group created as %1 instead of EAST (EAST groups: %2/144)", _sniperGroupSide, _eastGroups]] call A3XAI_fnc_log;
        } else {
            // Spawn all snipers into the shared group
            for "_s" from 0 to ((_sniperCount - 1) min (count _tallBuildings - 1)) do {
                private _building = _tallBuildings select _s;
                private _positions = _building buildingPos -1;
                private _topPos = _positions select (count _positions - 1);  // Highest position

                private _sniper = _sniperGroup createUnit ["O_sniper_F", _topPos, [], 0, "NONE"];

                // ✅ v3.7: CRITICAL - Spawn protection IMMEDIATELY after creation
                _sniper allowDamage false;

                _sniper setPos _topPos;
                _sniper setUnitPos "DOWN";  // Prone
                _sniper disableAI "PATH";   // Stay on rooftop position

                [_sniper, _difficulty] call A3XAI_fnc_initAI;
                [_sniper, _difficulty] call A3XAI_fnc_setAISkill;

                // Give sniper rifle
                removeAllWeapons _sniper;
                _sniper addWeapon "srifle_GM6_F";
                _sniper addMagazine "5Rnd_127x108_Mag";
                _sniper addMagazine "5Rnd_127x108_Mag";
                _sniper addMagazine "5Rnd_127x108_Mag";

                [_sniper] call A3XAI_fnc_addAIEventHandlers;

                [4, format ["Invasion: Sniper spawned at height %1m", _topPos select 2]] call A3XAI_fnc_log;
            };

            // Set shared group behavior
            if (count units _sniperGroup > 0) then {
                [_sniperGroup, "defend"] call A3XAI_fnc_setGroupBehavior;
                _sniperGroup setCombatMode "RED";
                _allGroups pushBack _sniperGroup;
                [4, format ["Invasion: %1 snipers in 1 shared group", count units _sniperGroup]] call A3XAI_fnc_log;
            } else {
                deleteGroup _sniperGroup;
            };
        };
    };
};

// Spawn loot crates at town center
private _lootBoxes = [];
private _crateCount = switch (_difficulty) do {
    case "easy": {2};
    case "medium": {3};
    case "hard": {4};
    case "extreme": {6};
    default {2};
};

private _crateTypes = [
    "Box_NATO_Wps_F",
    "Box_NATO_AmmoOrd_F",
    "Box_East_Wps_F",
    "Box_NATO_Support_F"
];

for "_c" from 0 to (_crateCount - 1) do {
    private _cratePos = _townPos getPos [10 + random 20, (360 / _crateCount) * _c];
    private _box = (selectRandom _crateTypes) createVehicle _cratePos;

    [_box, _difficulty, "invasion"] call A3XAI_fnc_spawnLoot;

    _box addEventHandler ["ContainerOpened", {
        params ["_container", "_player"];
        _container setVariable ["looted", true, true];
    }];

    _lootBoxes pushBack _box;
    _missionObjects pushBack _box;
};

// Spawn military vehicles
private _vehCount = switch (_difficulty) do {
    case "easy": {1};
    case "medium": {2};
    case "hard": {3};
    case "extreme": {4};
    default {1};
};

private _vehTypes = [
    "O_MRAP_02_F",
    "O_MRAP_02_hmg_F",
    "O_Truck_02_covered_F",
    "O_APC_Wheeled_02_rcws_F"
];

private _vehicles = [];
for "_v" from 0 to (_vehCount - 1) do {
    private _vehPos = _townPos getPos [_townRadius * 0.7, (360 / _vehCount) * _v];
    _vehPos = [_vehPos, 5, 30, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;

    private _vehicle = (selectRandom _vehTypes) createVehicle _vehPos;
    _vehicle setFuel (0.3 + random 0.4);
    _vehicle setDamage (random 0.3);

    [_vehicle] call A3XAI_fnc_initVehicle;

    _vehicles pushBack _vehicle;
    _missionObjects pushBack _vehicle;
};

// Create markers
if (A3XAI_enableMissionMarkers) then {
    // Area marker
    private _areaMarker = createMarker [format ["%1_area", _missionName], _townPos];
    _areaMarker setMarkerShape "ELLIPSE";
    _areaMarker setMarkerSize [_townRadius, _townRadius];
    _areaMarker setMarkerColor "ColorRed";
    _areaMarker setMarkerAlpha 0.3;

    // Icon marker
    private _iconMarker = createMarker [_missionName, _townPos];
    _iconMarker setMarkerType "mil_warning";
    _iconMarker setMarkerColor "ColorRed";
    _iconMarker setMarkerText format ["Town Invasion: %1 (%2)", _townName, _difficulty];

    _missionData set ["markers", [_areaMarker, _iconMarker]];
};

// Store mission data
_missionData set ["aiGroups", _allGroups];
_missionData set ["vehicles", _vehicles];
_missionData set ["lootBoxes", _lootBoxes];
_missionData set ["missionObjects", _missionObjects];

// Register mission
A3XAI_activeMissions pushBack _missionData;

// Send notification
if (A3XAI_enableMissionNotifications) then {
    private _totalAI = 0;
    {_totalAI = _totalAI + count units _x} forEach _allGroups;

    private _msg = format ["ALERT: Enemy forces have invaded %1! (%2 difficulty, ~%3 hostiles)", _townName, _difficulty, _totalAI];
    remoteExec ["systemChat", -2];
};

[3, format ["Invasion mission '%1' spawned at %2 with %3 groups", _missionName, _townName, count _allGroups]] call A3XAI_fnc_log;

_missionData
