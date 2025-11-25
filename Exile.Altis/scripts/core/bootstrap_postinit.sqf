if (!isServer) exitWith {};

diag_log "[UMC] PostInit starting";

[] execVM "scripts\a3xai\init.sqf";
[] execVM "scripts\dms\init.sqf";
[] execVM "scripts\occupation\init.sqf";
[] execVM "scripts\vemf\init.sqf";
[] execVM "scripts\dyce\init.sqf";

diag_log "[UMC] PostInit complete";
