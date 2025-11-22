/*
    A3XAI Elite - Initialize AI Unit
    Applies basic initialization to AI unit

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit) exitWith {false};

// ✅ v3.7: SPAWN PROTECTION - Prevent immediate death from collision/terrain
// Make unit invulnerable for first 2 seconds after spawn
_unit allowDamage false;

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

// ✅ v3.7: Re-enable damage after spawn protection delay (vanilla approach)
[_unit] spawn {
    params ["_unit"];
    sleep 2;
    if (!isNull _unit && alive _unit) then {
        _unit allowDamage true;
    };
};

// Set A3XAI marker variables
_unit setVariable ["A3XAI_unit", true, true];
_unit setVariable ["A3XAI_difficulty", _difficulty, true];
_unit setVariable ["A3XAI_spawnTime", time];

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

true
