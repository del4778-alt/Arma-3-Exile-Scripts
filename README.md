# Arma 3 Exile - Elite AI Systems Collection

Complete, debugged AI systems for Arma 3 Exile servers.

## Systems Included

### 1. Elite AI Driving System v8.3
**Location**: `Elite-AI-Driving/`

Advanced vehicle AI with velocity-based physics control.

- 11-ray obstacle detection
- Bridge/terrain detection
- Stuck recovery with auto-reverse
- Convoy behavior
- Emergency braking

**Installation**:
```sqf
[] execVM "Elite-AI-Driving\ead.sqf";
```

---

### 2. AI Patrol System v8.2
**Location**: `AI-Patrol-System/`

Dynamic AI patrols that spawn at Exile zones.

- Auto-detects ExileSpawnZone markers
- Dynamic caching (despawns when no players nearby)
- VCOMAI integration
- Cover system & tactical AI
- Optimized with distanceSqr

**Installation**:
```sqf
EXILE_PATROL_CONFIG = [2, 300, 1000, 999, 2000];
[] execVM "AI-Patrol-System\fn_aiPatrolSystem.sqf";
```

---

### 3. AI Recruit System v7.20
**Location**: `AI-Recruit-System/`

Player companion AI with advanced FSM brain.

- 3 AI recruits per player (AT, AA, Sniper)
- 4-state FSM (Idle, Combat, Retreat, Heal)
- Elite Driving integration (AI can drive vehicles)
- Stuck detection & recovery
- Automatic respawn on death

**Installation**:
```sqf
[] execVM "AI-Recruit-System\recruit_ai.sqf";
```

---

### 4. Ravage/Exile Integration v2.6
**Location**: `Ravage-Exile-Integration/`

Zombie resurrection system for Ravage mod.

- Zombies spawn when EAST AI die
- Recruit AI excluded from resurrection
- Zombie kill rewards (Poptabs + Respect)
- Safe zone protection
- Ambient bandits/scavengers

**Installation**:
```sqf
[] execVM "Ravage-Exile-Integration\rmg_ravage_exile_config.sqf";
```

---

### 5. Mission System Convoy Fix
**Location**: `Mission-Systems/`

Fixes convoy missions where AI/vehicles die instantly on spawn.

- Auto-patches A3XAI convoy spawns
- Manual integration for DMS/VEMF
- Prevents collision, fall damage, simulation issues
- Safe spawn function for custom missions
- Diagnostic tools

**Installation** (A3XAI auto-patch):
```sqf
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";
```

**See**: `Mission-Systems/CONVOY_TROUBLESHOOTING.md` for detailed guide

---

## Full Integration Example

**initServer.sqf or init.sqf**:

```sqf
// 1. Configure patrol system
EXILE_PATROL_CONFIG = [2, 300, 1000, 999, 2000];

// 2. Start all systems
[] execVM "Elite-AI-Driving\ead.sqf";
[] execVM "AI-Patrol-System\fn_aiPatrolSystem.sqf";
[] execVM "AI-Recruit-System\recruit_ai.sqf";
[] execVM "Ravage-Exile-Integration\rmg_ravage_exile_config.sqf";

// 3. Fix mission system convoy spawns (if using A3XAI/DMS/VEMF)
call compile preprocessFileLineNumbers "Mission-Systems\convoy_spawn_fix.sqf";
```

---

## System Compatibility

| System | Elite Driving | AI Patrol | AI Recruit | Ravage |
|--------|--------------|-----------|------------|--------|
| **Elite Driving** | - | ✅ | ✅ | ✅ |
| **AI Patrol** | ✅ | - | ✅ | ✅ |
| **AI Recruit** | ✅ | ✅ | - | ✅ |
| **Ravage** | ✅ | ✅ | ✅ | - |

### Integration Notes

- **Elite Driving ↔ AI Recruit**: Recruit AI drivers automatically use Elite Driving
- **Elite Driving ↔ AI Patrol**: Patrol AI explicitly excluded (EAID_Ignore flag)
- **AI Recruit ↔ Ravage**: Recruit AI have resurrection immunity
- **AI Patrol ↔ Ravage**: Patrol AI (EAST side) spawn zombies on death

---

## Version History

### Elite AI Driving v8.3
- Fixed hashMap netId usage
- Improved A3XAI integration
- Enhanced stuck detection

### AI Patrol v8.2
- Variable shadowing fixed
- Elite Driving exclusion flag
- distanceSqr optimization
- Player validation

### AI Recruit v7.20
- Elite Driving integration fixed
- FSM pause when in vehicles
- Stuck detection & recovery
- Passenger lock per-seat

### Ravage Integration v2.6
- Debug mode added
- EAST-only resurrection
- Recruit AI exclusion
- Zombie kill rewards

---

## Performance

- **Elite Driving**: ~1-2ms per vehicle
- **AI Patrol**: distanceSqr optimization, player caching
- **AI Recruit**: FSM-based (variable sleep 1-3s)
- **Ravage**: Event-driven (negligible overhead)

---

## Requirements

- **Arma 3**: 2.00+
- **Exile Mod**: Any version
- **Optional**: VCOMAI, Ravage, A3XAI

---

## Troubleshooting

### Vehicles not driving smoothly
- Ensure Elite Driving loaded before other AI systems
- Check `EAD_active` variable on vehicle
- Verify driver is not a player

### Patrols not spawning
- Check `ExileSpawnZone` markers exist
- Verify player within detection radius (2000m default)
- Check RPT for errors

### Recruit AI not spawning
- Check player has valid Exile session
- Verify `RECRUIT_AI_TYPES` classes exist
- Check spawn cooldown (5s default)

### Zombies not spawning
- Verify Ravage mod loaded
- Check AI is EAST side (not RESISTANCE)
- Enable DEBUG mode in config

---

## License

Free to use and modify. Credit appreciated but not required.

---

## Support

Check individual system READMEs for detailed configuration and troubleshooting.
