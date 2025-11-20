/*
    A3XAI_fnc_getCellID

    Description:
        Calculates the spatial grid cell ID for a given position.
        Used for spatial partitioning to optimize spawn location queries.

    Parameters:
        0: ARRAY - Position [x,y,z] or [x,y]

    Returns:
        STRING - Cell ID in format "x_y" (e.g., "15_23")

    Example:
        _cellID = [getPos player] call A3XAI_fnc_getCellID;
*/

params [["_pos", [0,0,0], [[]]]];

private _gridSize = missionNamespace getVariable ["A3XAI_gridSize", 1000];
private _cellX = floor ((_pos select 0) / _gridSize);
private _cellY = floor ((_pos select 1) / _gridSize);

format ["%1_%2", _cellX, _cellY]
