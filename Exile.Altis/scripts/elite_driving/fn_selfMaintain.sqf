/*
    Self-Maintenance System
    
    Handles automatic repair and refueling.
    - Repair starts at 5% damage
    - Refuel at 25% fuel
    
    Params:
    0: Vehicle
*/

params ["_veh"];

private _repairThreshold = ELITE_DRIVE_CONFIG get "repairThreshold";
private _refuelThreshold = ELITE_DRIVE_CONFIG get "refuelThreshold";

// ============================================
// SELF-REPAIR
// ============================================
private _damage = damage _veh;

if (_damage >= _repairThreshold) then {
    // Gradual repair (5% per tick)
    private _newDamage = (_damage - 0.05) max 0;
    _veh setDamage _newDamage;
    
    // Also repair hit points
    private _hitPoints = getAllHitPointsDamage _veh;
    
    if (count _hitPoints >= 3) then {
        private _hitNames = _hitPoints select 0;
        private _hitDamages = _hitPoints select 2;
        
        {
            private _hitDmg = _hitDamages select _forEachIndex;
            
            if (_hitDmg > 0) then {
                private _newHitDmg = (_hitDmg - 0.1) max 0;
                _veh setHitPointDamage [_x, _newHitDmg];
            };
        } forEach _hitNames;
    };
    
    // Log repair
    if (_damage > 0.2) then {
        diag_log format ["[ELITE DRIVE] Self-repair: %1 damage %2%% -> %3%%", 
            typeOf _veh, round(_damage * 100), round(_newDamage * 100)];
    };
};

// ============================================
// SELF-REFUEL
// ============================================
private _fuel = fuel _veh;

if (_fuel < _refuelThreshold) then {
    // Gradual refuel (10% per tick)
    private _newFuel = (_fuel + 0.1) min 1;
    _veh setFuel _newFuel;
    
    diag_log format ["[ELITE DRIVE] Self-refuel: %1 fuel %2%% -> %3%%",
        typeOf _veh, round(_fuel * 100), round(_newFuel * 100)];
};

// ============================================
// WHEEL REPAIR (specific for wheeled vehicles)
// ============================================
if (_veh isKindOf "Car" || _veh isKindOf "Wheeled_APC_F") then {
    private _wheels = ["HitLFWheel", "HitLF2Wheel", "HitLMWheel", "HitLBWheel",
                       "HitRFWheel", "HitRF2Wheel", "HitRMWheel", "HitRBWheel"];
    
    {
        private _wheelDmg = _veh getHitPointDamage _x;
        
        if (!isNil "_wheelDmg" && _wheelDmg > 0) then {
            _veh setHitPointDamage [_x, 0];
        };
    } forEach _wheels;
};

// ============================================
// ENGINE REPAIR (keep it running)
// ============================================
private _engineDmg = _veh getHitPointDamage "HitEngine";

if (!isNil "_engineDmg" && _engineDmg > 0.1) then {
    _veh setHitPointDamage ["HitEngine", (_engineDmg - 0.15) max 0];
};

// ============================================
// HULL REPAIR
// ============================================
private _hullDmg = _veh getHitPointDamage "HitHull";

if (!isNil "_hullDmg" && _hullDmg > 0.1) then {
    _veh setHitPointDamage ["HitHull", (_hullDmg - 0.1) max 0];
};
