/**
 * Warbands VATS (Vault-Tec Assisted Targeting System)
 * Fallout 4 style targeting for Arma 3
 */

if (!hasInterface) exitWith {};

WB_VATS_Active = false;
WB_VATS_Targets = [];
WB_VATS_SelectedIndex = 0;
WB_VATS_CritMeter = 0;
WB_VATS_StoredCrits = 0;

/**
 * Activate VATS targeting
 */
WB_fnc_activateVATS = {
    if (WB_VATS_Active) exitWith {
        [] call WB_fnc_deactivateVATS;
    };

    // Check if player has weapon ready
    if (currentWeapon player == "") exitWith {
        hint "You need a weapon to use VATS!";
    };

    // Check stamina (VATS costs stamina)
    private _stamina = player getVariable ["WB_Stamina", 100];
    if (_stamina < 20) exitWith {
        hint "Not enough stamina for VATS!";
    };

    WB_VATS_Active = true;

    // Slow time effect
    setAccTime 0.25; // 25% speed

    // Find nearby enemies
    WB_VATS_Targets = (player nearEntities [["Man", "LandVehicle", "Air"], 300]) select {
        alive _x &&
        _x != player &&
        side _x getFriend side player < 0.6 &&
        player distance _x < 300 &&
        [player, "VIEW", _x] checkVisibility [eyePos player, eyePos _x] > 0.1
    };

    if (count WB_VATS_Targets == 0) exitWith {
        hint "No targets in range!";
        [] call WB_fnc_deactivateVATS;
    };

    WB_VATS_SelectedIndex = 0;

    // Display VATS UI
    [] call WB_fnc_showVATSUI;

    // Add key handlers
    [] call WB_fnc_addVATSKeyHandlers;

    playSound "FD_CP_Not_Clear_F";
};

/**
 * Deactivate VATS
 */
WB_fnc_deactivateVATS = {
    WB_VATS_Active = false;
    setAccTime 1; // Normal time

    // Remove UI
    {
        ctrlDelete _x;
    } forEach (allControls (findDisplay 46) select {ctrlIDC _x >= 9000 && ctrlIDC _x < 9100});

    // Remove markers
    {
        deleteMarkerLocal format["vats_target_%1", _forEachIndex];
    } forEach WB_VATS_Targets;

    WB_VATS_Targets = [];
    WB_VATS_SelectedIndex = 0;
};

/**
 * Show VATS UI
 */
WB_fnc_showVATSUI = {
    private _display = findDisplay 46;

    // Create target markers
    {
        private _target = _x;
        private _targetPos = getPosATL _target;
        private _screenPos = worldToScreen _targetPos;

        if (count _screenPos > 0) then {
            _screenPos params ["_x", "_y"];

            // Calculate hit chance
            private _distance = player distance _target;
            private _perception = player getVariable ["WB_SPECIAL_Perception", 1];
            private _agility = player getVariable ["WB_SPECIAL_Agility", 1];

            private _baseChance = 95;
            private _distancePenalty = (_distance / 300) * 50; // -50% at max range
            private _perceptionBonus = _perception * 2; // +2% per point
            private _agilityBonus = _agility * 1; // +1% per point

            private _hitChance = (_baseChance - _distancePenalty + _perceptionBonus + _agilityBonus) max 5 min 95;

            // Create UI element
            private _ctrl = _display ctrlCreate ["RscStructuredText", 9000 + _forEachIndex];
            _ctrl ctrlSetPosition [_x - 0.05, _y - 0.05, 0.1, 0.1];

            private _color = if (_forEachIndex == WB_VATS_SelectedIndex) then {"#00FF00"} else {"#FFFFFF"};

            _ctrl ctrlSetStructuredText parseText format[
                "<t size='0.8' color='%1' align='center'>%2%%<br/>%3m</t>",
                _color,
                floor _hitChance,
                floor _distance
            ];
            _ctrl ctrlCommit 0;
        };
    } forEach WB_VATS_Targets;

    // Show crit meter
    private _critCtrl = _display ctrlCreate ["RscStructuredText", 9090];
    _critCtrl ctrlSetPosition [safeZoneX + 0.4, safeZoneY + safeZoneH - 0.15, 0.2, 0.1];

    private _critText = if (WB_VATS_CritMeter >= 100 || WB_VATS_StoredCrits > 0) then {
        "<t size='1' color='#FFD700'>CRITICAL READY!</t>"
    } else {
        format["<t size='0.8'>Critical: %1%%</t>", floor WB_VATS_CritMeter]
    };

    _critCtrl ctrlSetStructuredText parseText _critText;
    _critCtrl ctrlCommit 0;

    // Show instructions
    private _instrCtrl = _display ctrlCreate ["RscStructuredText", 9091];
    _instrCtrl ctrlSetPosition [safeZoneX + 0.35, safeZoneY + 0.1, 0.3, 0.2];
    _instrCtrl ctrlSetStructuredText parseText "<t size='0.7' align='center'>
        [TAB] - Cycle Target<br/>
        [SPACE] - Fire<br/>
        [C] - Critical (if ready)<br/>
        [V] - Exit VATS
    </t>";
    _instrCtrl ctrlCommit 0;
};

