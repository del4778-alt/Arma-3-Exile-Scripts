/*
    EXILE SCRIPTS - UNIFIED PERFORMANCE MONITORING SYSTEM
    Version 1.0

    Comprehensive performance tracking for:
    - recruit_ai.sqf (Recruited AI system)
    - ead_v95_apex.sqf (Elite AI Driving system)
    - Server health metrics

    FEATURES:
    - Real-time FPS tracking with history
    - AI unit and group counting
    - Memory usage estimation
    - Script execution time profiling
    - Automatic performance warnings
    - Configurable reporting intervals
*/

if (!isServer) exitWith {};

// ============================================
// CONFIGURATION
// ============================================

PERFMON_CFG = createHashMapFromArray [
    ["ENABLED", true],
    ["REPORT_INTERVAL", 300],           // Report every 5 minutes
    ["WARNING_INTERVAL", 60],           // Check warnings every minute
    ["FPS_WARNING_THRESHOLD", 15],      // Warn if FPS drops below this
    ["FPS_CRITICAL_THRESHOLD", 8],      // Critical if FPS drops below this
    ["AI_COUNT_WARNING", 50],           // Warn if total AI exceeds this
    ["MEMORY_WARNING_MB", 2048],        // Warn if estimated memory exceeds this
    ["FPS_HISTORY_SIZE", 30],           // Keep 30 FPS samples
    ["DEBUG_LEVEL", 2],                 // 0=off, 1=errors, 2=warnings, 3=info, 4=verbose
    ["LOG_TO_RPT", true],               // Log to server RPT file
    ["TRACK_FUNCTION_TIMES", true]      // Track function execution times
];

// ============================================
// GLOBAL STATISTICS
// ============================================

PERFMON_Stats = createHashMapFromArray [
    // Timing
    ["startTime", time],
    ["lastReportTime", time],
    ["lastWarningCheck", time],

    // FPS tracking
    ["currentFPS", 0],
    ["avgFPS", 0],
    ["minFPS", 999],
    ["maxFPS", 0],
    ["fpsHistory", []],

    // AI Counts
    ["recruitedAI", 0],
    ["eadVehicles", 0],
    ["a3xaiUnits", 0],
    ["totalAIUnits", 0],
    ["totalGroups", 0],
    ["totalVehicles", 0],

    // Script performance
    ["fsmTicksPerSecond", 0],
    ["eadTickAvgMs", 0],
    ["eadTickMaxMs", 0],

    // Warnings
    ["warningCount", 0],
    ["criticalCount", 0],
    ["lastWarningMessage", ""],

    // Counters
    ["reportCount", 0],
    ["aiSpawned", 0],
    ["aiKilled", 0],
    ["vehicleDrivingSessions", 0]
];

// Function call profiling
PERFMON_FunctionTimes = createHashMap;
PERFMON_FunctionCalls = createHashMap;

// ============================================
// LOGGING FUNCTION
// ============================================

PERFMON_fnc_log = {
    params ["_level", "_message"];

    if (_level > (PERFMON_CFG get "DEBUG_LEVEL")) exitWith {};

    private _prefix = switch (_level) do {
        case 0: { "[PERFMON]" };
        case 1: { "[PERFMON ERROR]" };
        case 2: { "[PERFMON WARN]" };
        case 3: { "[PERFMON INFO]" };
        case 4: { "[PERFMON DEBUG]" };
        default { "[PERFMON]" };
    };

    private _fullMessage = format ["%1 %2", _prefix, _message];

    if (PERFMON_CFG get "LOG_TO_RPT") then {
        diag_log _fullMessage;
    };
};

// ============================================
// FUNCTION PROFILING
// ============================================

PERFMON_fnc_startTimer = {
    params ["_funcName"];

    if !(PERFMON_CFG get "TRACK_FUNCTION_TIMES") exitWith {};

    private _startTime = diag_tickTime;
    _funcName setVariable ["PERFMON_startTime", _startTime];
};

