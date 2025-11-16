# Territory Defense AI v1.0

AI defenders that automatically spawn when enemy players approach Exile territories, scaling with territory level.

## Features

- **Auto-Detection**: Finds all Exile territory flags automatically
- **Level Scaling**: More defenders for higher territory levels (1-10)
- **Vehicle Patrols**: Armed vehicle patrols at level 5+ territories
- **Smart Spawning**: Only spawns when enemies detected within range
- **Auto Despawn**: Removes AI when no threats present (configurable)
- **Respawn System**: 5-minute cooldown after all defenders eliminated
- **Elite Driving Integration**: Vehicle patrols use autopilot
- **Perimeter Patrols**: AI patrol around flag radius

## Installation

1. Place the `Territory-Defense-AI` folder in your mission file
2. Add to `init.sqf`:
```sqf
[] execVM "Territory-Defense-AI\fn_territoryDefense.sqf";
```
3. **Requires Exile Mod** for territory flag detection

## Configuration

Edit the `TERRITORY_CONFIG` hashmap in `fn_territoryDefense.sqf`:

```sqf
TERRITORY_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["updateInterval", 15],               // Check every 15 seconds
    ["threatDistance", 300],              // Enemy detection range
    ["despawnDistance", 500],             // AI despawn range
    ["maxDefendersPerTerritory", 8],      // Max AI per territory

    // Defender count by territory level
    ["defendersLevel1", 2],               // Level 1-2
    ["defendersLevel3", 4],               // Level 3-4
    ["defendersLevel5", 6],               // Level 5-6
    ["defendersLevel7", 8],               // Level 7-9
    ["defendersLevel10", 10],             // Level 10 (max)

    // Vehicle patrols
    ["vehiclePatrolMinLevel", 5],         // Spawn vehicles at level 5+
    ["vehiclePatrolTypes", [
        "Exile_Car_Offroad_Armed_Guerilla01",
        "Exile_Car_BTR40_MG_Green"
    ]],

    // AI settings
    ["aiSide", EAST],
    ["aiSkill", 0.85],
    ["patrolRadius", 100],                // Patrol distance from flag

    // Respawn
    ["respawnDelay", 300],                // 5 min cooldown
    ["persistDefenders", false]           // Remove AI when no enemies
];
```

## How It Works

### Detection System
1. Scans for all `Exile_Construction_Flag_Static` objects every 15 seconds
2. Checks for enemy players within 300m of each flag
3. Compares player UID with territory owner UID
4. Activates defense if enemy detected

### Defender Scaling

| Territory Level | Foot Defenders | Vehicle Patrol |
|----------------|----------------|----------------|
| 1-2 | 2 | No |
| 3-4 | 4 | No |
| 5-6 | 6 | Yes (1 armed vehicle) |
| 7-9 | 8 | Yes (1 armed vehicle) |
| 10 | 10 | Yes (1 armed vehicle) |

### Patrol Behavior
- **Foot Defenders**: Patrol 8 waypoints in circle around flag (100m radius)
- **Vehicle Patrol**: Patrols 6 waypoints in wider circle (150m radius)
- **Combat Mode**: RED (aggressive engagement)
- **Formation**: WEDGE for tactical positioning
- **Speed**: Limited for vehicle patrols, Full for foot patrols

### Despawn Logic
- If `persistDefenders = false`:
  - AI despawn when no players within 500m
  - Saves server performance
- If `persistDefenders = true`:
  - AI stay active until all killed
  - Better for high-security territories

### Respawn After Wipe
- If all defenders killed, 5-minute cooldown activates
- New wave spawns automatically when cooldown expires
- Prevents instant respawn exploitation

## AI Skills

Defenders have enhanced skills (0.85 base):
- Aiming Accuracy: 0.75-0.90
- Spot Distance: 0.85-1.00
- Courage: 0.90-1.00
- Commanding: 0.85-1.00

## Integration

### With Elite Driving
- Vehicle patrol drivers NOT marked with `EAID_Ignore`
- Allows Elite Driving to control vehicle movement
- Foot defenders marked `EAID_Ignore = true`

### With AI Patrol System
- Uses similar patrol waypoint logic
- Compatible group behavior settings

### With VCOMAI
- AI automatically enhanced if VCOMAI present
- No configuration needed

## Performance

- **Update Rate**: 15 seconds (configurable)
- **Despawn**: Automatic when no threats
- **Max AI**: Limited by `maxDefendersPerTerritory`
- **Vehicle Limit**: 1 per territory (level 5+)

## Troubleshooting

### Defenders not spawning
- Verify Exile mod is installed
- Check territory has valid owner UID
- Ensure enemy player within 300m
- Check debug messages

### AI standing still
- Verify waypoints are created (check debug)
- Ensure patrol radius isn't too small
- Check terrain for obstacles

### Vehicle patrol not spawning
- Territory must be level 5 or higher
- Check `vehiclePatrolMinLevel` in config
- Verify vehicle classnames are valid

### Performance issues
- Reduce `updateInterval` to 30 seconds
- Lower `maxDefendersPerTerritory`
- Enable `persistDefenders = false` for auto despawn
- Disable vehicle patrols by setting `vehiclePatrolMinLevel = 99`

## Example Scenarios

### Scenario 1: Level 3 Territory Attack
1. Enemy player approaches within 300m
2. System spawns 4 foot defenders
3. Defenders patrol 100m radius around flag
4. Enemy eliminated or leaves 500m range
5. Defenders despawn (if persist = false)

### Scenario 2: Level 7 Territory Assault
1. Enemy approaches level 7 territory
2. System spawns 8 foot defenders + 1 armed vehicle
3. Vehicle patrols outer perimeter (150m)
4. Foot defenders patrol inner perimeter (100m)
5. All defenders killed
6. 5-minute cooldown activates
7. New wave spawns after cooldown

### Scenario 3: Persistent Defense
1. `persistDefenders = true` in config
2. Defenders spawn when first enemy detected
3. Defenders remain active indefinitely
4. Respawn 5 minutes after wipe
5. Never despawn unless territory destroyed

## Changelog

### v1.0 (2025-01-XX)
- Initial release
- Territory level scaling
- Vehicle patrol system
- Auto despawn functionality
- Respawn cooldown system
- Elite Driving integration
