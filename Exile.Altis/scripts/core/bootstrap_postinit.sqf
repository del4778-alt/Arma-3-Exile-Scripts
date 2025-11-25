if (!isServer) exitWith {};

diag_log "[UMC] PostInit starting";

// AI Systems
[] execVM "scripts\a3xai\init.sqf";
[] execVM "scripts\dms\init.sqf";
[] execVM "scripts\occupation\init.sqf";
[] execVM "scripts\vemf\init.sqf";
[] execVM "scripts\dyce\init.sqf";

// Elite Driving System (auto-applies to all AI vehicles)
[] execVM "scripts\elite_driving\init.sqf";

diag_log "[UMC] PostInit complete";
