/*
    Occupation Select Town - Selects a town that has players nearby
*/

// Get all towns/villages/cities on the map using nearestLocations
private _mapCenter = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");

// Find all location types that are towns
private _towns = nearestLocations [_mapCenter, ["NameCity", "NameVillage", "NameCityCapital", "NameLocal"], _mapSize];

if (count _towns == 0) exitWith {
    diag_log "[UMC][Occupation] No towns found on map";
    nil
};

// Filter to only towns that have players within 800m
private _validTowns = [];
{
    private _townPos = locationPosition _x;
    private _hasPlayer = false;
    
    {
        if (_x distance2D _townPos < 800) exitWith { _hasPlayer = true };
    } forEach allPlayers;
    
    if (_hasPlayer) then {
        _validTowns pushBack _x;
    };
} forEach _towns;

if (count _validTowns == 0) exitWith {
    // No towns with players nearby
    nil
};

// Check we don't already have a patrol there
private _active = OCC get "activePatrols";
private _availableTowns = [];

{
    private _townPos = locationPosition _x;
    private _hasPatrol = false;
    
    {
        if ((leader _x) distance2D _townPos < 300) exitWith { _hasPatrol = true };
    } forEach _active;
    
    if (!_hasPatrol) then {
        _availableTowns pushBack _x;
    };
} forEach _validTowns;

if (count _availableTowns == 0) exitWith {
    // All nearby towns already have patrols
    nil
};

private _selectedTown = selectRandom _availableTowns;
private _pos = locationPosition _selectedTown;

diag_log format ["[UMC][Occupation] Selected town: %1 at %2", text _selectedTown, _pos];
_pos
