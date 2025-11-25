/*
    A3XAI Spawn Group - Creates an AI patrol group
    
    Parameters:
    0: Position
    1: Unit count
    2: (Optional) Loot tier
*/

params ["_pos", "_count", ["_lootTier", "Tier1"]];

// Create group on EAST side (hostile to players)
private _grp = ["EAST"] call (UMC get "createSafeGroup");

if (isNull _grp) exitWith {
    diag_log "[UMC][A3XAI] ERROR: Failed to create group";
    grpNull
};

// Store loot tier for unit spawning
_grp setVariable ["A3XAI_lootTier", _lootTier, true];

// Spawn units
for "_i" from 1 to _count do {
    [_grp, _pos, _lootTier] call (A3XAI get "spawnUnit");
};

// Register with tracking system
[_grp] call (A3XAI get "registerGroup");

_grp
