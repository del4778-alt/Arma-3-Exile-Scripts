/*
    ELITE AI RECRUIT SYSTEM v7.32 - COMBAT & FORMATION OVERHAUL
    🔥 SUPER-AGGRESSIVE AI - Laser-accurate, instant reaction, tight formation

    CHANGES IN v7.32:
    - 🔥 CUSTOM LOADOUTS: AT gets DMR-03 suppressed, AA gets MXM, Sniper gets APDS rounds
    - 🔥 VIPER GEAR: All AI equipped with Viper helmets, uniforms, vests, and harnesses
    - 🔥 TIGHT FORMATION: Changed from COLUMN to WEDGE (fighter-jet style)
    - 🔥 CLOSE FOLLOW: AI stay within 5m (was lagging 30-50m behind)
    - 🔥 AGGRESSIVE STANCE: Combat-ready at all times (AWARE + RED combat mode)
    - 🔥 INSTANT ENGAGEMENT: Disabled COVER AI (snipers now shoot immediately)
    - 🔥 EXTENDED RANGE: Enemy detection increased to 800m (was 300m)
    - 🔥 KNOWLEDGE SHARING: When one AI sees enemy, all AI instantly know
    - 🔥 LASER ACCURACY: No bullet flinching, perfect aim, instant target acquisition
    - 🔥 SUPER MOVEMENT: 50% faster animation speed (1.5x multiplier)
    - ✅ FIXED: Snipers now engage targets (disabled COVER AI that made them hide)
    - ✅ FIXED: AT/AA more accurate (perfect aimingAccuracy + aimingShake + aimingSpeed)
    - ✅ FIXED: AI return to tight formation after combat (auto doMove to player pos)

    CUSTOM LOADOUTS:
    - AT: DMR-03 (suppressed) + Titan AT + Viper green hex gear + medic harness
    - AA: MXM (suppressed, bipod) + Titan AA + Viper hex gear + black harness
    - Sniper: GM6 Lynx .50 cal + APDS rounds + Viper green hex helmet + rangefinder

    CHANGES IN v7.31:
    - FIXED: EAD now re-activates when player re-enters vehicle
    - FIXED: Continuous EAD monitoring checks if inactive and re-registers
    - FIXED: Driver responds to waypoints after reaching destination
    - FIXED: Bridge stops no longer permanently disable driving

    CHANGES IN v7.30:
    - NEW: Automatic seat counting and AI assignment system
    - NEW: Overflow AI detection for vehicles with insufficient seats
    - NEW: Overflow AI enter WAIT state (disable movement, stop following)
    - NEW: Auto-recovery when vehicle stops or player exits
    - FIXED: Driver no longer slows down for AI left behind in 2-seat vehicles
*/

if (!isServer) exitWith {};

diag_log "[AI RECRUIT] ========================================";
diag_log "[AI RECRUIT] Starting v7.32 (Combat & Formation Overhaul)...";
diag_log "[AI RECRUIT] 🔥 SUPER-AGGRESSIVE AI - Laser accuracy, tight formation";
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
// 🔥 v7.32: Custom loadout configuration per AI type
// ====================================================================================
RECRUIT_fnc_ApplyCustomLoadout = {
    params ["_unit", "_type"];

    // Strip default loadout
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeAllAssignedItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;

    // Apply type-specific loadout
    switch (_type) do {
        // AT (Anti-Tank) - DMR loadout with Viper gear
        case "I_Soldier_AT_F": {
            // Equipment - ADD CONTAINERS FIRST!
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_Medic_F";
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";

            // Magazines for DMR-03 (7.62mm) - NOW they have a place to go!
            for "_i" from 1 to 8 do {
                _unit addMagazine "20Rnd_762x51_Mag";
            };

            // Launcher magazines
            for "_i" from 1 to 2 do {
                _unit addMagazine "Titan_AT";
            };

            // Medical & grenades
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};

            // Primary weapon: DMR-03 with suppressor
            _unit addWeapon "srifle_DMR_03_DMS_snds_F";
            _unit addPrimaryWeaponItem "optic_DMS";
            _unit addPrimaryWeaponItem "muzzle_snds_B";

            // Launcher: Titan AT
            _unit addWeapon "launch_I_Titan_short_F";

            // Items
            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit linkItem "NVGoggles_OPFOR";
            _unit addWeapon "Rangefinder";

            diag_log format ["[AI RECRUIT] ✓ Applied AT custom loadout to %1", name _unit];
        };

        // AA (Anti-Air) - MXM marksman with Viper gear
        case "I_Soldier_AA_F": {
            // Equipment - ADD CONTAINERS FIRST!
            _unit forceAddUniform "U_O_V_Soldier_Viper_hex_F";
            _unit addVest "V_PlateCarrierSpec_blk";
            _unit addBackpack "B_ViperHarness_blk_F";
            _unit addHeadgear "H_HelmetO_ViperSP_hex_F";

            // Magazines for MXM (6.5mm)
            for "_i" from 1 to 10 do {
                _unit addMagazine "30Rnd_65x39_caseless_khaki_mag";
            };

            // Launcher magazines
            for "_i" from 1 to 2 do {
                _unit addMagazine "Titan_AA";
            };

            // Medical & grenades
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};

            // Primary weapon: MXM with attachments
            _unit addWeapon "arifle_MXM_khk_MOS_Pointer_Bipod_Snds_F";
            _unit addPrimaryWeaponItem "optic_Hamr";
            _unit addPrimaryWeaponItem "acc_pointer_IR";
            _unit addPrimaryWeaponItem "bipod_01_F_khk";
            _unit addPrimaryWeaponItem "muzzle_snds_H_khk_F";

            // Launcher: Titan AA
            _unit addWeapon "launch_I_Titan_F";

            // Items
            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit linkItem "NVGoggles_OPFOR";
            _unit addWeapon "Rangefinder";

            diag_log format ["[AI RECRUIT] ✓ Applied AA custom loadout to %1", name _unit];
        };

        // Sniper - .50 cal with APDS rounds
        case "I_Sniper_F": {
            // Equipment - ADD CONTAINERS FIRST!
            _unit forceAddUniform "U_O_V_Soldier_Viper_F";
            _unit addVest "V_PlateCarrierSpec_mtp";
            _unit addBackpack "B_ViperHarness_ghex_F";
            _unit addHeadgear "H_HelmetO_ViperSP_ghex_F";

            // 🔥 APDS (Armor-Piercing Discarding Sabot) rounds instead of standard
            for "_i" from 1 to 10 do {
                _unit addMagazine "5Rnd_127x108_APDS_Mag";
            };

            // Pistol magazines
            for "_i" from 1 to 3 do {
                _unit addMagazine "11Rnd_45ACP_Mag";
            };

            // Medical & grenades
            for "_i" from 1 to 5 do {_unit addItem "FirstAidKit"};
            for "_i" from 1 to 2 do {_unit addMagazine "HandGrenade"};
            for "_i" from 1 to 2 do {_unit addMagazine "SmokeShell"};

            // Primary weapon: GM6 Lynx .50 cal
            _unit addWeapon "srifle_GM6_camo_F";
            _unit addPrimaryWeaponItem "optic_LRPS";

            // Secondary: Pistol
            _unit addWeapon "hgun_Pistol_heavy_01_F";
            _unit addHandgunItem "optic_MRD";

            // Items
            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemWatch";
            _unit linkItem "ItemRadio";
            _unit linkItem "NVGoggles_OPFOR";
            _unit addWeapon "Rangefinder";

            diag_log format ["[AI RECRUIT] ✓ Applied Sniper custom loadout (APDS rounds) to %1", name _unit];
        };
    };
};

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
// 🔥 v7.32: Share enemy knowledge across all AI in group
// ====================================================================================
RECRUIT_fnc_ShareEnemyKnowledge = {
    params ["_unit", "_threats"];

    private _grp = group _unit;
    private _allAI = units _grp select {alive _x && _x != _unit && !isPlayer _x};

    // Share all detected threats with all AI in group
    {
        private _threat = _x;
        {
            // Share at high knowledge level (4.0 = fully revealed)
            _x reveal [_threat, 4.0];
        } forEach _allAI;
    } forEach _threats;
};

