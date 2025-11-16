# Dynamic Weather Hazard System v1.0

Environmental challenges including radiation zones, toxic fog, and temperature survival mechanics.

## Features

- **Radiation Zones**: 3 random areas causing continuous damage
- **Toxic Fog**: Random fog events spawning zombies
- **Temperature System**: Hypothermia and heatstroke mechanics
- **Visual Markers**: Red zones marked on map
- **Damage Over Time**: Configurable damage rates

## Installation

```sqf
[] execVM "Dynamic-Weather-Hazards\fn_weatherHazards.sqf";
```

## Configuration

```sqf
WEATHER_CONFIG = createHashMapFromArray [
    ["radiationZones", 3],
    ["toxicFogChance", 0.2],
    ["extremeWeatherInterval", 1800],
    ["temperatureEnabled", true],
    ["damagePerTick", 0.05]
];
```

## Hazards

- **Radiation**: Enter zone = continuous damage
- **Toxic Fog**: 20% chance every 30 min, spawns zombies
- **Cold**: Rain + night = hypothermia damage
- **Heat**: Sun + day = heatstroke damage

## Changelog

### v1.0 (2025-01-XX)
- Initial release
