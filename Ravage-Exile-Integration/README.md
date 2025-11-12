# Ravage Exile Integration

**Complete zombie apocalypse integration for Exile servers using the Ravage mod**

Transform your Exile server into a zombie survival experience with AI-to-zombie resurrection, ambient threats, and rewarding gameplay.

---

## Overview

This script seamlessly integrates the Ravage zombie mod with Exile, providing:

- 🧟 **Dynamic Zombie Spawning** - AI deaths spawn zombies (90% single, 10% horde)
- 💰 **Kill Rewards** - 100 poptabs + 250 respect per zombie kill
- 🎯 **Faction System** - All AI factions attack zombies on sight
- 🛡️ **Safe Zones** - Trader zones protected from zombie/bandit spawns
- 🎖️ **Ambient Bandits** - Light patrol groups for additional PvE content
- ⚡ **Performance Optimized** - AI cap system prevents server lag

---

## Quick Start

### 1. Requirements
- Exile Mod (installed)
- Ravage Mod (Steam Workshop or manual)
- CBA_A3 (required dependency)

### 2. Installation (3 steps)

**Step 1**: Copy the script
```
Copy: scripts/rmg_ravage_exile_config.sqf
To: mpmissions/Exile.Altis/scripts/rmg_ravage_exile_config.sqf
```

**Step 2**: Edit initServer.sqf
```sqf
[] execVM "scripts\rmg_ravage_exile_config.sqf";
```

**Step 3**: Configure trader zones (in the script)
```sqf
["safeZoneMarkers", ["YourTraderZone1", "YourTraderZone2"]],
```

**Done!** Restart your server and enjoy zombies.

📖 **See [INSTALLATION.md](INSTALLATION.md) for complete setup instructions**

---

## Configuration Examples

### Adjust Zombie Rewards
```sqf
["zombieKillRewardPoptabs", 150],   // Increase to 150 poptabs
["zombieKillRewardRespect", 500]    // Increase to 500 respect
```

### Change Horde Settings
```sqf
["hordeSizeRange", [8, 16]],  // Bigger hordes (8-16 zombies)
["chanceHorde", 0.20],        // 20% horde chance (up from 10%)
```

### Disable Ambient Bandits
```sqf
["ambientEnabled", false],  // Turn off bandit patrols
```

### Performance Tuning
```sqf
["globalAICap", 150],  // Lower AI limit for better performance
```

---

## Features in Detail

### Zombie Resurrection System
When AI units die, they resurrect as zombies:
- **90% chance**: Single zombie spawn
- **10% chance**: Horde spawn (6-12 zombies)
- **Smart spawning**: Won't spawn near players (<40m) or in safe zones
- **Configurable sides**: Choose which AI factions resurrect

### Zombie Kill Rewards
Players earn rewards for every zombie kill:
- **100 poptabs** added to player account
- **250 respect** added to player score
- **In-game notification**: "Zombie Kill: +100 Poptabs, +250 Respect"
- **No penalties**: Killing CIVILIAN zombies has no negative effects
- **Vehicle kills**: Works from vehicles (instigator tracking)

### Faction Hostility
All AI factions will automatically attack zombies:
- EAST (OPFOR) ↔️ Zombies (hostile)
- RESISTANCE (Independent) ↔️ Zombies (hostile)
- WEST (BLUFOR) ↔️ Zombies (hostile)
- Zombies spawn on CIVILIAN side

### Safe Zone Protection
Trader zones are protected:
- No zombie spawns in trader zones
- No bandit patrols in trader zones
- Configurable radius (default 175m)
- Multiple trader zones supported

### Ambient Bandits
Light bandit patrols spawn dynamically:
- 2-4 bandits per group
- Maximum 6 groups active
- Spawn 800-1600m from players
- Simple patrol behavior
- Auto-despawn when far from players
- Fully configurable classes (supports RHS, CUP, etc.)

### Performance Optimization
Built-in AI cap system:
- Global AI limit: 220 units (configurable)
- Automatic culling of farthest AI
- Distance-based despawn logic
- Optimized for minimal server load

---

## File Structure

```
Ravage-Exile-Integration/
├── README.md                           ← You are here
├── INSTALLATION.md                     ← Full setup guide
└── scripts/
    └── rmg_ravage_exile_config.sqf    ← Main script file
```

---

## Compatibility

### Works With:
- ✅ All Exile versions
- ✅ A3XAI, DMS, VEMF, Occupation scripts
- ✅ CUP, RHS, and other weapon/unit mods
- ✅ Custom missions and AI spawners
- ✅ Infistar and other anti-cheat systems

### Server Requirements:
- **Minimum**: 8GB RAM, 4 CPU cores
- **Recommended**: 16GB RAM, 8 CPU cores (for 40+ players)
- **Mods**: Exile, Ravage, CBA_A3

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Zombies not spawning | Check zombie class names in config match Ravage version |
| No rewards | Verify `ExileServer_system_network_send_to` in CfgRemoteExec |
| AI ignore zombies | Check faction setup in RPT log |
| Performance lag | Lower `globalAICap` to 150 or disable ambient bandits |
| Script errors | Verify file path: `scripts\rmg_ravage_exile_config.sqf` |

📖 **See [INSTALLATION.md](INSTALLATION.md#troubleshooting) for detailed troubleshooting**

---

## Screenshots

```
[Screenshot: Zombie horde attacking a player]
[Screenshot: In-game reward notification]
[Screenshot: AI fighting zombies]
```

---

## Changelog

### Version 2.0 (Current)
- ✨ Added zombie kill reward system (poptabs + respect)
- ✨ Added WEST faction hostility support
- ⚡ Performance optimizations (cap culling)
- 🛠️ Custom trader zone configuration
- 📖 Comprehensive documentation

### Version 1.0
- Initial release
- Zombie resurrection system
- Ambient bandit patrols
- Safe zone protection

---

## Credits

**Author**: RMG
**Version**: 2.0
**License**: Free to use and modify

### Special Thanks:
- **Haleks** - Creator of Ravage Mod
- **Exile Mod Team** - For the amazing Exile framework
- **Community** - For feedback and testing

---

## Support

### Need Help?
1. Read [INSTALLATION.md](INSTALLATION.md) thoroughly
2. Check the [Troubleshooting](#troubleshooting) section
3. Review your server's RPT log for errors
4. Test with default configuration first

### Found a Bug?
Please report issues with:
- Server RPT log excerpt
- Script configuration used
- Steps to reproduce
- Expected vs actual behavior

---

## Configuration Reference

| Setting | Default | Description |
|---------|---------|-------------|
| `safeZoneMarkers` | `["MafiaTraderCity",...]` | Trader zone marker names |
| `safeZoneRadius` | `175` | Safe zone radius in meters |
| `zedClasses` | `["zombie_runner",...]` | Zombie class names |
| `hordeSizeRange` | `[6, 12]` | Min/max zombies in horde |
| `chanceHorde` | `0.10` | 10% horde, 90% single |
| `zombieKillRewardPoptabs` | `100` | Poptabs per kill |
| `zombieKillRewardRespect` | `250` | Respect per kill |
| `ambientEnabled` | `true` | Enable/disable bandits |
| `ambientMaxGroups` | `6` | Max bandit groups |
| `globalAICap` | `220` | Total AI unit limit |

📖 **See [INSTALLATION.md](INSTALLATION.md#configuration) for complete configuration guide**

---

## License

This script is free to use, modify, and distribute. No attribution required, but appreciated.

**Ravage Mod** and **Exile Mod** have their own respective licenses. Please respect them.

---

**Enjoy the apocalypse! 🧟💀**
