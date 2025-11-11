
params ["_unit", "_tier"];

switch (_tier) do {
    case 1: {
        removeAllWeapons _unit;
        _unit addWeapon "arifle_MX_F";
        _unit addPrimaryWeaponItem "optic_Hamr";
        for "_i" from 1 to 5 do {
            _unit addMagazine "30Rnd_65x39_caseless_mag";
        };
    };
    case 2: {
        removeAllWeapons _unit;
        _unit addWeapon "arifle_MX_SW_F";
        _unit addPrimaryWeaponItem "optic_MRCO";
        _unit addPrimaryWeaponItem "bipod_01_F_blk";
        for "_i" from 1 to 7 do {
            _unit addMagazine "100Rnd_65x39_caseless_mag";
        };
    };
    case 3: {
        removeAllWeapons _unit;
        _unit addWeapon "srifle_DMR_03_F";
        _unit addPrimaryWeaponItem "optic_DMS";
        _unit addPrimaryWeaponItem "muzzle_snds_B";
        for "_i" from 1 to 5 do {
            _unit addMagazine "20Rnd_762x51_Mag";
        };
        _unit addItem "FirstAidKit";
        _unit addItem "Medikit";
    };
};
