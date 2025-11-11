/*
    Shadow Hunter Loadout Assignment
    Assigns tier-based weapons and equipment to hunters
    Parameters: [_unit, _tier] - Unit and loadout tier (1-3)
*/

params [["_unit", objNull, [objNull]], ["_tier", 1, [0]]];

// Validation
if (isNull _unit) exitWith {
    diag_log "[Shadow Hunter] ERROR: Invalid unit in assignLoadout";
};

// Ensure tier is within valid range
_tier = (_tier max 1) min 3;

// Remove existing gear
removeAllWeapons _unit;
removeAllItems _unit;
removeAllAssignedItems _unit;
removeUniform _unit;
removeVest _unit;
removeBackpack _unit;
removeHeadgear _unit;
removeGoggles _unit;

// Add uniform and vest for inventory space
_unit forceAddUniform "U_B_CombatUniform_mcam";
_unit addVest "V_PlateCarrier1_rgr";

switch (_tier) do {
    case 1: {
        // Tier 1: Basic assault rifle with optic
        for "_i" from 1 to 6 do {
            _unit addMagazine "30Rnd_65x39_caseless_mag";
        };
        _unit addWeapon "arifle_MX_F";
        _unit addPrimaryWeaponItem "optic_Hamr";
        _unit addPrimaryWeaponItem "acc_flashlight";
    };
    case 2: {
        // Tier 2: LMG with bipod and improved optic
        for "_i" from 1 to 5 do {
            _unit addMagazine "100Rnd_65x39_caseless_mag";
        };
        _unit addWeapon "arifle_MX_SW_F";
        _unit addPrimaryWeaponItem "optic_MRCO";
        _unit addPrimaryWeaponItem "bipod_01_F_blk";
        _unit addPrimaryWeaponItem "acc_pointer_IR";
        _unit addItem "FirstAidKit";
    };
    case 3: {
        // Tier 3: Suppressed marksman rifle with advanced optic
        for "_i" from 1 to 7 do {
            _unit addMagazine "20Rnd_762x51_Mag";
        };
        _unit addWeapon "srifle_DMR_03_F";
        _unit addPrimaryWeaponItem "optic_DMS";
        _unit addPrimaryWeaponItem "muzzle_snds_B";
        _unit addPrimaryWeaponItem "bipod_01_F_blk";
        _unit addItem "FirstAidKit";
        _unit addItem "FirstAidKit";
        _unit addItem "Medikit";

        // Add NVG for tier 3
        _unit linkItem "NVGoggles";
    };
};

// Add standard equipment for all tiers
_unit linkItem "ItemMap";
_unit linkItem "ItemCompass";
_unit linkItem "ItemWatch";
_unit linkItem "ItemRadio";

// Reload weapon
reload _unit;