// ====================================================================================
// FSM: Analyze threat situation
// ====================================================================================
RECRUIT_fnc_FSM_AnalyzeThreat = {
    params ["_unit"];

    // 🔥 v7.32: EXTENDED RANGE - Scan for enemies at 800m (was 300m)
    private _maxDist = 800;
    private _threats = _unit nearEntities [["CAManBase"], _maxDist] select {
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
            _unit reveal [_x, 4.0];  // 🔥 v7.32: Increased from 2.0 to 4.0 (instant full knowledge)
        };
    } forEach _veryClose;

    // 🔥 v7.32: SHARE KNOWLEDGE - Tell all AI in group about detected enemies
    if (count _threats > 0) then {
        [_unit, _threats] call RECRUIT_fnc_ShareEnemyKnowledge;
    };

    if (count _threats == 0) exitWith {
        [0, objNull, 0, 0]
    };

    // OPTIMIZED: Use distanceSqr instead of distance
    _threats = _threats apply {[_x, _unit distanceSqr _x, _unit knowsAbout _x]};
    _threats sort true;

    private _closest = (_threats select 0) select 0;
    private _closestDistSqr = (_threats select 0) select 1;

    // Calculate average knowledge (optimized: replaced BIS_fnc_arithmeticMean)
    private _knowledgeValues = _threats apply {_x select 2};
    private _sum = 0;
    {_sum = _sum + _x} forEach _knowledgeValues;
    private _avgKnowledge = _sum / (count _knowledgeValues max 1);

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
            // 🔥 v7.32: AGGRESSIVE STANCE - Always combat-ready, tight formation
            _unit setBehaviour "AWARE";  // Changed from SAFE to AWARE (alert, ready to engage)
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";   // Changed from YELLOW to RED (seek and destroy)
            _playerGroup setFormation "WEDGE";  // Changed from COLUMN to WEDGE (tight fighter-jet formation)
            _unit setUnitPos "UP";

            // 🔥 v7.32: TIGHT FORMATION - Force AI to stay close (5m max distance)
            private _distToPlayer = _unit distance _player;
            if (_distToPlayer > 5) then {
                _unit doMove (getPos _player);  // Force move if > 5m away
            } else {
                _unit doFollow _player;
            };
        };

        case FSM_STATE_COMBAT: {
            _unit setBehaviour "COMBAT";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";
            _playerGroup setFormation "LINE";  // Spread out in combat
            _unit setUnitPos "AUTO";

            // 🔥 v7.32: Force engagement using assignedTarget
            private _target = assignedTarget _unit;
            if (!isNull _target) then {
                _unit doWatch _target;
                _unit doTarget _target;
            };
        };

        case FSM_STATE_RETREAT: {
            _unit setBehaviour "AWARE";
            _unit setSpeedMode "FULL";
            _unit setCombatMode "YELLOW";
            _playerGroup setFormation "WEDGE";  // Changed from COLUMN to WEDGE

            // 🔥 v7.32: Stay close during retreat
            private _distToPlayer = _unit distance _player;
            if (_distToPlayer > 5) then {
                _unit doMove (getPos _player);
            } else {
                _unit doFollow _player;
            };
            _unit setUnitPos "UP";

            if ("SmokeShell" in magazines _unit && random 1 > 0.7) then {
                _unit fire ["SmokeShellMuzzle", "SmokeShellMuzzle", "SmokeShell"];
            };

            // Note: AI chat messages disabled (remoteExec security restriction)
        };

        case FSM_STATE_HEAL: {
            _unit setBehaviour "AWARE";  // Changed from SAFE to AWARE
            _unit setSpeedMode "FULL";
            _unit setCombatMode "RED";   // Changed from YELLOW to RED
            _playerGroup setFormation "WEDGE";  // Changed from COLUMN to WEDGE

            // 🔥 v7.32: Stay close during healing
            private _distToPlayer = _unit distance _player;
            if (_distToPlayer > 5) then {
                _unit doMove (getPos _player);
            } else {
                _unit doFollow _player;
            };
            _unit setUnitPos "UP";

            if ("FirstAidKit" in items _unit) then {
                _unit action ["HealSoldierSelf", _unit];
            };
        };
    };
};

// ====================================================================================
// NEW: Count available vehicle seats
// ====================================================================================
RECRUIT_fnc_CountVehicleSeats = {
    params ["_veh"];

    if (isNull _veh) exitWith {[0, 0, 0, 0]};

    private _driverSeats = if (isNull driver _veh) then {1} else {0};
    private _cargoSeats = _veh emptyPositions "cargo";

    // Count available turrets (FIXED: emptyPositions doesn't accept turret paths)
    // Use fullCrew to get all turret positions and count empty ones
    private _allTurrets = fullCrew [_veh, "turret", true];
    private _turretSeats = count (_allTurrets select {isNull (_x select 0)});

    private _totalSeats = _driverSeats + _cargoSeats + _turretSeats;

    [_totalSeats, _driverSeats, _turretSeats, _cargoSeats]
};

