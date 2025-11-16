# Mission System RemoteExec Fix

## Problem: Convoy AI Dying Due to Blocked RemoteExec

**You're absolutely correct!** Mission systems (A3XAI, DMS, VEMF) use remoteExec heavily during spawn sequences. When these calls are blocked by Arma 3's security system, it causes:

- ❌ Script execution halts mid-spawn
- ❌ Vehicles/AI partially created then cleaned up
- ❌ Mission markers fail to create
- ❌ Everything appears "dead on arrival"

## Error Signatures in RPT

Look for these in your server RPT logs:

```
Scripting command 'createMarker' is not allowed to be remotely executed
Scripting command 'setMarkerPos' is not allowed to be remotely executed
Scripting command 'setMarkerText' is not allowed to be remotely executed
Scripting command 'setMarkerColor' is not allowed to be remotely executed
Scripting command 'createVehicle' is not allowed to be remotely executed
Scripting command 'addAction' is not allowed to be remotely executed
```

## Root Cause

Mission systems call functions like:
```sqf
// A3XAI creating mission marker
["missionMarker", _pos, "ICON", "ColorRed", "Mission"] remoteExec ["createMarker", 0];

// DMS spawning vehicles
[_vehClass, _pos] remoteExec ["createVehicle", 0];

// VEMF adding rewards
[_crate, "Collect Reward", ...] remoteExec ["addAction", 0];
```

When blocked → spawn fails → AI/vehicles deleted → mission "dead on spawn"

---

## Solution: Whitelist Mission Commands

### **remoteExec.txt Configuration**

Create or edit: `@ExileServer\addons\exile_server_config\remoteExec.txt`

Or in your mission folder: `mpmissions\your_mission\remoteExec.txt`

**Add these commands:**

```
// ============================================================
// MISSION SYSTEM COMMANDS - REQUIRED FOR A3XAI/DMS/VEMF
// ============================================================

// Marker creation (mission objectives)
createMarker 0
createMarkerLocal 0
deleteMarker 0
deleteMarkerLocal 0
setMarkerPos 0
setMarkerPosLocal 0
setMarkerSize 0
setMarkerSizeLocal 0
setMarkerColor 0
setMarkerColorLocal 0
setMarkerText 0
setMarkerTextLocal 0
setMarkerShape 0
setMarkerShapeLocal 0
setMarkerType 0
setMarkerTypeLocal 0
setMarkerAlpha 0
setMarkerAlphaLocal 0
setMarkerBrush 0
setMarkerBrushLocal 0

// Object/vehicle spawning
createVehicle 0
createVehicleLocal 0
createAgent 0
deleteVehicle 0
setPos 0
setPosATL 0
setPosASL 0
setDir 0
setVectorUp 0
setVelocity 0

// Actions (reward crates, interactions)
addAction 0
removeAction 0
removeAllActions 0

// Notifications (mission start/complete messages)
systemChat 0
sideChat 0
globalChat 0
vehicleChat 0
titleText 0
titleFadeOut 0
hint 0
hintSilent 0

// Variables (mission state sync)
setVariable 0
publicVariable 0
publicVariableServer 0

// Effects (explosions, smoke)
say 0
say2D 0
say3D 0
playSound 0
playSound3D 0

// Group management
createGroup 0
deleteGroup 0
join 0
joinSilent 0
leaveVehicle 0

// AI behavior
doMove 0
doFollow 0
doStop 0
setBehaviour 0
setCombatMode 0
setSpeedMode 0
setFormation 0
addWaypoint 0

// Damage/simulation
allowDamage 0
setDamage 0
setFuel 0
setVehicleAmmo 0
enableSimulation 0
enableSimulationGlobal 0

// ============================================================
// EXILE SPECIFIC
// ============================================================

// Exile network functions (needed for rewards)
ExileServer_system_network_send_to 1
ExileClient_system_notification_create 0

// ============================================================
// FORMAT EXPLANATION
// ============================================================
// <command> <mode>
//   0 = Allowed from clients and server
//   1 = Server only
//   2 = Blocked
// ============================================================
```

---

## Verification

After creating `remoteExec.txt`:

1. **Restart your server** completely (not just mission)
2. **Check RPT logs** - remoteExec errors should disappear
3. **Spawn a mission** and check if AI/vehicles survive
4. **Look for**: `[CONVOY FIX]` and mission system success messages

