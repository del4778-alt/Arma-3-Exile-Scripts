/**
 * Warbands Legendary Weapons System
 * Fallout 4 style legendary loot
 */

// Legendary prefixes and effects
WB_LegendaryPrefixes = [
    ["Two Shot", "Fires an additional projectile", {
        params ["_weapon", "_unit"];
        _unit addEventHandler ["Fired", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];
            if (_weapon getVariable ["WB_LegendaryEffect", ""] == "TwoShot") then {
                private _secondProjectile = _ammo createVehicle (getPosATL _projectile);
                _secondProjectile setVelocity (velocity _projectile);
            };
        }];
    }],

    ["Explosive", "+15 explosive damage", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_ExplosiveDamage", 15];
    }],

    ["Incendiary", "Sets targets on fire", {
        params ["_weapon", "_unit"];
        _unit addEventHandler ["HitPart", {
            params ["_target", "_shooter", "_projectile", "_position", "_velocity", "_selection", "_ammo", "_vector", "_radius", "_surfaceType", "_direct"];
            if (_shooter getVariable ["currentWeapon", ""] getVariable ["WB_LegendaryEffect", ""] == "Incendiary") then {
                _target setDamage [1, true]; // Burning effect placeholder
            };
        }];
    }],

    ["Wounding", "Targets bleed for additional damage", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_BleedDamage", 5]; // 5 damage per second for 10 seconds
    }],

    ["Freezing", "Slows target movement", {
        params ["_weapon", "_unit"];
        _unit addEventHandler ["HitPart", {
            params ["_target"];
            _target setAnimSpeedCoef 0.5;
            [{_this setAnimSpeedCoef 1}, _target, 10] call CBA_fnc_waitAndExecute;
        }];
    }],

    ["Penetrating", "Ignores 30% of armor", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_ArmorPen", 0.3];
    }],

    ["Mighty", "+25% damage", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_DamageBonus", 1.25];
    }],

    ["Furious", "Damage increases with consecutive hits", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_FuriousStacks", 0];
    }],

    ["VATS Enhanced", "Costs 25% less Action Points in VATS", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_VATSBonus", 0.25];
    }],

    ["Lucky", "+15% critical chance", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_CritBonus", 0.15];
    }],

    ["Bloodied", "Does more damage the lower your health", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_BloodiedEffect", true];
    }],

    ["Junkie's", "+50% damage when addicted", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_JunkieEffect", true];
    }],

    ["Instigating", "Double damage if target is at full health", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_InstigatingEffect", true];
    }],

    ["Rapid", "+25% fire rate, -15% recoil", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_RapidEffect", true];
    }],

    ["Never Ending", "Unlimited magazine capacity", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_InfiniteMag", true];
        _unit addEventHandler ["Reloaded", {
            params ["_unit", "_weapon"];
            if (_weapon getVariable ["WB_InfiniteMag", false]) then {
                _unit setAmmo [_weapon, 999];
            };
        }];
    }],

    ["Plasma Infused", "Additional energy damage", {
        params ["_weapon", "_unit"];
        _weapon setVariable ["WB_PlasmaDamage", 20];
    }]
];

/**
 * Generate legendary weapon
 */
WB_fnc_generateLegendaryWeapon = {
    params ["_baseWeapon"];

    private _luck = player getVariable ["WB_SPECIAL_Luck", 1];
    private _scrapper = player getVariable ["WB_Perk_Scrapper", 0];

    // Legendary chance: 2% base + 0.5% per Luck
    private _legendaryChance = 2 + (_luck * 0.5);
    if (_scrapper > 0) then {
        _legendaryChance = _legendaryChance * 1.5;
    };

    if (random 100 < _legendaryChance) then {
        // Generate legendary!
        private _prefix = selectRandom WB_LegendaryPrefixes;
        _prefix params ["_name", "_desc", "_effect"];

        private _legendaryWeapon = createVehicle [_baseWeapon, [0,0,0], [], 0, "CAN_COLLIDE"];
        _legendaryWeapon setVariable ["WB_IsLegendary", true, true];
        _legendaryWeapon setVariable ["WB_LegendaryName", _name, true];
        _legendaryWeapon setVariable ["WB_LegendaryEffect", _name select 0, true];
        _legendaryWeapon setVariable ["WB_LegendaryDesc", _desc, true];

        // Apply effect
        [_legendaryWeapon, player] call _effect;

        // Visual indicator
        ["SuccessTitleAndText", ["LEGENDARY WEAPON!", format["%1 %2", _name, _baseWeapon]]] call ExileClient_gui_toaster_addTemplateToast;
        playSound "FD_Finish_F";

        diag_log format["[WB] Generated legendary: %1 %2", _name, _baseWeapon];

        _legendaryWeapon
    } else {
        _baseWeapon
    };
};

