# Elite AI Driving System (EAD) v8.5

Advanced AI vehicle driving system with realistic physics-based navigation.

## Features

- **Velocity-based vehicle control** - Direct setVelocity for smooth, predictable driving
- **11-ray obstacle detection** - Comprehensive forward/side/corner scanning
- **Bridge detection** - Special handling for elevated roadways
- **Stuck recovery** - Automatic reverse maneuvers when blocked
- **Convoy behavior** - Intelligent follow-distance management
- **Emergency braking** - Collision avoidance at close range
- **Drift compensation** - Corrects lateral skidding
- **Terrain adaptation** - Adjusts speed for slopes, vegetation, road surfaces

## Installation

### Server-Side (init.sqf or mission init)

```sqf
[] execVM "Elite-AI-Driving\ead.sqf";
```

## Configuration

Edit the `EAD_CFG` hashmap at the top of `ead.sqf`:

```sqf
EAD_CFG = createHashMapFromArray [
    ["TICK", 0.10],              // Update frequency (seconds)
    ["HIGHWAY_BASE", 145],        // Base highway speed (km/h)
    ["CITY_BASE", 85],            // Base city speed (km/h)
    ["DEBUG_ENABLED", false]      // Enable debug logging
];
```

## Integration with Other AI Systems

### A3XAI Integration

EAD respects the `EAID_Ignore` flag. A3XAI vehicles should set this during spawn settling:

```sqf
_veh setVariable ["EAID_Ignore", true];  // Block EAD temporarily
// ... after waypoints configured ...
_veh setVariable ["EAID_Ignore", false]; // Allow EAD to take over
```

### AI Recruit System Integration

Works seamlessly with recruit AI drivers. When a recruit AI becomes a driver, EAD automatically takes control of vehicle navigation.

## Performance

- **0.1s tick rate** per vehicle (configurable)
- **~1-2ms avg** per vehicle per tick
- Auto-scaling based on vehicle count
- Minimal overhead when no AI drivers present

## Version History

### v8.5 (Current)
- **CRITICAL FIX**: Resolved A3XAI vehicle spinning issue
- EAD now disables AI PATH and AUTOTARGET when taking control
- Prevents conflict between EAD's direct control and AI waypoint pathfinding
- **NEW**: EAD steers toward AI group waypoints automatically
- Vehicles reach A3XAI objectives while maintaining smooth EAD control
- AI is properly re-enabled when EAD releases control

### v8.4
- Batch raycast processing (Arma 3 v2.20+)
- 22 raycasts per vehicle → 1 batch call
- ~10-15x faster obstacle detection
- Reduced CPU load for multiple AI vehicles

### v8.3
- Fixed hashMap string key usage for vehicle tracking
- Improved A3XAI integration with EAID_Ignore flag
- Enhanced stuck detection on bridges
- Optimized raycast performance

### v8.2
- Added bridge detection system
- Improved emergency braking logic
- Better convoy spacing

### v8.0
- Complete rewrite with velocity-based control
- Added 11-ray obstacle detection
- Implemented FSM-free design

## Compatibility

- **Arma 3**: 2.00+
- **Exile Mod**: All versions
- **A3XAI**: Compatible (use EAID_Ignore flag)
- **VCOMAI**: Compatible
- **Multiplayer**: Dedicated server + HC supported

## License

Free to use and modify. Credit appreciated but not required.
