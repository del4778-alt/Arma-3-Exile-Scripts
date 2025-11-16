// Fix for Ivory's Car Pack "waitUntil returned nil" error
[] execVM "scripts\ivory_patch.sqf";

// OPTIONAL: Uncomment to enable diagnostic logging (helps identify problem vehicles)
// [] execVM "scripts\ivory_diagnostic.sqf";

// OPTIONAL: Uncomment to enable vehicle blacklist (prevents specific vehicles from spawning)
// [] execVM "scripts\ivory_vehicle_blacklist.sqf";

[] execVM "scripts\Dynamic-Mission-System\fn_dynamicMissions.sqf";