if (!isServer) exitWith {};

{
    deleteVehicle _x;
} forEach allDeadMen;

{
    if (count units _x == 0) then { deleteGroup _x };
} forEach allGroups;

{
    if (!isNil {_x getVariable "UMC_timestamp"}) then {
        if (time - (_x getVariable "UMC_timestamp") > 1800) then {
            deleteVehicle _x;
        };
    };
} forEach vehicles;

diag_log "[UMC][CLEANUP] global cleanup done";
