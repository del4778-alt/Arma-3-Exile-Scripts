/*
    A3XAI Elite - Performance Monitor
    Tracks server performance and AI statistics
*/

if (!isServer) exitWith {};

private _monitorInterval = 300; // Report every 5 minutes
private _fpsHistory = [];
private _maxHistory = 10;

[3, "Performance monitor started"] call A3XAI_fnc_log;

while {A3XAI_enabled} do {
    sleep _monitorInterval;

    // Collect statistics
    private _fps = diag_fps;
    private _players = count allPlayers;
    private _activeAI = count (allUnits select {side _x == EAST});
    private _activeGroups = count A3XAI_activeGroups;
    private _activeVehicles = count A3XAI_activeVehicles;
    private _activeSpawns = 0;
    {
        _activeSpawns = _activeSpawns + count _y;
    } forEach A3XAI_spawnGrid;
    private _activeMissions = count A3XAI_activeMissions;

    // Track FPS history
    _fpsHistory pushBack _fps;
    if (count _fpsHistory > _maxHistory) then {
        _fpsHistory deleteAt 0;
    };

    private _avgFPS = 0;
    {
        _avgFPS = _avgFPS + _x;
    } forEach _fpsHistory;
    _avgFPS = _avgFPS / (count _fpsHistory);

    // Calculate uptime
    private _uptime = (time - (A3XAI_stats get "startTime")) / 3600; // hours

    // Log report
    [3, "========== A3XAI PERFORMANCE REPORT =========="] call A3XAI_fnc_log;
    [3, format ["Server FPS: %1 (avg: %2)", _fps toFixed 1, _avgFPS toFixed 1]] call A3XAI_fnc_log;
    [3, format ["Players: %1 | AI Units: %2/%3", _players, _activeAI, A3XAI_maxAIGlobal]] call A3XAI_fnc_log;
    [3, format ["Groups: %1 | Vehicles: %2 | Spawns: %3", _activeGroups, _activeVehicles, _activeSpawns]] call A3XAI_fnc_log;
    [3, format ["Active Missions: %1", _activeMissions]] call A3XAI_fnc_log;
    [3, format ["Total Kills: %1 | Missions Complete: %2", A3XAI_stats get "totalKills", A3XAI_stats get "missionsCompleted"]] call A3XAI_fnc_log;
    [3, format ["Uptime: %1 hours", _uptime toFixed 2]] call A3XAI_fnc_log;
    [3, "============================================"] call A3XAI_fnc_log;

    // FPS warning
    if (_fps < A3XAI_minServerFPS) then {
        [1, format ["WARNING: Server FPS below threshold (%1 < %2)", _fps toFixed 1, A3XAI_minServerFPS]] call A3XAI_fnc_log;
        [1, "Consider reducing spawn rates or AI limits"] call A3XAI_fnc_log;
    };

    // AI limit warning
    if (_activeAI >= (A3XAI_maxAIGlobal * 0.9)) then {
        [2, format ["WARNING: Approaching AI limit (%1/%2)", _activeAI, A3XAI_maxAIGlobal]] call A3XAI_fnc_log;
    };
};

[2, "Performance monitor stopped"] call A3XAI_fnc_log;