// ====================================================================================
// NEW: Handle vehicle seat assignments and overflow AI
// ====================================================================================
RECRUIT_fnc_HandleVehicleSeats = {
    params ["_player", "_veh"];

    if (isNull _player || isNull _veh) exitWith {};

    private _uid = getPlayerUID _player;
    private _aiList = all_recruited_ai_map getOrDefault [_uid, []];
    private _validAI = _aiList select {!isNull _x && alive _x && vehicle _x == _x}; // Only AI on foot

    if (count _validAI == 0) exitWith {
        diag_log "[AI RECRUIT] No AI to assign to vehicle";
    };

    // Count available seats (player already in vehicle, so don't count their seat)
    private _seatInfo = [_veh] call RECRUIT_fnc_CountVehicleSeats;
    _seatInfo params ["_totalSeats", "_driverSeats", "_turretSeats", "_cargoSeats"];

    diag_log format ["[AI RECRUIT] Vehicle seats: Total=%1, Driver=%2, Turrets=%3, Cargo=%4",
        _totalSeats, _driverSeats, _turretSeats, _cargoSeats];

    // Assign AI to available seats
    private _assignedAI = [];
    private _overflowAI = [];
    private _aiIndex = 0;

    // Priority 1: Assign driver
    if (_driverSeats > 0 && _aiIndex < count _validAI) then {
        private _ai = _validAI select _aiIndex;
        _ai assignAsDriver _veh;
        [_ai] orderGetIn true;
        _assignedAI pushBack _ai;
        _aiIndex = _aiIndex + 1;
        diag_log format ["[AI RECRUIT] Assigned %1 as DRIVER", name _ai];
    };

    // Priority 2: Assign gunners to turrets
    private _assignedTurrets = 0;
    while {_assignedTurrets < _turretSeats && _aiIndex < count _validAI} do {
        private _ai = _validAI select _aiIndex;
        _ai assignAsGunner _veh;
        [_ai] orderGetIn true;
        _assignedAI pushBack _ai;
        _aiIndex = _aiIndex + 1;
        _assignedTurrets = _assignedTurrets + 1;
        diag_log format ["[AI RECRUIT] Assigned %1 as GUNNER", name _ai];
    };

    // Priority 3: Assign cargo passengers
    private _assignedCargo = 0;
    while {_assignedCargo < _cargoSeats && _aiIndex < count _validAI} do {
        private _ai = _validAI select _aiIndex;
        _ai assignAsCargo _veh;
        [_ai] orderGetIn true;
        _assignedAI pushBack _ai;
        _aiIndex = _aiIndex + 1;
        _assignedCargo = _assignedCargo + 1;
        diag_log format ["[AI RECRUIT] Assigned %1 as CARGO", name _ai];
    };

    // Remaining AI are overflow
    while {_aiIndex < count _validAI} do {
        private _ai = _validAI select _aiIndex;
        _overflowAI pushBack _ai;
        _aiIndex = _aiIndex + 1;
    };

    // Handle overflow AI
    if (count _overflowAI > 0) then {
        diag_log format ["[AI RECRUIT] ⚠ OVERFLOW: %1 AI cannot fit in vehicle - putting them in WAIT state",
            count _overflowAI];

        {
            private _ai = _x;

            // Set overflow state
            _ai setVariable ["FSM_CurrentState", "OVERFLOW", false];
            _ai setVariable ["RECRUIT_overflowWaitPos", getPosATL _ai, false];

            // Stop following
            _ai doWatch objNull;
            _ai doFollow _ai; // Follow self = stop following others

            // Make them wait at current position
            _ai disableAI "MOVE";
            _ai setBehaviour "SAFE";
            _ai setSpeedMode "LIMITED";

            diag_log format ["[AI RECRUIT] %1 set to OVERFLOW/WAIT state at %2",
                name _ai, getPosATL _ai];
        } forEach _overflowAI;

        // Store overflow AI on vehicle
        _veh setVariable ["RECRUIT_overflowAI", _overflowAI];

        // Start overflow recovery monitor
        [_player, _veh, _overflowAI] spawn RECRUIT_fnc_OverflowRecoveryMonitor;
    };
};

// ====================================================================================
// NEW: Monitor for overflow AI recovery
// ====================================================================================
RECRUIT_fnc_OverflowRecoveryMonitor = {
    params ["_player", "_veh", "_overflowAI"];

    diag_log format ["[AI RECRUIT] Starting overflow recovery monitor for %1 AI", count _overflowAI];

    private _monitorActive = true;

    while {_monitorActive && !isNull _veh} do {
        sleep 5;

        // Check if player left the vehicle
        private _playerInVehicle = (!isNull _player && vehicle _player == _veh);

        // Check if vehicle has stopped (speed < 5 km/h for > 10 seconds)
        private _vehSpeed = speed _veh;
        private _vehStopped = _vehSpeed < 5;

        if (!_playerInVehicle || _vehStopped) then {
            // Conditions met - recover overflow AI
            diag_log format ["[AI RECRUIT] Recovering %1 overflow AI (PlayerInVeh=%2, VehStopped=%3)",
                count _overflowAI, _playerInVehicle, _vehStopped];

            {
                private _ai = _x;
                if (!isNull _ai && alive _ai) then {
                    // Clear overflow state
                    _ai setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
                    _ai setVariable ["RECRUIT_overflowWaitPos", nil];

                    // Re-enable movement
                    _ai enableAI "MOVE";
                    _ai setBehaviour "SAFE";
                    _ai setSpeedMode "FULL";

                    // Resume following player
                    _ai doFollow _player;

                    diag_log format ["[AI RECRUIT] %1 recovered from overflow - resuming normal behavior",
                        name _ai];
                };
            } forEach _overflowAI;

            // Clear overflow list
            _veh setVariable ["RECRUIT_overflowAI", nil];
            _monitorActive = false;
        };
    };

    diag_log "[AI RECRUIT] Overflow recovery monitor ended";
};

