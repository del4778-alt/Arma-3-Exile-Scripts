/*
    A3XAI Elite - Safe Function Call Wrapper
    Provides error handling and logging for all function calls

    Parameters:
        0: CODE - Function to call
        1: ARRAY - Parameters to pass
        2: STRING - Error message identifier (optional)

    Returns:
        ANY - Function result, or nil on error
*/

params ["_function", "_params", ["_errorMsg", "unknown"]];

private _result = nil;

try {
    _result = _params call _function;
} catch {
    private _error = _exception;
    [1, format ["ERROR in %1: %2", _errorMsg, _error]] call A3XAI_fnc_log;

    if (A3XAI_debugMode) then {
        diag_log format ["=== A3XAI ERROR STACK TRACE ==="];
        diag_log format ["Function: %1", _errorMsg];
        diag_log format ["Exception: %1", _error];
        diag_log format ["Params: %1", _params];
        diag_log format ["Stack: %1", diag_stacktrace];
        diag_log format ["==============================="];
    };

    _result = nil;
};

_result
