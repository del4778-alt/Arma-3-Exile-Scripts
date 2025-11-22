/*
    A3XAI Elite - Set AI Skill
    Sets AI skill based on difficulty level (DMS-style full skill configuration)

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success

    v2.0: DMS-style complete skill configuration
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit || !alive _unit) exitWith {false};

// Define DMS-style skill arrays per difficulty
// Format: [aimingAccuracy, aimingShake, aimingSpeed, endurance, spotDistance, spotTime, courage, reloadSpeed, commanding, general]
if (isNil "A3XAI_skillArrays") then {
    A3XAI_skillArrays = createHashMapFromArray [
        // Static guards - lower skills, defensive
        ["static", [
            ["aimingAccuracy", 0.20],
            ["aimingShake", 0.70],
            ["aimingSpeed", 0.30],
            ["endurance", 0.50],
            ["spotDistance", 0.40],
            ["spotTime", 0.60],
            ["courage", 0.60],
            ["reloadSpeed", 0.50],
            ["commanding", 0.40],
            ["general", 0.40]
        ]],

        // Easy - casual players, forgiving AI
        ["easy", [
            ["aimingAccuracy", 0.15],
            ["aimingShake", 0.80],
            ["aimingSpeed", 0.25],
            ["endurance", 0.40],
            ["spotDistance", 0.35],
            ["spotTime", 0.70],
            ["courage", 0.50],
            ["reloadSpeed", 0.45],
            ["commanding", 0.35],
            ["general", 0.35]
        ]],

        // Medium - balanced difficulty
        ["medium", [
            ["aimingAccuracy", 0.40],
            ["aimingShake", 0.55],
            ["aimingSpeed", 0.50],
            ["endurance", 0.60],
            ["spotDistance", 0.55],
            ["spotTime", 0.50],
            ["courage", 0.70],
            ["reloadSpeed", 0.60],
            ["commanding", 0.55],
            ["general", 0.55]
        ]],

        // Hard - challenging but fair
        ["hard", [
            ["aimingAccuracy", 0.60],
            ["aimingShake", 0.40],
            ["aimingSpeed", 0.70],
            ["endurance", 0.75],
            ["spotDistance", 0.70],
            ["spotTime", 0.35],
            ["courage", 0.80],
            ["reloadSpeed", 0.75],
            ["commanding", 0.70],
            ["general", 0.70]
        ]],

        // Extreme/Hardcore - high difficulty
        ["extreme", [
            ["aimingAccuracy", 0.85],
            ["aimingShake", 0.20],
            ["aimingSpeed", 0.90],
            ["endurance", 0.90],
            ["spotDistance", 0.85],
            ["spotTime", 0.20],
            ["courage", 0.95],
            ["reloadSpeed", 0.90],
            ["commanding", 0.85],
            ["general", 0.85]
        ]],

        // Hardcore alias for extreme
        ["hardcore", [
            ["aimingAccuracy", 0.95],
            ["aimingShake", 0.10],
            ["aimingSpeed", 0.95],
            ["endurance", 0.95],
            ["spotDistance", 0.90],
            ["spotTime", 0.15],
            ["courage", 1.00],
            ["reloadSpeed", 0.95],
            ["commanding", 0.90],
            ["general", 0.90]
        ]]
    ];
};

// Handle "random" difficulty
private _actualDifficulty = _difficulty;
if (_difficulty == "random") then {
    _actualDifficulty = selectRandom ["easy", "medium", "medium", "hard"];  // Weighted toward medium
};

// Get skill array for this difficulty (default to medium)
private _skillArray = A3XAI_skillArrays getOrDefault [_actualDifficulty, A3XAI_skillArrays get "medium"];

// Apply all skills
{
    _x params ["_skillName", "_skillValue"];

    // Add slight randomization (+/- 5%) for variety
    private _randomizedValue = _skillValue + (random 0.1) - 0.05;
    _randomizedValue = (_randomizedValue max 0.05) min 1.0;

    _unit setSkill [_skillName, _randomizedValue];
} forEach _skillArray;

// Store difficulty on unit for reference
_unit setVariable ["A3XAI_difficulty", _actualDifficulty, true];

// Difficulty-specific enhancements
switch (_actualDifficulty) do {
    case "easy": {
        // Easy AI have reduced suppression response and worse targeting
        _unit disableAI "SUPPRESSION";
    };

    case "hard";
    case "extreme";
    case "hardcore": {
        // Hard+ AI get NVG at night
        if (sunOrMoon < 0.5) then {
            if (random 1 < 0.8) then {  // 80% chance
                _unit linkItem "NVGoggles_OPFOR";
            };
        };

        // Extreme/hardcore get enhanced combat behavior
        if (_actualDifficulty in ["extreme", "hardcore"]) then {
            _unit enableAI "AUTOCOMBAT";
            _unit enableAI "TARGET";
            _unit enableAI "AUTOTARGET";
        };
    };
};

// Log skill assignment
if (A3XAI_debugMode) then {
    private _aimAcc = _unit skill "aimingAccuracy";
    [4, format ["AI %1 skill set: %2 (aimAcc: %3)", _unit, _actualDifficulty, _aimAcc toFixed 2]] call A3XAI_fnc_log;
};

true
