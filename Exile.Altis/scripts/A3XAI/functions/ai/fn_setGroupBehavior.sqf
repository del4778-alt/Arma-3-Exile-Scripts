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
        _group setSpeedMode "LIMITED";
    };

    case "defend": {
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";       // Engage at will
        _group setFormation "LINE";
        _group setSpeedMode "LIMITED";
    };

    case "vehicle": {
        _group setBehaviour "AWARE";      // Alert (was SAFE)
        _group setCombatMode "RED";       // Engage at will (was YELLOW)
        _group setFormation "COLUMN";
        _group setSpeedMode "LIMITED";
    };

    case "air": {
        _group setBehaviour "COMBAT";
        _group setCombatMode "RED";       // Engage at will
        _group setFormation "VEE";
        _group setSpeedMode "NORMAL";
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
        _group setBehaviour "AWARE";      // Alert (was SAFE)
        _group setCombatMode "RED";       // Engage at will (was YELLOW)
        _group setFormation "COLUMN";
        _group setSpeedMode "LIMITED";
    };

    default {
        [2, format ["Unknown behavior mode: %1", _mode]] call A3XAI_fnc_log;
        _group setBehaviour "AWARE";
        _group setCombatMode "RED";
    };
};

// Enable all AI features for all units in group
{
    _x enableAI "TARGET";
    _x enableAI "AUTOTARGET";
    _x enableAI "AUTOCOMBAT";
} forEach units _group;

// Mark group as A3XAI
_group setVariable ["A3XAI_group", true];
_group setVariable ["A3XAI_behaviorMode", _mode];

true
