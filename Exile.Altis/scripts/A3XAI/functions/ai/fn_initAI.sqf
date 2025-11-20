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

// Disable AI features we don't want
_unit disableAI "AUTOTARGET";
_unit disableAI "CHECKVISIBLE";

// Set side
_unit setVariable ["A3XAI_unit", true, true];
_unit setVariable ["A3XAI_difficulty", _difficulty, true];
_unit setVariable ["A3XAI_spawnTime", time];

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

true
