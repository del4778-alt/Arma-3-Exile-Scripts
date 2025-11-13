if (!isServer) exitWith {};
params ["_player","_arenaCenter"];
private _pos = if (!isNil "_arenaCenter") then {_arenaCenter} else { getPosWorld _player };
private _anchor = "Logic" createVehicle _pos;
[_player,_anchor] remoteExec ["WB_fnc_arenaSpectate_client", _player];

WB_fnc_arenaSpectate_client = {
    params ["_player","_anchor"];
    if (!hasInterface) exitWith {};
    private _cam = "camera" camCreate (getPos _anchor);
    _cam cameraEffect ["Internal","BACK"];
    _cam camSetTarget _anchor; _cam camCommit 0;
    [] spawn {
        private _a = 0;
        while {true} do {
            _a = _a + 3;
            private _p = (getPosASL _this) getPos [25, _a];
            _p set [2, (getPosASL _this select 2) + 8];
            (missionNamespace getVariable ["WB_sCam",objNull]) camSetPos _p;
            uiSleep 0.2;
        };
    };
};
