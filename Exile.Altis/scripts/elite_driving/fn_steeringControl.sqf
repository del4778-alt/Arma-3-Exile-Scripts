/*
    Steering Control
    
    Applies steering adjustments and speed control to the vehicle.
    Uses smooth interpolation for natural driving.
    
    Params:
    0: Vehicle
    1: Driver
    2: Steer amount (-1 to 1, negative = left)
    3: Target speed (km/h)
*/

params ["_veh", "_driver", "_steerAmount", "_targetSpeed"];

private _currentSpeed = speed _veh;
private _vehDir = getDir _veh;

// ============================================
// APPLY STEERING
// ============================================
if (abs _steerAmount > 0.05) then {
    // Calculate new direction
    private _steerDelta = _steerAmount * 25;  // Max 25 degrees per tick
    
    // Reduce steering at high speed for stability
    if (_currentSpeed > 60) then {
        _steerDelta = _steerDelta * (1 - ((_currentSpeed - 60) / 100));
    };
    
    private _newDir = _vehDir + _steerDelta;
    
    // Get a position in the new direction
    private _targetPos = _veh getPos [50, _newDir];
    
    // Order driver to move toward adjusted position
    _driver doMove _targetPos;
    
    // For more responsive steering, use setDir for minor adjustments
    if (abs _steerDelta < 5 && _currentSpeed > 10) then {
        // Smooth direction adjustment
        private _smoothDir = _vehDir + (_steerDelta * 0.3);
        _veh setDir _smoothDir;
    };
};

// ============================================
// SPEED CONTROL
// ============================================
private _speedDiff = _targetSpeed - _currentSpeed;

if (_speedDiff < -20) then {
    // Need to brake significantly
    _driver action ["YOURBRAKE", _veh];
    
    // Force speed reduction for emergency
    if (_targetSpeed < 10) then {
        _veh setVelocity ((velocity _veh) vectorMultiply 0.7);
    };
} else {
    if (_speedDiff < -5) then {
        // Light braking - let off throttle
        _veh setSpeedMode "LIMITED";
    } else {
        // Full speed ahead
        _veh setSpeedMode "FULL";
        
        // Boost acceleration if needed
        if (_speedDiff > 20 && _currentSpeed < 30) then {
            private _vel = velocity _veh;
            private _dir = getDir _veh;
            private _boost = 2;
            
            _veh setVelocity [
                (_vel select 0) + (sin _dir * _boost),
                (_vel select 1) + (cos _dir * _boost),
                _vel select 2
            ];
        };
    };
};

// ============================================
// FORCE FORWARD MOVEMENT (anti-stuck)
// ============================================
if (_currentSpeed < 3 && _targetSpeed > 10) then {
    // Vehicle might be stuck - give it a push
    private _vehDir = getDir _veh;
    private _pushVel = [
        (sin _vehDir) * 5,
        (cos _vehDir) * 5,
        0.5
    ];
    
    _veh setVelocity _pushVel;
    
    diag_log format ["[ELITE DRIVE] Unstuck push applied to %1", typeOf _veh];
};

// ============================================
// STABILITY CONTROL
// ============================================
// Prevent flipping
private _vehUp = vectorUp _veh;
if ((_vehUp select 2) < 0.7) then {
    // Vehicle tilting dangerously - try to stabilize
    private _vel = velocity _veh;
    _veh setVelocity [_vel select 0, _vel select 1, (_vel select 2) max -2];
    
    // Slight upward correction
    _veh setVectorUp [
        (_vehUp select 0) * 0.9,
        (_vehUp select 1) * 0.9,
        ((_vehUp select 2) max 0.7) * 1.1
    ];
};
