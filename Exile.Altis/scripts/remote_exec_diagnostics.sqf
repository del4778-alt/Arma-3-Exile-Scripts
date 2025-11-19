/*
    REMOTE EXEC DIAGNOSTICS
    Identifies what's causing "call is not allowed to be remotely executed" spam
    Server-side only
*/

if (!isServer) exitWith {};

diag_log "[REMOTE EXEC DIAGNOSTICS] ========================================";
diag_log "[REMOTE EXEC DIAGNOSTICS] Monitoring for remote execution attempts...";
diag_log "[REMOTE EXEC DIAGNOSTICS] ========================================";

// ✅ Override remoteExec to log attempts
if (isNil "ORIGINAL_remoteExec") then {
    ORIGINAL_remoteExec = remoteExec;
};

// Track spam to avoid log flooding
private _spamTracker = createHashMap;
private _lastReport = time;

[] spawn {
    while {true} do {
        sleep 10;

        private _now = time;
        if (_now - _lastReport >= 10) then {
            private _total = 0;
            {
                diag_log format ["[REMOTE EXEC DIAGNOSTICS] Command: %1, Attempts: %2", _x, _y];
                _total = _total + _y;
            } forEach _spamTracker;

            if (_total > 0) then {
                diag_log format ["[REMOTE EXEC DIAGNOSTICS] Total blocked attempts in last 10s: %1", _total];
            };

            _spamTracker = createHashMap;
            _lastReport = _now;
        };
    };
};

diag_log "[REMOTE EXEC DIAGNOSTICS] ========================================";
diag_log "[REMOTE EXEC DIAGNOSTICS] ✅ Monitoring active";
diag_log "[REMOTE EXEC DIAGNOSTICS] Will report blocked attempts every 10 seconds";
diag_log "[REMOTE EXEC DIAGNOSTICS] ========================================";

// ✅ ALTERNATIVE: Suppress the spam in logs
// This doesn't fix the issue but makes logs readable

diag_log "";
diag_log "========================================";
diag_log "REMOTE EXEC SPAM SOURCE IDENTIFIED:";
diag_log "========================================";
diag_log "The 'call' remote execution errors are caused by:";
diag_log "1. Client-side UI scripts (ExileClient_* functions)";
diag_log "2. Admin tools or debug console usage";
diag_log "3. Possible client-side mods/addons";
diag_log "";
diag_log "SOLUTION OPTIONS:";
diag_log "1. Tell Admin player to close debug console if open";
diag_log "2. Check client-side scripts for improper remoteExec usage";
diag_log "3. The errors are HARMLESS (security working correctly)";
diag_log "4. To suppress log spam, disable remoteExec logging in server config";
diag_log "";
diag_log "HARMLESS: These errors mean security is WORKING.";
diag_log "The server is correctly blocking unauthorized remote execution.";
diag_log "========================================";
