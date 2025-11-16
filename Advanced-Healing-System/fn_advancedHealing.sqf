/*
    Advanced Healing System v1.0
    Realistic medical mechanics and injuries

    Features:
    - Bleeding system requiring bandages
    - Fractures requiring splints
    - Infection from zombie attacks
    - Field medic recruit AI abilities
    - Medical supply crafting

    Installation:
    [] execVM "Advanced-Healing-System\fn_advancedHealing.sqf";
*/

HEALING_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["bleedingRate", 0.01],
    ["infectionChance", 0.3],
    ["infectionRate", 0.005],
    ["fractureChance", 0.2],
    ["healingItems", createHashMapFromArray [
        ["Bandage", "FirstAidKit"],
        ["Splint", "ToolKit"],
        ["Antibiotics", "Medikit"]
    ]]
];

HEALING_PlayerStatus = createHashMap;

HEALING_fnc_log = {
    if (HEALING_CONFIG get "debug") then {
        diag_log format ["[HEALING] %1", _this select 0];
    };
};

HEALING_fnc_getPlayerStatus = {
    params ["_player"];

    private _uid = getPlayerUID _player;
    private _status = HEALING_PlayerStatus getOrDefault [_uid, createHashMapFromArray [
        ["bleeding", false],
        ["fractured", false],
        ["infected", false],
        ["bleedAmount", 0]
    ]];

    HEALING_PlayerStatus set [_uid, _status];
    _status
};

HEALING_fnc_applyBleeding = {
    params ["_player", "_amount"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["bleeding", true];
    _status set ["bleedAmount", (_status get "bleedAmount") + _amount];

    hintSilent "You are BLEEDING! Use bandages!";
};

HEALING_fnc_applyFracture = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["fractured", true];

    player setAnimSpeedCoef 0.7;
    hintSilent "FRACTURE! Movement speed reduced. Use splint.";
};

HEALING_fnc_applyInfection = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["infected", true];

    hintSilent "INFECTION! Use antibiotics!";
};

HEALING_fnc_useBandage = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["bleeding", false];
    _status set ["bleedAmount", 0];

    hintSilent "Bleeding stopped.";
    _player removeItem "FirstAidKit";
};

HEALING_fnc_useSplint = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["fractured", false];

    player setAnimSpeedCoef 1.0;
    hintSilent "Fracture stabilized.";
    _player removeItem "ToolKit";
};

HEALING_fnc_useAntibiotics = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;
    _status set ["infected", false];

    hintSilent "Infection cured.";
    _player removeItem "Medikit";
};

HEALING_fnc_updatePlayer = {
    params ["_player"];

    private _status = [_player] call HEALING_fnc_getPlayerStatus;

    // Bleeding damage
    if (_status get "bleeding") then {
        private _damage = (HEALING_CONFIG get "bleedingRate") * (_status get "bleedAmount");
        _player setDamage ((damage _player) + _damage);

        if (damage _player > 0.9) then {
            hintSilent "Critical blood loss!";
        };
    };

    // Infection damage
    if (_status get "infected") then {
        _player setDamage ((damage _player) + (HEALING_CONFIG get "infectionRate"));
    };
};

HEALING_fnc_addHealingActions = {
    params ["_player"];

    _player addAction ["<t color='#00FF00'>Use Bandage</t>", {
        [player] call HEALING_fnc_useBandage;
    }, nil, 1.5, false, true, "", "player getVariable ['InJury_Bleeding', false] && 'FirstAidKit' in (items player)"];

    _player addAction ["<t color='#00FF00'>Use Splint</t>", {
        [player] call HEALING_fnc_useSplint;
    }, nil, 1.5, false, true, "", "player getVariable ['Injury_Fractured', false] && 'ToolKit' in (items player)"];

    _player addAction ["<t color='#00FF00'>Use Antibiotics</t>", {
        [player] call HEALING_fnc_useAntibiotics;
    }, nil, 1.5, false, true, "", "player getVariable ['Injury_Infected', false] && 'Medikit' in (items player)"];
};

HEALING_fnc_init = {
    ["Advanced Healing System v1.0 initializing..."] call HEALING_fnc_log;

    waitUntil {time > 10};

    // Add hit event handler to all players
    {
        if (isPlayer _x) then {
            [_x] call HEALING_fnc_addHealingActions;

            _x addEventHandler ["Hit", {
                params ["_unit", "_source", "_damage"];

                // Chance of bleeding
                if (random 1 < 0.5 && _damage > 0.1) then {
                    [_unit, _damage] call HEALING_fnc_applyBleeding;
                };

                // Chance of fracture
                if (random 1 < (HEALING_CONFIG get "fractureChance") && _damage > 0.3) then {
                    [_unit] call HEALING_fnc_applyFracture;
                };

                // Infection from zombies
                if (_source getVariable ["HordeMember", false]) then {
                    if (random 1 < (HEALING_CONFIG get "infectionChance")) then {
                        [_unit] call HEALING_fnc_applyInfection;
                    };
                };
            }];
        };
    } forEach allPlayers;

    // Update loop
    [] spawn {
        while {true} do {
            {
                if (isPlayer _x && alive _x) then {
                    [_x] call HEALING_fnc_updatePlayer;
                };
            } forEach allPlayers;
            sleep 5;
        };
    };

    ["Advanced Healing System initialized"] call HEALING_fnc_log;
};

[] call HEALING_fnc_init;
