if (!isServer) exitWith {};
params ["_player","_baseClass","_attachments"];
private _weapon = _baseClass;
_player addWeapon _weapon;
{ _player addPrimaryWeaponItem _x; } forEach _attachments;
