# AI Roaming Horde System v1.0

Large groups of 20-50 zombies that dynamically patrol between towns, creating mobile threats and high-reward PvE events.

## Features

- **Large Hordes**: 20-50 zombie groups
- **Dynamic Pathing**: Travels between towns and cities
- **Ravage Integration**: Uses Ravage zombie classes
- **Safe Zone Avoidance**: Won't path near traders
- **Map Tracking**: Real-time markers show horde locations
- **Split & Merge**: Hordes can split into smaller groups or merge
- **Player Detection**: Hordes pursue nearby players
- **High Rewards**: Poptabs and Respect per kill + completion bonus
- **Sound Effects**: Ambient audio for immersion

## Installation

1. Place the `AI-Roaming-Horde` folder in your mission file
2. **Requires Ravage Mod** for zombie classes
3. Add to `init.sqf`:
```sqf
[] execVM "AI-Roaming-Horde\fn_roamingHorde.sqf";
```

## Configuration

```sqf
HORDE_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["maxActiveHordes", 3],
    ["spawnInterval", 900],               // 15 min
    ["despawnDistance", 2000],

    // Size
    ["minHordeSize", 20],
    ["maxHordeSize", 50],
    ["eliteChance", 0.15],                // 15% elite zombies

    // Movement
    ["moveSpeed", 1.2],
    ["waypointDistance", 500],
    ["townPathingOnly", true],

    // Splitting/Merging
    ["splitChance", 0.1],
    ["mergeDistance", 100],
    ["minSplitSize", 15],

    // Combat
    ["detectionRange", 200],
    ["pursuitRange", 400],

    // Rewards
    ["rewardPerZombie", 250],             // Poptabs per kill
    ["respectPerZombie", 25],
    ["hordeCompleteBonus", 5000]          // Clear entire horde
];
```

## How It Works

### Spawning
- Every 15 minutes (configurable)
- Random town/city location
- 20-50 zombies (15% elite chance)
- Avoids safe zones (500m radius)

### Pathing
- Selects destination town
- Creates waypoints every 500m
- Upon arrival, selects new town
- Infinite patrol loop

### Player Detection
- 200m detection range
- Horde switches to pursuit mode
- Chases up to 400m
- Returns to patrol after losing player

### Split Mechanics
- 10% chance per update (30 sec)
- Minimum 15 zombies required
- Splits into two equal groups
- Each group gets own destination

### Merge Mechanics
- Hordes within 100m merge automatically
- Combined into single larger horde
- Shares destination

## Rewards

| Event | Poptabs | Respect |
|-------|---------|---------|
| Per Zombie Kill | 250 | 25 |
| Clear Entire Horde (20) | 5,000 + 5,000 bonus | 500 |
| Clear Entire Horde (50) | 12,500 + 5,000 bonus | 1,250 |

**Total for 50-zombie horde: 17,500 Poptabs + 1,250 Respect**

## Zombie Types

### Standard Zombies (85%)
- Zombie1_0_base
- Zombie2_0_base
- Zombie3_0_base
- Zombie4_0_base

### Elite Zombies (15%)
- Zombie_runner_1 (fast)
- Zombie_runner_2 (fast)
- Zombie_bolter_1 (very fast)

## Integration

### With Ravage Mod
- Uses Ravage zombie classnames
- Compatible with Ravage spawning systems
- Works alongside Ravage-Exile-Integration

### With Exile Mod
- Awards Poptabs and Respect
- Detects ExileSpawnZone safe zones
- Integrates with Exile economy

## Performance

- **Max Hordes**: 3 concurrent (60-150 zombies total)
- **Update Rate**: 30 seconds
- **Despawn**: 2km from all players
- **Optimization**: AI groups, not individual units

## Troubleshooting

### Hordes not spawning
- Check Ravage mod installed
- Verify zombie classnames valid
- Ensure towns exist on map

### Hordes stuck
- Increase `waypointDistance`
- Check terrain obstacles
- Disable `townPathingOnly` for open pathing

### Performance issues
- Reduce `maxActiveHordes` to 1-2
- Increase `spawnInterval` to 1800 (30 min)
- Lower `maxHordeSize` to 30
- Increase `despawnDistance`

## Changelog

### v1.0 (2025-01-XX)
- Initial release
- Town-based pathing
- Split/merge mechanics
- Player pursuit system
- Reward system
