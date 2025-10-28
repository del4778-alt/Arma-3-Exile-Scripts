if (isServer) then {

    _recruitment_groups = ["B_T_Recon_Medic_F", "B_CTRG_soldier_GL_LAT_F", "I_soldier_AA_F"];
    _recruitment_side = resistance;  // Kept for potential future use

    // Function to ensure player has exactly 3 alive AI buddies
    _ensure_ai_for_player = {
        params ["_player"];
        private _pos = getPos _player;
        private _dir = getDir _player;
        private _group = group _player;
        private _assigned = _player getVariable ["AssignedAI", []];
        
        // Clean dead units from assigned array
        _assigned = _assigned select { !isNull _x && alive _x };
        
        private _toSpawn = 3 - (count _assigned);
        if (_toSpawn > 0) then {
            private _offsets = [
                [2, 90],   // Right of player
                [2, -90],  // Left of player
                [3, 180]   // Behind player
            ];
            
            for "_i" from 0 to (_toSpawn - 1) do {
                private _unitClass = _recruitment_groups call BIS_fnc_selectRandom;
                private _unit = _group createUnit [_unitClass, _pos, [], 0, "NONE"];
                
                private _offsetDist = _offsets select (_i % (count _offsets)) select 0;
                private _offsetAngle = _offsets select (_i % (count _offsets)) select 1;
                private _spawnAngle = _dir + _offsetAngle;
                private _spawnPos = _pos getPos [_offsetDist, _spawnAngle];
                _unit setDir _dir;
                _unit setPos [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) max (_pos select 2) + 0.5];
                
                // Max skills (expanded as requested)
                _unit setSkill ["aimingAccuracy", 1.0];
                _unit setSkill ["aimingShake", 1.0];
                _unit setSkill ["aimingSpeed", 1.0];
                _unit setSkill ["spotDistance", 1.0];
                _unit setSkill ["spotTime", 1.0];
                _unit setSkill ["courage", 1.0];
                _unit setSkill ["reloadSpeed", 1.0];
                _unit setSkill ["commanding", 1.0];
                _unit setSkill ["general", 1.0];
               
                // 1.4x MOVEMENT SPEED (AI move faster than player)
                _unit setAnimSpeedCoef 1.4;
               
                // EXTREME AI BEHAVIOR SETTINGS (unit-level as requested)
                _unit setBehaviour "AWARE";
                _unit setCombatMode "YELLOW";
                _unit allowFleeing 0;
                _unit disableAI "SUPPRESSION";
                _unit setUnitPos "AUTO";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "MOVE";
                _unit enableAI "ANIM";
                _unit enableAI "FSM";
                _unit enableAI "AIMINGERROR";
                _unit enableAI "COVER";
                _unit enableAI "AUTOCOMBAT";
                
                // Track ownership (public for server cleanup)
                _unit setVariable ["ExileRecruited", true, true];
                _unit setVariable ["ownerUID", getPlayerUID _player, true];
                
                _assigned pushBack _unit;
            };
            
            // Update assigned array (public)
            _player setVariable ["AssignedAI", _assigned, true];
            
            // Group behaviors (kept, but unit overrides may take precedence)
            _group setBehaviour "COMBAT";
            _group setCombatMode "RED";
            _group setSpeedMode "FULL";
            _group setFormation "WEDGE";
            
            // VcomAI: Prevent flanking (as requested)
            _group setVariable ["VCM_NOFLANK", true];
        };
    };

    // Spawn/Respawn loop: Check every 10s, spawn up to 3 if missing/dead
    while {true} do {
        {
            _player = _x;
            if (vehicle _player == _player && {alive _player}) then {
                [_player] call _ensure_ai_for_player;
            };
        } forEach allPlayers;
        sleep 10;
    };

    // Cleanup loop: Delete AI if owner player is dead/disconnected (no radius needed)
    while {true} do {
        {
            private _uid = _x getVariable ["ownerUID", ""];
            if (_uid != "") then {
                private _owner = objNull;
                {
                    if (getPlayerUID _x == _uid) exitWith { _owner = _x };
                } forEach allPlayers;
                if (isNull _owner || {!alive _owner}) then {
                    deleteVehicle _x;
                };
            };
        } forEach (allUnits select {_x getVariable ["ExileRecruited", false]});
        sleep 10;
    };

};
