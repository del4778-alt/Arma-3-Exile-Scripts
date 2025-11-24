/*
    A3XAI Elite - Add AI Event Handlers
    Adds event handlers for AI units (Killed, Hit, etc.)

    Parameters:
        0: OBJECT - AI unit

    Returns:
        BOOL - Success
*/

params ["_unit"];

if (isNull _unit) exitWith {false};

// Killed event handler
_unit addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator", "_useEffects"];

    // ✅ v3.9: DEBUG - Log what killed the AI to diagnose deaths
    private _spawnTime = _unit getVariable ["A3XAI_spawnTime", 0];
    private _aliveTime = time - _spawnTime;
    private _killerType = if (isNull _killer) then {"NULL"} else {typeOf _killer};
    private _killerSide = if (isNull _killer) then {"NONE"} else {str (side _killer)};
    private _instigatorType = if (isNull _instigator) then {"NULL"} else {typeOf _instigator};
    private _mission = _unit getVariable ["A3XAI_mission", "unknown"];
    private _wasInVehicle = vehicle _unit != _unit;

    diag_log format ["[A3XAI:DEATH] Unit: %1 | Alive: %2s | Killer: %3 (%4) | Instigator: %5 | Mission: %6 | InVehicle: %7",
        typeOf _unit,
        _aliveTime toFixed 1,
        _killerType,
        _killerSide,
        _instigatorType,
        _mission,
        _wasInVehicle
    ];

    // Log if death was very quick (possible spawn issue)
    if (_aliveTime < 10) then {
        diag_log format ["[A3XAI:DEATH] ⚠️ QUICK DEATH after only %1 seconds! Position: %2", _aliveTime toFixed 1, getPosATL _unit];
    };

    // Update statistics
    if (A3XAI_stats getOrDefault ["totalKills", 0] >= 0) then {
        A3XAI_stats set ["totalKills", (A3XAI_stats get "totalKills") + 1];
    };

    // Remove from tracking
    A3XAI_activeGroups = A3XAI_activeGroups - [group _unit];

    // Remove high-value items if configured
    if (!isNil "A3XAI_removeLaunchers" && {A3XAI_removeLaunchers}) then {
        {
            if (_x isKindOf ["Launcher", configFile >> "CfgWeapons"]) then {
                _unit removeWeapon _x;
            };
        } forEach weapons _unit;
    };

    if (!isNil "A3XAI_removeNVG" && {A3XAI_removeNVG}) then {
        if ("NVGoggles" in (assignedItems _unit)) then {
            _unit unlinkItem "NVGoggles";
        };
        if ("NVGoggles_OPFOR" in (assignedItems _unit)) then {
            _unit unlinkItem "NVGoggles_OPFOR";
        };
    };

    // Award respect if killer is player
    if (isPlayer _killer && {isClass (configFile >> "CfgPatches" >> "exile_server")}) then {
        private _difficulty = _unit getVariable ["A3XAI_difficulty", "medium"];

        // Base respect based on difficulty
        private _baseRespect = switch (_difficulty) do {
            case "easy": {10};
            case "medium": {20};
            case "hard": {35};
            case "extreme": {50};
            default {20};
        };

        // Distance bonus (up to 2x for 500m+ kills)
        private _distance = _killer distance _unit;
        private _distanceMultiplier = 1 + ((_distance min 500) / 500);

        private _respect = floor(_baseRespect * _distanceMultiplier);

        // Award respect
        private _currentRespect = _killer getVariable ["ExileScore", 0];
        _killer setVariable ["ExileScore", _currentRespect + _respect];

        // Send notification
        if (!isNil "ExileClient_system_network_send") then {
            [_killer, "showFragRequest", [[format ["+%1 Respect", _respect]], 3]] call ExileClient_system_network_send;
        };

        // Kill streak tracking
        if (!isNil "A3XAI_killStreaks") then {
            private _playerUID = getPlayerUID _killer;
            private _streak = A3XAI_killStreaks getOrDefault [_playerUID, 0];
            _streak = _streak + 1;
            A3XAI_killStreaks set [_playerUID, _streak];

            // Kill streak milestones
            if (_streak in [5, 10, 25, 50]) then {
                private _bonus = _streak * 10;
                _killer setVariable ["ExileScore", (_killer getVariable ["ExileScore", 0]) + _bonus];

                if (!isNil "ExileClient_system_network_send") then {
                    [_killer, "toastRequest", ["Success", format ["%1 Kill Streak! +%2 Respect Bonus", _streak, _bonus]]] call ExileClient_system_network_send;
                };
            };
        };

        // Poptabs reward
        if (!isNil "A3XAI_poptabsReward" && {A3XAI_poptabsReward}) then {
            private _poptabs = switch (_difficulty) do {
                case "easy": {50};
                case "medium": {100};
                case "hard": {200};
                case "extreme": {350};
                default {100};
            };

            private _money = _killer getVariable ["ExileMoney", 0];
            _killer setVariable ["ExileMoney", _money + _poptabs];
        };
    };

    // Zombie resurrection (if enabled)
    if (!isNil "A3XAI_zombieResurrection" && {A3XAI_zombieResurrection} && {random 1 < 0.3}) then {
        [{
            params ["_unit"];

            if (!isNull _unit && {!alive _unit}) then {
                private _zombiePos = getPosATL _unit;
                private _zombie = createAgent ["RyanZombieC_man_1slow", _zombiePos, [], 0, "NONE"];

                if (!isNull _zombie) then {
                    _zombie setDir (random 360);
                    _zombie setVariable ["A3XAI_zombie", true];

                    // Track zombies for cleanup
                    if (isNil "A3XAI_zombies") then {A3XAI_zombies = []};
                    A3XAI_zombies pushBack _zombie;
                };
            };

            deleteVehicle _unit;
        }, [_unit], 2] call A3XAI_fnc_setTimeout;
    } else {
        // Standard body cleanup
        [{
            params ["_unit"];
            if (!isNull _unit) then {
                deleteVehicle _unit;
            };
        }, [_unit], 300] call A3XAI_fnc_setTimeout;  // 5 minute cleanup
    };
}];

