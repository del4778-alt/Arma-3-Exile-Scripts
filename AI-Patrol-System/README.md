# AI Patrol System v8.2

Elite AI patrol system for Exile servers with ExileSpawnZone marker detection.

## Features

- **Automatic Exile zone detection** - Spawns patrols at ExileSpawnZone markers
- **Dynamic caching** - AI despawn when no players nearby
- **VCOMAI integration** - Enhanced AI behavior when VCOMAI mod detected
- **Cover system** - Intelligent tactical positioning
- **Military building patrols** - Prefers patrolling military structures
- **Optimized performance** - distanceSqr, cached player checks
- **Zombie resurrection protection** - Won't be resurrected by Ravage/zombie mods
- **Elite Driving exclusion** - Won't interfere with vehicle AI

## Installation

### Server Config (init.sqf or initServer.sqf)

```sqf
// Configure patrol settings
EXILE_PATROL_CONFIG = [
    2,      // Units per patrol group
    300,    // Respawn delay (seconds)
    1000,   // Cache distance (meters)
    999,    // Max spawn attempts
    2000    // Detection radius (meters)
];

// Execute patrol system
[] execVM "AI-Patrol-System\fn_aiPatrolSystem.sqf";
```

### Map Markers

Create markers with type **"ExileSpawnZone"** where you want patrols to spawn.

## Configuration

Edit `EXILE_PATROL_CONFIG` array:

```sqf
EXILE_PATROL_CONFIG = [
    2,      // [0] Units per group (recommended: 2-4)
    300,    // [1] Respawn delay in seconds
    1000,   // [2] Cache distance - AI deleted if no players within this range
    999,    // [3] Max spawn attempts per zone
    2000    // [4] Player detection radius - activates patrol when player enters
];
```

### Advanced Options

Edit constants in the script file:

```sqf
#define DETECT_RAD 1500        // Combat detection radius
#define AUDIO_RAD 2000         // FiredNear event radius
#define GREN_CHANCE 0.7        // Grenade throw probability
```

## AI Behavior

- **Skills**: 0.75-0.95 (high accuracy and awareness)
- **Speed**: 1.4x movement speed
- **Formation**: WEDGE formation, switches to LINE in combat
- **Combat Mode**: YELLOW (defensive), switches to RED in combat
- **Grenades**: 70% chance to throw when enemy 10-40m away
- **Cover**: Seeks tactical positions every 15 seconds in combat

## VCOMAI Integration

When VCOMAI is detected:
- Units registered with `VCM_NOAI` array
- Groups registered with `VCM_SERVERAI` array
- Custom AI flags set: `VCM_CUSTOMAI`, `VCM_CUSTOMGROUP`
- Calls `VCM_fnc_INITAI` for enhanced behavior

## Compatibility

- **Arma 3**: 2.00+
- **Exile Mod**: All versions
- **VCOMAI**: Auto-detected and integrated
- **Elite AI Driving**: Compatible (EAID_Ignore flag set)
- **Ravage/Zombies**: Resurrection immunity enabled

## Performance

- **distanceSqr optimization**: 3x faster than distance checks
- **Player caching**: Checks every 15 seconds, not every tick
- **Player validation**: Filters out parachuting/JIP players
- **Automatic cleanup**: Dead bodies and empty groups removed

## Troubleshooting

### Patrols not spawning

1. Verify `ExileSpawnZone` markers exist and have valid positions
2. Check player is within detection radius (default 2000m)
3. Check RPT logs for errors
4. Ensure `isServer` returns true

### High server FPS drop

1. Reduce units per group (index 0 in config)
2. Increase cache distance (index 2)
3. Reduce detection radius (index 4)

## Version History

### v8.2 (Current)
- Variable shadowing fixed in ammo calculation
- Elite Driving exclusion flag added
- VCOMAI double-null checks
- Distance checks optimized with distanceSqr
- Player validation added
- Zombie resurrection protection

### v8.1
- VCOMAI integration added
- BIS function optimizations

## License

Free to use and modify.
