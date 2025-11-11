/*
    Shadow Hunter System - Client Initialization
    Triggers hunter spawn for the player on server
*/

if (!hasInterface) exitWith {};

// Wait for player to be ready
waitUntil { !isNull player && alive player && time > 1 };

// Wait for functions to be available (synced from server)
waitUntil { !isNil "SHW_fnc_spawnHunter" };

// Request hunters to spawn on server
[player] remoteExec ["SHW_fnc_spawnHunter", 2];

// Handle player disconnect - cleanup hunters
addMissionEventHandler ["HandleDisconnect", {
    params ["_unit", "_id", "_uid", "_name"];

    // Remove all hunters belonging to this player
    {
        if ((_x getVariable ["SHW_isHunter", false]) && (_x getVariable ["SHW_OwnerUID", ""]) == _uid) then {
            deleteVehicle _x;
        };
    } forEach allUnits;
}];

diag_log format ["[Shadow Hunter] Client initialized for player: %1", name player];
