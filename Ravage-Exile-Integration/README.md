# Ravage/Exile Integration v2.6

Zombie resurrection system for Ravage mod with Exile server integration.

## Features

- **Zombie resurrection**: EAST AI spawn zombies when killed
- **Recruit AI exclusion**: Player companions don't resurrect
- **Kill rewards**: Poptabs + Respect for killing zombies
- **Safe zones**: No zombie spawns near traders
- **Ambient bandits**: Scavenger groups patrol the map
- **Faction hostility**: All sides attack CIVILIAN zombies
- **Debug mode**: Comprehensive logging for troubleshooting

## Installation

```sqf
[] execVM "Ravage-Exile-Integration\rmg_ravage_exile_config.sqf";
```

## Configuration

Edit the `_CFG` array at the top of the script:

```sqf
private _CFG = [
    // Safe zones
    ["safeZoneMarkers", ["MafiaTraderCity","TraderZoneSilderas","TraderZoneFolia"]],
    ["safeZoneRadius", 500],

    // Zombie resurrection
    ["zedClasses", ["zombie_bolter","zombie_walker","zombie_runner"]],
    ["hordeSizeRange", [6, 12]],
    ["chanceHorde", 0.10],              // 10% chance of horde vs single zombie
    ["spawnFromSides", [east]],         // Only EAST AI resurrect

    // Rewards
    ["zombieKillRewardPoptabs", 200],
    ["zombieKillRewardRespect", 250],

    // Debug
    ["debugMode", true]                 // Enable verbose logging
];
```

## How It Works

1. EAST AI dies (A3XAI patrols, etc.)
2. System checks if position is safe (not in trader zone)
3. 10% chance spawn horde (6-12 zombies), 90% spawn single zombie
4. Zombies are CIVILIAN side, hostile to all
5. Player kills zombie → Receives Poptabs + Respect reward

## Exclusions

- **Recruit AI**: Never resurrect (ExileRecruited flag checked)
- **Zombies**: Don't resurrect other zombies
- **RESISTANCE**: Explicitly excluded (recruits are RESISTANCE)
- **Safe zones**: No spawns within 500m of traders

## Ambient Bandits

Optional scavenger/bandit groups that patrol the map:

```sqf
["ambientEnabled", true],
["ambientMaxGroups", 6],
["ambientGroupSize", [2,4]],
["ambientSpawnRadius", [100, 200]],
["ambientMinPlayerDist", 300],
```

## Zombie Kill Rewards

When players kill zombies:
- **+200 Poptabs** (configurable)
- **+250 Respect** (configurable)
- Notification sent to player

## Debug Mode

Enable detailed logging:

```sqf
["debugMode", true]
```

Logs include:
- Entity death events
- Side checks
- Spawn conditions
- Horde rolls
- Individual zombie spawns

## Compatibility

- **Arma 3**: 2.00+
- **Exile Mod**: Required
- **Ravage Mod**: Required for `rvg_fnc_infectCivilian`
- **AI Recruit System**: Compatible (exclusion built-in)
- **AI Patrol System**: Compatible (EAST AI spawn zombies)

## Troubleshooting

### Zombies not spawning

1. Check Ravage mod loaded
2. Enable DEBUG mode
3. Check RPT logs for "zombie spawn" messages
4. Verify AI dying is EAST side
5. Verify not in safe zone

### Too many zombies

Reduce horde chance or size:
```sqf
["chanceHorde", 0.05],        // 5% instead of 10%
["hordeSizeRange", [3, 6]],   // Smaller hordes
```

### Performance issues

Lower AI cap:
```sqf
["globalAICap", 50],          // Lower from 100
```

## Version History

### v2.6 (Current)
- Debug mode added
- Comprehensive logging
- EAST-only resurrection
- Recruit AI explicit exclusion
- Zombie kill rewards added

## License

Free to use and modify.
