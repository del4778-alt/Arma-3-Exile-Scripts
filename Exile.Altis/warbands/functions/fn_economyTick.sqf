if (!isServer) exitWith {};
params [["_event","pump"],["_arg",objNull]];

if (_event isEqualTo "pump") then {
    while {true} do {
        { if (random 1 < 0.5) then { [_x select 0] call WB_fnc_spawnCaravan; }; } forEach WB_factions;
        [] call WB_fnc_spawnFactionTraders;
        uiSleep ((missionNamespace getVariable ["WB_CARAVAN_TICK_MINUTES",7]) * 60);
    };
};

if (_event isEqualTo "caravanArrived") then {
    private _side = _arg;
    diag_log format ["[WB] Economy: caravan arrival credited to side %1", _side];
};
