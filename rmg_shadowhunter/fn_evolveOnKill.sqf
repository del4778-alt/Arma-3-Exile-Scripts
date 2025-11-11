/*
    Shadow Hunter Evolution On Kill
    Increases stats when hunters eliminate enemy AI
    Parameters: [_unit, _victim] - Hunter unit and killed enemy
*/

params [["_unit", objNull, [objNull]], ["_victim", objNull, [objNull]]];

// Validation
if (isNull _unit || isNull _victim) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid parameters in evolveOnKill";
};

if (!isServer) exitWith {};

// Track evolution statistics
private _oldAccuracy = SHW_accuracy;
private _oldAggression = SHW_aggression;
private _oldLoadoutTier = SHW_loadoutTier;

// Increase stats with proper operator precedence and caps
SHW_accuracy = ((SHW_accuracy + 0.02) min SHW_MAX_ACCURACY);
SHW_aggression = ((SHW_aggression + 20) min SHW_MAX_AGGRESSION);
SHW_loadoutTier = ((SHW_loadoutTier + 1) min SHW_MAX_LOADOUT_TIER);

// Track kill locations as hotspots for patrol
if (!isNull _victim) then {
    SHW_lastKnownHotspots pushBack (getPosATL _victim);
    // Keep only the 5 most recent hotspots
    if (count SHW_lastKnownHotspots > 5) then {
        SHW_lastKnownHotspots deleteAt 0;
    };
};

// Sync variables to all clients
publicVariable "SHW_accuracy";
publicVariable "SHW_aggression";
publicVariable "SHW_loadoutTier";
publicVariable "SHW_lastKnownHotspots";

// Log evolution if tier changed
if (SHW_loadoutTier > _oldLoadoutTier) then {
    diag_log format ["[Shadow Hunter] Evolution! Tier: %1->%2, Accuracy: %3->%4, Aggression: %5->%6",
        _oldLoadoutTier, SHW_loadoutTier, _oldAccuracy, SHW_accuracy, _oldAggression, SHW_aggression];

    // Upgrade loadouts for all existing hunters when tier increases
    {
        if (_x getVariable ["SHW_isHunter", false]) then {
            [_x, SHW_loadoutTier] call SHW_fnc_assignLoadout;
        };
    } forEach allUnits;
};
