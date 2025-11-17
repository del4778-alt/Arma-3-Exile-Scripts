# AI Resurrection System - Mission Script

A comprehensive AI resurrection and revival system for Arma 3, designed for mission scripts. This system allows AI to automatically revive incapacitated allies, provides player revive actions, a drag system, and customizable admin controls.

**Author:** Adri_karry
**Converted to:** Mission Script Format

## Features

- **AI Auto-Revive**: AI units automatically search for and revive incapacitated allies within a configurable radius
- **Player Revive Actions**: Players can manually revive incapacitated units using hold actions
- **Drag System**: Drag incapacitated units using User Action 8 key
- **Admin Menu**: Comprehensive admin controls via User Action 10 key
- **Player Menu**: Quick access player menu via User Action 7 key with:
  - Auto-revive countdown (7 seconds)
  - Leadership controls (become/step down as leader)
  - Recruit system (recruit AI units to your group)
- **Incapacitation System**: Units enter an incapacitated state before death
- **Death Timer**: Configurable timer before incapacitated units die
- **Faction-Specific Toggles**: Enable/disable the system per faction
- **Damage Management**: Configurable damage reduction and lethal damage options

## Installation

### Method 1: Quick Install (init.sqf)

1. Copy `AIR_Resurrection_Mission.sqf` to your mission folder
2. Add this line to your `init.sqf`:

```sqf
execVM "AIR_Resurrection_Mission.sqf";
```

### Method 2: initPlayerLocal.sqf

1. Copy `AIR_Resurrection_Mission.sqf` to your mission folder
2. Add this line to your `initPlayerLocal.sqf`:

```sqf
execVM "AIR_Resurrection_Mission.sqf";
```

### Method 3: initServer.sqf

1. Copy `AIR_Resurrection_Mission.sqf` to your mission folder
2. Add this line to your `initServer.sqf`:

```sqf
execVM "AIR_Resurrection_Mission.sqf";
```

## Configuration

All configuration variables are located at the top of the script file:

```sqf
// Death timer before unit dies (seconds)
AIR_deathTime = 180;

// Radius in which AI will search for incapacitated allies (meters)
AIR_reviveRadius = 80;

// Maximum revive attempts
AIR_maxRetries = 12;

// Life/damage level after revival (0 = full health, 0.5 = half health)
AIR_life = 0;

// Faction-specific toggles (false = revive enabled, true = revive disabled)
AIR_factionWest = false;
AIR_factionEast = false;
AIR_factionIndependent = false;
AIR_factionCivilian = false;

// Lethal damage (true = units can die instantly from high damage)
AIR_Letal_Damage_A = false;

// Damage reduction threshold before incapacitation
AIR_damageReduction = 0;
```

## Usage

### Player Controls

- **User Action 7**: Open Player Menu
  - Auto-Revive: Instantly revive yourself after 7 second countdown
  - Leadership: Become or step down as group leader
  - Recruiting: Toggle recruit mode to add AI units to your group

- **User Action 8**: Drag System
  - Press once near an incapacitated unit to start dragging
  - Press again to release

- **User Action 10**: Admin Menu (Admins/Server Only)
  - Adjust death timer (60-600 seconds)
  - Configure life after revival (0-0.5)
  - Set revive radius (10-100 meters)
  - Adjust max revive attempts (1-15)
  - Toggle factions (BLUFOR, OPFOR, Independent, Civilian)
  - Enable/disable lethal damage
  - Adjust damage reduction (0-0.7)

### Manual Revive

When near an incapacitated unit, hold the action key to perform a manual revive (4.5 seconds).

## How It Works

### Incapacitation System

- When a unit takes damage exceeding 97%, they become incapacitated instead of dying
- Incapacitated units enter unconscious state and have a death timer
- AI allies will automatically move to revive incapacitated units within the configured radius
- Players can manually revive using hold actions
- If the death timer expires, the unit dies permanently

### AI Behavior

- AI scans for incapacitated allies within the revive radius
- When found, AI moves to the incapacitated unit
- AI performs a 7-second medical animation
- Upon completion, the ally is revived with configured health level
- AI then returns to normal behavior

### Faction System

- Each unit's original side is tracked
- AI only revives units from their own faction
- Factions can be individually enabled/disabled via admin menu

## Compatibility

- **Arma 3**: All versions
- **Multiplayer**: Full support (dedicated servers and hosted)
- **Single Player**: Full support
- **Mods**: Compatible with most Arma 3 mods
- **DLC**: No DLC required

## Performance

The script is optimized for performance:
- Efficient unit scanning with sleep timers
- Smart AI detection that only activates when needed
- Minimal performance impact even with large numbers of units

## Troubleshooting

### Script not working?

1. Verify the script is being called from `init.sqf`, `initPlayerLocal.sqf`, or `initServer.sqf`
2. Check the RPT log for errors
3. Ensure you're using the correct key bindings (User Action 7, 8, 10)

### AI not reviving?

1. Check faction toggles in admin menu
2. Verify AI is within revive radius (default 80m)
3. Ensure the incapacitated unit hasn't exceeded death timer

### Admin menu not opening?

1. Verify you have admin rights on the server
2. In single player, admin rights are automatic
3. Check that User Action 10 key binding is not conflicting

## Credits

- **Original Author**: Adri_karry
- **Script Type**: Mission Script Version
- **Conversion**: Adapted for mission-based implementation

## License

This project is provided as-is for use in Arma 3 missions and scenarios.

## Support

For issues, questions, or suggestions, please open an issue in the repository.

---

**Note**: This is a mission script version. For mod-based implementation, consider converting to a proper Arma 3 mod structure.