/**
 * Add legendary weapon to loot
 */
WB_fnc_addLegendaryToLoot = {
    params ["_container"];

    // Get all weapons in Arma 3
    private _allWeapons = "getNumber (_x >> 'scope') >= 2" configClasses (configFile >> "CfgWeapons");
    private _weaponsList = _allWeapons apply {configName _x};

    // Filter to actual weapons
    _weaponsList = _weaponsList select {
        private _cfg = configFile >> "CfgWeapons" >> _x;
        getNumber(_cfg >> "type") == 1 // Weapons only
    };

    private _randomWeapon = selectRandom _weaponsList;
    private _legendary = [_randomWeapon] call WB_fnc_generateLegendaryWeapon;

    if (_legendary isEqualType objNull && {_legendary getVariable ["WB_IsLegendary", false]}) then {
        _container addItemCargoGlobal [typeOf _legendary, 1];
    };
};

/**
 * Check if weapon is legendary on pickup
 */
player addEventHandler ["InventoryOpened", {
    params ["_unit", "_container"];

    {
        private _item = _x;
        if (_item getVariable ["WB_IsLegendary", false]) then {
            private _name = _item getVariable ["WB_LegendaryName", ""];
            private _desc = _item getVariable ["WB_LegendaryDesc", ""];

            hint parseText format["<t size='1.2' color='#FFD700'>★ LEGENDARY ★</t><br/><t size='1'>%1</t><br/><t size='0.8' color='#00FF00'>%2</t>", _name, _desc];
        };
    } forEach (weapons _unit);
}];

/**
 * Apply legendary effects in combat
 */
player addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

    private _weaponObj = _unit weaponAccessories _weapon;
    if (_weaponObj getVariable ["WB_IsLegendary", false]) then {
        private _effect = _weaponObj getVariable ["WB_LegendaryEffect", ""];

        switch (_effect) do {
            case "TwoShot": {
                // Already handled in prefix definition
            };

            case "Explosive": {
                private _explosiveDmg = _weaponObj getVariable ["WB_ExplosiveDamage", 0];
                "GrenadeHand" createVehicle (getPosATL _projectile);
            };

            case "Mighty": {
                private _bonus = _weaponObj getVariable ["WB_DamageBonus", 1];
                _projectile setVariable ["WB_DamageMultiplier", _bonus];
            };

            case "Bloodied": {
                private _healthPercent = (1 - (damage _unit));
                private _damageBonus = 1 + ((1 - _healthPercent) * 1.5); // Up to +150% at low health
                _projectile setVariable ["WB_DamageMultiplier", _damageBonus];
            };
        };
    };
}];

/**
 * Legendary enemy spawn chance
 */
WB_fnc_spawnLegendaryEnemy = {
    params ["_enemy"];

    private _legendaryChance = 5; // 5% chance

    if (random 100 < _legendaryChance) then {
        // Make enemy legendary
        _enemy setVariable ["WB_IsLegendary", true, true];
        _enemy setVariable ["WB_LegendaryLevel", 1 + floor(random 3), true]; // 1-3 star

        // Buff stats
        private _level = _enemy getVariable ["WB_LegendaryLevel", 1];
        _enemy setDamage (-_level * 0.5); // More health (negative damage = bonus health)
        _enemy setSkill (0.5 + (_level * 0.2)); // Better skills

        // Add glow effect
        private _light = "#lightpoint" createVehicleLocal (getPos _enemy);
        _light setLightBrightness 0.5;
        _light setLightColor [1, 0.8, 0];
        _light attachTo [_enemy, [0, 0, 1]];

        // Guaranteed legendary drop
        _enemy addEventHandler ["Killed", {
            params ["_unit"];

            private _level = _unit getVariable ["WB_LegendaryLevel", 1];

            // Drop legendary weapon
            for "_i" from 1 to _level do {
                [_unit] call WB_fnc_addLegendaryToLoot;
            };

            // Extra caps
            private _caps = 50 * _level;
            _unit setVariable ["ExileMoney", _caps, true];

            hint parseText format["<t size='1.2' color='#FFD700'>★ LEGENDARY ENEMY DEFEATED ★</t><br/><t size='0.9'>+%1 caps</t>", _caps];
        }];

        diag_log format["[WB] Spawned %1-star legendary enemy", _level];
    };
};

diag_log "[WB] Legendary weapons system initialized";
