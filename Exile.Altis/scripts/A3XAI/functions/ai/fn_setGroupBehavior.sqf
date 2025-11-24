/*
    A3XAI Elite - Set Group Behavior
    Sets behavior mode for AI group

    Parameters:
        0: GROUP - AI group
        1: STRING - Behavior mode: "patrol", "defend", "vehicle", "air", "hunter", "convoy"

    Returns:
        BOOL - Success

    v2.0: Fixed combat modes - all AI now use RED (engage at will)
*/

params ["_group", ["_mode", "patrol"]];

if (isNull _group) exitWith {false};

switch (_mode) do {
    case "patrol": {
        _group setBehaviour "AWARE";      // Alert, looking for threats (was SAFE)
        _group setCombatMode "RED";       // Engage at will (was YELLOW)
        _group setFormation "STAG COLUMN";
        _group setSpeedMode "FULL";       // v3.18: Changed from LIMITED for high-speed patrol
    };

    case "defend": {
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";       // Engage at will
        _group setFormation "LINE";
        _group setSpeedMode "FULL";       // v3.18: Changed from LIMITED for rapid response
    };

    case "vehicle": {
        _group setBehaviour "CARELESS";   // v3.18: Changed from AWARE - no speed limit behavior
        _group setCombatMode "RED";       // Engage at will (was YELLOW)
        _group setFormation "COLUMN";
        _group setSpeedMode "FULL";       // v3.18: Changed from LIMITED for max vehicle speed
    };

    case "air": {
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";       // Engage at will
        _group setFormation "VEE";
        _group setSpeedMode "FULL";       // v3.18: Changed from NORMAL for max air speed
    };

    case "hunter": {
        _group setBehaviour "COMBAT";     // Full combat mode (was AWARE)
        _group setCombatMode "RED";       // Engage at will
        _group setFormation "WEDGE";
        _group setSpeedMode "FULL";

        // Enable hunting behavior
        {
            _x setSkill ["courage", 0.9];
            _x setSkill ["commanding", 0.8];
        } forEach units _group;
    };

    case "convoy": {
        _group setBehaviour "CARELESS";   // v3.18: Changed from AWARE - no speed limit behavior
        _group setCombatMode "RED";       // Engage at will (was YELLOW)
        _group setFormation "COLUMN";
        _group setSpeedMode "FULL";       // v3.18: Changed from LIMITED for high-speed convoy
    };

    default {
        [2, format ["Unknown behavior mode: %1", _mode]] call A3XAI_fnc_log;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
    };
};

// ✅ v3.7: Enable ALL AI features for all units in group (was missing MOVE, PATH, ANIM, FSM)
// This is critical to prevent frozen/stuck AI
{
    _x enableAI "ALL";         // Master enable (covers everything)
    _x enableAI "MOVE";        // Movement
    _x enableAI "PATH";        // Pathfinding
    _x enableAI "ANIM";        // Animations
    _x enableAI "FSM";         // Finite state machine (behavior)
    _x enableAI "TARGET";      // Targeting
    _x enableAI "AUTOTARGET";  // Auto-targeting enemies
    _x enableAI "AUTOCOMBAT";  // Automatic combat response
    _x enableAI "COVER";       // Taking cover
    _x enableAI "SUPPRESSION"; // Suppressive fire
    _x enableAI "CHECKVISIBLE";// Visual checks

    // ✅ v3.7: Additional fixes for frozen AI
    _x setUnitPos "AUTO";      // Automatic stance (not stuck crouched)
    _x allowFleeing 0;         // Never flee (stay in combat)
} forEach units _group;

// Mark group as A3XAI
_group setVariable ["A3XAI_group", true];
_group setVariable ["A3XAI_behaviorMode", _mode];

true
