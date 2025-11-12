# Ravage Mod RemoteExec Fix

## Problem

When using the Ravage mod with Arma 3 Exile, you may see these errors in your server logs:

```
User Admin (76561197990653113) tried to remoteExec a disabled function: 'say3d'
User Admin (76561197990653113) tried to remoteExec a disabled function: 'call'
```

## What This Means

Arma 3 uses a security system called **CfgRemoteExec** to control which functions can be executed remotely across the network. This prevents malicious code execution. The Ravage mod needs to use certain functions (`say3d` for audio, `call` for code execution) but they're not whitelisted by default in your mission configuration.

## Security Considerations

⚠️ **IMPORTANT SECURITY WARNING** ⚠️

- **`say3d`** - Relatively safe. Used for playing 3D sounds
- **`call`** - DANGEROUS if not restricted properly. Allows remote code execution

Enabling `call` without proper restrictions can allow clients to execute arbitrary code on the server. Only enable it if:
1. You trust all players on your server
2. You have anti-cheat protection (e.g., infiSTAR)
3. You understand the security risks

## The Solution

You need to add these functions to your mission's **description.ext** file in the CfgRemoteExec section.

### Location

Your mission's description.ext file is located at:
```
@ExileMod/mpmissions/YourMission.MapName/description.ext
```

For example:
```
@ExileMod/mpmissions/Exile.Altis/description.ext
```

### Option 1: Safe Configuration (Recommended)

This configuration allows `say3d` (safe) but restricts `call` to server-side only:

```cpp
class CfgRemoteExec
{
    class Functions
    {
        // Ravage mod support
        mode = 1;  // 0=disabled, 1=whitelist, 2=blacklist

        class say3d
        {
            allowedTargets = 0;  // 0=any machine, 1=client only, 2=server only
            jip = 0;             // 0=no JIP, 1=enable JIP
        };

        class call
        {
            allowedTargets = 2;  // Only allow server to call this
            jip = 0;
        };

        // Add existing Exile functions here...
        class ExileServer_system_network_send_broadcast
        {
            allowedTargets = 0;
        };

        class ExileServer_system_network_send_to
        {
            allowedTargets = 0;
        };
    };

    class Commands
    {
        mode = 1;  // Whitelist mode

        class say3D
        {
            allowedTargets = 0;
        };
    };
};
```

### Option 2: Full Ravage Support (Less Secure)

If Ravage features aren't working with Option 1, use this (requires anti-cheat):

```cpp
class CfgRemoteExec
{
    class Functions
    {
        mode = 1;

        class say3d
        {
            allowedTargets = 0;
            jip = 0;
        };

        class call
        {
            allowedTargets = 0;  // Allow from any machine
            jip = 0;
        };

        class spawn
        {
            allowedTargets = 2;  // Server only
            jip = 0;
        };

        // Ravage-specific functions
        class BIS_fnc_effectKilled
        {
            allowedTargets = 0;
        };

        class BIS_fnc_ambientAnim
        {
            allowedTargets = 0;
        };
    };

    class Commands
    {
        mode = 1;

        class say3D
        {
            allowedTargets = 0;
        };

        class createVehicle
        {
            allowedTargets = 2;  // Server only for security
        };

        class deleteVehicle
        {
            allowedTargets = 2;  // Server only
        };
    };
};
```

### Option 3: If You Already Have CfgRemoteExec

If your description.ext already has a CfgRemoteExec section, simply add these functions to the existing `class Functions` block:

```cpp
class say3d
{
    allowedTargets = 0;
    jip = 0;
};

class call
{
    allowedTargets = 2;  // Server only (safer)
    jip = 0;
};
```

And add to the existing `class Commands` block:

```cpp
class say3D
{
    allowedTargets = 0;
};
```

## Understanding allowedTargets Values

- **0** = Any machine (client or server)
- **1** = Client only
- **2** = Server only

## Understanding JIP (Join In Progress)

- **0** = Command is not saved for players joining later
- **1** = Command is saved and executed for JIP players

## Testing the Fix

1. **Restart your server** after modifying description.ext
2. **Repack your mission PBO** if using a PBO file
3. **Check server logs** - the errors should be gone
4. **Test Ravage features** - zombies should make sounds, animations should work

## Troubleshooting

### Errors Still Appear

- Make sure you edited the correct mission file (check server.cfg for mission name)
- Verify the mission PBO was repacked properly
- Check for syntax errors in description.ext (missing semicolons, braces)

### Ravage Features Not Working

- Try Option 2 (Full Ravage Support) configuration
- Enable debug logging in Ravage config
- Check if other mods conflict with Ravage

### Security Concerns

If you're worried about security with `call` enabled:

1. **Install anti-cheat** (infiSTAR, BE filters)
2. **Use allowedTargets = 2** (server only)
3. **Monitor server logs** for suspicious activity
4. **Keep whitelist mode** (mode = 1) enabled

## Additional Exile Functions

Your Exile mission may need these additional functions whitelisted:

```cpp
class ExileServer_system_network_send_to { allowedTargets = 0; };
class ExileServer_system_network_send_broadcast { allowedTargets = 0; };
class ExileClient_gui_notification_event_addNotification { allowedTargets = 0; };
class ExileClient_object_player_save { allowedTargets = 0; };
```

## Complete Example description.ext

Here's a minimal complete description.ext with Ravage support:

```cpp
// Mission Header
author = "YourName";
onLoadName = "Exile - Ravage Edition";
onLoadMission = "Survive the apocalypse";
loadScreen = "exile_assets\texture\exile.paa";
disableChannels[] = {0,1,2,6};

// Remote Execution Configuration
class CfgRemoteExec
{
    class Functions
    {
        mode = 1;  // Whitelist

        // Ravage Support
        class say3d { allowedTargets = 0; jip = 0; };
        class call { allowedTargets = 2; jip = 0; };  // Server only for security

        // Exile Functions
        class ExileServer_system_network_send_to { allowedTargets = 0; };
        class ExileServer_system_network_send_broadcast { allowedTargets = 0; };
        class ExileClient_gui_notification_event_addNotification { allowedTargets = 0; };
    };

    class Commands
    {
        mode = 1;  // Whitelist

        class say3D { allowedTargets = 0; };
    };
};

// Include Exile configuration
#include "config.cpp"
```

## References

- [Bohemia Wiki - CfgRemoteExec](https://community.bistudio.com/wiki/Arma_3:_Remote_Execution)
- [Exile Mod Forums](https://www.exilemod.com/forums/)
- [Ravage Mod Documentation](https://forums.bohemia.net/forums/topic/194483-ravage-mod/)

## Need Help?

If you're still having issues:

1. Check your server RPT logs for specific errors
2. Verify Ravage mod version compatibility
3. Ask on Exile Discord: https://discord.gg/exile
4. Post on Ravage forums with your server logs

---

**Document Version:** 1.0
**Last Updated:** 2025-11-12
**Tested With:** Arma 3 v2.18+, Exile 1.0.4+, Ravage 0.1.78+
