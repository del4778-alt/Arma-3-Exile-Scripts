# Vehicle Recovery & Repair Service v1.0

AI-driven tow truck system for recovering disabled vehicles using Elite Driving autopilot.

## Features

- **On-Demand Service**: Request via action menu
- **AI Autopilot**: Tow truck uses Elite Driving
- **Cost-Based**: Distance + vehicle value pricing
- **Auto-Repair**: Optional repair at destination
- **Safe Zone Delivery**: Returns to nearest trader
- **Multiple Recoveries**: Up to 5 concurrent
- **Timeout Protection**: 30-minute limit

## Installation

1. Place folder in mission
2. **Requires Elite Driving System**
3. Add to `init.sqf`:
```sqf
[] execVM "Elite-AI-Driving\ead.sqf";
[] execVM "Vehicle-Recovery-Service\fn_vehicleRecovery.sqf";
```

## Configuration

```sqf
RECOVERY_CONFIG = createHashMapFromArray [
    ["baseCost", 1000],
    ["costPerMeter", 0.5],
    ["vehicleValueMultiplier", 0.1],
    ["repairOnArrival", true],
    ["repairCost", 500],
    ["recoverySpeed", "LIMITED"],
    ["timeoutMinutes", 30]
];
```

## Usage

1. Stand near disabled vehicle (within 50m)
2. Scroll menu → "Request Vehicle Recovery"
3. See cost estimate
4. Confirm payment
5. Wait for tow truck
6. Vehicle transported to safe zone

## Cost Calculation

```
Total = Base + (Distance × PerMeter) + (Value × 10%) + Repair
Example: 1000 + (2000 × 0.5) + (5000 × 0.1) + 500 = 3000 Poptabs
```

## Recovery Process

1. **Tow Truck Spawns**: 1km away
2. **Travel to Vehicle**: Elite Driving autopilot
3. **Attach**: Vehicle connects to truck
4. **Towing**: Transport to safe zone
5. **Detach**: Vehicle placed at destination
6. **Repair**: Optional auto-repair
7. **Cleanup**: Tow truck despawns

## Changelog

### v1.0 (2025-01-XX)
- Initial release
