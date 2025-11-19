/*
    VEHICLE TIRE PROTECTION
    Prevents tires from being destroyed - auto-repairs them when damaged
    Runs on server only
*/

if (!isServer) exitWith {};

diag_log "[TIRE PROTECTION] ========================================";
diag_log "[TIRE PROTECTION] Initializing vehicle tire protection...";
diag_log "[TIRE PROTECTION] ========================================";

// Configuration
TIRE_PROTECTION_ENABLED = true;
TIRE_PROTECTION_INTERVAL = 5; // Check every 5 seconds
TIRE_PROTECTION_MAX_DAMAGE = 0.9; // Max tire damage allowed (0.9 = 90%, will repair before destruction)

// Common wheel hit point names across different vehicle types
TIRE_PROTECTION_WHEEL_HITPOINTS = [
    "HitLFWheel", "HitLF2Wheel", "HitLMWheel",  // Left wheels
    "HitRFWheel", "HitRF2Wheel", "HitRMWheel",  // Right wheels
    "HitLBWheel", "HitRBWheel"                   // Back wheels
];

[] spawn {
    diag_log "[TIRE PROTECTION] ✅ Started tire protection loop";

    while {TIRE_PROTECTION_ENABLED} do {
        {
            private _vehicle = _x;

            // Only check ground vehicles with wheels
            if (alive _vehicle && {!(_vehicle isKindOf "Air")} && {!(_vehicle isKindOf "Ship")}) then {

                // Check all wheel hit points
                {
                    private _hitPoint = _x;
                    private _damage = _vehicle getHitPointDamage _hitPoint;

                    // If wheel is damaged beyond threshold, repair it
                    if (_damage > TIRE_PROTECTION_MAX_DAMAGE) then {
                        _vehicle setHitPointDamage [_hitPoint, 0, false]; // false = no event handlers fired

                        if (false) then { // Set to true for debug logging
                            diag_log format ["[TIRE PROTECTION] Repaired %1 on %2 (was %3%% damaged)",
                                _hitPoint,
                                typeOf _vehicle,
                                round (_damage * 100)
                            ];
                        };
                    };
                } forEach TIRE_PROTECTION_WHEEL_HITPOINTS;
            };
        } forEach vehicles;

        sleep TIRE_PROTECTION_INTERVAL;
    };
};

diag_log "[TIRE PROTECTION] ========================================";
diag_log "[TIRE PROTECTION] ✅ TIRE PROTECTION ACTIVE";
diag_log format ["TIRE PROTECTION] - Check interval: %1 seconds", TIRE_PROTECTION_INTERVAL];
diag_log format ["[TIRE PROTECTION] - Max damage allowed: %1%% (auto-repair at %2%%)",
    round (TIRE_PROTECTION_MAX_DAMAGE * 100),
    round (TIRE_PROTECTION_MAX_DAMAGE * 100)
];
diag_log "[TIRE PROTECTION] ========================================";