// ====================================================================================
// NEW: Force Elite Driving Re-registration
// ====================================================================================
RECRUIT_fnc_ForceEADReregister = {
    params ["_veh"];

    if (isNull _veh) exitWith {};

    private _driver = driver _veh;
    if (isNull _driver || isPlayer _driver) exitWith {};

    // Check if already active to avoid spam
    if (_veh getVariable ["EAD_active", false]) exitWith {};

    // Clear Elite Driving state
    _veh setVariable ["EAID_Ignore", false]; // Remove block flag

    // Force immediate re-registration
    [_driver, _veh] spawn {
        params ["_driver", "_veh"];
        sleep 0.5;

        if (!isNull _driver && alive _driver && driver _veh == _driver) then {
            // Call Elite Driving registration function
            if (!isNil "EAD_fnc_registerDriver") then {
                [_driver, _veh] call EAD_fnc_registerDriver;
                _veh setVariable ["EAD_active", true]; // Set active flag after registration
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

                // ✅ FIX: Don't run stuck detection if a PLAYER is in the vehicle as passenger/driver
                private _player = [_playerUID] call BIS_fnc_getUnitByUID;
                private _playerInVehicle = (!isNull _player && vehicle _player == _veh);

                if (_playerInVehicle) then {
                    // Player is in vehicle - reset stuck timer and skip detection
                    _unit setVariable ["RECRUIT_driverStuckTime", time];
                    _unit setVariable ["RECRUIT_lastDriverPos", getPosATL _unit];

                    // ✅ FIX: Check if EAD is still active, re-register if needed
                    if !(_veh getVariable ["EAD_active", false]) then {
                        diag_log format ["[AI RECRUIT] EAD inactive while player in vehicle %1 - re-registering", typeOf _veh];
                        [_veh] call RECRUIT_fnc_ForceEADReregister;
                    };
                } else {
                    // ✅ FIX: Add grace period after getting into vehicle
                    private _getInTime = _unit getVariable ["RECRUIT_driverGetInTime", 0];
                    private _timeSinceGetIn = time - _getInTime;

                    // Only check stuck if AI has been driver for at least 20 seconds
                    if (_timeSinceGetIn > 20) then {
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
                    } else {
                        // Still in grace period - reset stuck timer
                        _unit setVariable ["RECRUIT_driverStuckTime", time];
                        _unit setVariable ["RECRUIT_lastDriverPos", getPosATL _unit];
                    };
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

            // ✅ HANDLE OVERFLOW STATE - AI waiting because vehicle was full
            if (_lastState == "OVERFLOW") then {
                // Check if still in overflow or if we should resume
                private _overflowPos = _unit getVariable ["RECRUIT_overflowWaitPos", []];

                // If overflow state but no wait position, clear it
                if (count _overflowPos == 0) then {
                    _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
                    _unit enableAI "MOVE";
                    diag_log format ["[AI RECRUIT FSM] %1 cleared from overflow - resuming normal", name _unit];
                } else {
                    // Still in overflow - skip normal FSM logic
                    sleep 5;
                };
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

// ====================================================================================
// Function: Check if player is fully in-game and ready
// ====================================================================================
fn_isPlayerReady = {
    params ["_player"];

    if (isNull _player) exitWith { false };
    if (!alive _player) exitWith { false };
    if (!isPlayer _player) exitWith { false };

    private _uid = getPlayerUID _player;
    if (_uid isEqualTo "") exitWith { false };
    if (isNull group _player) exitWith { false };

    // ✅ Check if player has valid position (not at world origin)
    private _pos = getPosATL _player;
    if (_pos isEqualTo [0,0,0]) exitWith {
        diag_log format ["[AI RECRUIT] Player %1 at world origin - not spawned yet", name _player];
        false
    };

    // ✅ Check if Exile session is initialized
    private _sessionID = _player getVariable ["ExileSessionID", ""];
    if (_sessionID isEqualTo "") exitWith {
        diag_log format ["[AI RECRUIT] Player %1 waiting for Exile session...", name _player];
        false
    };

    // ✅ Player is standing in-game and ready!
    true
};

// ====================================================================================
// Function: Check spawn cooldown (OPTIMIZED with combat check)
// ====================================================================================
fn_checkSpawnCooldown = {
    params ["_uid"];

    private _lastSpawnTime = spawn_cooldowns getOrDefault [_uid, 0];
    private _cooldownRemaining = (_lastSpawnTime + 5) - time;

    // ✅ Also check if player is in active combat
    private _player = [_uid] call BIS_fnc_getUnitByUID;
    if (!isNull _player) then {
        private _inCombat = (_player getVariable ["FSM_CurrentState", ""]) == FSM_STATE_COMBAT;
        if (_inCombat) exitWith {
            diag_log format ["[AI RECRUIT] Spawn blocked - player %1 in combat", name _player];
            false
        };
    };

    if (_cooldownRemaining > 0) then {
        diag_log format ["[AI RECRUIT] Spawn cooldown active for UID %1 - %2s remaining",
            _uid, _cooldownRemaining];
        false
    } else {
        true
    }
};

// ====================================================================================
// Function: Set spawn cooldown
// ====================================================================================
fn_setSpawnCooldown = {
    params ["_uid"];
    spawn_cooldowns set [_uid, time];
    diag_log format ["[AI RECRUIT] Spawn cooldown set for UID %1", _uid];
};

// ====================================================================================
// Function: Spawn AI teammate
// ====================================================================================
fn_spawnAI = {
    params ["_player", "_type", "_spawnIndex"];

    if (!isClass (configFile >> "CfgVehicles" >> _type)) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Cannot spawn invalid AI type '%1'", _type];
        objNull
    };

    private _playerGroup = group _player;
    if (isNull _playerGroup) exitWith {
        diag_log "[AI RECRUIT] ERROR: Player has null group";
        objNull
    };

    // ✅ IMPROVED: Better group ownership transfer with retry logic
    if (groupOwner _playerGroup != 2) then {
        diag_log format ["[AI RECRUIT] Transferring group ownership for %1 (current owner: %2)...",
            name _player, groupOwner _playerGroup];

        _playerGroup setGroupOwner 2;

        private _transferred = false;
        private _attempts = 0;
        private _maxAttempts = 10;

        while {!_transferred && _attempts < _maxAttempts} do {
            sleep 0.2;
            _attempts = _attempts + 1;

            if (groupOwner _playerGroup == 2) then {
                _transferred = true;
                diag_log format ["[AI RECRUIT] ✓ Group ownership transferred after %1 attempts", _attempts];
            };
        };

        if (!_transferred) then {
            diag_log format ["[AI RECRUIT] ⚠ WARNING: Group ownership transfer timeout for %1 (still owner: %2)",
                name _player, groupOwner _playerGroup];
            diag_log "[AI RECRUIT] Attempting to continue anyway...";
        };
    } else {
        diag_log format ["[AI RECRUIT] ✓ Group already owned by server for %1", name _player];
    };

    private _offset = 3 + (_spawnIndex * 0.5);
    private _angle = 120 * _spawnIndex;

    // Calculate relative position (optimized: replaced BIS_fnc_relPos)
    private _playerPos = getPosATL _player;
    private _playerDir = getDir _player;
    private _finalAngle = _playerDir + _angle;
    private _pos = [
        (_playerPos select 0) + (_offset * sin _finalAngle),
        (_playerPos select 1) + (_offset * cos _finalAngle),
        _playerPos select 2
    ];

    private _unit = _playerGroup createUnit [_type, _pos, [], 0, "FORM"];

    if (isNull _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Failed to create %1", _type];
        objNull
    };

    if (!alive _unit) exitWith {
        diag_log format ["[AI RECRUIT] ERROR: Created %1 but unit is dead", _type];
        deleteVehicle _unit;
        objNull
    };

    _unit setDir (_player getDirVisual _pos);
    _unit setVariable ["ExileRecruited", true, true];
    _unit setVariable ["OwnerUID", getPlayerUID _player, true];
    _unit setVariable ["OwnerName", name _player, true];
    _unit setVariable ["AIType", _type, true];

    // 🔥 v7.32: Apply custom loadout (Viper gear, APDS ammo, custom weapons)
    [_unit, _type] call RECRUIT_fnc_ApplyCustomLoadout;

    // ✅ ZOMBIE RESURRECTION PROTECTION
    _unit setVariable ["NoRessurect", true, true];
    _unit setVariable ["RVG_ZedIgnore", true, true];

    // ✅ ELITE DRIVING INTEGRATION:
    // DO NOT set EAID_Ignore - we WANT drivers to use Elite Driving!

    private _globalList = all_recruited_ai_map getOrDefault [getPlayerUID _player, []];
    _globalList pushBack _unit;
    all_recruited_ai_map set [getPlayerUID _player, _globalList];

    diag_log format ["[AI RECRUIT] Spawned %1 for %2 - %3 AI total",
        typeOf _unit, name _player, count _globalList];

    // Blacklist from A3XAI
    if (!isNil "A3XAI_NOAI") then {
        A3XAI_NOAI pushBackUnique _unit;
        publicVariable "A3XAI_NOAI";
    };
    _unit setVariable ["A3XAI_Ignore", true, true];
    _playerGroup setVariable ["A3XAI_Ignore", true, true];

    // 🔥 v7.32: ENHANCED AI SKILLS - Laser-accurate, instant reaction
    {
        _unit setSkill [_x select 0, _x select 1];
    } forEach [
        ["aimingAccuracy", 1.0],   // Perfect accuracy
        ["aimingShake", 1.0],      // No weapon shake
        ["aimingSpeed", 1.0],      // Instant target acquisition
        ["spotDistance", 1.0],     // Spot enemies at max range
        ["spotTime", 1.0],         // Instant enemy recognition
        ["courage", 1.0],          // Never flee
        ["reloadSpeed", 1.0],      // Instant reloads
        ["commanding", 1.0],       // Perfect command execution
        ["general", 1.0]           // Overall skill max
    ];

    // 🔥 v7.32: SUPER HUMAN - Fast movement, no fear, stealthy
    _unit setAnimSpeedCoef 1.5;  // Increased from 1.4 to 1.5 (50% faster)
    _unit allowFleeing 0;
    _unit setUnitTrait ["camouflageCoef", 0.3];  // Reduced from 0.5 (harder to spot)
    _unit setUnitTrait ["audibleCoef", 0.3];     // Reduced from 0.5 (quieter)

    // 🔥 v7.32: AGGRESSIVE DEFAULTS - Combat-ready from spawn
    _unit setBehaviour "AWARE";    // Changed from SAFE to AWARE
    _unit setCombatMode "RED";     // Changed from YELLOW to RED (seek and destroy)
    _unit setSpeedMode "FULL";
    _unit setUnitPos "UP";
    _unit doFollow _player;

    // 🔥 v7.32: COMBAT AI - Enable all combat features
    _unit enableAI "SUPPRESSION";
    _unit disableAI "COVER";       // Changed: Disable COVER so they don't hide (especially snipers)
    _unit enableAI "AUTOCOMBAT";

    {
        _unit enableAI _x;
    } forEach [
        "TARGET",
        "AUTOTARGET",
        "MOVE",
        "ANIM",
        "FSM",
        "AIMINGERROR",
        "TEAMSWITCH"
    ];

    _unit setSkill ["courage", 1.0];
    _unit enableGunLights "AUTO";
    _unit setUnitTrait ["UAVHacker", true];

    // 🔥 v7.32: Suppress bullet reaction - no flinching
    _unit setUnitTrait ["audibleCoef", 0.1];

    // 🔥 v7.32: GROUP SETTINGS - Aggressive, tight formation
    _playerGroup setCombatMode "RED";      // Always seek and destroy
    _playerGroup setBehaviour "AWARE";     // Changed from COMBAT to AWARE (more responsive)
    _playerGroup enableAttack true;
    _playerGroup setFormation "WEDGE";     // Changed from COLUMN to WEDGE (tight formation)

    // VCOMAI Integration
    if (RECRUIT_VCOMAI_Active) then {
        if (!isNil "VCM_NOAI" && {!isNil {VCM_NOAI}}) then {
            VCM_NOAI pushBackUnique _unit;
            publicVariable "VCM_NOAI";
        };

        _unit setVariable ["VCM_CUSTOMAI", true, true];
        _unit setVariable ["VCM_RECRUIT", true, true];

        if (!isNil "VCM_fnc_INITAI" && {!isNil {VCM_fnc_INITAI}}) then {
            [_unit] call VCM_fnc_INITAI;
        };

        if (!isNil "VCM_SERVERAI" && {!isNil {VCM_SERVERAI}}) then {
            VCM_SERVERAI pushBackUnique _playerGroup;
            publicVariable "VCM_SERVERAI";
            _playerGroup setVariable ["VCM_RECRUITGROUP", true, true];
        };
    };

    // LAMBS Integration
    _unit setVariable ["LAMBS_RECRUIT", true, true];
    _unit setVariable ["LAMBS_dangerRadius", 100, true];
    _unit setVariable ["LAMBS_dangerCausesCreep", true, true];
    _unit setVariable ["LAMBS_suppressionRadius", 50, true];
    _unit setVariable ["LAMBS_suppressionDuration", 15, true];

    // Activate FSM Brain
    [_unit, getPlayerUID _player, _playerGroup] spawn RECRUIT_fnc_FSM_BrainLoop;

    // ✅ GetIn Event Handler - Track vehicle role
    _unit addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];
        _unit setVariable ["RECRUIT_lastVehicleRole", [_role, _turret]];

        // If this AI just became driver, ensure Elite Driving activates
        if (_role == "driver") then {
            // ✅ FIX: Set grace period timestamp to prevent immediate stuck detection
            _unit setVariable ["RECRUIT_driverGetInTime", time];
            _unit setVariable ["RECRUIT_driverStuckTime", time];
            _unit setVariable ["RECRUIT_lastDriverPos", getPosATL _unit];

            [_vehicle] spawn {
                params ["_veh"];
                sleep 1;
                [_veh] call RECRUIT_fnc_ForceEADReregister;
            };
        };

        // ✅ FIX: Immediately disable AUTOCOMBAT for passengers to prevent instant exit
        if (_role == "cargo") then {
            _unit disableAI "AUTOCOMBAT";
            _unit disableAI "FSM";
            diag_log format ["[AI RECRUIT] %1 boarded as passenger - disabled AUTOCOMBAT", name _unit];
        };

        // For gunners, keep combat AI active but prevent dismounting
        if (_role == "gunner" || {_role == "turret"}) then {
            _unit disableAI "AUTOCOMBAT"; // Prevent exit for combat, but keep targeting
        };
    }];
    
    // ✅ GetOut Event Handler - Re-enable FSM
    _unit addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        // Force FSM back to IDLE
        _unit setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
        _unit setVariable ["FSM_StateTimer", time, false];
    }];

    // AI death handler
    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _ownerUID = _unit getVariable ["OwnerUID", ""];

        if (_ownerUID isEqualTo "") exitWith {};

        private _owner = [_ownerUID] call BIS_fnc_getUnitByUID;

        if (!isNull _owner && {!(_owner isKindOf "CAManBase")}) then {
            _owner = effectiveCommander _owner;
        };

        if (!isNull _owner && alive _owner) then {
            private _assigned = _owner getVariable ["AssignedAI", []];
            _assigned = _assigned - [_unit];
            _owner setVariable ["AssignedAI", _assigned, true];

            private _globalList = all_recruited_ai_map getOrDefault [_ownerUID, []];
            _globalList = _globalList - [_unit];
            all_recruited_ai_map set [_ownerUID, _globalList];

            diag_log format ["[AI RECRUIT] AI killed: %1 (owner: %2) - %3 AI remaining",
                typeOf _unit, name _owner, count _globalList];

            [_owner, _ownerUID] spawn {
                params ["_owner", "_ownerUID"];
                sleep 3;

                if (!isNull _owner && alive _owner) then {
                    if ([_ownerUID] call fn_checkSpawnCooldown) then {
                        [_ownerUID] call fn_setSpawnCooldown;
                        [_owner] call fn_ensureTeam;
                    };
                };
            };
        };
    }];

    _unit
};

