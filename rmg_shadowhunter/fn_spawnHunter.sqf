
params ["_player"];

private _spawnPos = _player modelToWorld [3 + random 2, 3 + random 2, 0];

private _group = createGroup resistance;

for "_i" from 1 to 3 do {
    private _unit = _group createUnit ["B_Soldier_F", _spawnPos, [], 0, "FORM"];
    _unit setSkill SHW_accuracy + SHW_stealth;
    _unit setUnitPos "MIDDLE";
    _unit setVariable ["SHW_isHunter", true, true];
    _unit setVariable ["SHW_OwnerUID", getPlayerUID _player, true];

    [_unit, SHW_loadoutTier min 3] call compile preprocessFileLineNumbers "rmg_shadowhunter\fn_assignLoadout.sqf";
    [_unit, _player] spawn compile preprocessFileLineNumbers "rmg_shadowhunter\fn_escortLoop.sqf";

    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer", "_instigator"];
        [_unit, _instigator] call compile preprocessFileLineNumbers "rmg_shadowhunter\fn_evolveOnDeath.sqf";
        [_unit getVariable "SHW_OwnerUID"] spawn {
            params ["_uid"];
            sleep 15;
            private _plrs = allPlayers select {getPlayerUID _x == _uid};
            if (count _plrs > 0) then {
                [_plrs#0] call compile preprocessFileLineNumbers "rmg_shadowhunter\fn_spawnHunter.sqf";
            };
        };
    }];

    _unit addEventHandler ["HandleScore", {
        params ["_unit", "_victim"];
        if ((side _victim) isEqualTo east && !isPlayer _victim) then {
            [_unit, _victim] call compile preprocessFileLineNumbers "rmg_shadowhunter\fn_evolveOnKill.sqf";
        };
    }];
};
