/*
    A3XAI Elite - Set AI Skill
    Sets AI skill based on difficulty level

    Parameters:
        0: OBJECT - AI unit
        1: STRING - Difficulty level (default: "medium")

    Returns:
        BOOL - Success
*/

params ["_unit", ["_difficulty", "medium"]];

if (isNull _unit) exitWith {false};

// Define skill levels if not already defined
if (isNil "A3XAI_skillLevels") then {
    A3XAI_skillLevels = createHashMapFromArray [
        ["easy", [0.25, 0.35, 0.20, 0.30]],      // [aimAccuracy, aimSpeed, spotDistance, spotTime]
        ["medium", [0.45, 0.55, 0.45, 0.50]],
        ["hard", [0.65, 0.75, 0.65, 0.70]],
        ["extreme", [0.85, 0.95, 0.85, 0.90]]
    ];
};

// Get skill array for difficulty
private _skills = A3XAI_skillLevels getOrDefault [_difficulty, [0.45, 0.55, 0.45, 0.50]];

// Apply skills
_unit setSkill ["aimingAccuracy", _skills select 0];
_unit setSkill ["aimingSpeed", _skills select 1];
_unit setSkill ["spotDistance", _skills select 2];
_unit setSkill ["spotTime", _skills select 3];

// Common skills for all difficulties
_unit setSkill ["courage", 0.7];
_unit setSkill ["reloadSpeed", 0.8];
_unit setSkill ["commanding", 0.6];
_unit setSkill ["general", 0.7];

// Add NVG for hard+ at night
if (_difficulty in ["hard", "extreme"]) then {
    if (sunOrMoon < 0.5) then {
        if (random 1 < 0.7) then {  // 70% chance
            _unit linkItem "NVGoggles_OPFOR";
        };
    };
};

true