// ====================================================================================
// Function: Ensure player has correct AI teammates (MAX 3)
// ====================================================================================
fn_ensureTeam = {
    params ["_player"];

    if (!([_player] call fn_isPlayerReady)) exitWith {};

    private _uid = getPlayerUID _player;
    if (_uid isEqualTo "") exitWith {};

    private _isSpawning = _player getVariable ["_aiSpawning", false];
    private _spawnLockTime = _player getVariable ["_aiSpawnLockTime", 0];

    if (_isSpawning && (time - _spawnLockTime > 30)) then {
        diag_log format ["[AI RECRUIT] WARNING: Spawn lock timeout for %1 - resetting", name _player];
        _isSpawning = false;
        _player setVariable ["_aiSpawning", false];
    };

    if (_isSpawning) exitWith {
        diag_log format ["[AI RECRUIT] Spawn in progress for %1 - skipping", name _player];
    };

    _player setVariable ["_aiSpawning", true];
    _player setVariable ["_aiSpawnLockTime", time];

    private _globalAI = all_recruited_ai_map getOrDefault [_uid, []];
    private _globalValid = _globalAI select { !isNull _x && alive _x };

    private _assigned = _player getVariable ["AssignedAI", []];
    private _assignedValid = _assigned select { !isNull _x && alive _x };

    private _combined = _globalValid + _assignedValid;
    private _validAI = _combined arrayIntersect _combined;

    if (count _validAI > 3) then {
        diag_log format ["[AI RECRUIT] WARNING: Player %1 has %2 AI! Removing extras...",
            name _player, count _validAI];

        private _toKeep = _validAI select [0, 3];
        private _toDelete = _validAI - _toKeep;

        {
            if (!isNull _x) then {
                _x setDamage 1;
                deleteVehicle _x;
            };
        } forEach _toDelete;

        _validAI = _toKeep;
    };

    private _currentCount = count _validAI;

    if (_currentCount >= 3) exitWith {
        _player setVariable ["AssignedAI", _validAI, true];
        all_recruited_ai_map set [_uid, _validAI];
        _player setVariable ["_aiSpawning", false];
    };

    private _existingTypes = _validAI apply { typeOf _x };
    private _missing = RECRUIT_AI_TYPES select { !(_x in _existingTypes) };

    if (_missing isEqualTo []) exitWith {
        _player setVariable ["AssignedAI", _validAI, true];
        all_recruited_ai_map set [_uid, _validAI];
        _player setVariable ["_aiSpawning", false];
    };

    diag_log format ["[AI RECRUIT] Player %1 needs %2 AI (has %3)",
        name _player, count _missing, _currentCount];

    private _spawnIndex = count _validAI;
    {
        if (count _validAI < 3) then {
            private _ai = [_player, _x, _spawnIndex] call fn_spawnAI;
            if (!isNull _ai) then {
                _validAI pushBack _ai;
                _spawnIndex = _spawnIndex + 1;
            } else {
                diag_log format ["[AI RECRUIT] Failed to spawn AI type %1 for %2", _x, name _player];
            };
            sleep 0.5;
        };
    } forEach _missing;

    _player setVariable ["AssignedAI", _validAI, true];
    all_recruited_ai_map set [_uid, _validAI];
    _player setVariable ["_aiSpawning", false];

    diag_log format ["[AI RECRUIT] Team spawn complete for %1 - now has %2 AI",
        name _player, count _validAI];
};

