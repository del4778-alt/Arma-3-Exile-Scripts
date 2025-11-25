/*
    VEMF Select Town - Selects a city for invasion
    Returns: [position, name] or nil
*/

// Get all cities on the map using nearestLocations (VEMF only targets bigger towns)
private _mapCenter = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");

// Find cities and capitals only for invasions
private _towns = nearestLocations [_mapCenter, ["NameCity", "NameCityCapital"], _mapSize];

if (count _towns == 0) exitWith {
    diag_log "[UMC][VEMF] No cities found on map";
    nil
};

// Check for active invasions to avoid duplicates
private _activeInvasions = VEMF get "activeInvasions";
private _activeTowns = _activeInvasions apply { _x select 2 };

// Filter out towns with active invasions
private _availableTowns = _towns select { !(text _x in _activeTowns) };

if (count _availableTowns == 0) then {
    _availableTowns = _towns;  // Fall back to all if all have invasions
};

private _selectedTown = selectRandom _availableTowns;
private _pos = locationPosition _selectedTown;
private _name = text _selectedTown;

diag_log format ["[UMC][VEMF] Selected city for invasion: %1 at %2", _name, _pos];

[_pos, _name]