---

## A3XAI Specific

A3XAI heavily uses:
- `createMarker` for mission markers
- `setMarkerPos/Color/Text` for marker updates
- `createVehicle` for spawning
- `addAction` for reward crates

**If convoys die immediately**, A3XAI is likely hitting remoteExec blocks during spawn.

### A3XAI Test

```sqf
// Run this in debug console (server exec)
_pos = position player;
_mission = [_pos, "convoy", 1] call A3XAI_createMission;

// Check RPT for errors
```

---

## DMS Specific

DMS uses:
- `createMarkerLocal` for client-side markers
- `publicVariable` for mission state
- `titleText` for notifications
- `addAction` extensively

### DMS Test

```sqf
// If using DMS
_mission = ["convoy", _pos, "hard"] call DMS_fnc_SpawnMission;
```

---

## VEMF Specific

VEMF uses:
- `createMarker`
- `hint` for notifications
- `addAction` for crates
- `say3D` for sounds

---

## Testing Without Restart

If you want to test without server restart:

```sqf
// Temporarily disable remoteExec restrictions (DEBUG ONLY!)
// Run in server console

remoteExecWhitelist = [];

// Now spawn a mission and see if it works
// If it works = remoteExec was the problem
```

**⚠️ WARNING**: Don't leave this on a live server! It disables security.

---

## Combined Fix: Physical + RemoteExec

For best results, use BOTH fixes:

**1. Physical spawn issues** → `convoy_spawn_fix.sqf`
**2. RemoteExec blocking** → `remoteExec.txt` whitelist

**In your initServer.sqf:**
```sqf
// Load convoy spawn fix
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";

// RemoteExec.txt should already be loaded by server
// Check RPT for: "Loading remoteExec restrictions from..."
```

---

## Symptoms by Cause

| Symptom | Physical Issue | RemoteExec Block |
|---------|---------------|------------------|
| All dead instantly | ✅ | ✅ |
| Some vehicles OK, some not | ✅ | ❌ |
| No mission marker appears | ❌ | ✅ |
| RPT: "not allowed to be remotely executed" | ❌ | ✅ |
| RPT: "Object X:XXX not found" | ✅ | ❌ |
| Vehicles clustered together | ✅ | ❌ |

---

## Quick Diagnosis

**Run this after a convoy spawns:**

```sqf
// Check if remoteExec is the issue
_checkRemoteExec = {
    private _testMarker = createMarker ["test_marker_delete_me", getPos player];
    if (_testMarker == "") then {
        systemChat "ERROR: createMarker is blocked!";
        diag_log "ERROR: createMarker remoteExec is blocked - missions will fail!";
        false
    } else {
        deleteMarker _testMarker;
        systemChat "OK: createMarker works";
        true
    };
};

[] call _checkRemoteExec;
```

---

## Alternative: Disable Mission Markers

If you can't edit remoteExec.txt, disable markers in mission config:

**A3XAI:**
```sqf
// In A3XAI_config.sqf
A3XAI_missionMarkers = false;  // Disable markers
```

**DMS:**
```sqf
// In DMS_config.sqf
DMS_ShowMarkers = false;
```

This won't fix vehicle spawns if those use remoteExec, but reduces errors.

---

## Expected Result

After whitelisting:

✅ Mission markers appear correctly
✅ AI and vehicles spawn alive
✅ Reward crates have actions
✅ Notifications show to players
✅ No remoteExec errors in RPT

---

## Still Failing?

If AI still die after:
1. ✅ remoteExec.txt configured
2. ✅ convoy_spawn_fix.sqf loaded
3. ✅ Server restarted

Then check:
- Hostile AI nearby (A3XAI patrols, zombies)
- Mission spawn blacklist zones
- Server performance (lag causing timeouts)
- Mod conflicts (check RPT for errors)

---

## Final Checklist

Mission spawns should work with:

- [x] `remoteExec.txt` configured with mission commands
- [x] `convoy_spawn_fix.sqf` loaded in initServer.sqf
- [x] Server fully restarted (not just mission restart)
- [x] No remoteExec errors in RPT
- [x] Mission markers visible to players
- [x] AI alive and vehicles intact

Good luck! This combination should fix 99% of convoy spawn issues.
