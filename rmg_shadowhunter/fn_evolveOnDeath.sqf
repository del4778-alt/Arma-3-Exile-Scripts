
params ["_unit", "_instigator"];

SHW_phase = SHW_phase + 1;
SHW_stealth = SHW_stealth + 0.05;

if (!isNull _instigator) then {
    private _dmgType = currentWeapon _instigator;

    if (_dmgType find "sniper" > -1) then { SHW_accuracy = SHW_accuracy + 0.05; };
    if (_dmgType find "mine" > -1) then { SHW_aggression = SHW_aggression + 30; };
    if (_dmgType find "silencer" > -1) then { SHW_stealth = SHW_stealth + 0.05; };
};

publicVariable "SHW_phase";
publicVariable "SHW_stealth";
publicVariable "SHW_accuracy";
publicVariable "SHW_aggression";
