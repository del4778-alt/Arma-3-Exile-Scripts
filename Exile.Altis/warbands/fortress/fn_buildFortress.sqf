params ["_pos","_dir","_factionId","_templateFile"];
private _objs = [];
private _parts = call compile preprocessFileLineNumbers _templateFile;

{
    _x params ["_classname","_ofs","_angle"];
    private _ofsRot = [
        _ofs select 0 * cos _dir - _ofs select 1 * sin _dir,
        _ofs select 0 * sin _dir + _ofs select 1 * cos _dir,
        _ofs select 2
    ];
    private _worldPos = [
        (_pos select 0) + (_ofsRot select 0),
        (_pos select 1) + (_ofsRot select 1),
        (_pos select 2) + (_ofsRot select 2)
    ];
    private _obj = createVehicle [_classname, _worldPos, [], 0, "CAN_COLLIDE"];
    _obj setDir (_angle + _dir);
    _obj setVectorUp surfaceNormal getPosATL _obj;
    _obj setVariable ["ExileIsPersistent", true, true];
    _obj setVariable ["WB_faction", _factionId, true];
    _obj enableSimulationGlobal false;
    _objs pushBack _obj;
} forEach _parts;

[_factionId, _pos, _objs] call WB_fnc_registerFortress;
_objs
