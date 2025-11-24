/*
    A3XAI Elite - Position Blacklist Check
    Comprehensive check for spawn-restricted areas (Exile Occupation style)

    Parameters:
        0: ARRAY - Position [x,y,z]
        1: NUMBER - Custom radius override (optional)

    Returns:
        BOOL - True if position is blacklisted (DO NOT SPAWN HERE)

    v2.0: Added Exile territory, trader, spawn zone, and map marker checks
*/

params ["_pos", ["_customRadius", -1]];

// Quick validation
if (count _pos < 2) exitWith {true};  // Invalid position = blacklisted

// ============================================
// CHECK 1: Manual Blacklist Zones (from config)
// ============================================
if (!isNil "A3XAI_blacklistZones") then {
    {
        _x params ["_name", "_center", "_radius"];
        private _checkRadius = if (_customRadius > 0) then {_customRadius} else {_radius};
        if (_pos distance2D _center < _checkRadius) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Position blacklisted: Inside zone '%1'", _name]] call A3XAI_fnc_log;
            };
            true
        };
        false
    } forEach A3XAI_blacklistZones;
};

// ============================================
// CHECK 2: Exile Trader Zones
// ============================================
// Uses Exile function if available
private _minDistTrader = if (!isNil "A3XAI_minDistanceToTraders") then {A3XAI_minDistanceToTraders} else {750};

if (!isNil "ExileClient_util_world_isTraderZoneInRange") then {
    if ([_pos, _minDistTrader] call ExileClient_util_world_isTraderZoneInRange) exitWith {
        if (A3XAI_debugMode) then {
            [4, format ["Position blacklisted: Too close to trader zone (%1m)", _minDistTrader]] call A3XAI_fnc_log;
        };
        true
    };
};

// ============================================
// CHECK 3: Exile Spawn Zones
// ============================================
private _minDistSpawn = if (!isNil "A3XAI_minDistanceToSpawnZones") then {A3XAI_minDistanceToSpawnZones} else {750};

if (!isNil "ExileClient_util_world_isSpawnZoneInRange") then {
    if ([_pos, _minDistSpawn] call ExileClient_util_world_isSpawnZoneInRange) exitWith {
        if (A3XAI_debugMode) then {
            [4, format ["Position blacklisted: Too close to spawn zone (%1m)", _minDistSpawn]] call A3XAI_fnc_log;
        };
        true
    };
};

// ============================================
// CHECK 4: Player Territories (Exile Flags)
// ============================================
private _minDistTerritory = if (!isNil "A3XAI_minDistanceToTerritory") then {A3XAI_minDistanceToTerritory} else {350};

// Method 1: Use Exile function if available
if (!isNil "ExileClient_util_world_isTerritoryInRange") then {
    if ([_pos, _minDistTerritory] call ExileClient_util_world_isTerritoryInRange) exitWith {
        if (A3XAI_debugMode) then {
            [4, format ["Position blacklisted: Too close to territory (%1m)", _minDistTerritory]] call A3XAI_fnc_log;
        };
        true
    };
} else {
    // Method 2: Direct flag check (fallback)
    private _nearbyFlags = _pos nearObjects ["Exile_Construction_Flag_Static", _minDistTerritory];
    if (count _nearbyFlags > 0) exitWith {
        if (A3XAI_debugMode) then {
            [4, format ["Position blacklisted: Too close to player base flag (%1m)", _minDistTerritory]] call A3XAI_fnc_log;
        };
        true
    };
};

// ============================================
// CHECK 5: Map Markers (DMS missions, etc.)
// ============================================
private _minDistMarker = if (!isNil "A3XAI_minDistanceToMarkers") then {A3XAI_minDistanceToMarkers} else {350};

{
    private _markerPos = getMarkerPos _x;
    if (count _markerPos >= 2) then {
        if (_pos distance2D _markerPos < _minDistMarker) exitWith {
            if (A3XAI_debugMode) then {
                [4, format ["Position blacklisted: Too close to marker '%1' (%2m)", _x, _minDistMarker]] call A3XAI_fnc_log;
            };
            true
        };
    };
    false
} forEach allMapMarkers;

// ============================================
// CHECK 6: Active Players (don't spawn too close)
// ============================================
private _minDistPlayer = if (!isNil "A3XAI_minDistanceToPlayer") then {A3XAI_minDistanceToPlayer} else {250};

// Method 1: Use Exile function if available
if (!isNil "ExileClient_util_world_isAlivePlayerInRange") then {
    if ([_pos, _minDistPlayer] call ExileClient_util_world_isAlivePlayerInRange) exitWith {
        if (A3XAI_debugMode) then {
            [4, format ["Position blacklisted: Too close to player (%1m)", _minDistPlayer]] call A3XAI_fnc_log;
        };
        true
    };
} else {
    // Method 2: Direct player check (fallback)
    {
        if (alive _x && !(_x getVariable ["ExileIsBambi", false])) then {
            if (_pos distance2D (position _x) < _minDistPlayer) exitWith {
                if (A3XAI_debugMode) then {
                    [4, format ["Position blacklisted: Too close to player (%1m)", _minDistPlayer]] call A3XAI_fnc_log;
                };
                true
            };
        };
        false
    } forEach allPlayers;
};

// All checks passed - position is NOT blacklisted
false