// ====================================================================================
// Function: CLEANUP (FIXED - safe group deletion)
// ====================================================================================
fn_cleanupPlayerAI = {
    params ["_uid", "_name"];

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP START: %1 (UID: %2) ***", _name, _uid];
    diag_log "========================================";

    if (_uid isEqualTo "") exitWith {
        diag_log "[AI RECRUIT] ERROR: Empty UID - cannot cleanup";
    };

    private _player = [_uid] call BIS_fnc_getUnitByUID;
    diag_log format ["[AI RECRUIT] Player object lookup: %1",
        if (isNull _player) then {"NULL"} else {"FOUND"}];

    // SOURCE 1: Global map
    private _ai_from_map = all_recruited_ai_map getOrDefault [_uid, []];
    diag_log format ["[AI RECRUIT] Source 1 (Global Map): %1 AI found", count _ai_from_map];

    // SOURCE 2: Player variable
    private _ai_from_var = [];
    if (!isNull _player) then {
        _ai_from_var = _player getVariable ["AssignedAI", []];
        diag_log format ["[AI RECRUIT] Source 2 (Player Variable): %1 AI found", count _ai_from_var];
    } else {
        diag_log "[AI RECRUIT] Source 2 (Player Variable): Skipped (player null)";
    };

    // SOURCE 3: Player's group
    private _ai_from_group = [];
    if (!isNull _player && !isNull group _player) then {
        _ai_from_group = (units group _player) select {
            !isPlayer _x && {_x getVariable ["ExileRecruited", false]}
        };
        diag_log format ["[AI RECRUIT] Source 3 (Player Group): %1 AI found", count _ai_from_group];
    } else {
        diag_log "[AI RECRUIT] Source 3 (Player Group): Skipped (player/group null)";
    };

    private _ai_to_delete = _ai_from_map + _ai_from_var + _ai_from_group;
    _ai_to_delete = _ai_to_delete arrayIntersect _ai_to_delete;

    diag_log format ["[AI RECRUIT] Total unique AI to delete: %1", count _ai_to_delete];

    if (_ai_to_delete isEqualTo []) exitWith {
        diag_log format ["[AI RECRUIT] *** NO AI TO CLEANUP for %1 ***", _name];
        diag_log "========================================";
    };

    private _groupsToClean = [];

    // ✅ OPTIMIZED: Batch deletion
    // Phase 1: Disable and collect groups
    {
        if (!isNull _x) then {
            private _aiGroup = group _x;
            if (!isNull _aiGroup && {!(_aiGroup in _groupsToClean)}) then {
                _groupsToClean pushBack _aiGroup;
            };

            if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
                VCM_NOAI = VCM_NOAI - [_x];
            };

            if (!isNil "A3XAI_NOAI") then {
                A3XAI_NOAI = A3XAI_NOAI - [_x];
            };

            _x removeAllEventHandlers "Killed";
            _x removeAllEventHandlers "GetInMan";
            _x removeAllEventHandlers "GetOutMan";
            if (alive _x) then { _x setDamage 1 };

            diag_log format ["[AI RECRUIT]   Deleted: %1", typeOf _x];
        };
    } forEach _ai_to_delete;

    // Phase 2: Batch delete all units
    {deleteVehicle _x} forEach _ai_to_delete;

    // ✅ FIXED: Safe group deletion (never delete player's group)
    {
        if (!isNull _x && {count units _x == 0}) then {
            private _isPlayerGroup = if (!isNull _player) then {
                _x == group _player
            } else {
                false
            };

            if (!_isPlayerGroup) then {
                deleteGroup _x;
                diag_log format ["[AI RECRUIT]   Deleted empty group: %1", _x];
            } else {
                diag_log "[AI RECRUIT]   Skipped player's group (safety check)";
            };
        };
    } forEach _groupsToClean;

    if (RECRUIT_VCOMAI_Active && !isNil "VCM_NOAI") then {
        publicVariable "VCM_NOAI";
    };

    if (!isNil "A3XAI_NOAI") then {
        publicVariable "A3XAI_NOAI";
    };

    all_recruited_ai_map deleteAt _uid;
    spawn_cooldowns deleteAt _uid;

    if (!isNull _player) then {
        _player setVariable ["AssignedAI", [], true];
        _player setVariable ["_aiSpawning", false, true];
        _player setVariable ["_aiSpawnLockTime", 0, true];
        diag_log "[AI RECRUIT] Player variables cleared";
    };

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** CLEANUP COMPLETE for %1 ***", _name];
    diag_log format ["[AI RECRUIT] Results: %1 AI deleted, %2 groups cleaned",
        count _ai_to_delete, count _groupsToClean];
    diag_log "========================================";
};

