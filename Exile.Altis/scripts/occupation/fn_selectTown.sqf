// Get all towns/villages/cities on the map using nearestLocations
private _mapCenter = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
private _mapSize = getNumber (configFile >> "CfgWorlds" >> worldName >> "mapSize");

// Find all location types that are towns
private _towns = nearestLocations [_mapCenter, ["NameCity", "NameVillage", "NameCityCapital", "NameLocal"], _mapSize];

if (count _towns == 0) exitWith {
    diag_log "[UMC][Occupation] No towns found on map";
    nil
};

private _selectedTown = selectRandom _towns;
private _pos = locationPosition _selectedTown;

diag_log format ["[UMC][Occupation] Selected town: %1 at %2", text _selectedTown, _pos];
_pos