PERFMON_fnc_endTimer = {
    params ["_funcName"];

    if !(PERFMON_CFG get "TRACK_FUNCTION_TIMES") exitWith {};

    private _startTime = _funcName getVariable ["PERFMON_startTime", diag_tickTime];
    private _elapsed = (diag_tickTime - _startTime) * 1000; // ms

    // Update statistics
    private _currentAvg = PERFMON_FunctionTimes getOrDefault [_funcName, 0];
    private _callCount = PERFMON_FunctionCalls getOrDefault [_funcName, 0];

    // Rolling average
    private _newAvg = if (_callCount == 0) then {
        _elapsed
    } else {
        (_currentAvg * 0.9) + (_elapsed * 0.1)
    };

    PERFMON_FunctionTimes set [_funcName, _newAvg];
    PERFMON_FunctionCalls set [_funcName, _callCount + 1];
};

// ============================================
// DATA COLLECTION
// ============================================

PERFMON_fnc_collectData = {
    // FPS
    private _fps = diag_fps;
    PERFMON_Stats set ["currentFPS", _fps];

    // Update FPS history
    private _history = PERFMON_Stats get "fpsHistory";
    _history pushBack _fps;
    if (count _history > (PERFMON_CFG get "FPS_HISTORY_SIZE")) then {
        _history deleteAt 0;
    };
    PERFMON_Stats set ["fpsHistory", _history];

    // Calculate FPS statistics
    if (count _history > 0) then {
        private _sum = 0;
        private _min = 999;
        private _max = 0;
        {
            _sum = _sum + _x;
            if (_x < _min) then { _min = _x };
            if (_x > _max) then { _max = _x };
        } forEach _history;

        PERFMON_Stats set ["avgFPS", _sum / count _history];
        PERFMON_Stats set ["minFPS", _min];
        PERFMON_Stats set ["maxFPS", _max];
    };

    // Count recruited AI
    private _recruitedAI = 0;
    {
        _recruitedAI = _recruitedAI + count (_y select {!isNull _x && alive _x});
    } forEach all_recruited_ai_map;
    PERFMON_Stats set ["recruitedAI", _recruitedAI];

    // Count EAD vehicles
    private _eadVehicles = if (!isNil "EAD_TrackedVehicles") then {
        count (EAD_TrackedVehicles select {!isNull _x && alive _x})
    } else { 0 };
    PERFMON_Stats set ["eadVehicles", _eadVehicles];

    // Count A3XAI units
    private _a3xaiUnits = if (!isNil "A3XAI_activeGroups") then {
        private _count = 0;
        {
            if (!isNull _x) then {
                _count = _count + count (units _x select {alive _x});
            };
        } forEach A3XAI_activeGroups;
        _count
    } else { 0 };
    PERFMON_Stats set ["a3xaiUnits", _a3xaiUnits];

    // Total AI (all non-player units)
    private _totalAI = count (allUnits select {!isPlayer _x && alive _x});
    PERFMON_Stats set ["totalAIUnits", _totalAI];

    // Groups and vehicles
    PERFMON_Stats set ["totalGroups", count allGroups];
    PERFMON_Stats set ["totalVehicles", count vehicles];

    // EAD tick performance
    if (!isNil "EAD_Stats") then {
        PERFMON_Stats set ["eadTickAvgMs", (EAD_Stats getOrDefault ["avgTickTime", 0]) * 1000];
        PERFMON_Stats set ["eadTickMaxMs", (EAD_Stats getOrDefault ["maxTickTime", 0]) * 1000];
    };
};

// ============================================
// WARNING SYSTEM
// ============================================

