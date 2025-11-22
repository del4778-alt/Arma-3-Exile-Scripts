/*
    A3XAI Elite - AI Refresh System
    Continuously monitors and replenishes AI ammo and vehicle fuel (Sarge-AI style)

    Parameters:
        0: OBJECT - AI unit to monitor

    Returns:
        Nothing (runs as spawned loop)

    v1.0: Based on Sarge-AI fn_AI_refresh.sqf pattern
*/

params ["_ai"];

if (isNull _ai || !alive _ai) exitWith {};

// Configuration
private _refreshInterval = if (!isNil "A3XAI_ammoRefreshInterval") then {A3XAI_ammoRefreshInterval} else {120};
private _fuelThreshold = 0.2;
private _ammoThreshold = 0.3;

[4, format ["AI Refresh started for %1", _ai]] call A3XAI_fnc_log;

while {alive _ai} do {
    sleep _refreshInterval;

    if (!alive _ai) exitWith {};

    private _vehicle = vehicle _ai;

    // ============================================
    // VEHICLE AMMO & FUEL REFRESH
    // ============================================
    if (_vehicle != _ai) then {
        // Check vehicle fuel
        if (fuel _vehicle < _fuelThreshold) then {
            _vehicle setFuel 1;
            if (A3XAI_debugMode) then {
                [4, format ["Refueled vehicle %1", typeOf _vehicle]] call A3XAI_fnc_log;
            };
        };

        // Check vehicle ammo
        if (someAmmo _vehicle) then {
            // Has some ammo, check if low
            private _currentAmmo = _vehicle ammo (currentWeapon _vehicle);
            if (_currentAmmo < 10) then {
                _vehicle setVehicleAmmo 1;
                if (A3XAI_debugMode) then {
                    [4, format ["Rearmed vehicle %1", typeOf _vehicle]] call A3XAI_fnc_log;
                };
            };
        } else {
            // No ammo, reload
            _vehicle setVehicleAmmo 1;
        };
    } else {
        // ============================================
        // INFANTRY AMMO REFRESH
        // ============================================
        private _primaryWeapon = primaryWeapon _ai;
        private _secondaryWeapon = handgunWeapon _ai;

        // Check primary weapon magazines
        if (_primaryWeapon != "") then {
            private _mags = magazines _ai;
            private _primaryMags = getArray (configFile >> "CfgWeapons" >> _primaryWeapon >> "magazines");

            if (count _primaryMags > 0) then {
                private _magClass = _primaryMags select 0;
                private _magCount = {_x == _magClass} count _mags;

                // Replenish if low on mags
                if (_magCount < 2) then {
                    _ai addMagazines [_magClass, 4];
                    if (A3XAI_debugMode) then {
                        [4, format ["Replenished primary ammo for %1 (%2)", _ai, _magClass]] call A3XAI_fnc_log;
                    };
                };
            };
        };

        // Check pistol magazines
        if (_secondaryWeapon != "") then {
            private _mags = magazines _ai;
            private _pistolMags = getArray (configFile >> "CfgWeapons" >> _secondaryWeapon >> "magazines");

            if (count _pistolMags > 0) then {
                private _magClass = _pistolMags select 0;
                private _magCount = {_x == _magClass} count _mags;

                // Replenish if low on mags
                if (_magCount < 1) then {
                    _ai addMagazines [_magClass, 2];
                };
            };
        };

        // Heal slightly if wounded (regeneration)
        private _damage = damage _ai;
        if (_damage > 0 && _damage < 0.8) then {
            _ai setDamage (_damage - 0.05);  // Slow regeneration
        };
    };
};

[4, format ["AI Refresh ended for %1 (dead or deleted)", _ai]] call A3XAI_fnc_log;
