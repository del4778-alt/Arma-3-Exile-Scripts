# RemoteExec Security Error Fix

## Error Message
```
Scripting command 'systemchat' is not allowed to be remotely executed
User Admin tried to remoteExec a disabled function: 'systemchat'
```

## Cause
Arma 3 blocks certain commands from being remotely executed for security reasons. Commands like `systemChat`, `sideChat`, `globalChat`, etc. are disabled by default.

## Solution

### Option 1: Whitelist Commands (Recommended for Exile servers)

Create or edit the file `@ExileServer\addons\exile_server_config\remoteExec.txt` (or in your mission folder) with the following content:

```
// Allowed commands for remoteExec

// Chat commands (needed for AI communication and some mods)
systemChat 0
sideChat 0
globalChat 0
vehicleChat 0

// Other commonly whitelisted commands for Exile
setVariable 0
addAction 0
removeAction 0
```

**Format:** `<command> <mode>`
- Mode `0` = Allowed from clients and server
- Mode `1` = Allowed from server only
- Mode `2` = Blocked

### Option 2: Disable RemoteExec Restrictions (NOT RECOMMENDED - Security Risk)

In your server config or init file, add:
```sqf
// WARNING: This disables all remoteExec security!
// Only use for testing, not production servers
remoteExecRestrictions = [];
```

### Option 3: Update Calling Code

If the error is from your own scripts, replace `remoteExec` calls with server-side execution or alternative methods.

**Bad (causes error):**
```sqf
[player, "Hello!"] remoteExec ["systemChat", 0];
```

**Good (server-side only):**
```sqf
if (isServer) then {
    player sideChat "Hello!";
};
```

## Changes Made

**Removed from `recruit_ai.sqf`:**
- Line 178: Removed `[_unit, "I'm hit bad!"] remoteExec ["sideChat", 0];` (non-critical flavor text)

## ⚠️ CRITICAL: Mission Systems (A3XAI, DMS, VEMF)

**If your convoy missions have AI/vehicles dying on spawn**, remoteExec blocking is likely the cause!

Mission systems use remoteExec heavily for:
- Creating mission markers
- Spawning vehicles/AI
- Adding reward crate actions
- Sending notifications

**When blocked → spawn fails → everything dies instantly**

### Quick Fix for Mission Systems

Add these to your `remoteExec.txt`:

```
// Mission system essentials
createMarker 0
setMarkerPos 0
setMarkerColor 0
setMarkerText 0
createVehicle 0
addAction 0
titleText 0
hint 0
```

**📖 See**: `Mission-Systems/MISSION_REMOTEEXEC_FIX.md` for complete mission system remoteExec configuration.

## External Mod Issues

If the error persists after these changes, it's likely coming from:
- **A3XAI / DMS / VEMF** - Mission systems (see above)
- **Exile Mod** - Player interaction scripts
- **RMG Ravage** - Zombie/ambient systems
- **Ivory Mod** - Vehicle scripts
- **Other third-party addons**

Contact the mod authors or update to latest versions.

## Testing

1. Apply the remoteExec.txt configuration
2. Restart your server
3. Check server logs for the error
4. If error persists, identify which mod is calling systemChat and update accordingly