PERFMON_fnc_checkWarnings = {
    private _fps = PERFMON_Stats get "currentFPS";
    private _totalAI = PERFMON_Stats get "totalAIUnits";
    private _warnings = [];

    // FPS Critical
    if (_fps < (PERFMON_CFG get "FPS_CRITICAL_THRESHOLD")) then {
        _warnings pushBack format ["CRITICAL: Server FPS at %1 (below %2)", _fps toFixed 1, PERFMON_CFG get "FPS_CRITICAL_THRESHOLD"];
        PERFMON_Stats set ["criticalCount", (PERFMON_Stats get "criticalCount") + 1];
    } else {
        // FPS Warning
        if (_fps < (PERFMON_CFG get "FPS_WARNING_THRESHOLD")) then {
            _warnings pushBack format ["WARNING: Server FPS low at %1 (threshold: %2)", _fps toFixed 1, PERFMON_CFG get "FPS_WARNING_THRESHOLD"];
        };
    };

    // AI Count Warning
    if (_totalAI > (PERFMON_CFG get "AI_COUNT_WARNING")) then {
        _warnings pushBack format ["WARNING: High AI count: %1 units (threshold: %2)", _totalAI, PERFMON_CFG get "AI_COUNT_WARNING"];
    };

    // EAD tick time warning (> 5ms is concerning)
    private _eadTickAvg = PERFMON_Stats get "eadTickAvgMs";
    if (_eadTickAvg > 5) then {
        _warnings pushBack format ["WARNING: EAD tick time high: %1ms avg", _eadTickAvg toFixed 2];
    };

    // Log warnings
    {
        [2, _x] call PERFMON_fnc_log;
        PERFMON_Stats set ["warningCount", (PERFMON_Stats get "warningCount") + 1];
        PERFMON_Stats set ["lastWarningMessage", _x];
    } forEach _warnings;

    count _warnings
};

// ============================================
// REPORT GENERATION
// ============================================

PERFMON_fnc_generateReport = {
    private _uptime = (time - (PERFMON_Stats get "startTime")) / 3600; // hours
    private _players = count allPlayers;

    [3, ""] call PERFMON_fnc_log;
    [3, "============================================================"] call PERFMON_fnc_log;
    [3, "           EXILE SCRIPTS PERFORMANCE REPORT"] call PERFMON_fnc_log;
    [3, "============================================================"] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    // Server Health
    [3, format ["SERVER HEALTH:"]] call PERFMON_fnc_log;
    [3, format ["  FPS: %1 (avg: %2, min: %3, max: %4)",
        (PERFMON_Stats get "currentFPS") toFixed 1,
        (PERFMON_Stats get "avgFPS") toFixed 1,
        (PERFMON_Stats get "minFPS") toFixed 1,
        (PERFMON_Stats get "maxFPS") toFixed 1
    ]] call PERFMON_fnc_log;
    [3, format ["  Players: %1", _players]] call PERFMON_fnc_log;
    [3, format ["  Uptime: %1 hours", _uptime toFixed 2]] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    // AI Statistics
    [3, "AI STATISTICS:"] call PERFMON_fnc_log;
    [3, format ["  Recruited AI: %1", PERFMON_Stats get "recruitedAI"]] call PERFMON_fnc_log;
    [3, format ["  A3XAI Units: %1", PERFMON_Stats get "a3xaiUnits"]] call PERFMON_fnc_log;
    [3, format ["  Total AI Units: %1", PERFMON_Stats get "totalAIUnits"]] call PERFMON_fnc_log;
    [3, format ["  Total Groups: %1", PERFMON_Stats get "totalGroups"]] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    // EAD Performance
    [3, "ELITE AI DRIVING (EAD):"] call PERFMON_fnc_log;
    [3, format ["  Active Vehicles: %1", PERFMON_Stats get "eadVehicles"]] call PERFMON_fnc_log;
    [3, format ["  Tick Time: %1ms avg, %2ms max",
        (PERFMON_Stats get "eadTickAvgMs") toFixed 2,
        (PERFMON_Stats get "eadTickMaxMs") toFixed 2
    ]] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    // Vehicles
    [3, format ["VEHICLES: %1 total in world", PERFMON_Stats get "totalVehicles"]] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    // Warnings Summary
    [3, "WARNINGS SUMMARY:"] call PERFMON_fnc_log;
    [3, format ["  Total Warnings: %1", PERFMON_Stats get "warningCount"]] call PERFMON_fnc_log;
    [3, format ["  Critical Events: %1", PERFMON_Stats get "criticalCount"]] call PERFMON_fnc_log;
    private _lastWarn = PERFMON_Stats get "lastWarningMessage";
    if (_lastWarn != "") then {
        [3, format ["  Last Warning: %1", _lastWarn]] call PERFMON_fnc_log;
    };
    [3, ""] call PERFMON_fnc_log;

    // Function Profiling (if enabled and has data)
    if (PERFMON_CFG get "TRACK_FUNCTION_TIMES" && count keys PERFMON_FunctionTimes > 0) then {
        [3, "FUNCTION PROFILING (top 10 by time):"] call PERFMON_fnc_log;

        // Sort by execution time
        private _funcList = [];
        {
            _funcList pushBack [_x, _y, PERFMON_FunctionCalls getOrDefault [_x, 0]];
        } forEach PERFMON_FunctionTimes;

        _funcList sort false; // Sort by time descending
        private _shown = 0;

        {
            if (_shown < 10) then {
                [3, format ["  %1: %2ms avg (%3 calls)",
                    _x select 0,
                    (_x select 1) toFixed 3,
                    _x select 2
                ]] call PERFMON_fnc_log;
                _shown = _shown + 1;
            };
        } forEach _funcList;
        [3, ""] call PERFMON_fnc_log;
    };

    [3, "============================================================"] call PERFMON_fnc_log;
    [3, ""] call PERFMON_fnc_log;

    PERFMON_Stats set ["reportCount", (PERFMON_Stats get "reportCount") + 1];
    PERFMON_Stats set ["lastReportTime", time];
};

