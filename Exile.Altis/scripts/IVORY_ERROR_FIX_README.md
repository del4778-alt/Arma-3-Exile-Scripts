# Ivory's Car Pack - Error Fix Solutions

## The Problem
You're seeing this error spam in your server RPT:
```
Error Undefined behavior: waitUntil returned nil. True or false expected.
File ivory_data\functions\vehicle\fn_takedown.sqf..., line 57
```

This is caused by a bug in Ivory's Car Pack mod where the `ani_takedown` variable is sometimes undefined, causing `waitUntil` to return `nil` instead of true/false.

---

## Solution 1: Auto-Fix Patch (RECOMMENDED - Already Active)

**File:** `scripts/ivory_patch.sqf`

**Status:** ✅ Already enabled in your init.sqf

**What it does:**
- Automatically overrides the buggy function from Ivory's mod
- Adds default values (0) to all `getVariable` calls to prevent `nil` errors
- Works on both client and server
- Doesn't modify the mod files (keeps your server "green button")

**How it works:**
1. Waits for Ivory's mod functions to load
2. Replaces `ivory_fnc_takedown` with a fixed version
3. The fixed version uses `getVariable ["ani_takedown", 0]` instead of `getVariable "ani_takedown"`

**Changes made:**
- Line 57 fix: Added default value to prevent `waitUntil` returning nil
- 7 total fixes throughout the function for all `getVariable` calls

---

## Solution 2: Diagnostic Tool (Optional)

**File:** `scripts/ivory_diagnostic.sqf`

**Status:** 🔴 Disabled (commented out in init.sqf)

**When to use:**
- If the error is still occurring after the patch
- To identify which specific vehicle is causing problems

**How to enable:**
1. Open `init.sqf`
2. Uncomment line 5: `[] execVM "scripts\ivory_diagnostic.sqf";`
3. Restart server
4. Check your RPT log for `[IVORY DIAG]` entries

**What it does:**
- Logs all Ivory vehicle spawns
- Monitors vehicles for undefined `ani_takedown` variables
- Shows warnings when it detects potential problem vehicles
- Logs recent vehicle spawns every 60 seconds

**Sample output:**
```
[IVORY DIAG] Vehicle spawned: ivory_charger_2012 at [1234, 5678, 0] (time: 456)
[IVORY DIAG] ⚠️ WARNING: Vehicle ivory_charger_2012 has UNDEFINED ani_takedown variable!
```

---

## Solution 3: Vehicle Blacklist (Optional)

**File:** `scripts/ivory_vehicle_blacklist.sqf`

**Status:** 🔴 Disabled (commented out in init.sqf)

**When to use:**
- If specific vehicles keep causing errors even after the patch
- As a last resort to stop problem vehicles from spawning

**How to enable:**
1. Open `init.sqf`
2. Uncomment line 8: `[] execVM "scripts\ivory_vehicle_blacklist.sqf";`
3. Edit `ivory_vehicle_blacklist.sqf`
4. Add problem vehicle classnames to the array:
```sqf
IVORY_BLACKLIST_VEHICLES = [
    "ivory_charger_2012",  // Example
    "ivory_cvpi_2011"      // Example
];
```
5. Restart server

**What it does:**
- Prevents blacklisted vehicles from spawning
- Automatically deletes them if they do spawn
- Logs blocked vehicles in RPT

**Runtime blacklisting:**
You can also blacklist vehicles while the server is running:
```sqf
["ivory_charger_2012"] call IVORY_fnc_blacklistVehicle;
```

---

## Troubleshooting

### Error still occurring after patch?

1. **Check if patch loaded:**
   - Search your RPT for: `[IVORY PATCH] ✅ fn_takedown patched successfully!`
   - If not found, the patch didn't load properly

2. **Enable diagnostics:**
   - Uncomment `ivory_diagnostic.sqf` in init.sqf
   - Find which vehicle is causing the problem

3. **Blacklist problem vehicles:**
   - Use the diagnostic log to identify the vehicle classname
   - Add it to `ivory_vehicle_blacklist.sqf`

### How to find vehicle classname from error?

The error doesn't tell you which vehicle, so:
1. Enable `ivory_diagnostic.sqf`
2. Wait for the error to occur
3. Check your RPT for the most recently spawned Ivory vehicle
4. That's likely your culprit

### Still not working?

The patch should work for 99% of cases. If it doesn't:
1. Make sure `ivory_patch.sqf` is being executed (check RPT logs)
2. Verify Ivory's mod is loading before the patch
3. Check if Ivory updated their mod (different function names)
4. Contact the mod author to fix the bug properly

---

## Technical Details

**The Root Cause:**
```sqf
// BUGGY (original mod code):
waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && _car getVariable "ani_takedown" > 0)};
```

When `ani_takedown` variable doesn't exist, `getVariable` returns `nil`. Then `nil > 0` returns `nil`, causing `waitUntil` to return `nil` instead of a boolean.

**The Fix:**
```sqf
// FIXED (our patch):
waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_takedown", 0]) > 0)};
```

Using the 2-parameter version of `getVariable` provides a default value (0) when the variable doesn't exist, ensuring the condition always returns a boolean.

---

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `ivory_patch.sqf` | Auto-fix the error | ✅ Active |
| `ivory_diagnostic.sqf` | Identify problem vehicles | 🔴 Optional |
| `ivory_vehicle_blacklist.sqf` | Block specific vehicles | 🔴 Optional |

---

## Questions?

- **Is this safe?** Yes, it only overrides the function in memory, doesn't modify mod files
- **Will this affect performance?** No, minimal overhead
- **Do I need all 3 scripts?** No, just the patch is usually enough
- **Can I modify the patch?** Yes, but be careful with the syntax

Good luck! The patch should suppress the error completely.