/**
 * Add VATS key handlers
 */
WB_fnc_addVATSKeyHandlers = {
    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_display", "_key", "_shift", "_ctrl", "_alt"];

        if (!WB_VATS_Active) exitWith {false};

        switch (_key) do {
            case 15: { // TAB - Cycle target
                WB_VATS_SelectedIndex = (WB_VATS_SelectedIndex + 1) mod (count WB_VATS_Targets);
                [] call WB_fnc_showVATSUI;
                playSound "ReadoutClick";
                true
            };

            case 57: { // SPACE - Fire
                [] call WB_fnc_fireVATSShot;
                true
            };

            case 46: { // C - Critical
                if (WB_VATS_CritMeter >= 100 || WB_VATS_StoredCrits > 0) then {
                    [true] call WB_fnc_fireVATSShot;
                } else {
                    hint "Critical not ready!";
                };
                true
            };

            case 47: { // V - Exit
                [] call WB_fnc_deactivateVATS;
                true
            };

            default {false};
        };
    }];
};

/**
 * Fire VATS shot
 */
WB_fnc_fireVATSShot = {
    params [["_isCritical", false]];

    if (count WB_VATS_Targets == 0) exitWith {};

    private _target = WB_VATS_Targets select WB_VATS_SelectedIndex;
    if (!alive _target) exitWith {
        WB_VATS_Targets deleteAt WB_VATS_SelectedIndex;
        WB_VATS_SelectedIndex = 0 max ((WB_VATS_SelectedIndex - 1) min (count WB_VATS_Targets - 1));
    };

    // Calculate hit chance
    private _distance = player distance _target;
    private _perception = player getVariable ["WB_SPECIAL_Perception", 1];
    private _agility = player getVariable ["WB_SPECIAL_Agility", 1];

    private _baseChance = 95;
    private _distancePenalty = (_distance / 300) * 50;
    private _perceptionBonus = _perception * 2;
    private _agilityBonus = _agility * 1;

    private _hitChance = (_baseChance - _distancePenalty + _perceptionBonus + _agilityBonus) max 5 min 95;

    // Roll for hit
    private _roll = random 100;

    if (_roll <= _hitChance) then {
        // HIT!
        player reveal _target;
        player doTarget _target;

        // Calculate damage
        private _baseDamage = 1.0;

        // Apply weapon perks
        private _weapon = currentWeapon player;
        private _weaponConfig = configFile >> "CfgWeapons" >> _weapon;
        private _fireMode = getNumber(_weaponConfig >> "Single" >> "reloadTime");

        // Check if automatic or semi-auto
        private _isAutomatic = _fireMode < 0.1;
        private _isRifle = primaryWeapon player == _weapon;
        private _isPistol = handgunWeapon player == _weapon;

        // Apply Rifleman perk
        if (_isRifle && !_isAutomatic) then {
            private _riflemanRank = player getVariable ["WB_Perk_Rifleman", 0];
            _baseDamage = _baseDamage * (1 + (0.2 * _riflemanRank));
        };

        // Apply Commando perk
        if (_isAutomatic) then {
            private _commandoRank = player getVariable ["WB_Perk_Commando", 0];
            _baseDamage = _baseDamage * (1 + (0.2 * _commandoRank));
        };

        // Apply Gunslinger perk
        if (_isPistol) then {
            private _gunslingerRank = player getVariable ["WB_Perk_Gunslinger", 0];
            _baseDamage = _baseDamage * (1 + (0.25 * _gunslingerRank));
        };

        // Apply Bloody Mess
        private _bloodyMessRank = player getVariable ["WB_Perk_BloodyMess", 0];
        _baseDamage = _baseDamage * (1 + (0.05 * _bloodyMessRank));

        // Critical hit
        if (_isCritical) then {
            private _betterCritsRank = player getVariable ["WB_Perk_BetterCriticals", 0];
            _baseDamage = _baseDamage * (1.5 + (0.5 * _betterCritsRank));

            // Use stored crit or current meter
            if (WB_VATS_StoredCrits > 0) then {
                WB_VATS_StoredCrits = WB_VATS_StoredCrits - 1;
            } else {
                WB_VATS_CritMeter = 0;
            };

            player setVariable ["WB_VATS_StoredCrits", WB_VATS_StoredCrits, true];

            playSound "FD_Finish_F";
            hint "CRITICAL HIT!";
        };

        // Apply damage
        _target setDamage ((damage _target) + _baseDamage);

        // Visual effect
        playSound "FD_Hit_F";

        // Increase crit meter
        if (!_isCritical) then {
            private _luck = player getVariable ["WB_SPECIAL_Luck", 1];
            private _critGain = 10 + (_luck * 2);

            WB_VATS_CritMeter = (WB_VATS_CritMeter + _critGain) min 100;

            // Check Four Leaf Clover perk
            private _fourLeafRank = player getVariable ["WB_Perk_FourLeafClover", 0];
            if (_fourLeafRank > 0) then {
                private _fourLeafChance = [3, 5, 7, 10] select (_fourLeafRank - 1);
                if (random 100 < _fourLeafChance) then {
                    WB_VATS_CritMeter = 100;
                    hint "Critical meter filled!";
                };
            };

            // Check Critical Banker - store crits
            if (WB_VATS_CritMeter >= 100) then {
                private _critBankerRank = player getVariable ["WB_Perk_CriticalBanker", 0];
                if (_critBankerRank > 0 && WB_VATS_StoredCrits < _critBankerRank) then {
                    WB_VATS_StoredCrits = WB_VATS_StoredCrits + 1;
                    WB_VATS_CritMeter = 0;
                    player setVariable ["WB_VATS_StoredCrits", WB_VATS_StoredCrits, true];
                    hint "Critical stored!";
                };
            };
        };

        // Check Grim Reaper's Sprint
        if (!alive _target) then {
            private _grimReaperRank = player getVariable ["WB_Perk_GrimReapersSprint", 0];
            if (_grimReaperRank > 0) then {
                private _grimChance = [15, 25, 35] select (_grimReaperRank - 1);
                if (random 100 < _grimChance) then {
                    player setVariable ["WB_Stamina", 100, true];
                    if (_grimReaperRank >= 3) then {
                        player setDamage 0; // Full heal
                    };
                    hint "Grim Reaper's Sprint!";
                };
            };
        };

    } else {
        // MISS
        playSound "FD_CP_Clear_F";
        hint "MISSED!";
    };

    // Consume stamina
    private _stamina = player getVariable ["WB_Stamina", 100];
    player setVariable ["WB_Stamina", (_stamina - 10) max 0, true];

    // Exit VATS after shot
    sleep 0.5;
    [] call WB_fnc_deactivateVATS;
};

/**
 * Key binding for VATS
 */
[] spawn {
    waitUntil {!isNull (findDisplay 46)};

    (findDisplay 46) displayAddEventHandler ["KeyDown", {
        params ["_display", "_key", "_shift", "_ctrl", "_alt"];

        // V key activates VATS
        if (_key == 47 && !_shift && !_ctrl && !_alt) then {
            if (!WB_VATS_Active) then {
                [] call WB_fnc_activateVATS;
            };
            true
        };

        false
    }];
};

diag_log "[WB] VATS system initialized";