// ============================================
// PUBLIC API FUNCTIONS
// ============================================

// Increment AI spawned counter
PERFMON_fnc_recordAISpawn = {
    PERFMON_Stats set ["aiSpawned", (PERFMON_Stats get "aiSpawned") + 1];
};

// Increment AI killed counter
PERFMON_fnc_recordAIKill = {
    PERFMON_Stats set ["aiKilled", (PERFMON_Stats get "aiKilled") + 1];
};

// Record new EAD driving session
PERFMON_fnc_recordDrivingSession = {
    PERFMON_Stats set ["vehicleDrivingSessions", (PERFMON_Stats get "vehicleDrivingSessions") + 1];
};

// Get current stats as string (for remote queries)
PERFMON_fnc_getStatsString = {
    format ["FPS:%1 AI:%2 Recruit:%3 EAD:%4 Warnings:%5",
        (PERFMON_Stats get "currentFPS") toFixed 1,
        PERFMON_Stats get "totalAIUnits",
        PERFMON_Stats get "recruitedAI",
        PERFMON_Stats get "eadVehicles",
        PERFMON_Stats get "warningCount"
    ]
};

// Force generate report now
PERFMON_fnc_forceReport = {
    [] call PERFMON_fnc_collectData;
    [] call PERFMON_fnc_generateReport;
};

// ============================================
// MAIN MONITORING LOOPS
// ============================================

// Warning check loop (runs frequently)
[] spawn {
    sleep 30; // Initial delay

    while {PERFMON_CFG get "ENABLED"} do {
        [] call PERFMON_fnc_collectData;
        [] call PERFMON_fnc_checkWarnings;
        PERFMON_Stats set ["lastWarningCheck", time];

        sleep (PERFMON_CFG get "WARNING_INTERVAL");
    };
};

// Report generation loop (runs less frequently)
[] spawn {
    sleep 60; // Initial delay

    while {PERFMON_CFG get "ENABLED"} do {
        [] call PERFMON_fnc_collectData;
        [] call PERFMON_fnc_generateReport;

        // Reset EAD max tick time after report
        if (!isNil "EAD_Stats") then {
            EAD_Stats set ["maxTickTime", 0];
        };

        sleep (PERFMON_CFG get "REPORT_INTERVAL");
    };
};

// ============================================
// INITIALIZATION
// ============================================

diag_log "";
diag_log "============================================================";
diag_log "[PERFMON] EXILE SCRIPTS PERFORMANCE MONITOR INITIALIZED";
diag_log format ["[PERFMON] Report Interval: %1s", PERFMON_CFG get "REPORT_INTERVAL"];
diag_log format ["[PERFMON] Warning Interval: %1s", PERFMON_CFG get "WARNING_INTERVAL"];
diag_log format ["[PERFMON] FPS Warning Threshold: %1", PERFMON_CFG get "FPS_WARNING_THRESHOLD"];
diag_log format ["[PERFMON] Debug Level: %1", PERFMON_CFG get "DEBUG_LEVEL"];
diag_log "============================================================";
diag_log "";

// Generate initial report after 30 seconds
[] spawn {
    sleep 30;
    [3, "Generating initial performance baseline..."] call PERFMON_fnc_log;
    [] call PERFMON_fnc_forceReport;
};
