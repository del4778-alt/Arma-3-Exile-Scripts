/*
    Shadow Hunter Evolution On Death
    Increases stats when hunters are killed - they learn from death
    Parameters: [_unit, _instigator] - Killed hunter and killer
*/

params [["_unit", objNull, [objNull]], ["_instigator", objNull, [objNull]]];

// Validation
if (isNull _unit) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid unit in evolveOnDeath";
};

if (!isServer) exitWith {};

// Track evolution
private _oldPhase = SHW_phase;
private _oldStealth = SHW_stealth;
private _oldAccuracy = SHW_accuracy;
private _oldAggression = SHW_aggression;

// Base evolution - hunters learn from death
SHW_phase = SHW_phase + 1;
SHW_stealth = ((SHW_stealth + 0.05) min SHW_MAX_STEALTH);

// Analyze killer's weapon for specialized evolution
if (!isNull _instigator && isPlayer _instigator) then {
    private _weapon = currentWeapon _instigator;
    private _weaponConfig = configFile >> "CfgWeapons" >> _weapon;

    // Check weapon type via config
    if (isClass _weaponConfig) then {
        // Get weapon info
        private _weaponType = getText (_weaponConfig >> "type");
        private _muzzles = getArray (_weaponConfig >> "muzzles");

        // Check for suppressor attachment
        private _hasSuppressor = false;
        {
            private _item = _x;
            if (isClass (configFile >> "CfgWeapons" >> _item)) then {
                private _itemType = getText (configFile >> "CfgWeapons" >> _item >> "ItemInfo" >> "type");
                if (_itemType == "201") then { _hasSuppressor = true; }; // Type 201 = Suppressor
            };
        } forEach (primaryWeaponItems _instigator);

        // Evolution based on weapon characteristics
        // Sniper/Marksman rifles (high accuracy kill)
        if (_weapon isKindOf ["SniperRifle", configFile >> "CfgWeapons"] ||
            _weapon isKindOf ["DMR", configFile >> "CfgWeapons"]) then {
            SHW_accuracy = ((SHW_accuracy + 0.05) min SHW_MAX_ACCURACY);
            diag_log "[Shadow Hunter] Death by precision weapon - accuracy evolved";
        };

        // Suppressed weapons (stealth kill)
        if (_hasSuppressor) then {
            SHW_stealth = ((SHW_stealth + 0.08) min SHW_MAX_STEALTH);
            diag_log "[Shadow Hunter] Death by suppressed weapon - stealth evolved";
        };

        // Explosive/Mine kills (aggression response)
        if (_weapon == "Put" || _weapon == "Throw") then {
            SHW_aggression = ((SHW_aggression + 40) min SHW_MAX_AGGRESSION);
            diag_log "[Shadow Hunter] Death by explosive - aggression evolved";
        };
    };
};

// Sync variables to all clients
publicVariable "SHW_phase";
publicVariable "SHW_stealth";
publicVariable "SHW_accuracy";
publicVariable "SHW_aggression";

// Log evolution
diag_log format ["[Shadow Hunter] Death Evolution (Phase %1): Stealth: %2->%3, Accuracy: %4->%5, Aggression: %6->%7",
    SHW_phase, _oldStealth, SHW_stealth, _oldAccuracy, SHW_accuracy, _oldAggression, SHW_aggression];
