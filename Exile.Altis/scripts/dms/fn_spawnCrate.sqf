params ["_pos"];

private _crate = createVehicle ["Box_NATO_Ammo_F", _pos, [], 0, "CAN_COLLIDE"];

clearWeaponCargoGlobal _crate;
clearMagazineCargoGlobal _crate;
clearItemCargoGlobal _crate;

private _loot = ["Tier3"] call (UMC get "getLoot");
_crate addWeaponCargoGlobal [_loot select 0, 1];
_crate addMagazineCargoGlobal [_loot select 1, 5];
_crate addItemCargoGlobal [_loot select 2, 1];

_crate setVariable ["UMC_timestamp", time];

_crate
