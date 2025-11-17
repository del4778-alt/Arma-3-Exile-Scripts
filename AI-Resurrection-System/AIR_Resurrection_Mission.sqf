/*
	AI RESURRECTION SYSTEM - Mission Script Version
	by Adri_karry
	Converted to mission script format

	INSTALLATION:
	1. Save this file to your mission folder (e.g., mission.sqf)
	2. Add to init.sqf: execVM "AIR_Resurrection_Mission.sqf";
	3. Configure settings in the CONFIGURATION section below

	FEATURES:
	- AI automatically revive incapacitated allies
	- Player revive actions for incapacitated units
	- Drag system (User Action 8 key)
	- Admin menu (User Action 10 key)
	- Player menu (User Action 7 key) with auto-revive, leadership, and recruit options
*/

// ============================================================================
// CONFIGURATION
// ============================================================================

// Death timer before unit dies (seconds)
AIR_deathTime = 180;

// Radius in which AI will search for incapacitated allies (meters)
AIR_reviveRadius = 80;

// Maximum revive attempts
AIR_maxRetries = 12;

// Life/damage level after revival (0 = full health, 0.5 = half health)
AIR_life = 0;

// Faction-specific toggles (false = revive enabled, true = revive disabled for that faction)
AIR_factionWest = false;
AIR_factionEast = false;
AIR_factionIndependent = false;
AIR_factionCivilian = false;

// Lethal damage (true = units can die instantly from high damage, false = always incapacitate first)
AIR_Letal_Damage_A = false;

// Damage reduction threshold before incapacitation
AIR_damageReduction = 0;

// Publish variables globally
publicVariable "AIR_deathTime";
publicVariable "AIR_reviveRadius";
publicVariable "AIR_maxRetries";
publicVariable "AIR_life";
publicVariable "AIR_factionWest";
publicVariable "AIR_factionEast";
publicVariable "AIR_factionIndependent";
publicVariable "AIR_factionCivilian";
publicVariable "AIR_Letal_Damage_A";
publicVariable "AIR_damageReduction";

// ============================================================================
// MAIN AI RESURRECTION SYSTEM
// ============================================================================

