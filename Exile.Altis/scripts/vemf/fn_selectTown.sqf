// Get all cities on the map using nearestLocations (VEMF only targets bigger towns)
private _mapCenter = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");

// Find cities and capitals only for invasions
private _towns = nearestLocations [_mapCenter, ["NameCity", "NameCityCapital"], _mapSize];

if (count _towns == 0) exitWith {
    diag_log "[UMC][VEMF] No cities found on map";
    nil
};

private _selectedTown = selectRandom _towns;
private _pos = locationPosition _selectedTown;

diag_log format ["[UMC][VEMF] Selected city for invasion: %1 at %2", text _selectedTown, _pos];
_pos
