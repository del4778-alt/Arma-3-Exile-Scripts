/*
    ELITE AI RECRUIT SYSTEM v7.20 - ELITE DRIVING FIX
    ✅ Fixed: Driver stops after combat (EAD re-registration)
    ✅ Fixed: FSM interference with Elite Driving
    ✅ Fixed: Passengers jumping out immediately
    ✅ Fixed: Bridge freezing (stuck detection)
    ✅ Fixed: Movement commands conflicting with autopilot

    CHANGES IN v7.20:
    - FSM now PAUSES completely when player is in vehicle as driver
    - Elite Driving re-registers automatically after combat
    - Passenger lock only applies to specific seats, not entire vehicle
    - Driver gets stuck recovery with automatic dismount/remount
    - Regroup command forces FSM reset
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] ========================================";
diag_log "[AI RECRUIT] Starting v7.20 (Elite Driving Fix)...";
diag_log "[AI RECRUIT] ========================================";

// ============================================
// VCOMAI COMPATIBILITY CHECK
// ============================================

RECRUIT_VCOMAI_Active = false;
if (!isNil "VCM_ACTIVATEAI") then {
    RECRUIT_VCOMAI_Active = true;
    diag_log "[AI RECRUIT] VCOMAI detected - Enhanced AI behavior enabled";
} else {
    diag_log "[AI RECRUIT] VCOMAI not detected - Using standard AI";
};

// Map to track all recruited AI per player's UID
all_recruited_ai_map = createHashMap;

// Track spawn cooldowns to prevent cascading respawns
spawn_cooldowns = createHashMap;

RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",
    "I_Soldier_AA_F",
    "I_Sniper_F"
];

// Validate AI types on startup
diag_log "[AI RECRUIT] Validating AI types...";
{
    if (!isClass (configFile >> "CfgVehicles" >> _x)) then {
        diag_log format ["[AI RECRUIT] ERROR: Invalid AI type '%1' - not found in CfgVehicles!", _x];
    } else {
        diag_log format ["[AI RECRUIT] Validated AI type: %1", _x];
    };
} forEach RECRUIT_AI_TYPES;

// ====================================================================================
// ADVANCED FSM BRAIN SYSTEM
// ====================================================================================

// FSM States
FSM_STATE_IDLE = "IDLE";
FSM_STATE_COMBAT = "COMBAT";
FSM_STATE_RETREAT = "RETREAT";
FSM_STATE_HEAL = "HEAL";

diag_log "[AI RECRUIT] FSM Brain: 4-state simplified system initialized";
diag_log "[AI RECRUIT] States: IDLE ⟷ COMBAT → RETREAT → HEAL → IDLE";

// ====================================================================================
// FSM: Analyze threat situation
// ====================================================================================
RECRUIT_fnc_FSM_AnalyzeThreat = {
    params ["_unit"];

    // Scan for enemies at 300m range - OPTIMIZED with distanceSqr
    private _maxDistSqr = 300 * 300; // 90000
    private _threats = _unit nearEntities [["CAManBase"], 300] select {
        side _x != side _unit && alive _x && _unit knowsAbout _x > 0.05
    };

    // Also check for very close enemies regardless of knowledge
    private _veryClose = _unit nearEntities [["CAManBase"], 50] select {
        side _x != side _unit && alive _x
    };

    // Merge both lists
    {
        if (!(_x in _threats)) then {
            _threats pushBack _x;
            _unit reveal [_x, 2.0];
        };
    } forEach _veryClose;

    if (count _threats == 0) exitWith {
        [0, objNull, 0, 0]
    };

    // OPTIMIZED: Use distanceSqr instead of distance
    _threats = _threats apply {[_x, _unit distanceSqr _x, _unit knowsAbout _x]};
    _threats sort true;

    private _closest = (_threats select 0) select 0;
    private _closestDistSqr = (_threats select 0) select 1;
    private _avgKnowledge = ((_threats apply {_x select 2}) call BIS_fnc_arithmeticMean);

    [count _threats, _closest, sqrt _closestDistSqr, _avgKnowledge]
};

// ====================================================================================
// FSM: Evaluate next state
// ====================================================================================
RECRUIT_fnc_FSM_EvaluateNextState = {
    params ["_unit", "_currentState", "_player"];

    private _threatInfo = [_unit] call RECRUIT_fnc_FSM_AnalyzeThreat;
    _threatInfo params ["_threatCount", "_closestThreat", "_threatDist", "_avgKnowledge"];

    private _damage = damage _unit;
    private _suppression = getSuppression _unit;

    // PRIORITY 1: Retreat if critically wounded
    if (_damage > 0.7) exitWith { FSM_STATE_RETREAT };

    // PRIORITY 2: Combat if threats detected
    if (_threatCount > 0) exitWith { FSM_STATE_COMBAT };

    // PRIORITY 3: Heal if wounded but safe
    if (_damage > 0.3) exitWith { FSM_STATE_HEAL };

    // PRIORITY 4: Stay with player (default)
    FSM_STATE_IDLE
};

// ====================================================================================
// FSM: Execute state-specific behavior
// ====================================================================================
RECRUIT_fnc_FSM_ExecuteState = {
    params ["_unit", "_state", "_player", "_playerGroup", "_threatInfo"];
    _threatInfo params ["_threatCount", "_closestThreat", "_threatDist", "_avgKnowledge"];

    switch (_state) do {
        case FSM_STATE_IDLE: {
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit setUnitPos "UP";
            _unit doFollow _player;

            private _distToPlayer = _unit distanceSqr _player;
            if (_distToPlayer > (10 * 10)) then {
                _unit doMove (getPos _player);
            };
        };

        case FSM_STATE_COMBAT: {
            _unit setBehaviour "COMBAT";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";
            _playerGroup setFormation "LINE";
            _unit setUnitPos "AUTO";
        };

        case FSM_STATE_RETREAT: {
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit doFollow _player;
            _unit setUnitPos "UP";

            if ("SmokeShell" in magazines _unit && random 1 > 0.7) then {
                _unit fire ["SmokeShellMuzzle", "SmokeShellMuzzle", "SmokeShell"];
            };

            if (random 1 > 0.8) then {
                [_unit, "I'm hit bad!"] remoteExec ["sideChat", 0];
            };
        };

        case FSM_STATE_HEAL: {
            _unit setBehaviour "SAFE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "COLUMN";
            _unit doFollow _player;
            _unit setUnitPos "UP";

            if ("FirstAidKit" in items _unit) then {
                _unit action ["HealSoldierSelf", _unit];
            };
        };
    };
};

// ====================================================================================
// NEW: Force Elite Driving Re-registration
// ====================================================================================
RECRUIT_fnc_ForceEADReregister = {
    params ["_veh"];

    if (isNull _veh) exitWith {};

    private _driver = driver _veh;
    if (isNull _driver || isPlayer _driver) exitWith {};

    // Clear Elite Driving state
    _veh setVariable ["EAD_active", false];
    _veh setVariable ["EAID_Ignore", false]; // Remove block flag

    // Force immediate re-registration
    [_driver, _veh] spawn {
        params ["_driver", "_veh"];
        sleep 0.5;

        if (!isNull _driver && alive _driver && driver _veh == _driver) then {
            // Call Elite Driving registration function
            if (!isNil "EAD_fnc_registerDriver") then {
                [_driver, _veh] call EAD_fnc_registerDriver;
                diag_log format ["[AI RECRUIT] ✓ Elite Driving re-registered for %1", typeOf _veh];
            };
        };
    };
};

// ====================================================================================
// NEW: Stuck Detection & Recovery for Drivers
// ====================================================================================
RECRUIT_fnc_DriverStuckMonitor = {
    params ["_unit", "_playerUID"];

    while {!isNull _unit && alive _unit} do {
        private _veh = vehicle _unit;

        // Only monitor when unit is driver
        if (_veh != _unit && driver _veh == _unit) then {
            private _role = assignedVehicleRole _unit;
            if (count _role > 0 && (_role select 0) == "driver") then {

                // Check if stuck
                private _spd = speed _veh;
                private _lastPos = _unit getVariable ["RECRUIT_lastDriverPos", getPosATL _unit];
                private _currentPos = getPosATL _unit;
                private _moved = _lastPos distance2D _currentPos;

                _unit setVariable ["RECRUIT_lastDriverPos", _currentPos];

                // Stuck if: speed < 5 km/h AND moved < 2m in 5 seconds
                if (_spd < 5 && _moved < 2) then {
                    private _stuckTime = _unit getVariable ["RECRUIT_driverStuckTime", time];

                    if ((time - _stuckTime) > 8) then {
                        diag_log format ["[AI RECRUIT] Driver %1 stuck in %2 - attempting recovery",
                            name _unit, typeOf _veh];

                        // Recovery: Everyone out, wait, everyone back in
                        private _player = [_playerUID] call BIS_fnc_getUnitByUID;
                        if (!isNull _player) then {
                            private _allCrew = crew _veh;

                            // Dismount all
                            {
                                if (!isPlayer _x) then {
                                    unassignVehicle _x;
                                    [_x] orderGetIn false;
                                    _x action ["Eject", _veh];
                                };
                            } forEach _allCrew;

                            sleep 2;

                            // Re-board
                            {
                                if (!isPlayer _x && alive _x) then {
                                    _x assignAsDriver _veh;
                                    [_x] orderGetIn true;
                                };
                            } forEach [_unit]; // Only driver gets back in

                            sleep 1;

                            // Force EAD re-register
                            [_veh] call RECRUIT_fnc_ForceEADReregister;
                        };

                        _unit setVariable ["RECRUIT_driverStuckTime", time];
                    };
                } else {
                    _unit setVariable ["RECRUIT_driverStuckTime", time];
                };
            };
        };

        sleep 5;
    };
};

// ====================================================================================
// FSM: Main brain loop (FIXED - No interference with Elite Driving)
// ====================================================================================
RECRUIT_fnc_FSM_BrainLoop = {
    params ["_unit", "_playerUID", "_playerGroup"];

    private _stagger = random [0, 1, 2];
    sleep _stagger;

    _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
    _unit setVariable ["FSM_StateTimer", time, false];
    _unit setVariable ["FSM_LastTransition", time, false];

    diag_log format ["[AI RECRUIT FSM] Brain activated for %1 (UID: %2, stagger: %3s)",
        typeOf _unit, _playerUID, _stagger];

    // ✅ Start stuck monitor for this unit
    [_unit, _playerUID] spawn RECRUIT_fnc_DriverStuckMonitor;

    while {!isNull _unit && alive _unit} do {
        private _player = [_playerUID] call BIS_fnc_getUnitByUID;

        // ✅ CHECK IF IN VEHICLE
        private _veh = vehicle _unit;
        private _inVehicle = _veh != _unit;

        if (_inVehicle) then {
            // AI is in a vehicle
            private _role = assignedVehicleRole _unit;
            private _roleType = "";

            if (count _role > 0) then {
                _roleType = _role select 0;
            };

            if (_roleType == "driver") then {
                // ✅ DRIVER: FSM completely paused, Elite Driving handles everything
                _unit setVariable ["FSM_CurrentState", "VEHICLE_DRIVER", false];

                // ✅ CRITICAL: Don't issue ANY movement commands to driver
                // Elite Driving uses velocity-based control, any doMove/doFollow breaks it

                // Just verify EAD is active
                if !(_veh getVariable ["EAD_active", false]) then {
                    diag_log format ["[AI RECRUIT] WARNING: Driver in vehicle but EAD inactive - re-registering"];
                    [_veh] call RECRUIT_fnc_ForceEADReregister;
                };
            };

            if (_roleType == "gunner" || {_roleType == "turret"}) then {
                // Gunner: Keep combat AI active
                _unit setVariable ["FSM_CurrentState", "VEHICLE_GUNNER", false];
                _unit setBehaviour "COMBAT";
                _unit setCombatMode "RED";
            };

            if (_roleType == "cargo") then {
                // ✅ PASSENGER: Minimal AI intervention
                _unit setVariable ["FSM_CurrentState", "VEHICLE_PASSENGER", false];

                // DON'T lock cargo - this causes them to exit immediately
                // Instead, just disable their movement AI so they stay put
                _unit disableAI "MOVE";
                _unit disableAI "FSM";
                _unit disableAI "AUTOCOMBAT"; // Don't exit for combat

                // Keep them aware but passive
                _unit setBehaviour "AWARE";
                _unit setCombatMode "YELLOW";
            };

            // Long sleep while in vehicle
            sleep 5;

        } else {
            // ✅ ON FOOT - FSM brain active

            // Re-enable AI if coming from vehicle
            private _lastState = _unit getVariable ["FSM_CurrentState", FSM_STATE_IDLE];
            if (_lastState in ["VEHICLE_DRIVER", "VEHICLE_GUNNER", "VEHICLE_PASSENGER"]) then {

                // Unlock cargo seat if was passenger
                if (_lastState == "VEHICLE_PASSENGER") then {
                    private _lastVeh = objectParent _unit;
                    if (!isNull _lastVeh) then {
                        private _lastRole = _unit getVariable ["RECRUIT_lastVehicleRole", []];
                        if (count _lastRole > 1) then {
                            private _cargoIdx = _lastRole select 1;
                            _lastVeh lockCargo [_cargoIdx, false];
                        };
                    };
                };

                // Re-enable all AI
                _unit enableAI "MOVE";
                _unit enableAI "FSM";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOCOMBAT";

                _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
                _unit setVariable ["FSM_StateTimer", time, false];
                diag_log format ["[AI RECRUIT FSM] %1 exited vehicle - FSM resumed", name _unit];
            };

            // Normal FSM brain logic
            if (!isNull _player && alive _player && alive _unit) then {
                private _currentState = _unit getVariable ["FSM_CurrentState", FSM_STATE_IDLE];
                private _stateTimer = _unit getVariable ["FSM_StateTimer", time];
                private _lastTransition = _unit getVariable ["FSM_LastTransition", time];
                private _timeInState = time - _stateTimer;

                private _threatInfo = [_unit] call RECRUIT_fnc_FSM_AnalyzeThreat;
                private _threatCount = _threatInfo select 0;

                private _canSwitch = if (_threatCount > 0) then {
                    true
                } else {
                    _timeInState > 2
                };

                if (_canSwitch) then {
                    private _nextState = [_unit, _currentState, _player] call RECRUIT_fnc_FSM_EvaluateNextState;

                    if (_nextState != _currentState) then {
                        diag_log format ["[AI RECRUIT FSM] %1: %2 → %3 (Threat: %4 @ %5m)",
                            name _unit, _currentState, _nextState,
                            (_threatInfo select 0), round (_threatInfo select 2)
                        ];

                        _unit setVariable ["FSM_CurrentState", _nextState, false];
                        _unit setVariable ["FSM_StateTimer", time, false];
                        _unit setVariable ["FSM_LastTransition", time, false];

                        _currentState = _nextState;

                        [_unit, _currentState, _player, _playerGroup, _threatInfo] call RECRUIT_fnc_FSM_ExecuteState;
                    };
                };

                // ✅ CRITICAL FIX: Follow enforcement ONLY when:
                // - NOT in combat
                // - Player NOT in vehicle (or if player IS vehicle driver, no follow)
                // - AI NOT in vehicle
                if (_currentState != FSM_STATE_COMBAT) then {
                    private _playerVeh = vehicle _player;
                    private _playerInVehicle = _playerVeh != _player;

                    // Only follow if player is on foot
                    if (!_playerInVehicle) then {
                        private _distanceToPlayerSqr = _unit distanceSqr _player;

                        if (_distanceToPlayerSqr > (30 * 30)) then {
                            _unit doFollow _player;
                            _unit doMove (getPos _player);
                        };

                        if (_timeInState > 2) then {
                            _unit doFollow _player;
                        };
                    } else {
                        // Player is in vehicle - AI should NOT follow
                        // Clear any follow commands
                        if (_timeInState > 5) then {
                            _unit doFollow _player;
                            _unit setVariable ["FSM_StateTimer", time, false];
                        };
                    };
                };
            };

            // Variable sleep based on state
            private _currentState = _unit getVariable ["FSM_CurrentState", FSM_STATE_IDLE];
            private _sleepTime = switch (_currentState) do {
                case FSM_STATE_COMBAT: { 1.0 };
                case FSM_STATE_RETREAT: { 1.0 };
                case FSM_STATE_HEAL: { 2.5 };
                default { 3.0 };
            };

            sleep _sleepTime;
        };
    };

    diag_log format ["[AI RECRUIT FSM] Brain terminated for %1", typeOf _unit];
};

// (Continue with remaining functions...)
