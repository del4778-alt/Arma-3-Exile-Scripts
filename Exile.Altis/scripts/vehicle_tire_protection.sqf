/*
    VEHICLE TIRE PROTECTION v2.0
    Prevents tires from being destroyed - auto-repairs them instantly
    Runs on server only
*/

if (!isServer) exitWith {};

diag_log "[TIRE PROTECTION] ========================================";
diag_log "[TIRE PROTECTION] Initializing v2.0 (auto-detect wheels)...";
diag_log "[TIRE PROTECTION] ========================================";

// Configuration
TIRE_PROTECTION_ENABLED = true;
TIRE_PROTECTION_INTERVAL = 1; // ✅ Check every 1 second (faster response)
TIRE_PROTECTION_REPAIR_THRESHOLD = 0.01; // ✅ Repair ANY damage (even 1%)

[] spawn {
    diag_log "[TIRE PROTECTION] ✅ Started tire protection loop (1 second interval)";

    while {TIRE_PROTECTION_ENABLED} do {
        private _repairedCount = 0;

        {
            private _vehicle = _x;

            // Only check ground vehicles with wheels
            if (alive _vehicle && {!(_vehicle isKindOf "Air")} && {!(_vehicle isKindOf "Ship")} && {!(_vehicle isKindOf "Man")}) then {

                // ✅ USE getAllHitPointsDamage to get ACTUAL hit point names for this vehicle
                private _hitPointData = getAllHitPointsDamage _vehicle;

                if (count _hitPointData >= 2) then {
                    private _hitPointNames = _hitPointData select 0; // Array of hit point names
                    private _hitPointDamages = _hitPointData select 2; // Array of damage values

                    // Find and repair wheel-related hit points
                    {
                        private _hitPointName = _x;
                        private _damage = _hitPointDamages select _forEachIndex;

                        // ✅ Check if this hit point is wheel-related (contains "wheel" or "tire")
                        if (
                            (_hitPointName find "wheel") >= 0 ||
                            (_hitPointName find "Wheel") >= 0 ||
                            (_hitPointName find "tire") >= 0 ||
                            (_hitPointName find "Tire") >= 0
                        ) then {

                            // ✅ Repair ANY damage (even 1%)
                            if (!isNil "_damage" && {_damage > TIRE_PROTECTION_REPAIR_THRESHOLD}) then {
                                _vehicle setHitPointDamage [_hitPointName, 0, false];
                                _repairedCount = _repairedCount + 1;

                                // Debug logging (enable to see repairs)
                                if (true) then { // ✅ Set to false to disable spam
                                    diag_log format ["[TIRE PROTECTION] Repaired %1 on %2 (was %3%% damaged)",
                                        _hitPointName,
                                        typeOf _vehicle,
                                        round (_damage * 100)
                                    ];
                                };
                            };
                        };

                    } forEach _hitPointNames;
                };
            };
        } forEach vehicles;

        // Log summary every 10 seconds
        if (time % 10 < 1 && _repairedCount > 0) then {
            diag_log format ["[TIRE PROTECTION] Repaired %1 wheels in last 10 seconds", _repairedCount];
        };

        sleep TIRE_PROTECTION_INTERVAL;
    };
};

diag_log "[TIRE PROTECTION] ========================================";
diag_log "[TIRE PROTECTION] ✅ TIRE PROTECTION v2.0 ACTIVE";
diag_log "[TIRE PROTECTION] - Check interval: 1 second (instant repair)";
diag_log "[TIRE PROTECTION] - Repair threshold: ANY damage (even 1%)";
diag_log "[TIRE PROTECTION] - Auto-detects wheel hit points per vehicle";
diag_log "[TIRE PROTECTION] ========================================";
