params [["_factionId","",[""]]];
if (!isServer) exitWith {};

private _f = WB_factions select (WB_factions findIf { (_x select 0) isEqualTo _factionId });
if (isNil "_f") exitWith {};

private _side = _f select 4;
private _homes = _f select 3; if ((count _homes) < 2) exitWith {};

private _start = getMarkerPos (selectRandom _homes);
private _dest  = getMarkerPos (selectRandom (_homes - [(_homes select 0)]));

private _grp = createGroup [_side, true];
private _truckClass = switch (_side) do {
    case east: {"O_Truck_03_transport_F"};
    case independent: {"I_Truck_02_transport_F"};
    case resistance: {"C_Van_01_transport_F"};
    default {"B_Truck_01_transport_F"};
};

private _veh = createVehicle [_truckClass, _start, [], 0, "NONE"];
_veh lock 2; _veh enableDynamicSimulation true;

private _driver = _grp createUnit [switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; case resistance: {"C_man_1"}; default {"B_Soldier_F"}}, _start, [], 3, "FORM"];
_driver moveInDriver _veh;
_driver enableDynamicSimulation true;

private _sizeRange = missionNamespace getVariable ["WB_CARAVAN_SIZE_RANGE",[4,8]];
private _n = floor random [_sizeRange select 0, ((_sizeRange select 0)+(_sizeRange select 1))/2, _sizeRange select 1];

for "_i" from 2 to _n do {
    private _u = _grp createUnit [switch (_side) do {case east: {"O_Soldier_F"}; case independent: {"I_Soldier_F"}; case resistance: {"C_man_p_beggar_F"}; default {"B_Soldier_F"}}, _start, [], 3, "FORM"];
    _u assignAsCargo _veh; _u moveInCargo _veh; _u enableDynamicSimulation true;
};

private _wp = _grp addWaypoint [_dest, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "LIMITED";
_wp setWaypointBehaviour "SAFE";

[_veh, _grp] spawn {
    params ["_veh","_grp"];
    waitUntil { sleep 5; (currentWaypoint _grp) >= (count waypoints _grp) || !alive _veh };
    if (alive _veh) then { ["caravanArrived", side _grp] call WB_fnc_economyTick; };
    { deleteVehicle _x } forEach (crew _veh);
    deleteVehicle _veh; deleteGroup _grp;
};
