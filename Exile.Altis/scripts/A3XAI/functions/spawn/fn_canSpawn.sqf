/*
    A3XAI Elite - Can Spawn Check
    Validates if spawning is allowed based on current conditions

    Parameters:
        0: ARRAY - Position [x,y,z] (optional)

    Returns:
        ARRAY - [canSpawn (BOOL), reason (STRING)]
*/

params [["_pos", []]];

// Check if system is enabled
if (!A3XAI_enabled) exitWith {
    [false, "A3XAI system disabled"]
};

// Check if server is initialized
if (!A3XAI_initialized) exitWith {
    [false, "System not initialized"]
};

// Check player count
private _players = allPlayers select {alive _x && !(_x getVariable ["ExileIsBambi", false])};
if (count _players == 0) exitWith {
    [false, "No players online"]
};

// Check server FPS
private _fps = diag_fps;
if (_fps < A3XAI_minServerFPS) exitWith {
    [false, format ["Low server FPS: %1", _fps toFixed 1]]
};

// Check global AI limit
// Count AI with A3XAI variables OR units in EAST groups (more reliable than config side check)
private _currentAI = count (allUnits select {
    alive _x && {
        (_x getVariable ["A3XAI_unit", false]) ||
        (_x getVariable ["A3XAI_spawned", false]) ||
        (side group _x == EAST && !isPlayer _x)
    }
});
if (_currentAI >= A3XAI_maxAIGlobal) exitWith {
    [false, format ["AI limit reached: %1/%2", _currentAI, A3XAI_maxAIGlobal]]
};

// ✅ v3.12: Check EAST group limit (Arma 3 has 144 groups per side limit)
// When exceeded, createGroup silently creates wrong-faction groups causing GUER AI spawns!
private _eastGroups = {side _x == EAST} count allGroups;
private _groupSafetyBuffer = 20;  // Stop spawning at 124 groups to leave headroom
private _maxEastGroups = 144 - _groupSafetyBuffer;
if (_eastGroups >= _maxEastGroups) exitWith {
    [1, format ["CRITICAL: EAST group limit approaching! %1/144 groups - blocking new spawns", _eastGroups]] call A3XAI_fnc_log;
    [false, format ["EAST group limit: %1/%2 (max 144)", _eastGroups, _maxEastGroups]]
};

// Check position-specific conditions if provided
if (count _pos > 0) then {
    // Check blacklist
    if ([_pos] call A3XAI_fnc_inBlacklist) exitWith {
        [false, "Position in blacklist zone"]
    };

    // Check spawn cooldown for this location
    if (!isNil "A3XAI_spawnCooldowns") then {
        private _locationID = format ["%1_%2", floor(_pos select 0), floor(_pos select 1)];
        private _lastSpawn = A3XAI_spawnCooldowns getOrDefault [_locationID, 0];
        private _timeSince = time - _lastSpawn;

        if (_timeSince < A3XAI_spawnCooldownTime) exitWith {
            [false, format ["Location on cooldown (%1s remaining)", ceil(A3XAI_spawnCooldownTime - _timeSince)]]
        };
    };
};

// All checks passed
[true, "OK"]
