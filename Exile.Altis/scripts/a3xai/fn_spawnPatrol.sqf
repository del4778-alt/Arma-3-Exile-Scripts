/*
    A3XAI Spawn Patrol - Creates an AI patrol at a position
    
    Parameters:
    0: Position (array)
    1: Tier (number) - 0=easy, 1=medium, 2=hard, 3=military
    
    Returns: Group
*/

params ["_centerPos", ["_tier", 1]];

private _cfg = (missionConfigFile >> "UMC_Master" >> "A3XAI");
private _minAI = A3XAI get "minAI";
private _maxAI = A3XAI get "maxAI";

// Scale group size by tier
private _tierBonus = switch (_tier) do {
    case 0: { 0 };   // Easy - base size
    case 1: { 1 };   // Medium - +1
    case 2: { 2 };   // Hard - +2
    case 3: { 3 };   // Military - +3
    default { 1 };
};

private _count = (_minAI + _tierBonus) + floor random ((_maxAI - _minAI) + 1);
_count = _count min 8;  // Cap at 8 per group

// Get loot tier based on difficulty
private _lootTier = switch (_tier) do {
    case 0: { "Tier1" };
    case 1: { "Tier1" };
    case 2: { "Tier2" };
    case 3: { "Tier3" };
    default { "Tier1" };
};

// Unit types based on tier
private _unitTypes = switch (_tier) do {
    case 0: { ["O_G_Soldier_lite_F", "O_G_Soldier_F"] };
    case 1: { ["O_G_Soldier_F", "O_G_Soldier_AR_F", "O_G_medic_F"] };
    case 2: { ["O_G_Soldier_F", "O_G_Soldier_AR_F", "O_G_Soldier_M_F", "O_G_Soldier_GL_F"] };
    case 3: { ["O_G_Soldier_AR_F", "O_G_Soldier_M_F", "O_G_Soldier_GL_F", "O_G_Soldier_LAT_F", "O_G_Soldier_TL_F"] };
    default { ["O_G_Soldier_F"] };
};

// Create group with proper loot tier
private _grp = [_centerPos, _count, _lootTier] call (A3XAI get "spawnGroup");

if (isNull _grp) exitWith {
    diag_log "[UMC][A3XAI] Failed to create group";
    grpNull
};

// Set patrol waypoints around the area
private _patrolRadius = 80 + (_tier * 30);  // Larger patrol area for higher tiers

for "_i" from 1 to 4 do {
    private _wpPos = _centerPos getPos [random _patrolRadius, random 360];
    private _wp = _grp addWaypoint [_wpPos, 25];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour (["SAFE", "AWARE", "AWARE", "COMBAT"] select _tier);
    _wp setWaypointSpeed (["LIMITED", "NORMAL", "NORMAL", "FULL"] select _tier);
};

// Add cycle waypoint
private _cycleWP = _grp addWaypoint [_centerPos, 30];
_cycleWP setWaypointType "CYCLE";

// Store metadata
_grp setVariable ["A3XAI_tier", _tier, true];
_grp setVariable ["A3XAI_lootTier", _lootTier, true];
_grp setVariable ["A3XAI_spawnTime", time, true];

diag_log format ["[UMC][A3XAI] Spawned patrol: %1 units, tier %2 at %3", count units _grp, _tier, _centerPos];

_grp
