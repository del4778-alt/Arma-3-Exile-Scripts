/*
    Bridge Detection
    
    Determines if the vehicle is on a bridge structure.
    Used to maintain speed and prevent unnecessary braking.
    
    Params:
    0: Vehicle
    
    Returns: Boolean (true if on bridge)
*/

params ["_veh"];

private _vehPos = getPosASL _veh;
private _vehPosATL = getPosATL _veh;

// ============================================
// METHOD 1: Height above terrain
// ============================================
// Bridges typically have a significant gap between vehicle and actual terrain
private _terrainHeight = getTerrainHeightASL (getPos _veh);
private _heightAboveTerrain = (_vehPos select 2) - _terrainHeight;

// If more than 3 meters above terrain, likely on a bridge
if (_heightAboveTerrain > 3) exitWith { true };

// ============================================
// METHOD 2: Check for bridge objects below
// ============================================
private _checkPos = _vehPos vectorAdd [0, 0, -1];
private _endPos = _vehPos vectorAdd [0, 0, -15];

private _intersects = lineIntersectsSurfaces [
    _checkPos,
    _endPos,
    _veh,
    objNull,
    true,
    5,
    "GEOM",
    "NONE"
];

{
    private _hitObj = _x select 2;
    
    if (!isNull _hitObj) then {
        private _class = typeOf _hitObj;
        private _className = toLower _class;
        
        // Check for bridge-related classnames
        if (_className find "bridge" >= 0 ||
            _className find "pier" >= 0 ||
            _className find "platform" >= 0 ||
            _className find "runway" >= 0) exitWith {
            true
        };
    };
} forEach _intersects;

// ============================================
// METHOD 3: Road segment check
// ============================================
// Check if we're on a road that's elevated
private _nearRoads = (getPos _veh) nearRoads 10;

if (count _nearRoads > 0) then {
    private _road = _nearRoads select 0;
    private _roadPos = getPosASL _road;
    private _roadTerrainHeight = getTerrainHeightASL (getPos _road);
    
    // If road is significantly above terrain, it's likely a bridge
    if ((_roadPos select 2) - _roadTerrainHeight > 2) exitWith { true };
};

// ============================================
// METHOD 4: Surface type check
// ============================================
private _surface = surfaceType (getPos _veh);

// Concrete/metal surfaces at height often indicate bridges
if (_surface in ["#concrete", "#metal", "#asphalt"] && _heightAboveTerrain > 1.5) exitWith {
    true
};

// ============================================
// METHOD 5: Water below check
// ============================================
// If there's water directly below, we're probably on a bridge
private _checkWaterPos = getPos _veh;
_checkWaterPos set [2, 0];

if (surfaceIsWater _checkWaterPos && _vehPosATL select 2 > 2) exitWith {
    true
};

false
