# AI Trader Convoy System v1.0

Automated convoys that travel between trader zones delivering supplies, creating high-risk/high-reward PvE events.

## Features

- **Automated Routes**: Travels between ExileSpawnZone trader locations
- **Elite Driving Integration**: Vehicles use autopilot for realistic movement
- **Multiple Vehicles**: 2-4 vehicle convoys (lead, cargo, escorts)
- **Valuable Loot**: 2x normal mission rewards in cargo vehicles
- **Trader Bonuses**: Successful deliveries unlock trader benefits
- **Air Support**: Attack helicopter reinforcements when under attack
- **Dynamic Events**: Schedule-based spawning every 30-60 minutes
- **Tracking**: Map markers follow convoy position in real-time

## Installation

1. Place the `AI-Trader-Convoy` folder in your mission file
2. **Requires Elite Driving System** - Install first!
3. Add to `init.sqf`:
```sqf
[] execVM "Elite-AI-Driving\ead.sqf";        // Load Elite Driving first
[] execVM "AI-Trader-Convoy\fn_traderConvoy.sqf";
```

## Configuration

Edit the `CONVOY_CONFIG` hashmap in `fn_traderConvoy.sqf`:

```sqf
CONVOY_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["spawnInterval", 1800],              // 30 min between convoys
    ["maxActiveConvoys", 2],              // Max concurrent convoys
    ["convoySpeed", "LIMITED"],           // Movement speed
    ["escortDistance", 50],               // Space between vehicles

    // Convoy composition
    ["minVehicles", 2],
    ["maxVehicles", 4],
    ["leadVehicleTypes", [
        "Exile_Car_Offroad_Armed_Guerilla01",
        "Exile_Car_BTR40_MG_Green"
    ]],
    ["cargoVehicleTypes", [
        "Exile_Car_Van_Box_White",
        "Exile_Car_Zamak"
    ]],
    ["escortVehicleTypes", [
        "Exile_Car_Offroad_Armed_Guerilla01",
        "Exile_Car_HMMWV_M2_Desert"
    ]],

    // AI settings
    ["aiSide", INDEPENDENT],              // Neutral faction
    ["aiSkill", 0.9],
    ["crewPerVehicle", 3],

    // Loot
    ["lootMultiplier", 2.0],              // 2x mission loot
    ["lootMoney", [10000, 25000]],        // Poptabs

    // Rewards for successful delivery
    ["deliveryReward", 15000],
    ["traderStockBonus", true],
    ["traderPriceReduction", 0.9],        // 10% discount

    // Combat
    ["alertRange", 400],
    ["fleeOnDamage", false],
    ["callReinforcements", true],
    ["reinforcementDelay", 60]            // 1 min delay
];
```

## How It Works

### Convoy Spawning
1. System finds all `ExileSpawnZone` markers (trader locations)
2. Selects random start and end zones (minimum 1000m apart)
3. Spawns 2-4 vehicles at start location
4. Creates AI crews for each vehicle
5. Adds waypoint to destination trader zone

### Convoy Composition

| Position | Vehicle Type | Purpose |
|----------|-------------|---------|
| Lead | Armed (Offroad/BTR) | Scout and defense |
| Middle | Mix of Cargo/Escort | Transport and protection |
| Rear | Cargo (Van/Zamak) | **Contains loot** |

### Elite Driving Integration
- All convoy vehicles controlled by Elite Driving autopilot
- Realistic physics-based movement
- Automatic obstacle avoidance
- Smooth formation driving
- Vehicles set with `EAID_Ignore = false` to enable control

### Combat System

#### Attack Detection
- Vehicles have damage event handlers
- Convoy enters "under attack" mode on first hit
- Changes behavior to combat mode
- Calls reinforcements after 1 minute

#### Reinforcements
- Attack helicopter spawns 200m above convoy
- Circles convoy position providing air support
- Engages hostile players
- Remains until convoy destroyed or delivered

#### Player Strategy
- Attack early to prevent reinforcements
- Target cargo vehicle (rear) for loot
- Expect heavy resistance from air support

## Rewards

### For Players (Attack Convoy)
- **Loot**: 2x normal mission rewards
- **Weapons**: High-tier rifles and LMGs
- **Items**: Medical, tools, optics
- **Money**: 10,000-25,000 Poptabs in cargo

### For Server (Convoy Success)
- **Trader Stock**: Rare items added to traders
- **Price Reduction**: 10% discount for limited time
- **Bonus**: 15,000 Poptabs value to economy

## Event Flow

### Successful Delivery
```
Convoy spawns → Travels to trader → Arrives within 100m →
Trader receives supplies → Bonuses activated → Convoy cleaned up
```

### Intercepted Convoy
```
Convoy spawns → Player attacks → Reinforcements called →
All vehicles destroyed → Players loot cargo → Convoy fails
```

### Timeline Example
- **T+0:00**: Convoy spawns, announces in chat
- **T+05:00**: Players locate and engage
- **T+06:00**: Reinforcement helicopter arrives
- **T+10:00**: Convoy destroyed or escapes
- **T+15:00**: Convoy arrives at trader OR fails

## Integration

### With Elite Driving
- **Required**: Convoy vehicles use autopilot
- **Setup**: Load Elite Driving BEFORE convoy system
- **Control**: Vehicles automatically controlled
- **Performance**: ~2ms per vehicle per tick

### With Dynamic Mission System
- **Compatible**: Can run simultaneously
- **Different**: Convoys are mobile, missions are static
- **Coordination**: Share AI configuration

### With Exile Mod
- **Trader Detection**: Auto-finds ExileSpawnZone markers
- **Rewards**: Integrates with Poptabs/Respect (needs server config)

## Performance

- **Spawn Rate**: Every 30 minutes (configurable)
- **Max Convoys**: 2 concurrent
- **Update Rate**: 10 seconds
- **Cleanup**: Automatic on completion/destruction
- **AI Count**: 6-12 per convoy (2-4 vehicles × 3 crew)

## Troubleshooting

### Convoys not spawning
- Check Elite Driving is loaded first
- Verify at least 2 ExileSpawnZone markers exist
- Ensure zones are 1000m+ apart
- Check debug messages

### Vehicles not moving
- **Most Common**: Elite Driving not loaded
- Check `EAID_Ignore = false` on vehicles
- Verify Elite Driving initialized (`EAID_Initialized`)
- Look for "stuck" messages in Elite Driving logs

### Reinforcements not spawning
- Set `callReinforcements = true`
- Check 1 minute passed since attack
- Verify `reinforcementsCalled` flag not already set

### Convoy stuck on obstacles
- Elite Driving handles obstacles automatically
- Convoy recalculates route every 5 minutes
- Check terrain between trader zones
- Increase `convoySpeed` to "NORMAL" or "FULL"

## Tips for Server Admins

### Balancing Difficulty
- **Easy**: 2 vehicles, no reinforcements, slow speed
- **Medium**: 3 vehicles, reinforcements enabled, limited speed
- **Hard**: 4 vehicles, instant reinforcements, full speed

### Adjusting Rewards
- Increase `lootMultiplier` for higher value
- Adjust `lootMoney` range for economy balance
- Enable/disable `traderStockBonus` for server impact

### Performance Optimization
- Reduce `maxActiveConvoys` to 1
- Increase `spawnInterval` to 3600 (1 hour)
- Limit `maxVehicles` to 2-3

## Changelog

### v1.0 (2025-01-XX)
- Initial release
- Elite Driving integration
- 5 mission types
- Air support system
- Trader bonus mechanics
- Real-time marker tracking