// ✅ v3.21: ROBUST FRIENDLY FIRE PROTECTION
// Fixed: HandleDamage returning 0 wasn't preventing death in all cases
// Now explicitly resets damage and uses current damage return pattern
_unit addEventHandler ["HandleDamage", {
    params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

    // Get current damage for this hit point (we'll return this to block damage)
    private _currentDamage = if (_selection == "") then {
        damage _unit
    } else {
        _unit getHitPointDamage _hitPoint
    };

    // ✅ v3.21: FRIENDLY FIRE CHECK - Block damage from other A3XAI/DyCE units
    // Check source unit
    private _sourceIsA3XAI = false;
    if (!isNull _source) then {
        _sourceIsA3XAI = (_source getVariable ["A3XAI_unit", false]) ||
                         (_source getVariable ["DyCE_unit", false]) ||
                         (_source getVariable ["A3XAI_spawned", false]);
    };
    // Check instigator (actual shooter, important for vehicle/turret damage)
    if (!isNull _instigator && !_sourceIsA3XAI) then {
        _sourceIsA3XAI = (_instigator getVariable ["A3XAI_unit", false]) ||
                         (_instigator getVariable ["DyCE_unit", false]) ||
                         (_instigator getVariable ["A3XAI_spawned", false]);
    };

    // ✅ v3.21: Also check if source is same side as target (catches wrong-side spawns)
    if (!_sourceIsA3XAI && !isNull _source) then {
        private _sourceSide = side group _source;
        private _targetSide = side group _unit;
        // If both are EAST (normal A3XAI) or both have same group side, block FF
        if (_sourceSide == _targetSide && _sourceSide != CIVILIAN) then {
            _sourceIsA3XAI = true;
        };
    };

    // If source is also A3XAI - BLOCK the damage completely
    if (_sourceIsA3XAI) exitWith {
        // Log friendly fire attempts (only first 30 seconds for debugging)
        private _spawnTime = _unit getVariable ["A3XAI_spawnTime", 0];
        private _aliveTime = time - _spawnTime;
        if (_aliveTime < 30 && _damage > 0.1) then {
            private _srcType = if (!isNull _instigator) then {typeOf _instigator} else {typeOf _source};
            diag_log format ["[A3XAI:FF] BLOCKED friendly fire! Source: %1 -> Target at %2", _srcType, getPosATL _unit];
        };

        // ✅ v3.21: CRITICAL FIX - Explicitly reset damage to prevent accumulation
        // This is necessary because just returning 0 doesn't always prevent death
        if (_selection == "") then {
            _unit setDamage (damage _unit);  // Reset overall damage to current
        };

        // Return CURRENT damage (not 0) to prevent damage change
        // In Arma 3, returning the current damage value = "no change"
        _currentDamage
    };

    // Only log significant damage (> 0.1)
    if (_damage > 0.1) then {
        private _spawnTime = _unit getVariable ["A3XAI_spawnTime", 0];
        private _aliveTime = time - _spawnTime;
        private _sourceType = if (isNull _source) then {"NULL/Environment"} else {typeOf _source};
        private _sourceSide = if (isNull _source) then {"NONE"} else {str (side group _source)};

        // Log damage for early deaths (within first 30 seconds)
        if (_aliveTime < 30) then {
            diag_log format ["[A3XAI:DAMAGE] Unit hit at %1s | Damage: %2 | Source: %3 (%4) | Projectile: %5 | HitPoint: %6",
                _aliveTime toFixed 1,
                _damage toFixed 2,
                _sourceType,
                _sourceSide,
                _projectile,
                _hitPoint
            ];
        };
    };

    // Return original damage (allow non-FF damage)
    _damage
}];

// Hit event handler (for aggressive reaction)
_unit addEventHandler ["Hit", {
    params ["_unit", "_source", "_damage"];

    if (!isNull _source && {isPlayer _source}) then {
        // Reveal shooter to group
        {
            _x reveal [_source, 4];
        } forEach units (group _unit);

        // Set combat mode to red
        (group _unit) setCombatMode "RED";
        (group _unit) setBehaviour "COMBAT";
    };
}];

true