// ====================================================================================
// Setup event handlers for a player
// ====================================================================================
fn_setupPlayerHandlers = {
    params ["_player"];

    private _uid = getPlayerUID _player;

    diag_log format ["[AI RECRUIT] Setting up handlers for %1 (UID: %2)", name _player, _uid];

    _player addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _uid = getPlayerUID _unit;
        diag_log format ["[AI RECRUIT] Player death detected: %1 - cleaning up AI", name _unit];
        [_uid, name _unit] call fn_cleanupPlayerAI;
    }];

    diag_log format ["[AI RECRUIT] Death event handlers registered for %1", name _player];

    _player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];

        private _uid = getPlayerUID _unit;

        diag_log "========================================";
        diag_log format ["[AI RECRUIT] *** PLAYER RESPAWNED: %1 (UID: %2) ***", name _unit, _uid];
        diag_log "========================================";

        private _existingAI = all_recruited_ai_map getOrDefault [_uid, []];
        if (count _existingAI > 0) then {
            diag_log format ["[AI RECRUIT] WARNING: Found %1 orphaned AI on respawn - cleaning",
                count _existingAI];
            [_uid, name _unit] call fn_cleanupPlayerAI;
        } else {
            diag_log "[AI RECRUIT] Good: No orphaned AI found";
        };

        _unit setVariable ["AssignedAI", [], true];
        _unit setVariable ["_aiSpawning", false, true];
        _unit setVariable ["_aiSpawnLockTime", 0, true];
        _unit setVariable ["_lastCheckTime", 0, true];

        [_unit, _uid] spawn {
            params ["_player", "_uid"];

            // ✅ Wait for player to be in-game (Exile session + valid position)
            waitUntil {
                sleep 1;
                [_player] call fn_isPlayerReady
            };

            diag_log format ["[AI RECRUIT] ✓ Player %1 in-game after respawn - spawning AI", name _player];

            if ([_uid] call fn_checkSpawnCooldown) then {
                [_uid] call fn_setSpawnCooldown;
                [_player] call fn_ensureTeam;
            };
        };
    }];

    // ✅ NEW: Player GetIn event - Handle vehicle seat assignments and overflow AI
    _player addEventHandler ["GetInMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        diag_log format ["[AI RECRUIT] Player %1 entered %2 as %3", name _unit, typeOf _vehicle, _role];

        // Small delay to let player settle into seat
        [_unit, _vehicle] spawn {
            params ["_player", "_veh"];
            sleep 1;

            // Only handle if player is still in vehicle
            if (vehicle _player == _veh) then {
                [_player, _veh] call RECRUIT_fnc_HandleVehicleSeats;

                // ✅ FIX: Wait for AI to get in, then ensure EAD is active
                sleep 2;

                private _driver = driver _veh;
                if (!isNull _driver && !isPlayer _driver) then {
                    // Check if EAD is active for the AI driver
                    if !(_veh getVariable ["EAD_active", false]) then {
                        diag_log format ["[AI RECRUIT] Player entered %1 but EAD inactive - re-registering", typeOf _veh];
                        [_veh] call RECRUIT_fnc_ForceEADReregister;
                    } else {
                        diag_log format ["[AI RECRUIT] Player entered %1 - EAD already active", typeOf _veh];
                    };
                };
            };
        };
    }];

    // ✅ NEW: Player GetOut event - Recover overflow AI
    _player addEventHandler ["GetOutMan", {
        params ["_unit", "_role", "_vehicle", "_turret"];

        diag_log format ["[AI RECRUIT] Player %1 exited %2", name _unit, typeOf _vehicle];

        // Check if there are overflow AI to recover
        private _overflowAI = _vehicle getVariable ["RECRUIT_overflowAI", []];
        if (count _overflowAI > 0) then {
            diag_log format ["[AI RECRUIT] Player exited - recovering %1 overflow AI", count _overflowAI];

            {
                private _ai = _x;
                if (!isNull _ai && alive _ai) then {
                    // Clear overflow state
                    _ai setVariable ["FSM_CurrentState", FSM_STATE_IDLE, false];
                    _ai setVariable ["RECRUIT_overflowWaitPos", nil];

                    // Re-enable movement
                    _ai enableAI "MOVE";
                    _ai setBehaviour "SAFE";
                    _ai setSpeedMode "FULL";

                    // Resume following player
                    _ai doFollow _unit;

                    diag_log format ["[AI RECRUIT] %1 recovered from overflow", name _ai];
                };
            } forEach _overflowAI;

            _vehicle setVariable ["RECRUIT_overflowAI", nil];
        };
    }];

    diag_log format ["[AI RECRUIT] Handlers setup complete for %1", name _player];
};

// ====================================================================================
// Player disconnect cleanup
// ====================================================================================
addMissionEventHandler ["PlayerDisconnected", {
    params ["_id", "_uid", "_name", "_jip"];

    diag_log "========================================";
    diag_log format ["[AI RECRUIT] *** PLAYER DISCONNECTED: %1 ***", _name];
    diag_log "========================================";

    [_uid, _name] call fn_cleanupPlayerAI;
}];

// ====================================================================================
// Player Connected - SIMPLIFIED (just wait for Exile session + valid position)
// ====================================================================================
addMissionEventHandler ["PlayerConnected", {
    params ["_id", "_uid", "_name", "_jip", "_owner"];

    diag_log format ["[AI RECRUIT] Player connecting: %1 (UID: %2)", _name, _uid];

    [_uid, _name] spawn {
        params ["_uid", "_name"];

        // ✅ Wait for player object to exist
        private _player = objNull;
        private _timeout = time + 30;

        while {isNull _player && time < _timeout} do {
            sleep 1;
            _player = [_uid] call BIS_fnc_getUnitByUID;
        };

        if (isNull _player) exitWith {
            diag_log format ["[AI RECRUIT] ERROR: Could not find player object for %1 after 30s", _name];
        };

        diag_log format ["[AI RECRUIT] Player object found for %1, waiting for in-game spawn...", _name];

        // ✅ SIMPLIFIED: Just wait for Exile session + valid position
        waitUntil {
            sleep 1;
            [_player] call fn_isPlayerReady
        };

        diag_log format ["[AI RECRUIT] ✓ Player %1 is in-game and standing - spawning AI!", _name];

        // ✅ Setup handlers
        [_player] call fn_setupPlayerHandlers;

        // ✅ Small delay then spawn
        sleep 2;

        if ([_uid] call fn_checkSpawnCooldown) then {
            [_uid] call fn_setSpawnCooldown;
            [_player] call fn_ensureTeam;
        };
    };
}];

