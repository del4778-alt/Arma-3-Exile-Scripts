# Arma 3 Exile - Elite AI Systems Collection

**13 Complete AI & Gameplay Systems** for Arma 3 Exile servers.

From advanced AI driving and recruit systems to dynamic missions, faction warfare, and environmental hazards - a comprehensive modular collection for enhanced PvE gameplay.

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

### 5. Dynamic Mission System v1.0
**Location**: `Dynamic-Mission-System/`

AI-driven missions with 5 types: Crash Sites, Supply Caches, Convoys, Rescue, and AI Camps.

- Dynamic spawning avoiding safe zones
- Rewards based on difficulty (Easy/Medium/Hard)
- Elite Driving integration for convoy missions
- Auto cleanup and despawn

**Installation**:
```sqf
[] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
```

---

### 6. Territory Defense AI v1.0
**Location**: `Territory-Defense-AI/`

AI defenders spawn when enemies approach player Exile territories.

- Auto-detect Exile territory flags
- Defender count scales with territory level (1-10)
- Vehicle patrols at level 5+
- Respawn system with cooldown

**Installation**:
```sqf
[] execVM "Territory-Defense-AI\fn_territoryDefense.sqf";
```

---

### 7. AI Trader Convoy System v1.0
**Location**: `AI-Trader-Convoy/`

Convoys travel between trader zones with valuable cargo.

- 2-4 vehicle convoys using Elite Driving
- High-value loot in cargo vehicles
- Attack helicopter reinforcements
- Trader bonuses on successful delivery

**Installation**:
```sqf
[] execVM "AI-Trader-Convoy\fn_traderConvoy.sqf";
```

---

### 8. Recruit AI Loadout Manager v1.0
**Location**: `Recruit-AI-Loadout-Manager/`

In-game menu to customize recruit AI equipment.

- Change weapons, attachments, gear
- Save/load loadout presets
- Quick templates (CQB, Long Range, Stealth)
- Poptabs-based upgrade costs

**Installation**:
```sqf
[] execVM "Recruit-AI-Loadout-Manager\fn_loadoutManager.sqf";
```

---

### 9. AI Roaming Horde System v1.0
**Location**: `AI-Roaming-Horde/`

Large zombie hordes (20-50) that patrol between towns.

- Ravage integration for zombie classes
- Dynamic pathing avoiding safe zones
- Horde split/merge mechanics
- Player pursuit system
- High rewards for clearing hordes

**Installation**:
```sqf
[] execVM "AI-Roaming-Horde\fn_roamingHorde.sqf";
```

---

### 10. Vehicle Recovery Service v1.0
**Location**: `Vehicle-Recovery-Service/`

AI tow trucks recover disabled vehicles using Elite Driving.

- Request via action menu
- Cost based on distance and vehicle value
- Auto-repair at destination
- Tow truck autopilot navigation

**Installation**:
```sqf
[] execVM "Vehicle-Recovery-Service\fn_vehicleRecovery.sqf";
```

---

### 11. Dynamic Weather Hazards v1.0
**Location**: `Dynamic-Weather-Hazards/`

Environmental survival challenges.

- Radiation zones with continuous damage
- Toxic fog events spawning zombies
- Temperature system (hypothermia/heatstroke)
- Visual markers and alerts

**Installation**:
```sqf
[] execVM "Dynamic-Weather-Hazards\fn_weatherHazards.sqf";
```

---

### 12. AI Faction Warfare v1.0
**Location**: `AI-Faction-Warfare/`

Three AI factions compete for territory control.

- Red Army, Blue Alliance, Green Coalition
- 10 contested territories
- Dynamic battles and shifting frontlines
- AI patrols defend territories

**Installation**:
```sqf
[] execVM "AI-Faction-Warfare\fn_factionWarfare.sqf";
```

---

### 13. Advanced Healing System v1.0
**Location**: `Advanced-Healing-System/`

Realistic medical mechanics with injuries and treatments.

- Bleeding requiring bandages
- Fractures reducing movement speed
- Infections from zombie attacks
- Item-based treatment system

**Installation**:
```sqf
[] execVM "Advanced-Healing-System\fn_advancedHealing.sqf";
```

---

## Full Integration Example

**initServer.sqf or init.sqf**:

```sqf
// 1. Configure patrol system
EXILE_PATROL_CONFIG = [2, 300, 1000, 999, 2000];

// 2. Start core systems (load in order)
[] execVM "Elite-AI-Driving\ead.sqf";                    // Load first - required by many systems
[] execVM "AI-Patrol-System\fn_aiPatrolSystem.sqf";
[] execVM "AI-Recruit-System\recruit_ai.sqf";
[] execVM "Ravage-Exile-Integration\rmg_ravage_exile_config.sqf";

// 3. Start new gameplay systems
[] execVM "Dynamic-Mission-System\fn_dynamicMissions.sqf";
[] execVM "Territory-Defense-AI\fn_territoryDefense.sqf";
[] execVM "AI-Trader-Convoy\fn_traderConvoy.sqf";
[] execVM "AI-Roaming-Horde\fn_roamingHorde.sqf";
[] execVM "AI-Faction-Warfare\fn_factionWarfare.sqf";
[] execVM "Dynamic-Weather-Hazards\fn_weatherHazards.sqf";
[] execVM "Advanced-Healing-System\fn_advancedHealing.sqf";

// 4. Start utility systems
[] execVM "Recruit-AI-Loadout-Manager\fn_loadoutManager.sqf";
[] execVM "Vehicle-Recovery-Service\fn_vehicleRecovery.sqf";
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
