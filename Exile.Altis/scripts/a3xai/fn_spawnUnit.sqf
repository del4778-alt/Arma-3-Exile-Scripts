/*
    A3XAI Spawn Unit - Creates a single AI unit
    
    Parameters:
    0: Group
    1: Position
    2: (Optional) Loot tier - "Tier1", "Tier2", "Tier3"
    3: (Optional) Unit type classname
*/

params ["_grp", "_pos", ["_lootTier", "Tier1"], ["_unitType", ""]];

// Select random unit type if not specified
if (_unitType isEqualTo "") then {
    _unitType = selectRandom [
        "O_G_Soldier_F",
        "O_G_Soldier_lite_F", 
        "O_G_Soldier_AR_F",
        "O_G_medic_F"
    ];
};

// Find safe spawn position (not in water, valid terrain)
private _spawnPos = _pos;
private _attempts = 0;

while {_attempts < 20} do {
    private _testPos = _pos getPos [random 10, random 360];
    _testPos set [2, 0];
    
    if (!surfaceIsWater _testPos) exitWith {
        _spawnPos = _testPos;
    };
    _attempts = _attempts + 1;
};

// Create unit at safe position  
private _u = _grp createUnit [_unitType, _spawnPos, [], 0, "NONE"];

if (isNull _u) exitWith {
    diag_log format ["[UMC][A3XAI] ERROR: Failed to create unit at %1", _spawnPos];
    objNull
};

// Move to proper ATL position
_u setPosATL [_spawnPos select 0, _spawnPos select 1, 0.1];

// Apply skill settings
[_u] call (UMC get "applySkill");

// Get and apply loot based on tier
private _loot = [_lootTier] call (UMC get "getLoot");
if (count _loot >= 2) then {
    removeAllWeapons _u;
    _u addWeapon (_loot select 0);
    _u addMagazines [(_loot select 1), 4];
};

// Set AI behavior
_u setBehaviour "AWARE";
_u setCombatMode "RED";

// Rewards scale with tier
private _respectBase = switch (_lootTier) do {
    case "Tier1": { 3 };
    case "Tier2": { 5 };
    case "Tier3": { 8 };
    default { 3 };
};

private _poptabBase = switch (_lootTier) do {
    case "Tier1": { 5 };
    case "Tier2": { 10 };
    case "Tier3": { 15 };
    default { 5 };
};

_u addEventHandler ["Killed", compile format ["
    params ['_unit', '_killer'];
    [_killer, %1, %2] call (UMC get 'reward');
", _respectBase, _poptabBase]];

_u