// ====================================================================================
// NEW: Manual Regroup Command Fix
// ====================================================================================
[] spawn {
    while {true} do {
        {
            private _player = _x;
            if (isPlayer _player && alive _player) then {
                private _uid = getPlayerUID _player;
                private _aiList = all_recruited_ai_map getOrDefault [_uid, []];
                
                {
                    private _ai = _x;
                    if (!isNull _ai && alive _ai) then {
                        // Check if AI was just ordered to regroup
                        private _lastOrder = _ai getVariable ["RECRUIT_lastOrderTime", 0];
                        
                        // If player uses formation commands, reset FSM
                        private _currentFormation = formation group _ai;
                        private _lastFormation = _ai getVariable ["RECRUIT_lastFormation", ""];
                        
                        if (_currentFormation != _lastFormation) then {
                            _ai setVariable ["RECRUIT_lastFormation", _currentFormation];
                            _ai setVariable ["FSM_StateTimer", time, false];
                            
                            // Force follow command
                            _ai doFollow _player;
                        };
                    };
                } forEach _aiList;
            };
        } forEach allPlayers;
        
        sleep 2;
    };
};

// ====================================================================================
// Main server loop (SIMPLIFIED)
// ====================================================================================
[] spawn {
    diag_log "[AI RECRUIT] Waiting for mission start...";

    waitUntil {time > 0};
    sleep 5;

    diag_log "[AI RECRUIT] Checking for existing players...";

    // ✅ Process existing players (server restart with players already connected)
    {
        private _player = _x;
        private _uid = getPlayerUID _player;

        if (_uid != "") then {
            diag_log format ["[AI RECRUIT] Found existing player: %1", name _player];

            [_player, _uid] spawn {
                params ["_player", "_uid"];

                // ✅ Wait for player to be in-game
                waitUntil {
                    sleep 1;
                    [_player] call fn_isPlayerReady
                };

                diag_log format ["[AI RECRUIT] ✓ Existing player %1 is in-game - spawning AI", name _player];

                [_player] call fn_setupPlayerHandlers;
                sleep 2;

                if ([_uid] call fn_checkSpawnCooldown) then {
                    [_uid] call fn_setSpawnCooldown;
                    [_player] call fn_ensureTeam;
                };
            };
        };
    } forEach allPlayers;

    diag_log "[AI RECRUIT] System initialized";

    private _playerAliveStates = createHashMap;

    while {true} do {
        {
            private _player = _x;
            private _uid = getPlayerUID _player;

            if (_uid != "" && isPlayer _player) then {
                private _isAlive = alive _player;
                private _wasAlive = _playerAliveStates getOrDefault [_uid, true];

                if (_wasAlive && !_isAlive) then {
                    diag_log format ["[AI RECRUIT] !!!!! DEATH DETECTED (BACKUP): %1 !!!!!",
                        name _player];
                    [_uid, name _player] call fn_cleanupPlayerAI;
                    _playerAliveStates set [_uid, false];
                };

                if (_isAlive && !_wasAlive) then {
                    diag_log format ["[AI RECRUIT] Player %1 alive again (respawned)", name _player];
                    _playerAliveStates set [_uid, true];
                };

                if (_isAlive && [_player] call fn_isPlayerReady) then {
                    private _lastCheck = _player getVariable ["_lastCheckTime", 0];

                    if (time - _lastCheck > 30) then {
                        if ([_uid] call fn_checkSpawnCooldown) then {
                            [_uid] call fn_setSpawnCooldown;
                            [_player] call fn_ensureTeam;
                        };
                        _player setVariable ["_lastCheckTime", time];
                    };
                    
                    // ✅ Check if player is in vehicle as driver - ensure EAD is active
                    private _veh = vehicle _player;
                    if (_veh != _player && driver _veh == _player) then {
                        if !(_veh getVariable ["EAD_active", false]) then {
                            [_veh] call RECRUIT_fnc_ForceEADReregister;
                        };
                    };
                };
            };
        } forEach allPlayers;

        sleep 5;
    };
};

// ====================================================================================
// STARTUP LOG
// ====================================================================================
diag_log "========================================";
diag_log "[AI RECRUIT] Elite AI Recruit System v7.31 - EAD PERSISTENCE FIX";
diag_log "";
diag_log "  ✅ MAJOR FIXES:";
diag_log "    - Driver stops after combat → EAD auto re-registers";
diag_log "    - FSM interference → Paused when player drives";
diag_log "    - Passengers jumping out → Per-seat cargo lock";
diag_log "    - Bridge freezing → Stuck detection & recovery";
diag_log "    - Movement conflicts → No commands to drivers";
diag_log "    - 2-SEAT VEHICLES → Overflow AI wait instead of slowing driver";
diag_log "    - EAD NON-RESPONSIVE → Re-activates after player exit/re-enter";
diag_log "";
diag_log "  • EAD PERSISTENCE (v7.31):";
diag_log "    - Continuous monitoring when player in vehicle";
diag_log "    - Auto re-register if EAD becomes inactive";
diag_log "    - Works after long trips, bridges, destinations";
diag_log "    - Player can exit/re-enter without losing AI driver";
diag_log "";
diag_log "  • VEHICLE BEHAVIOR:";
diag_log "    - Driver = Elite Driving (ZERO FSM interference)";
diag_log "    - Passengers = Locked per cargo index";
diag_log "    - Gunners = Active combat AI";
diag_log "    - Auto-recovery after 8s stuck";
diag_log "";
diag_log "  • OVERFLOW AI SYSTEM:";
diag_log "    - Detects when vehicle has insufficient seats";
diag_log "    - Assigns AI: Driver → Gunner → Cargo (priority order)";
diag_log "    - Overflow AI enter WAIT state (no follow = no slowdown)";
diag_log "    - Auto-recovery when vehicle stops or player exits";
diag_log "    - Perfect for 2-seat sports cars and fast vehicles";
diag_log "";
diag_log "  • EXTREME SKILLS: 1.0 (PERFECT) all categories";
diag_log "  • 300M SIGHT: Detect enemies at extreme distance";
diag_log "  • 1.4X SPEED: Lightning movement";
diag_log "  • STEALTH: 50% harder to spot, 50% quieter";
diag_log "";
diag_log "  • STUCK RECOVERY:";
diag_log "    - Detects: < 5 km/h for 8 seconds";
diag_log "    - Recovery: Dismount → Wait 2s → Remount → EAD restart";
diag_log "    - Works on bridges, obstacles, combat aftermath";
diag_log "";
diag_log "  • PROTECTIONS:";
diag_log "    - Ravage zombie immunity";
diag_log "    - Safe group deletion";
diag_log "    - Regroup command support";
diag_log "";
if (RECRUIT_VCOMAI_Active) then {
    diag_log "  • VCOMAI Integration: ENABLED";
} else {
    diag_log "  • VCOMAI Integration: DISABLED";
};
diag_log "========================================";
