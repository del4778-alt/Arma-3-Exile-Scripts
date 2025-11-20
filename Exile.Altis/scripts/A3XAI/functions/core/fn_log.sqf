/*
    A3XAI Elite - Logging Function
    Logs messages based on log level

    Parameters:
        0: NUMBER - Log level (0=none, 1=error, 2=warn, 3=info, 4=debug)
        1: STRING - Message to log

    Returns:
        BOOL - True if logged
*/

params ["_level", "_message"];

if (isNil "A3XAI_logLevel") then {A3XAI_logLevel = 2};

if (_level > A3XAI_logLevel) exitWith {false};

private _prefix = switch (_level) do {
    case 1: {"[ERROR]"};
    case 2: {"[WARN] "};
    case 3: {"[INFO] "};
    case 4: {"[DEBUG]"};
    default {""};
};

diag_log format ["[A3XAI] %1 %2", _prefix, _message];

true
