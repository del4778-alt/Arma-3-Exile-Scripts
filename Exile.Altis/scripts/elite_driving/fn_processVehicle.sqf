/*
    Main Vehicle Processing
    
    Analyzes raycast data and determines steering/speed adjustments.
    
    Params:
    0: Vehicle
    1: Driver
*/

params ["_veh", "_driver"];

private _speed = speed _veh;
private _vehDir = getDir _veh;

// ============================================
// RAYCAST SCAN
// ============================================
private _scanResults = [_veh, _driver] call (ELITE_DRIVE get "raycastScan");

// ============================================
// ANALYZE RESULTS
// ============================================
private _obstacleAvoidDist = ELITE_DRIVE_CONFIG get "obstacleAvoidDist";
private _cornerSlowThreshold = ELITE_DRIVE_CONFIG get "cornerSlowThreshold";
private _sharpCornerThreshold = ELITE_DRIVE_CONFIG get "sharpCornerThreshold";
private _minCornerSpeed = ELITE_DRIVE_CONFIG get "minCornerSpeed";

private _leftThreat = 0;
private _rightThreat = 0;
private _centerThreat = 0;
private _groundThreat = false;
private _cliffThreat = false;
private _nearestObstacle = 999;
private _shouldBrake = false;

// Process scan results
{
    _x params ["_rayName", "_angle", "_distance", "_objType", "_hitPos"];
    
    // Track nearest obstacle
    if (_distance < _nearestObstacle) then {
        _nearestObstacle = _distance;
    };
    
    // Calculate threat level (closer = higher threat)
    private _threat = 1 - (_distance / _obstacleAvoidDist);
    _threat = _threat max 0;
    
    // Categorize by direction
    switch (true) do {
        case (_rayName find "left" >= 0): {
            _leftThreat = _leftThreat max _threat;
        };
        case (_rayName find "right" >= 0): {
            _rightThreat = _rightThreat max _threat;
        };
        case (_rayName find "center" >= 0 || _rayName find "forward" >= 0): {
            _centerThreat = _centerThreat max _threat;
        };
        case (_rayName find "ground" >= 0): {
            if (_distance < 10 && _objType in ["fence", "sign", "barrier", "rock"]) then {
                _groundThreat = true;
            };
        };
        case (_rayName find "topdown" >= 0): {
            if (_objType in ["cliff", "void"]) then {
                _cliffThreat = true;
                if (_angle < 0) then { _leftThreat = 1; } else { _rightThreat = 1; };
            };
        };
    };
    
    // Emergency brake for very close obstacles
    if (_distance < 5 && _objType in ["building", "wall", "vehicle", "rock"]) then {
        _shouldBrake = true;
    };
} forEach _scanResults;

// ============================================
// BRIDGE DETECTION
// ============================================
private _onBridge = [_veh] call (ELITE_DRIVE get "detectBridge");

// ============================================
// DETERMINE STEERING
// ============================================
private _steerAmount = 0;

if (_centerThreat > 0.3 || _leftThreat > 0.5 || _rightThreat > 0.5) then {
    // Calculate steer direction based on threat balance
    _steerAmount = (_leftThreat - _rightThreat) * 0.8;
    
    // If center blocked, steer toward less threatened side
    if (_centerThreat > 0.5) then {
        if (_leftThreat < _rightThreat) then {
            _steerAmount = -0.6;  // Steer left
        } else {
            _steerAmount = 0.6;   // Steer right
        };
    };
    
    // Cliff avoidance is highest priority
    if (_cliffThreat) then {
        _steerAmount = _steerAmount * 1.5;
    };
};

// ============================================
// DETERMINE SPEED
// ============================================
private _targetSpeed = 999;  // No limit by default

// Check for upcoming turns (using waypoints if available)
private _grp = group _driver;
private _waypoints = waypoints _grp;

if (count _waypoints > 0) then {
    private _currentWP = currentWaypoint _grp;
    
    if (_currentWP < count _waypoints) then {
        private _wpPos = waypointPosition [_grp, _currentWP];
        private _dirToWP = _veh getDir _wpPos;
        private _angleDiff = abs (_vehDir - _dirToWP);
        
        // Normalize angle
        if (_angleDiff > 180) then { _angleDiff = 360 - _angleDiff };
        
        // Slow for corners
        if (_angleDiff > _sharpCornerThreshold) then {
            _targetSpeed = _minCornerSpeed;
        } else {
            if (_angleDiff > _cornerSlowThreshold) then {
                // Scale speed based on turn sharpness
                _targetSpeed = _minCornerSpeed + ((1 - (_angleDiff / 90)) * 60);
            };
        };
    };
};

// Emergency speed reduction for obstacles
if (_shouldBrake) then {
    _targetSpeed = 5;
} else {
    if (_nearestObstacle < 15) then {
        _targetSpeed = _targetSpeed min (20 + _nearestObstacle * 2);
    };
};

// Bridge handling - maintain speed
if (_onBridge && !_shouldBrake) then {
    _targetSpeed = _targetSpeed max 40;  // Keep moving on bridges
};

// ============================================
// APPLY STEERING
// ============================================
[_veh, _driver, _steerAmount, _targetSpeed] call (ELITE_DRIVE get "steeringControl");
