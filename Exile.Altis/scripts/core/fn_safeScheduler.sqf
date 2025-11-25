if (!isServer) exitWith {};

private _queues = createHashMap;

UMC set ["_schedulerQueues", _queues];

UMC set ["scheduler", {
    params ["_cmd", "_data"];
    
    private _queues = UMC get "_schedulerQueues";

    switch (_cmd) do {
        case "registerQueue": {
            private _name = _data select 0;
            private _interval = _data select 1 max 1;
            _queues set [_name, [_interval, time, {true}]];
        };
        case "setFunction": {
            private _name = _data select 0;
            private _fn = _data select 1;
            private _entry = _queues get _name;
            if (!isNil "_entry") then {
                _entry set [2, _fn];
                _queues set [_name, _entry];
            };
        };
        case "run": {
            {
                private _name = _x;
                private _entry = _queues get _name;
                private _interval = _entry select 0;
                private _lastRun = _entry select 1;
                private _fn = _entry select 2;
                if (time >= _lastRun + _interval) then {
                    call _fn;
                    _entry set [1, time];
                    _queues set [_name, _entry];
                };
            } forEach (keys _queues);
        };
    };
}];

[] spawn {
    waitUntil {time > 0};
    sleep 5;
    diag_log "[UMC] Scheduler loop started";
    while {true} do {
        ["run", []] call (UMC get "scheduler");
        sleep 1;
    };
};

diag_log "[UMC] Scheduler initialized";
