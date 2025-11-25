/*
    ELITE AI DRIVING SYSTEM v1.0
    
    Advanced raycast-based driving for all AI vehicles on the server.
    
    Features:
    - 11-ray adaptive scanning (eye level, ground, top-down)
    - LineIntersect collision detection
    - Small obstacle detection (fences, signs, barriers)
    - Bridge crossing without braking
    - Self-repair starting at 5% damage
    - Self-refuel when low
    - No speed limiter (only slow for sharp corners)
    - Physics-based smooth steering
    
    Usage: Automatically applies to all AI-driven vehicles
*/

if (!isServer) exitWith {};

diag_log "[ELITE DRIVE] Initializing Elite AI Driving System v1.0...";

// ============================================
// CONFIGURATION
// ============================================
ELITE_DRIVE_CONFIG = createHashMap;

// Scanning
ELITE_DRIVE_CONFIG set ["scanInterval", 0.15];        // Scan every 150ms
ELITE_DRIVE_CONFIG set ["maxScanDistance", 80];       // Max raycast distance
ELITE_DRIVE_CONFIG set ["obstacleAvoidDist", 25];     // Start avoiding at this distance

// Speed control
ELITE_DRIVE_CONFIG set ["maxSpeed", 999];             // No real limit
ELITE_DRIVE_CONFIG set ["cornerSlowThreshold", 45];   // Slow down for corners > 45 degrees
ELITE_DRIVE_CONFIG set ["sharpCornerThreshold", 75];  // Hard brake for corners > 75 degrees
ELITE_DRIVE_CONFIG set ["minCornerSpeed", 25];        // Minimum speed in sharp corners (km/h)

// Self-maintenance
ELITE_DRIVE_CONFIG set ["repairThreshold", 0.05];     // Start repair at 5% damage
ELITE_DRIVE_CONFIG set ["refuelThreshold", 0.25];     // Refuel at 25% fuel

// Bridge detection
ELITE_DRIVE_CONFIG set ["bridgeSpeedBoost", true];    // Maintain speed on bridges

// ============================================
// GLOBAL TRACKING - Use array instead of HashMap (objects can't be keys)
// ============================================
ELITE_DRIVE_VEHICLES = [];

// ============================================
// LOAD FUNCTIONS
// ============================================
ELITE_DRIVE = createHashMap;

ELITE_DRIVE set ["raycastScan",     compile preprocessFileLineNumbers "scripts\elite_driving\fn_raycastScan.sqf"];
ELITE_DRIVE set ["processVehicle",  compile preprocessFileLineNumbers "scripts\elite_driving\fn_processVehicle.sqf"];
ELITE_DRIVE set ["steeringControl", compile preprocessFileLineNumbers "scripts\elite_driving\fn_steeringControl.sqf"];
ELITE_DRIVE set ["selfMaintain",    compile preprocessFileLineNumbers "scripts\elite_driving\fn_selfMaintain.sqf"];
ELITE_DRIVE set ["registerVehicle", compile preprocessFileLineNumbers "scripts\elite_driving\fn_registerVehicle.sqf"];
ELITE_DRIVE set ["detectBridge",    compile preprocessFileLineNumbers "scripts\elite_driving\fn_detectBridge.sqf"];

// ============================================
// AUTO-REGISTER AI VEHICLES
// ============================================
[] spawn {
    sleep 5;
    
    while {true} do {
        {
            private _veh = _x;
            private _driver = driver _veh;
            
            // Check if AI-driven land vehicle
            if (!isNull _driver && 
                !isPlayer _driver && 
                _veh isKindOf "LandVehicle" &&
                alive _veh &&
                !(_veh in ELITE_DRIVE_VEHICLES)) then {
                
                [_veh] call (ELITE_DRIVE get "registerVehicle");
            };
        } forEach vehicles;
        
        // Cleanup dead/deleted vehicles from tracking
        ELITE_DRIVE_VEHICLES = ELITE_DRIVE_VEHICLES select { !isNull _x && alive _x };
        
        sleep 3;
    };
};

diag_log "[ELITE DRIVE] System Ready - Auto-registering AI vehicles";
