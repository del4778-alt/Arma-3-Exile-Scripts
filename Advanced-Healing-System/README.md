# Advanced Healing System v1.0

Realistic medical mechanics including bleeding, fractures, and infections with item-based treatment.

## Features

- **Bleeding System**: Damage over time requiring bandages (FirstAidKit)
- **Fracture System**: Reduced movement speed requiring splints (ToolKit)
- **Infection System**: From zombie attacks, requires antibiotics (Medikit)
- **Action Menu**: Use medical items via scroll menu
- **Progressive Damage**: Untreated injuries worsen over time

## Installation

```sqf
[] execVM "Advanced-Healing-System\fn_advancedHealing.sqf";
```

## Configuration

```sqf
HEALING_CONFIG = createHashMapFromArray [
    ["bleedingRate", 0.01],
    ["infectionChance", 0.3],
    ["infectionRate", 0.005],
    ["fractureChance", 0.2]
];
```

## Injury Types

### Bleeding
- **Cause**: 50% chance on any hit > 0.1 damage
- **Effect**: Continuous health loss
- **Treatment**: FirstAidKit (Bandage)
- **Action**: "Use Bandage"

### Fracture
- **Cause**: 20% chance on hit > 0.3 damage
- **Effect**: 30% movement speed reduction
- **Treatment**: ToolKit (Splint)
- **Action**: "Use Splint"

### Infection
- **Cause**: 30% chance from zombie hits
- **Effect**: Continuous health loss
- **Treatment**: Medikit (Antibiotics)
- **Action**: "Use Antibiotics"

## Usage

1. Take damage → Check for injury notifications
2. Scroll menu → Select treatment option
3. Item consumed → Injury cured

## Integration

- **Ravage Integration**: Zombies can cause infections
- **Recruit AI**: Compatible with medic recruit abilities
- **Item System**: Uses standard Arma 3 items

## Changelog

### v1.0 (2025-01-XX)
- Initial release
