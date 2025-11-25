/*
    11-Ray Adaptive Scanning System
    
    Scans in multiple directions at different heights:
    - Eye level (driver POV)
    - Ground level (detect low obstacles)
    - Elevated (detect overhead/signs)
    - Side rays (detect road edges)
    
    Params:
    0: Vehicle
    1: Driver
    
    Returns: Array of [direction, distance, objectType] for detected obstacles
*/

params ["_veh", "_driver"];

private _results = [];
private _maxDist = ELITE_DRIVE_CONFIG get "maxScanDistance";
private _vehPos = getPosASL _veh;
private _vehDir = getDir _veh;
private _speed = speed _veh;

// Adjust scan distance based on speed
private _scanDist = _maxDist min (20 + (_speed * 0.8));

// Vehicle dimensions for ray origins
private _bbox = boundingBoxReal _veh;
private _vehWidth = ((_bbox select 1) select 0) - ((_bbox select 0) select 0);
private _vehLength = ((_bbox select 1) select 1) - ((_bbox select 0) select 1);
private _vehHeight = ((_bbox select 1) select 2) - ((_bbox select 0) select 2);

// Ray heights (relative to vehicle)
private _groundHeight = 0.3;
private _eyeHeight = 1.2;
private _highHeight = 2.0;

// ============================================
// RAY DEFINITIONS: [angleOffset, heightLevel, name]
// ============================================
private _rayDefs = [
    // Forward rays (eye level)
    [0, _eyeHeight, "forward_center"],
    [-15, _eyeHeight, "forward_left"],
    [15, _eyeHeight, "forward_right"],
    [-30, _eyeHeight, "wide_left"],
    [30, _eyeHeight, "wide_right"],
    
    // Ground level rays (detect curbs, small obstacles)
    [0, _groundHeight, "ground_center"],
    [-20, _groundHeight, "ground_left"],
    [20, _groundHeight, "ground_right"],
    
    // High rays (detect signs, barriers, overpasses)
    [0, _highHeight, "high_center"],
    [-10, _highHeight, "high_left"],
    [10, _highHeight, "high_right"]
];

// ============================================
// PERFORM RAYCASTS
// ============================================
{
    _x params ["_angleOffset", "_height", "_rayName"];
    
    private _rayDir = _vehDir + _angleOffset;
    private _rayStart = _vehPos vectorAdd [0, 0, _height];
    
    // Calculate end point
    private _rayEnd = _rayStart vectorAdd [
        (sin _rayDir) * _scanDist,
        (cos _rayDir) * _scanDist,
        0
    ];
    
    // Use lineIntersectsSurfaces for precise detection
    private _intersects = lineIntersectsSurfaces [
        _rayStart,
        _rayEnd,
        _veh,
        objNull,
        true,
        1,
        "GEOM",
        "FIRE"
    ];
    
    if (count _intersects > 0) then {
        private _hit = _intersects select 0;
        private _hitPos = _hit select 0;
        private _hitObj = _hit select 2;
        private _distance = _rayStart distance _hitPos;
        
        // Identify object type
        private _objType = "unknown";
        
        if (!isNull _hitObj) then {
            private _class = typeOf _hitObj;
            
            // Categorize the obstacle
            _objType = switch (true) do {
                case (_hitObj isKindOf "Building"): { "building" };
                case (_hitObj isKindOf "Wall"): { "wall" };
                case (_hitObj isKindOf "Fence"): { "fence" };
                case (_class find "sign" >= 0): { "sign" };
                case (_class find "barrier" >= 0): { "barrier" };
                case (_class find "rock" >= 0): { "rock" };
                case (_hitObj isKindOf "LandVehicle"): { "vehicle" };
                case (_hitObj isKindOf "Man"): { "person" };
                case (_hitObj isKindOf "Tree"): { "tree" };
                default { "terrain" };
            };
        } else {
            _objType = "terrain";
        };
        
        _results pushBack [_rayName, _angleOffset, _distance, _objType, _hitPos];
    };
} forEach _rayDefs;

// ============================================
// TOP-DOWN SCAN (for road edges and drop-offs)
// ============================================
private _topDownAngles = [-45, -25, 0, 25, 45];
private _topDownDist = 15;

{
    private _angle = _vehDir + _x;
    private _checkPos = _vehPos vectorAdd [
        (sin _angle) * _topDownDist,
        (cos _angle) * _topDownDist,
        10  // Start from above
    ];
    
    private _groundCheck = lineIntersectsSurfaces [
        _checkPos,
        _checkPos vectorAdd [0, 0, -15],
        _veh,
        objNull,
        true,
        1,
        "GEOM",
        "NONE"
    ];
    
    if (count _groundCheck > 0) then {
        private _groundPos = (_groundCheck select 0) select 0;
        private _heightDiff = (_vehPos select 2) - (_groundPos select 2);
        
        // Detect significant drops (cliffs, edges)
        if (_heightDiff > 2) then {
            _results pushBack ["topdown_drop", _x, _topDownDist, "cliff", _groundPos];
        };
    } else {
        // No ground found - water or void
        _results pushBack ["topdown_void", _x, _topDownDist, "void", [0,0,0]];
    };
} forEach _topDownAngles;

_results