[] spawn {
    if (!isServer) exitWith {};
    while {true} do {
        {
            if (
                side _x in [west, independent, east, civilian] &&
                alive _x &&
                isNil {_x getVariable "originalSide"}
            ) then {
                _x setVariable ["originalSide", side _x, true];
                _x setVariable ["reviving", false, true];
                private _unit = _x;
                [_unit] spawn {
                    params ["_unit"];
                    _unit setCaptive false;

                    _unit addEventHandler ["HandleDamage", {
                        params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

                        private _allowIncap = false;
                        if (side _unit == west) then {_allowIncap = missionNamespace getVariable ["AIR_factionWest", false] isEqualTo false};
                        if (side _unit == east) then {_allowIncap = missionNamespace getVariable ["AIR_factionEast", false] isEqualTo false};
                        if (side _unit == independent) then {_allowIncap = missionNamespace getVariable ["AIR_factionIndependent", false] isEqualTo false};
                        if (side _unit == civilian) then {_allowIncap = missionNamespace getVariable ["AIR_factionCivilian", false] isEqualTo false};

                        if (_allowIncap) then {

                        if (!(_unit getVariable ["isIncapacitated", false])) then {
                        if (missionNamespace getVariable ["AIR_Letal_Damage_A", false]) then {
                            if (_damage > 0.99) then {
                                _unit setDamage 1;
                            };
                        } else {
                            if (_damage > 0.97) then {
                                _unit setDamage 0.98;
                            };
                        };
                    };

                        if (vehicle _unit != _unit && {damage (vehicle _unit) >= 1}) then {
                            if (_unit in (crew (vehicle _unit))) then {
                                _unit setDamage 1;
                                _unit setUnconscious false;
                                _unit setVariable ["isIncapacitated", false, true];
                                _unit setVariable ["reviving", false, true];
                                _unit setVariable ["damageDelayTimer", 0, true];
                                _unit setCaptive false;
                                _unit setVariable ["originalSide", side _unit, true];
                                _unit setVariable ["reviveActionAdded", false];
                                _unit setVariable ["AIR_damageImmune", false];
                            };
                        };

                        private _damageReduction = missionNamespace getVariable ["AIR_damageReduction", 0];
                        if (((damage _unit + _damage) - _damageReduction) > 0.97 && alive _unit && {lifeState _unit != "incapacitated"} && !(_unit getVariable ["isIncapacitated", false])) then {

                            _unit setDamage 0.8;
                            _unit setUnconscious true;
                            _unit setVariable ["isIncapacitated", true, true];
                            _unit setVariable ["reviving", false, true];
                            _unit setCaptive false;

                            _unit setVariable ["AIR_damageImmune", true];
                            [_unit] spawn {
                                params ["_unit"];
                                sleep 1;
                                _unit setVariable ["AIR_damageImmune", false];
                                _unit setCaptive false;
                            };

                            private _deathTimerHandle = [_unit] spawn {
                                params ["_unit"];

                                private _deathTime = missionNamespace getVariable ["AIR_deathTime", 180];
                                while {
                                    _deathTime > 0 &&
                                    (_unit getVariable "isIncapacitated" == true) &&
                                    alive _unit
                                } do {
                                    sleep 1;
                                    _deathTime = _deathTime - 1;
                                };
                                if (_deathTime == 0 && (_unit getVariable "isIncapacitated" == true) && alive _unit) then {
                                    _unit setDamage 1;
                                };
                                _unit setVariable ["deathTimerHandle", nil];
                            };
                            _unit setVariable ["deathTimerHandle", _deathTimerHandle, true];

                            _damage = 0;
                        };

                        if (_unit getVariable ["isIncapacitated", false]) then {
                            _unit setCaptive false;
                            if !(_unit getVariable ["AIR_damageImmune", false]) then {
                                private _total = (damage _unit + _damage);
                                if (_total >= 0.9) then {
                                    _damage;
                                };
                            };
                            if (_unit getVariable ["AIR_damageImmune", false]) then {
                            _damage = 0;
                            };
                        };

                        _damage
                        } else {
                            _damage
                        };
                    }];

                    _unit addEventHandler ["Killed", {
                        params ["_unit"];
                        _unit setUnconscious false;
                        _unit setVariable ["isIncapacitated", false, true];
                        _unit setVariable ["reviving", false, true];
                        _unit setVariable ["damageDelayTimer", 0, true];
                        _unit setCaptive false;
                        _unit setVariable ["originalSide", side _unit, true];
                        _unit setVariable ["reviveActionAdded", false];
                        _unit setVariable ["AIR_damageImmune", false];
                    }];

                    private _reviveRadius = missionNamespace getVariable ["AIR_reviveRadius", 80];
                    while {alive _unit} do {
                        if (_unit isKindOf "CAManBase" && isNil {_unit getVariable "originalSide"}) then {
                            _unit setVariable ["originalSide", side _unit, true];
                        };

                        if (!isPlayer _unit && vehicle _unit == _unit) then {
                            private _nearbyIncapacitatedAllies = allUnits select {
                                (_x != _unit) &&
                                (lifeState _x == "incapacitated") &&
                                {!(_x getVariable ["reviving", false])} &&
                                !isNil {_x getVariable "originalSide"} &&
                                (side _unit == (_x getVariable "originalSide")) &&
                                alive _x &&
                                (_unit distance _x <= _reviveRadius)
                            };
                            _nearbyIncapacitatedAllies sort true;
                            if (count _nearbyIncapacitatedAllies > 0) then {
                                private _incapacitatedAlly = _nearbyIncapacitatedAllies select 0;
                                if (lifeState _unit == "incapacitated") exitWith {};
                                _incapacitatedAlly setVariable ["reviving", true, false];

                                if (
                                    alive _unit &&
                                    !(_unit getVariable ["animating", false]) &&
                                    !(_unit getVariable ["isIncapacitated", false]) &&
                                    !isNull _incapacitatedAlly &&
                                    alive _incapacitatedAlly &&
                                    lifeState _incapacitatedAlly == "incapacitated" &&
                                    _unit != _incapacitatedAlly
                                ) then {
                                    _unit setVariable ["animating", true, false];
                                    private _grupo = group _unit;
                                    {
                                        if (alive _x && (leader _grupo != _x)) then {
                                            _x doMove getPos _unit;
                                            _x setSpeedMode "FULL";
                                        };
                                    } forEach units _grupo;
                                    _unit setSpeedMode "FULL";

                                    private _timeoutStart = time;
                                    private _timeout = 60;

                                    waitUntil {
                                        if (!alive _unit || !alive _incapacitatedAlly) exitWith {true};
                                        if (_unit getVariable ["isIncapacitated", false]) exitWith {true};
                                        if (lifeState _incapacitatedAlly != "incapacitated") exitWith {true};
                                        if ((time - _timeoutStart) > _timeout) exitWith {true};

                                        if (_unit distance _incapacitatedAlly > 3) then {
                                            _unit doMove getPos _incapacitatedAlly;
                                            false
                                        } else {
                                            true
                                        };
                                    };

                                    _unit setVariable ["animating", false, false];

                                    if (
                                        alive _unit &&
                                        !(_unit getVariable ["animating", false]) &&
                                        !(_unit getVariable ["isIncapacitated", false]) &&
                                        !isNull _incapacitatedAlly &&
                                        alive _incapacitatedAlly &&
                                        lifeState _incapacitatedAlly == "incapacitated" &&
                                        _unit != _incapacitatedAlly
                                    ) then {
                                    _unit doWatch _incapacitatedAlly;
                                    _unit setDir (_unit getDir _incapacitatedAlly);
                                    _unit setUnitPos "MIDDLE";
                                    _unit disableAI "WEAPONAIM";
                                    _unit disableAI "MOVE";
                                    _unit disableAI "ANIM";
                                    _unit switchMove "AinvPknlMstpSnonWnonDnon_medic_1";
                                    sleep 7;
                                    _unit enableAI "WEAPONAIM";
                                    _unit enableAI "MOVE";
                                    _unit enableAI "ANIM";
                                    _unit setUnitPos "AUTO";
                                    if (
                                        alive _unit &&
                                        !(_unit getVariable ["animating", false]) &&
                                        !(_unit getVariable ["isIncapacitated", false]) &&
                                        !isNull _incapacitatedAlly &&
                                        alive _incapacitatedAlly &&
                                        lifeState _incapacitatedAlly == "incapacitated" &&
                                        _unit != _incapacitatedAlly
                                    ) then {
                                        {
                                            if (alive _x && (leader group _x != _x)) then {
                                                _x doFollow (leader group _x);
                                            };
                                        } forEach units group _unit;
                                        private _Life = missionNamespace getVariable ["AIR_Life", 0];
                                        _incapacitatedAlly setUnconscious false;
                                        _incapacitatedAlly setDamage _Life;
                                        _incapacitatedAlly setVariable ["damageDelayTimer", 0, true];
                                        _incapacitatedAlly setVariable ["reviving", false, false];
                                        _incapacitatedAlly setVariable ["isIncapacitated", false, true];
                                    } else {
                                        if (!isNull _incapacitatedAlly && alive _incapacitatedAlly) then {
                                            _incapacitatedAlly setVariable ["reviving", false, false];
                                        };
                                    };
                                } else {
                                    if (!isNull _incapacitatedAlly && alive _incapacitatedAlly) then {
                                        _incapacitatedAlly setVariable ["reviving", false, false];
                                    };
                                };
                            };
                            sleep 3;
                        };
                        sleep 3;
                    };
                };
            };
        } forEach allUnits;
        sleep 10;
    };
};

// ============================================================================
// PLAYER REVIVE ACTIONS
// ============================================================================

[] spawn {
    if (!isServer) exitWith {};

    private _trackedUnits = [];

    while {true} do {
        private _activeSides = [];
        {
            if (isPlayer _x && alive _x) then {
                _activeSides pushBackUnique (side _x);
            };
        } forEach allPlayers;

        {
            if (
                side _x in _activeSides &&
                alive _x &&
                isNull objectParent _x &&
                !(_x getVariable ["reviveActionManaged", false])
            ) then {
                _x setVariable ["reviveActionManaged", true, true];
                _trackedUnits pushBackUnique _x;
            };
        } forEach allUnits;

        {
            private _unit = _x;

            if (!alive _unit) then {
                _trackedUnits deleteAt (_trackedUnits find _unit);
                _unit setVariable ["reviveActionAdded", false, true];
                _unit setVariable ["reviveActionID", nil, true];
                _unit setVariable ["reviveActionManaged", false, true];
            };

            if (_unit getVariable ["isIncapacitated", false]) then {
                private _nearbyPlayers = allPlayers select {
                    alive _x && (_x distance _unit <= 10)
                };

                if ((count _nearbyPlayers > 0) && !(_unit getVariable ["reviveActionAdded", false])) then {
                    private _actionID = [_unit,
                        "Revive",
                        "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_revive_ca.paa",
                        "\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_revive_ca.paa",
                        "_this distance _target <= 2 && { alive _target && _target getVariable ['isIncapacitated', false] }",
                        "alive _target && _target getVariable ['isIncapacitated', false]",
                        { (_this select 1) playMove "AinvPknlMstpSnonWnonDnon_medic_1"; },
                        {},
                        {
                            params ["_target", "_caller", "_actionID"];
                            if ((_target getVariable ["isIncapacitated", false]) && {alive _caller}) then {
                                private _Life = missionNamespace getVariable ["AIR_Life", 0];
                                _target setUnconscious false;
                                _target setDamage _Life;
                                _target setCaptive false;
                                _target setVariable ["damageDelayTimer", 0, true];
                                _target setVariable ["reviving", false, false];
                                _target setVariable ["isIncapacitated", false, true];
                                _target setVariable ["reviveActionAdded", false];
                                _target setVariable ["AIR_damageImmune", false];
                            };
                        },
                        { (_this select 1) switchMove ""; },
                        [],
                        4.5,
                        nil,
                        true,
                        false
                    ] call BIS_fnc_holdActionAdd;

                    _unit setVariable ["reviveActionID", _actionID, true];
                    _unit setVariable ["reviveActionAdded", true, true];
                };
            };

            if (
                !(_unit getVariable ["isIncapacitated", false]) &&
                (_unit getVariable ["reviveActionAdded", false])
            ) then {
                private _actionID = _unit getVariable ["reviveActionID", nil];
                if (!isNil "_actionID") then {
                    [_unit, _actionID] call BIS_fnc_holdActionRemove;
                };
                _unit setVariable ["reviveActionAdded", false, true];
                _unit setVariable ["reviveActionID", nil, true];
            };
        } forEach _trackedUnits;

        sleep 2;
    };
};

// ============================================================================
// DRAG SYSTEM (User Action 8)
// ============================================================================

[] spawn {
    if (!isServer) exitWith {};

    private _trackedUnits = [];

    while {true} do {
        private _activeSides = [];
        {
            if (isPlayer _x && alive _x) then {
                _activeSides pushBackUnique (side _x);
            };
        } forEach allPlayers;

        {
            if (
                side _x in _activeSides &&
                alive _x &&
                isNull objectParent _x &&
                !(_x getVariable ["AIR_dragActionManaged", false])
            ) then {
                _x setVariable ["AIR_dragActionManaged", true, true];
                _trackedUnits pushBackUnique _x;
            };
        } forEach allUnits;

        {
            private _unit = _x;

            if (!alive _unit) then {
                _trackedUnits deleteAt (_trackedUnits find _unit);
                _unit setVariable ["AIR_dragActionManaged", false, true];
                private _dragger = _unit getVariable ["AIR_draggingTarget", objNull];
                if (!isNull _dragger) then {
                    detach _unit;
                    _unit setVariable ["AIR_beingDragged", false, true];
                    _dragger setVariable ["AIR_draggingTarget", nil, true];
                    _dragger switchMove "AmovPercMstpSnonWnonDnon";
                };
                continue;
            };

            if (!(_unit getVariable ["isIncapacitated", false]) && (_unit getVariable ["AIR_beingDragged", false])) then {
                private _dragger = _unit getVariable ["AIR_draggingTarget", objNull];
                if (!isNull _dragger) then {
                    detach _unit;
                    _unit setVariable ["AIR_beingDragged", false, true];
                    _dragger setVariable ["AIR_draggingTarget", nil, true];
                    _dragger switchMove "AmovPercMstpSnonWnonDnon";
                };
            };
        } forEach _trackedUnits;

        sleep 1;
    };
};

[] spawn {
    if (isDedicated) exitWith {};

    waitUntil {!(isNull (findDisplay 46))};

    if (isNil {player getVariable "dragKeyEH"}) then {
        private _eh = (findDisplay 46) displayAddEventHandler ["KeyDown", {
            params ["_display", "_key"];
            private _player = player;
            private _AIR_draggingTarget = _player getVariable ["AIR_draggingTarget", objNull];

            if !(_key in (actionKeys "User8")) exitWith {false};

            if (!isNull _AIR_draggingTarget) then {
                detach _AIR_draggingTarget;
                _AIR_draggingTarget setVariable ["AIR_beingDragged", false, true];
                _player setVariable ["AIR_draggingTarget", nil, true];
                _player switchMove "AcinPknlMstpSrasWrflDnon_AmovPknlMstpSrasWrflDnon";
                true;
            } else {
                private _nearUnit = objNull;
                {
                    if (
                        alive _x &&
                        _x getVariable ["isIncapacitated", false] &&
                        !(_x getVariable ["AIR_beingDragged", false]) &&
                        !(_x isEqualTo _player) &&
                        _player distance _x <= 2
                    ) exitWith {
                        _nearUnit = _x;
                    };
                } forEach allUnits;

                if (!isNull _nearUnit) then {
                    _player switchMove "AcinPknlMstpSrasWrflDnon_AmovPknlMstpSrasWrflDnon";
                    _player switchMove "AcinPknlMwlkSnonWnonDb";

                    private _offset = [0, 1.1, -0.6];
                    _nearUnit attachTo [_player, _offset, "Pelvis"];
                    _nearUnit setDir 180;

                    _player playMoveNow "AcinPknlMwlkSnonWnonDb";

                    _nearUnit setVariable ["AIR_beingDragged", true, true];
                    _player setVariable ["AIR_draggingTarget", _nearUnit, true];

                    [_player, _nearUnit] spawn {
                        params ["_caller", "_target"];
                        waitUntil {
                            !alive _caller ||
                            !alive _target ||
                            !(_target getVariable ["isIncapacitated", false]) ||
                            !(_target getVariable ["AIR_beingDragged", false]) ||
                            !(_caller getVariable ["AIR_draggingTarget", objNull] isEqualTo _target) ||
                            (_caller getVariable ["isIncapacitated", false])
                        };

                        detach _target;
                        _target setVariable ["AIR_beingDragged", false, true];
                        _caller setVariable ["AIR_draggingTarget", nil, true];
                        _caller switchMove "AcinPknlMstpSrasWrflDnon_AmovPknlMstpSrasWrflDnon";
                    };
                    true;
                } else {
                    false;
                };
            };
        }];
        player setVariable ["dragKeyEH", _eh, true];
    };
};

// ============================================================================
// ADMIN MENU (User Action 10)
// ============================================================================

[] spawn {
    if (!isServer) exitWith {};
    waitUntil {!(isNull (findDisplay 46))};

    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_control", "_key"];

        if (_key in (actionKeys "User10")) then {
            disableSerialization;

            player setVariable ["adminStatus", false, true];
            if (isMultiplayer) then {
                private _playerOwner = owner player;
                private _adminLevel = admin _playerOwner;

                if (_playerOwner == 2 || _adminLevel > 0) then {
                    player setVariable ["adminStatus", true, true];
                } else {
                    player setVariable ["adminStatus", false, true];
                };
            };

            if !(isMultiplayer) then {
                player setVariable ["adminStatus", true, true];
            };

            if ((player getVariable ["adminStatus", false]) isEqualTo true) then {
                _display = findDisplay 46 createDisplay "RscDisplayEmpty";

                private _background = _display ctrlCreate ["RscText", -1];
                _background ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.247 * safezoneH + safezoneY,0.220355 * safezoneW,0.686487 * safezoneH];
                _background ctrlSetBackgroundColor [0, 0, 0, 1];
                _background ctrlCommit 0;

                private _sliderDeathTime = _display ctrlCreate ["RscXSliderH", -1];
                _sliderDeathTime ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.335 * safezoneH + safezoneY,0.221719 * safezoneW,0.044 * safezoneH];
                _sliderDeathTime ctrlSetBackgroundColor [0, 0, 0, 1];
                _sliderDeathTime sliderSetRange [60, 600];
                _sliderDeathTime sliderSetPosition (missionNamespace getVariable ["AIR_deathTime", 180]);
                _sliderDeathTime ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_control", "_value"];
                    missionNamespace setVariable ["AIR_deathTime", round _value, true];
                    systemChat format ["Death Time: %1 seconds", round _value];
                }];
                _sliderDeathTime ctrlCommit 0;

                private _labelDeathTime = _display ctrlCreate ["RscText", -1];
                _labelDeathTime ctrlSetPosition [0.438125 * safezoneW + safezoneX,0.291 * safezoneH + safezoneY,0.12375 * safezoneW,0.044 * safezoneH];
                _labelDeathTime ctrlSetText "Death Time";
                _labelDeathTime ctrlSetTextColor [1, 1, 1, 1];
                _labelDeathTime ctrlCommit 0;

                private _sliderLife = _display ctrlCreate ["RscXSliderH", -1];
                _sliderLife ctrlSetPosition [0.386562 * safezoneW + safezoneX,0.434 * safezoneH + safezoneY,0.221719 * safezoneW,0.044 * safezoneH];
                _sliderLife ctrlSetBackgroundColor [0, 0, 0, 1];
                _sliderLife sliderSetRange [0, 0.5];
                _sliderLife sliderSetPosition (missionNamespace getVariable ["AIR_Life", 0]);
                _sliderLife ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_control", "_value"];
                    missionNamespace setVariable ["AIR_Life", _value, true];
                    systemChat format ["Life After Revive: %1", _value toFixed 2];
                }];
                _sliderLife ctrlCommit 0;

                private _labelLife = _display ctrlCreate ["RscText", -1];
                _labelLife ctrlSetPosition [0.443281 * safezoneW + safezoneX,0.39 * safezoneH + safezoneY,0.12375 * safezoneW,0.044 * safezoneH];
                _labelLife ctrlSetText "Life After Revive";
                _labelLife ctrlSetTextColor [1, 1, 1, 1];
                _labelLife ctrlCommit 0;

                private _sliderReviveRadius = _display ctrlCreate ["RscXSliderH", -1];
                _sliderReviveRadius ctrlSetPosition [0.386562 * safezoneW + safezoneX, 0.533 * safezoneH + safezoneY, 0.221719 * safezoneW, 0.044 * safezoneH];
                _sliderReviveRadius ctrlSetBackgroundColor [0, 0, 0, 1];
                _sliderReviveRadius sliderSetRange [10, 100];
                _sliderReviveRadius sliderSetPosition (missionNamespace getVariable ["AIR_reviveRadius", 80]);
                _sliderReviveRadius ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_control", "_value"];
                    missionNamespace setVariable ["AIR_reviveRadius", round _value, true];
                    systemChat format ["Revive Radius: %1 meters", round _value];
                }];
                _sliderReviveRadius ctrlCommit 0;

                private _labelReviveRadius = _display ctrlCreate ["RscText", -1];
                _labelReviveRadius ctrlSetPosition [0.443281 * safezoneW + safezoneX, 0.489 * safezoneH + safezoneY, 0.12375 * safezoneW, 0.044 * safezoneH];
                _labelReviveRadius ctrlSetText "Revive Radius";
                _labelReviveRadius ctrlSetTextColor [1, 1, 1, 1];
                _labelReviveRadius ctrlCommit 0;

                private _sliderMaxRetries = _display ctrlCreate ["RscXSliderH", -1];
                _sliderMaxRetries ctrlSetPosition [0.386562 * safezoneW + safezoneX, 0.632 * safezoneH + safezoneY, 0.221719 * safezoneW, 0.044 * safezoneH];
                _sliderMaxRetries ctrlSetBackgroundColor [0, 0, 0, 1];
                _sliderMaxRetries sliderSetRange [1, 15];
                _sliderMaxRetries sliderSetPosition (missionNamespace getVariable ["AIR_maxRetries", 3]);
                _sliderMaxRetries ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_control", "_value"];
                    missionNamespace setVariable ["AIR_maxRetries", round _value, true];
                    systemChat format ["Revive Attempts: %1", round _value];
                }];
                _sliderMaxRetries ctrlCommit 0;

                private _labelMaxRetries = _display ctrlCreate ["RscText", -1];
                _labelMaxRetries ctrlSetPosition [0.443281 * safezoneW + safezoneX, 0.588 * safezoneH + safezoneY, 0.12375 * safezoneW, 0.044 * safezoneH];
                _labelMaxRetries ctrlSetText "Revive Attempts";
                _labelMaxRetries ctrlSetTextColor [1, 1, 1, 1];
                _labelMaxRetries ctrlCommit 0;

                private _background2 = _display ctrlCreate ["RscText", -1];
                _background2 ctrlSetPosition [0.601363 * safezoneW + safezoneX,0.509404 * safezoneH + safezoneY,0.149841 * safezoneW,0.366753 * safezoneH];
                _background2 ctrlSetBackgroundColor [0, 0, 0, 1];
                _background2 ctrlCommit 0;

                private _labelFactions = _display ctrlCreate ["RscText", -1];
                _labelFactions ctrlSetPosition [0.618991 * safezoneW + safezoneX,0.531081 * safezoneH + safezoneY,0.113271 * safezoneW,0.0330333 * safezoneH];
                _labelFactions ctrlSetText "FACTION TOGGLES";
                _labelFactions ctrlSetTextColor [1, 1, 1, 1];
                _labelFactions ctrlCommit 0;

                private _botonWest = _display ctrlCreate ["RscButton", -1];
                _botonWest ctrlSetPosition [0.618991 * safezoneW + safezoneX, 0.575231 * safezoneH + safezoneY, 0.110177 * safezoneW, 0.0564236 * safezoneH];
                private _westEnabled = missionNamespace getVariable ["AIR_factionWest", false];
                _botonWest ctrlSetText format ["BLUFOR %1", if (_westEnabled) then {"ENABLED"} else {"DISABLED"}];
                _botonWest ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonWest ctrlSetTextColor (if (_westEnabled) then {[1, 1, 0, 1]} else {[0, 0.3, 1, 1]});
                _botonWest ctrlCommit 0;
                _botonWest ctrlAddEventHandler ["ButtonClick", {
                    private _control = _this select 0;
                    private _estadoActual = missionNamespace getVariable ["AIR_factionWest", false];
                    private _nuevoEstado = !_estadoActual;
                    missionNamespace setVariable ["AIR_factionWest", _nuevoEstado, true];
                    _control ctrlSetText format ["BLUFOR %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                    _control ctrlSetTextColor (if (_nuevoEstado) then {[1, 1, 0, 1]} else {[0, 0.3, 1, 1]});
                    systemChat format ["BLUFOR %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                }];

                private _botonEast = _display ctrlCreate ["RscButton", -1];
                _botonEast ctrlSetPosition [0.618991 * safezoneW + safezoneX, 0.650463 * safezoneH + safezoneY, 0.110177 * safezoneW, 0.0564236 * safezoneH];
                private _eastEnabled = missionNamespace getVariable ["AIR_factionEast", false];
                _botonEast ctrlSetText format ["OPFOR %1", if (_eastEnabled) then {"ENABLED"} else {"DISABLED"}];
                _botonEast ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonEast ctrlSetTextColor (if (_eastEnabled) then {[1, 1, 0, 1]} else {[1, 0, 0, 1]});
                _botonEast ctrlCommit 0;
                _botonEast ctrlAddEventHandler ["ButtonClick", {
                    private _control = _this select 0;
                    private _estadoActual = missionNamespace getVariable ["AIR_factionEast", false];
                    private _nuevoEstado = !_estadoActual;
                    missionNamespace setVariable ["AIR_factionEast", _nuevoEstado, true];
                    _control ctrlSetText format ["OPFOR %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                    _control ctrlSetTextColor (if (_nuevoEstado) then {[1, 1, 0, 1]} else {[1, 0, 0, 1]});
                    systemChat format ["OPFOR %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                }];

                private _botonIndependent = _display ctrlCreate ["RscButton", -1];
                _botonIndependent ctrlSetPosition [0.618991 * safezoneW + safezoneX, 0.725694 * safezoneH + safezoneY, 0.110177 * safezoneW, 0.0564236 * safezoneH];
                private _independentEnabled = missionNamespace getVariable ["AIR_factionIndependent", false];
                _botonIndependent ctrlSetText format ["INDEPENDENT %1", if (_independentEnabled) then {"ENABLED"} else {"DISABLED"}];
                _botonIndependent ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonIndependent ctrlSetTextColor (if (_independentEnabled) then {[1, 1, 0, 1]} else {[0, 1, 0, 1]});
                _botonIndependent ctrlCommit 0;
                _botonIndependent ctrlAddEventHandler ["ButtonClick", {
                    private _control = _this select 0;
                    private _estadoActual = missionNamespace getVariable ["AIR_factionIndependent", false];
                    private _nuevoEstado = !_estadoActual;
                    missionNamespace setVariable ["AIR_factionIndependent", _nuevoEstado, true];
                    _control ctrlSetText format ["INDEPENDENT %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                    _control ctrlSetTextColor (if (_nuevoEstado) then {[1, 1, 0, 1]} else {[0, 1, 0, 1]});
                    systemChat format ["INDEPENDENT %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                }];

                private _botonCivilian = _display ctrlCreate ["RscButton", -1];
                _botonCivilian ctrlSetPosition [0.618991 * safezoneW + safezoneX, 0.800926 * safezoneH + safezoneY, 0.110177 * safezoneW, 0.0564236 * safezoneH];
                private _civilianEnabled = missionNamespace getVariable ["AIR_factionCivilian", false];
                _botonCivilian ctrlSetText format ["CIVILIAN %1", if (_civilianEnabled) then {"ENABLED"} else {"DISABLED"}];
                _botonCivilian ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonCivilian ctrlSetTextColor (if (_civilianEnabled) then {[1, 1, 0, 1]} else {[0.6, 0, 0.6, 1]});
                _botonCivilian ctrlCommit 0;
                _botonCivilian ctrlAddEventHandler ["ButtonClick", {
                    private _control = _this select 0;
                    private _estadoActual = missionNamespace getVariable ["AIR_factionCivilian", false];
                    private _nuevoEstado = !_estadoActual;
                    missionNamespace setVariable ["AIR_factionCivilian", _nuevoEstado, true];
                    _control ctrlSetText format ["CIVILIAN %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                    _control ctrlSetTextColor (if (_nuevoEstado) then {[1, 1, 0, 1]} else {[0.6, 0, 0.6, 1]});
                    systemChat format ["CIVILIAN %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                }];

                private _botonLetalD = _display ctrlCreate ["RscButton", -1];
                _botonLetalD ctrlSetPosition [0.39423 * safezoneW + safezoneX,0.800926 * safezoneH + safezoneY,0.21154 * safezoneW,0.0564236 * safezoneH];
                private _Letal_Damage_A = missionNamespace getVariable ["AIR_Letal_Damage_A", false];
                _botonLetalD ctrlSetText (if (_Letal_Damage_A) then {"Lethal Damage ENABLED"} else {"Lethal Damage DISABLED"});
                _botonLetalD ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonLetalD ctrlSetTextColor (if (_Letal_Damage_A) then {[1, 0.5, 0, 1]} else {[0, 0.8, 1, 1]});
                _botonLetalD ctrlCommit 0;
                _botonLetalD ctrlAddEventHandler ["ButtonClick", {
                    private _control = _this select 0;
                    private _estadoActual = missionNamespace getVariable ["AIR_Letal_Damage_A", false];
                    private _nuevoEstado = !_estadoActual;

                    missionNamespace setVariable ["AIR_Letal_Damage_A", _nuevoEstado, true];

                    _control ctrlSetText (if (_nuevoEstado) then {"Lethal Damage ENABLED"} else {"Lethal Damage DISABLED"});
                    _control ctrlSetTextColor (if (_nuevoEstado) then {[1, 0.5, 0, 1]} else {[0, 0.8, 1, 1]});

                    systemChat format ["Lethal Damage %1", if (_nuevoEstado) then {"ENABLED"} else {"DISABLED"}];
                }];

                private _sliderDamageReduction = _display ctrlCreate ["RscXSliderH", -1];
                _sliderDamageReduction ctrlSetPosition [0.389823 * safezoneW + safezoneX,0.744502 * safezoneH + safezoneY,0.221719 * safezoneW,0.044 * safezoneH];
                _sliderDamageReduction ctrlSetBackgroundColor [0, 0, 0, 1];
                _sliderDamageReduction sliderSetRange [0, 0.7];
                _sliderDamageReduction sliderSetPosition (missionNamespace getVariable ["AIR_damageReduction", 0]);
                _sliderDamageReduction ctrlAddEventHandler ["SliderPosChanged", {
                    params ["_control", "_value"];
                    missionNamespace setVariable ["AIR_damageReduction", _value, true];
                    systemChat format ["Damage Reduction: %1", _value toFixed 2];
                }];
                _sliderDamageReduction ctrlCommit 0;

                private _labelDamageReduction = _display ctrlCreate ["RscText", -1];
                _labelDamageReduction ctrlSetPosition [0.442708 * safezoneW + safezoneX,0.688079 * safezoneH + safezoneY,0.12375 * safezoneW,0.044 * safezoneH];
                _labelDamageReduction ctrlSetText "Damage Reduction";
                _labelDamageReduction ctrlSetTextColor [1, 1, 1, 1];
                _labelDamageReduction ctrlCommit 0;

                private _buttonCerrar = _display ctrlCreate ["RscButton", -1];
                _buttonCerrar ctrlSetPosition [0.587656 * safezoneW + safezoneX,0.247 * safezoneH + safezoneY,0.020625 * safezoneW,0.033 * safezoneH];
                _buttonCerrar ctrlSetText "X";
                _buttonCerrar ctrlSetTextColor [1, 0, 0, 1];
                _buttonCerrar ctrlAddEventHandler ["ButtonClick", {
                    params ["_control"];
                    private _display = ctrlParent _control;
                    _display closeDisplay 1;
                }];
                _buttonCerrar ctrlCommit 0;
            };
        };
    }];
};

// ============================================================================
// PLAYER MENU (User Action 7)
// ============================================================================

[] spawn {
    if !(isDedicated) then {
        waitUntil {!(isNull (findDisplay 46))};
        (findDisplay 46) displayAddEventHandler ["KeyDown", {
            private _key = _this select 1;
            if (_key in (actionKeys "User7")) then {
                disableSerialization;
                private _display = findDisplay 46 createDisplay "RscDisplayEmpty";
                private _background = _display ctrlCreate ["RscText", -1];
                _background ctrlSetPosition [0.025625 * safezoneW + safezoneX,0.643 * safezoneH + safezoneY,0.159844 * safezoneW,0.264 * safezoneH];
                _background ctrlSetBackgroundColor [0, 0, 0, 1];
                _background ctrlCommit 0;
                private _buttonClose = _display ctrlCreate ["RscButton", -1];
                _buttonClose ctrlSetPosition [0.17 * safezoneW + safezoneX,0.643 * safezoneH + safezoneY,0.0154689 * safezoneW,0.022 * safezoneH];
                _buttonClose ctrlSetText "X";
                _buttonClose ctrlCommit 0;
                _buttonClose ctrlAddEventHandler ["ButtonClick", {
                    private _display = findDisplay 46 createDisplay "RscDisplayEmpty";
                    if (!isNull _display) then {
                        _display closeDisplay 1;
                    };
                }];
                private _botonLider = _display ctrlCreate ["RscButton", -1];
                _botonLider ctrlSetPosition [0.0359375 * safezoneW + safezoneX, 0.841 * safezoneH + safezoneY, 0.139219 * safezoneW, 0.055 * safezoneH];
                private _esLider = (leader group player == player);
                _botonLider ctrlSetText (if (_esLider) then {"Step Down as Leader"} else {"Become Leader"});
                _botonLider ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonLider ctrlSetTextColor (if (_esLider) then {[1, 0, 0, 1]} else {[0, 1, 0, 1]});
                _botonLider ctrlCommit 0;
                _botonLider ctrlAddEventHandler ["ButtonClick", {
                    private _grupo = group player;
                    private _esLider = (leader _grupo == player);
                    if (!_esLider) then {
                        [_grupo, player] remoteExec ["selectLeader", 0, true];
                        (_this select 0) ctrlSetText "Step Down as Leader";
                        (_this select 0) ctrlSetTextColor [1, 0, 0, 1];
                    } else {
                        private _miembros = units _grupo - [player];
                        if (count _miembros > 0) then {
                            private _nuevoLider = selectRandom _miembros;
                            [_grupo, _nuevoLider] remoteExec ["selectLeader", 0, true];
                            (_this select 0) ctrlSetText "Become Leader";
                            (_this select 0) ctrlSetTextColor [0, 1, 0, 1];
                        };
                    };
                }];
                private _botonAutoRevive = _display ctrlCreate ["RscButton", -1];
                _botonAutoRevive ctrlSetPosition [0.0359 * safezoneW + safezoneX, 0.775 * safezoneH + safezoneY, 0.1392 * safezoneW, 0.055 * safezoneH];
                _botonAutoRevive ctrlSetText "Auto Revive";
                _botonAutoRevive ctrlSetBackgroundColor [0.1, 0.1, 0.1, 0.8];
                _botonAutoRevive ctrlSetTextColor [0, 1, 0, 1];
                _botonAutoRevive ctrlCommit 0;
                uiNamespace setVariable ["autoReviveButton", _botonAutoRevive];
                private _textoCuenta = _display ctrlCreate ["RscStructuredText", -1];
                _textoCuenta ctrlSetPosition [0.0359375 * safezoneW + safezoneX, 0.643 * safezoneH + safezoneY, 0.134062 * safezoneW, 0.044 * safezoneH];
                _textoCuenta ctrlSetStructuredText parseText "<t size='1.2' color='#00FF00'>Ready to Revive</t>";
                _textoCuenta ctrlCommit 0;
                uiNamespace setVariable ["autoReviveText", _textoCuenta];
                uiNamespace setVariable ["autoReviveCountdown", -1];
                [] spawn {
                    disableSerialization;
                    while { !isNull (uiNamespace getVariable ["autoReviveButton", controlNull]) } do {
                        private _btn = uiNamespace getVariable ["autoReviveButton", controlNull];
                        private _txt = uiNamespace getVariable ["autoReviveText", controlNull];
                        private _countdown = uiNamespace getVariable ["autoReviveCountdown", -1];
                        private _incap = player getVariable ["isIncapacitated", false];
                        if (!isNull _btn && !isNull _txt) then {
                            _btn ctrlEnable (_incap && _countdown == -1);
                            if (_countdown > 0) then {
                                _txt ctrlSetStructuredText parseText format ["<t size='1.2' color='#00FF00'>Reviving in %1...</t>", _countdown];
                                _txt ctrlCommit 0;
                            } else {
                                if (_incap) then {
                                    _txt ctrlSetStructuredText parseText "<t size='1.2' color='#00FF00'>Ready to Revive</t>";
                                    _txt ctrlCommit 0;
                                } else {
                                    _txt ctrlSetStructuredText parseText "<t size='1.2' color='#FFFFFF'>Not Incapacitated</t>";
                                    _txt ctrlCommit 0;
                                };
                            };
                        };
                        if (_countdown > 0) then {
                            uiNamespace setVariable ["autoReviveCountdown", _countdown - 1];
                        };
                        sleep 1;
                    };
                };
                _botonAutoRevive ctrlAddEventHandler ["ButtonClick", {
                    disableSerialization;
                    private _countdown = uiNamespace getVariable ["autoReviveCountdown", -1];
                    if (_countdown == -1 && player getVariable ["isIncapacitated", false]) then {
                        uiNamespace setVariable ["autoReviveCountdown", 7];
                        [] spawn {
                            disableSerialization;
                            private _txt = uiNamespace getVariable ["autoReviveText", controlNull];
                            waitUntil {
                                (uiNamespace getVariable ["autoReviveCountdown", -1]) <= 0 ||
                                !(player getVariable ["isIncapacitated", false]) ||
                                !alive player
                            };
                            if (alive player && player getVariable ["isIncapacitated", false]) then {
                                private _display = findDisplay 46 createDisplay "RscDisplayEmpty";
                                if (!isNull _display) then {
                                    _display closeDisplay 1;
                                };
                                player setUnconscious false;
                                player setDamage 0;
                                player setCaptive false;
                                player setVariable ["damageDelayTimer", 0, true];
                                player setVariable ["reviving", false, true];
                                player setVariable ["isIncapacitated", false, true];
                                player setVariable ["originalSide", side player, true];

                                if (!isNull _txt) then {
                                    _txt ctrlSetStructuredText parseText "<t size='1.2' color='#00FF00'>Ready to Revive</t>";
                                    _txt ctrlCommit 0;
                                };
                            };
                            uiNamespace setVariable ["autoReviveCountdown", -1];
                        };
                    };
                }];
                if (isNil {uiNamespace getVariable "reclutarVisible"}) then {
                    uiNamespace setVariable ["reclutarVisible", false];
                };
                if (isNil {player getVariable "reclutarActionID"}) then {
                    player setVariable ["reclutarActionID", -1];
                };

                private _reclutarVisible = uiNamespace getVariable "reclutarVisible";

                private _botonReclutar = _display ctrlCreate ["RscButton", -1];
                _botonReclutar ctrlSetPosition [0.0359375 * safezoneW + safezoneX, 0.709 * safezoneH + safezoneY, 0.139219 * safezoneW, 0.055 * safezoneH];
                _botonReclutar ctrlSetText (if (_reclutarVisible) then {"Recruiting ON"} else {"Recruiting OFF"});
                _botonReclutar ctrlSetBackgroundColor [0, 0, 0, 0.7];
                _botonReclutar ctrlSetTextColor (if (_reclutarVisible) then {[0, 1, 0, 1]} else {[1, 0, 0, 1]});
                _botonReclutar ctrlCommit 0;

                _botonReclutar ctrlAddEventHandler ["ButtonClick", {
                    disableSerialization;
                    private _estado = uiNamespace getVariable ["reclutarVisible", false];
                    private _nuevoEstado = !_estado;
                    uiNamespace setVariable ["reclutarVisible", _nuevoEstado];
                    player setVariable ["reclutarVisible", _nuevoEstado];

                    private _boton = _this select 0;
                    _boton ctrlSetText (if (_nuevoEstado) then {"Recruiting ON"} else {"Recruiting OFF"});
                    _boton ctrlSetTextColor (if (_nuevoEstado) then {[0, 1, 0, 1]} else {[1, 0, 0, 1]});
                    _boton ctrlCommit 0;

                    if (_nuevoEstado) then {
                        if (player getVariable ["reclutarActionID", -1] == -1) then {
                            private _actionText = "Recruit <img image='\a3\missions_f_oldman\data\img\holdactions\holdaction_follow_start_ca.paa' size='1.8' shadow=0 />";

                            private _actionID = player addAction [
                                _actionText,
                                {
                                    private _target = cursorObject;
                                    private _freeUnits = units side player - units group player;
                                    if (_target in _freeUnits) then {
                                        [_target] join group player;
                                        addSwitchableUnit _target;
                                    };
                                },
                                [],
                                0,
                                true,
                                true,
                                "",
                                "cursorTarget in (units side player - units group player) && {uiNamespace getVariable ['reclutarVisible', false]}"
                            ];
                            player setVariable ["reclutarActionID", _actionID];
                        };
                    } else {
                        private _actionID = player getVariable ["reclutarActionID", -1];
                        if (_actionID != -1) then {
                            player removeAction _actionID;
                            player setVariable ["reclutarActionID", -1];
                        };
                    };
                }];
            };
        }];
    };
};

// ============================================================================
// SYSTEM INITIALIZED
// ============================================================================

systemChat "AI Resurrection System Initialized";
systemChat "Press User Action 7 for Player Menu";
systemChat "Press User Action 10 for Admin Menu (Admins Only)";
systemChat "Press User Action 8 to Drag Incapacitated Units";
