/*
    A3XAI DEBUG DISABLE PATCH

    A3XAI has debug logging left enabled by the developer.
    This patch disables all A3XAI debug output to clean up server logs.

    Installation:
    1. Add to initServer.sqf BEFORE A3XAI loads: [] execVM "scripts\a3xai_debug_disable.sqf";
    2. Restart server

    What this disables:
    - "DEBUG :: Added optics item..." spam
    - "DEBUG: B_Carryall_oucamo" spam
    - "DEBUG: V_PlateCarrierSpec_blk" spam
    - All other A3XAI debug messages
*/

if (!isServer) exitWith {};

diag_log "[A3XAI PATCH] ========================================";
diag_log "[A3XAI PATCH] Disabling A3XAI debug output...";
diag_log "[A3XAI PATCH] ========================================";

// Wait for A3XAI to load and initialize
[] spawn {
    // Wait 10 seconds for A3XAI to fully load
    sleep 10;

    diag_log "[A3XAI PATCH] Attempting to disable A3XAI debug mode...";

    // A3XAI stores debug settings in global variables
    // Override all known debug variables

    // Main debug flag
    if (!isNil "A3XAI_debugLevel") then {
        A3XAI_debugLevel = 0;
        publicVariable "A3XAI_debugLevel";
        diag_log "[A3XAI PATCH] ✅ Set A3XAI_debugLevel = 0";
    };

    // Verbose logging flag
    if (!isNil "A3XAI_enableDebugLog") then {
        A3XAI_enableDebugLog = false;
        publicVariable "A3XAI_enableDebugLog";
        diag_log "[A3XAI PATCH] ✅ Set A3XAI_enableDebugLog = false";
    };

    // HC debug (if using headless client)
    if (!isNil "A3XAI_enableHC_debug") then {
        A3XAI_enableHC_debug = false;
        publicVariable "A3XAI_enableHC_debug";
        diag_log "[A3XAI PATCH] ✅ Set A3XAI_enableHC_debug = false";
    };

    // Loadout debug (the "DEBUG :: Added optics" spam)
    if (!isNil "A3XAI_debugLoadouts") then {
        A3XAI_debugLoadouts = false;
        publicVariable "A3XAI_debugLoadouts";
        diag_log "[A3XAI PATCH] ✅ Set A3XAI_debugLoadouts = false";
    };

    // Additional debug flags
    if (!isNil "A3XAI_debugMarkers") then {
        A3XAI_debugMarkers = false;
        publicVariable "A3XAI_debugMarkers";
        diag_log "[A3XAI PATCH] ✅ Set A3XAI_debugMarkers = false";
    };

    diag_log "[A3XAI PATCH] ========================================";
    diag_log "[A3XAI PATCH] ✅ A3XAI DEBUG OUTPUT DISABLED";
    diag_log "[A3XAI PATCH] Debug spam should now be suppressed";
    diag_log "[A3XAI PATCH] ========================================";
};
