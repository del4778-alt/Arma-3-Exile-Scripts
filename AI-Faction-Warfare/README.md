# AI Faction Warfare v1.0

Three AI factions compete for territory control across the map with dynamic battles and shifting frontlines.

## Features

- **3 Factions**: Red Army (EAST), Blue Alliance (WEST), Green Coalition (INDEPENDENT)
- **Territory Control**: 10 contested zones marked on map
- **Dynamic Battles**: Territories change hands based on faction strength
- **AI Patrols**: 2 patrols per territory
- **Player Alliances**: Gain reputation with factions
- **Visual Markers**: Color-coded territorial boundaries

## Installation

```sqf
[] execVM "AI-Faction-Warfare\fn_factionWarfare.sqf";
```

## Configuration

```sqf
FACTION_CONFIG = createHashMapFromArray [
    ["numFactions", 3],
    ["numTerritories", 10],
    ["battleInterval", 600],
    ["patrolsPerTerritory", 2],
    ["reputationGainPerKill", 10]
];
```

## Factions

- **Red Army** (EAST, Red markers)
- **Blue Alliance** (WEST, Blue markers)
- **Green Coalition** (INDEPENDENT, Green markers)

## Mechanics

- Territories auto-spawn with random faction ownership
- Battles every 10 minutes between factions
- Stronger faction captures territory
- AI patrols defend territories
- Kill enemy faction AI to gain reputation

## Changelog

### v1.0 (2025-01-XX)
- Initial release
