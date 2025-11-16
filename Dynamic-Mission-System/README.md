# Dynamic Mission System v1.0

AI-driven missions that spawn at random locations providing dynamic PvE content for Exile servers.

## Features

- **5 Mission Types**:
  - **Crash Sites**: Downed helicopters with loot and AI guards
  - **Supply Caches**: Multiple crates with escalating AI waves
  - **Convoy Intercept**: Moving convoys with armed vehicles
  - **Rescue Hostages**: Save civilians from AI captors
  - **AI Camps**: Fortified positions with heavy resistance

- **Dynamic Spawning**: Avoids safe zones and player positions
- **AI Integration**: Works with Elite Driving for vehicle behavior
- **Reward System**: Poptabs and Respect based on difficulty
- **Difficulty Levels**: Easy, Medium, Hard with scaling AI and loot
- **Auto Cleanup**: Missions despawn after timeout or completion
- **Configurable**: All parameters adjustable via hashmap

## Installation

1. Place the `Dynamic-Mission-System` folder in your mission file
2. Add to `init.sqf`:
```sqf
[] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
```

## Configuration

Edit the `MISSION_CONFIG` hashmap at the top of `fn_dynamicMissions.sqf`:

```sqf
MISSION_CONFIG = createHashMapFromArray [
    ["enabled", true],                    // Enable/disable system
    ["debug", true],                      // Show debug messages
    ["minPlayers", 1],                    // Min players for missions
    ["maxActiveMissions", 3],             // Max concurrent missions
    ["spawnInterval", 600],               // Seconds between spawns (10 min)
    ["missionTimeout", 1800],             // Mission expires after 30 min
    ["safeZoneDistance", 1000],           // Distance from traders
    ["minPlayerDistance", 500],           // Distance from players

    // Rewards
    ["rewardPoptabs", [5000, 15000]],     // Min/Max Poptabs
    ["rewardRespect", [500, 2000]],       // Min/Max Respect

    // Mission spawn chances (weights)
    ["crashSiteWeight", 25],
    ["supplyCacheWeight", 30],
    ["convoyWeight", 15],
    ["rescueWeight", 20],
    ["campWeight", 10],

    // AI difficulty
    ["aiSkill", 0.8],
    ["aiCountEasy", [3, 5]],
    ["aiCountMedium", [5, 8]],
    ["aiCountHard", [8, 12]]
];
```

## Mission Types

### Crash Site
- Wrecked helicopter with loot
- AI guards patrol the area
- Single wave of AI
- **Difficulty**: Easy/Medium/Hard

### Supply Cache
- 3 supply crates with weapons and items
- Multiple AI waves spawn when players approach
- Escalating difficulty
- **Difficulty**: Easy/Medium/Hard

### Convoy Intercept
- 2-3 armed vehicles traveling across the map
- Moving target with AI crews
- Loot stored in vehicles
- Uses Elite Driving for convoy movement
- **Difficulty**: Medium/Hard only

### Rescue Hostages
- 2-5 hostages held in small camp
- Must eliminate AI and approach hostages
- Hostages must be alive for completion
- **Difficulty**: Easy/Medium/Hard

### AI Camp
- Fortified position with barriers
- Multiple loot crates
- Armed vehicle
- Higher AI count than other missions
- **Difficulty**: Medium/Hard only

## Rewards

Rewards scale with difficulty:
- **Easy**: 1.0x multiplier
- **Medium**: 1.5x multiplier
- **Hard**: 2.0x multiplier

Players within 500m of mission when completed receive rewards.

## Integration

### With Elite Driving
- Convoy vehicles controlled by Elite Driving autopilot
- AI guards excluded via `EAID_Ignore` flag

### With AI Patrol System
- Similar AI behavior patterns
- Uses same skill configurations

### With Exile Server
- Detects `ExileSpawnZone` markers for safe zones
- Awards Poptabs and Respect (requires server-side integration)

## Performance

- **Spawn Interval**: 10 minutes (configurable)
- **Update Rate**: Every 10 seconds
- **Max Missions**: 3 concurrent (configurable)
- **Auto Cleanup**: Removes inactive missions

## Troubleshooting

### Missions not spawning
- Check `minPlayers` requirement
- Verify `enabled` is true in config
- Check debug messages for spawn position failures

### AI not moving
- Ensure Elite Driving is loaded if using convoys
- Check AI waypoints in debug mode

### Rewards not working
- Requires server-side Exile integration
- Check player distance to mission (500m requirement)

## Changelog

### v1.0 (2025-01-XX)
- Initial release
- 5 mission types implemented
- Dynamic spawning system
- Configurable rewards and difficulty
- Elite Driving integration
