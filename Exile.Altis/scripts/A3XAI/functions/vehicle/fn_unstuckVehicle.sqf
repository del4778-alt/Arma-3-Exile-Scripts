/*
    A3XAI Elite - Unstuck Vehicle
    Comprehensive vehicle recovery with group recreation (Exile Occupation style)

    Parameters:
        0: OBJECT - Vehicle
        1: STRING - Stuck reason

    Returns:
        BOOL - Success

    v2.0: Added group recreation, AI re-enabling, and fuel/ammo management
*/

params ["_vehicle", "_reason"];

if (isNull _vehicle || !alive _vehicle) exitWith {false};

// Track recovery attempts
private _attempts = _vehicle getVariable ["A3XAI_recoveryAttempts", 0];
_attempts = _attempts + 1;
_vehicle setVariable ["A3XAI_recoveryAttempts", _attempts];

// Give up after max attempts
if (_attempts >= (A3XAI_maxRecoveryAttempts max 3)) exitWith {
    [2, format ["Vehicle %1 abandoned after %2 recovery attempts - deleting", typeOf _vehicle, _attempts]] call A3XAI_fnc_log;

    // Despawn vehicle and crew
    {
        deleteVehicle _x;
    } forEach crew _vehicle;

    deleteVehicle _vehicle;
    A3XAI_activeVehicles = A3XAI_activeVehicles - [_vehicle];

    false
};

[3, format ["=== UNSTICK VEHICLE (attempt %1/%2): %3 ===", _attempts, A3XAI_maxRecoveryAttempts, _reason]] call A3XAI_fnc_log;

private _currentPos = getPosATL _vehicle;
private _spawnPos = _vehicle getVariable ["A3XAI_spawnPos", _currentPos];
private _vehClass = typeOf _vehicle;
private _recovered = false;
private _newPos = [];

// ============================================
// STEP 1: Find new safe position
// ============================================

switch (_reason) do {
    case "STEEP_TERRAIN";
    case "OFF_ROAD": {
        // Teleport to nearest flat road
        private _roads = _currentPos nearRoads 200;
        if (count _roads > 0) then {
            _newPos = position (_roads select 0);
        } else {
            // Use findEmptyPosition as fallback
            _newPos = _currentPos findEmptyPosition [0, 150, _vehClass];
        };
    };

    case "WATER": {
        // Teleport to nearest land
        _newPos = [_currentPos, 0, 100, 5, 0, 0.3, 0] call BIS_fnc_findSafePos;
    };

    case "COLLISION": {
        // Move to empty position nearby
        _newPos = _currentPos findEmptyPosition [0, 100, _vehClass];
        if (count _newPos == 0) then {
            // Fallback: move back 20m
            private _dir = getDir _vehicle;
            _newPos = _vehicle getPos [20, _dir + 180];
        };
    };

    case "STUCK_UNKNOWN";
    default {
        // Generic recovery: find any empty position
        _newPos = _currentPos findEmptyPosition [0, 150, _vehClass];
        if (count _newPos == 0) then {
            // Return to spawn position
            _newPos = _spawnPos;
        };
    };
};

// Validate new position
if (count _newPos < 2) then {
    _newPos = _spawnPos;  // Last resort: return to spawn
};

// ============================================
// STEP 2: Get current crew and their group
// ============================================

private _crew = crew _vehicle;
private _oldGroup = if (count _crew > 0) then {group (_crew select 0)} else {grpNull};

[4, format ["Unstick: %1 crew members, moving to %2", count _crew, _newPos]] call A3XAI_fnc_log;

// ============================================
// STEP 3: Relocate vehicle
// ============================================

_vehicle setPos _newPos;
_vehicle setVectorUp [0, 0, 1];
_vehicle setVelocity [0, 0, 0];
_vehicle setFuel 1;
_vehicle setDamage 0;
_vehicle lock 0;

// ============================================
// STEP 4: Recreate group (Exile Occupation style)
// ============================================

if (count _crew > 0 && !isNull _oldGroup) then {
    // Remove dead units from crew list
    _crew = _crew select {alive _x};

    if (count _crew > 0) then {
        // Create new group with same side
        private _side = side _oldGroup;
        private _newGroup = createGroup [_side, true];

        // Transfer all units to new group
        {
            [_x] joinSilent _newGroup;

            // Re-enable all AI systems
            _x enableAI "MOVE";
            _x enableAI "FSM";
            _x enableAI "TARGET";
            _x enableAI "AUTOTARGET";
            _x enableAI "AUTOCOMBAT";

            // Reload ammo
            _x setVehicleAmmo 1;

            // Ensure they're in the vehicle
            if !(vehicle _x == _vehicle) then {
                _x moveInAny _vehicle;
            };
        } forEach _crew;

        // Set new group behavior - HIGH-SPEED recovery
        // v3.18: Changed to CARELESS/FULL for fast recovery (was AWARE/NORMAL)
        _newGroup setBehaviour "CARELESS";   // No speed limit from behavior
        _newGroup setCombatMode "RED";
        _newGroup setSpeedMode "FULL";       // Maximum speed

        // Clear old waypoints
        while {count waypoints _newGroup > 0} do {
            deleteWaypoint [_newGroup, 0];
        };

        // Create waypoint back to spawn area
        private _wp = _newGroup addWaypoint [_spawnPos, 50];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "CARELESS";  // v3.18: Changed from AWARE
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "FULL";          // v3.18: Changed from NORMAL

        // Add patrol waypoint
        private _wp2 = _newGroup addWaypoint [_spawnPos, 200];
        _wp2 setWaypointType "SAD";
        _wp2 setWaypointBehaviour "CARELESS"; // v3.18: Changed from AWARE

        // Cycle waypoint
        private _wp3 = _newGroup addWaypoint [_spawnPos, 0];
        _wp3 setWaypointType "CYCLE";

        // Store new group on vehicle
        _vehicle setVariable ["A3XAI_group", _newGroup, true];

        // Delete old group if empty
        if (count units _oldGroup == 0) then {
            deleteGroup _oldGroup;
        };

        [3, format ["Unstick: Created new group, assigned %1 waypoints", count waypoints _newGroup]] call A3XAI_fnc_log;
    };
};

// ============================================
// STEP 5: If EAD available, recalculate route
// ============================================

if (!isNil "A3XAI_EAD_available" && {A3XAI_EAD_available} && {_vehicle getVariable ["EAD_enabled", false]}) then {
    if (!isNil "EAD_fnc_recalculateRoute") then {
        [_vehicle] call EAD_fnc_recalculateRoute;
        [4, "Unstick: Recalculated EAD route"] call A3XAI_fnc_log;
    };
};

// ============================================
// STEP 6: Reset stuck detection
// ============================================

_vehicle setVariable ["A3XAI_lastPos", getPosATL _vehicle];
_vehicle setVariable ["A3XAI_lastMoveTime", time];
_vehicle setVariable ["A3XAI_stuckCheckTime", time + 30];
_vehicle setVariable ["A3XAI_recoveryAttempts", 0];  // Reset on success

_recovered = true;

[3, format ["=== UNSTICK SUCCESS: %1 moved to %2 ===", _vehClass, _newPos]] call A3XAI_fnc_log;

_recovered
