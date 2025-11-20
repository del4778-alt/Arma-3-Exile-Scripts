/*
    A3XAI Elite - Set Timeout
    Executes code after a delay (wrapper for spawn/sleep pattern)

    Parameters:
        0: CODE - Code to execute
        1: ARRAY - Parameters to pass
        2: NUMBER - Delay in seconds

    Returns:
        SCRIPT - Script handle
*/

params ["_code", "_params", "_delay"];

[_code, _params, _delay] spawn {
    params ["_code", "_params", "_delay"];

    sleep _delay;

    _params call _code;
};
