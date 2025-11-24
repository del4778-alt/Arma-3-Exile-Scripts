/*
    A3XAI Elite - Initialize AI Unit
    Applies basic initialization to AI unit

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success
        
    v3.24: BULLETPROOF SPAWN PROTECTION
        - setDamage 0 in addition to allowDamage false
        - Handles cases where other scripts use setDamage directly
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit) exitWith {false};

// ✅ v3.24: IMMEDIATE DAMAGE PREVENTION - Must happen FIRST
// setDamage 0 resets any damage that might have occurred during createUnit
_unit setDamage 0;
_unit allowDamage false;

// ✅ v3.8: Set A3XAI marker IMMEDIATELY - before anything else
// This is critical for side detection in EntityKilled handler
_unit setVariable ["A3XAI_unit", true, true];
_unit setVariable ["A3XAI_difficulty", _difficulty, true];
_unit setVariable ["A3XAI_spawnTime", time];
_unit setVariable ["A3XAI_spawnProtected", true, true];  // v3.24: Track protection status

// ✅ v3.7: Fix spawn position - ensure unit is on ground and not stuck
private _pos = getPosATL _unit;
private _safePos = _pos findEmptyPosition [0, 5, typeOf _unit];
if (count _safePos > 0) then {
    _unit setPosATL [_safePos select 0, _safePos select 1, 0];
} else {
    // Fallback: just ensure on ground
    _unit setPosATL [_pos select 0, _pos select 1, 0];
};

// ✅ CRITICAL FIX: Enable all combat AI features so they attack enemies
_unit enableAI "TARGET";        // Enable targeting
_unit enableAI "AUTOTARGET";    // Enable auto-targeting enemies
_unit enableAI "AUTOCOMBAT";    // Enable automatic combat behavior
_unit enableAI "MOVE";          // Enable movement
_unit enableAI "FSM";           // Enable FSM behavior
_unit enableAI "PATH";          // Enable pathfinding
_unit enableAI "ANIM";          // Enable animations

// ✅ FIX: Add critical AI behavior settings (from DMS)
_unit allowFleeing 0;  // Never flee
_unit enableGunLights "forceOn";  // Gun lights for night combat

// ✅ v3.24: Re-enable damage after EXTENDED spawn protection (5 seconds)
// Also re-enable all AI features in case something disabled them
[_unit] spawn {
    params ["_unit"];
    
    // v3.24: Multiple safety checks during protection period
    for "_i" from 1 to 5 do {
        sleep 1;
        if (isNull _unit) exitWith {};
        if (!alive _unit) then {
            diag_log format ["[A3XAI:SPAWN] ❌ Unit DIED during protection at %1s - likely setDamage bypass!", _i];
        };
        // Keep resetting damage during protection
        _unit setDamage 0;
    };
    
    if (!isNull _unit && alive _unit) then {
        private _pos = getPosATL _unit;
        diag_log format ["[A3XAI:SPAWN] Protection ending for unit at %1 - enabling damage", _pos];

        // v3.24: Clear protection flag BEFORE enabling damage
        _unit setVariable ["A3XAI_spawnProtected", false, true];
        
        _unit allowDamage true;
        // Re-enable AI in case it got disabled
        _unit enableAI "ALL";
        _unit enableAI "MOVE";
        _unit enableAI "PATH";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit setUnitPos "AUTO";

        // Log status 1 second after protection ends
        sleep 1;
        if (!isNull _unit) then {
            if (alive _unit) then {
                diag_log format ["[A3XAI:SPAWN] ✅ Unit still alive 1s after protection ended at %1", getPosATL _unit];
            } else {
                diag_log format ["[A3XAI:SPAWN] ❌ Unit DIED within 1s of protection ending!"];
            };
        };
    } else {
        diag_log format ["[A3XAI:SPAWN] ❌ Unit died DURING 5s protection period!"];
    };
};

// ✅ v3.0: Zombies are WEST, mission AI are EAST - faction hostility handles combat
// No more RVG_ZedIgnore needed - zombies WILL attack mission AI and vice versa

// Add to VCOM exclusion if VCOM is present
if (!isNil "Vcm_ActivateAI") then {
    _unit setVariable ["VCM_NOAI", true];
};

// Add to ASR_AI3 exclusion if ASR_AI3 is present
if (!isNil "asr_ai3_main_setskills") then {
    _unit setVariable ["asr_ai3_exclude", true];
};

// Disable fatigue for higher difficulties
if (_difficulty in ["hard", "extreme"]) then {
    _unit enableFatigue false;
};

// Enable stamina for realism
_unit enableStamina true;

// Set unit ready
_unit setUnitPos "AUTO";

// ✅ v3.0: Combat mode RED - engage all enemies (including zombies)
// Zombies are WEST, mission AI are EAST - they will fight each other
(group _unit) setCombatMode "RED";

// Clear any targets at spawn
_unit doTarget objNull;
_unit doWatch objNull;

true
