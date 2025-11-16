# AI Recruit System v7.20

Elite AI companion system with advanced FSM brain and vehicle integration.

## Features

- **3 AI recruits per player**: AT, AA, Sniper specializations
- **4-state FSM**: IDLE ↔ COMBAT → RETREAT → HEAL → IDLE
- **Elite Driving integration**: AI drivers use velocity-based autopilot
- **Stuck detection**: Auto-recovery for drivers on bridges/obstacles
- **Perfect skills**: 1.0 (100%) all categories
- **300m sight range**: Extreme detection distance
- **1.4x movement speed**: Lightning-fast repositioning
- **Stealth**: 50% harder to spot, 50% quieter

## Installation

```sqf
[] execVM "AI-Recruit-System\recruit_ai.sqf";
```

## How It Works

1. Player joins server
2. System waits for Exile session initialization
3. Spawns 3 AI (1x AT, 1x AA, 1x Sniper)
4. AI follow player with FSM brain
5. On death, AI respawn after 5s cooldown

## Vehicle Behavior

- **Driver**: FSM pauses, Elite Driving takes full control
- **Gunner**: Active combat AI
- **Passenger**: Movement AI disabled, stays seated
- **Stuck recovery**: Auto dismount/remount after 8s stuck

## Configuration

Edit `RECRUIT_AI_TYPES` array in recruit_ai.sqf:

```sqf
RECRUIT_AI_TYPES = [
    "I_Soldier_AT_F",      // Anti-Tank
    "I_Soldier_AA_F",      // Anti-Air
    "I_Sniper_F"           // Sniper
];
```

## FSM States

- **IDLE**: Follow player, safe mode, column formation
- **COMBAT**: Engage enemies, red mode, line formation
- **RETREAT**: Return to player, throw smoke, heal priority
- **HEAL**: Use medkits, stay with player

## Compatibility

- **Elite AI Driving**: Full integration, drivers use EAD
- **VCOMAI**: Auto-detected, enhanced AI behavior
- **LAMBS**: Danger AI integration
- **Ravage**: Zombie resurrection immunity

## Version History

### v7.20 (Current)
- Fixed driver stopping after combat
- FSM pauses when in vehicles
- Per-seat passenger locking
- Stuck detection & recovery
- Regroup command support

## License

Free to use and modify.
