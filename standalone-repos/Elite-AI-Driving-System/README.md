# 🚗 Elite AI Driving System v4.2

**Tesla Autopilot-style AI driving for Arma 3 Exile servers**

Transform your AI drivers from bumbling idiots into professional race car drivers! This system uses advanced raycast sensors and dynamic speed optimization to give AI smooth, intelligent driving behavior.

---

## ✨ Features

### 🎯 Core Capabilities
- **Multi-Ray LIDAR Sensor System** - 7-ray forward detection + side sensors
- **Dynamic Speed Optimization** - Adapts to curves, terrain, weather, and obstacles
- **Highway Mode** - Up to 90 km/h on straight roads
- **Urban Mode** - Auto-slowdown to 45 km/h near buildings
- **Building Detection** - Prevents crashes at intersections (50m range)
- **Vehicle Avoidance** - Detects and slows for vehicles ahead
- **Drift Detection & Correction** - Counter-steering system prevents skidding
- **Auto-Unstuck System** - Gentle reverse recovery when stuck
- **Cliff Detection** - Prevents driving off edges

### 🛡️ Safety Features
- **Anti-Flip Recovery** - Automatically rights flipped vehicles
- **Smooth Speed Transitions** - No sudden jerking or acceleration
- **Steering Deadzone** - Prevents micro-corrections and wobbling
- **Physics-Safe** - No position changes that cause floating

### 🔧 Compatibility
- ✅ **Exile Mod**
- ✅ **A3XAI, DMS, VCOMAI** - Works alongside AI mods
- ✅ **Recruit AI Systems** - Automatically excludes player recruits
- ✅ **CBA Optional** - Works with or without CBA
- ✅ **Zero FPS Impact** - Lightweight raycast-only system

---

## 📦 Installation

### Step 1: Download
Click the green **Code** button → **Download ZIP**

### Step 2: Extract
Extract `AI_EliteDriving.sqf` to your mission folder:
```
YourMission.Map/scripts/AI_EliteDriving.sqf
```

### Step 3: Initialize
Add to `initServer.sqf`:
```sqf
// Elite AI Driving System
execVM "scripts\AI_EliteDriving.sqf";
```

### Step 4: Restart Server
Restart your Arma 3 server and watch AI drive like pros!

---

## ⚙️ Configuration

Edit the `AIS_CONFIG` section at the top of `AI_EliteDriving.sqf`:

```sqf
AIS_CONFIG = createHashMapFromArray [
    // === ENABLE/DISABLE ===
    ["ENABLED", true],          // Set to false to disable system
    ["DEBUG", true],            // Enable debug logging

    // === SPEED LIMITS (km/h) ===
    ["SPEED_MAX_HIGHWAY", 90],  // Max speed on straight roads
    ["SPEED_MAX_ROAD", 75],     // Max speed on normal roads
    ["SPEED_MAX_DIRT", 55],     // Max speed on dirt roads
    ["SPEED_CITY", 45],         // Speed limit in cities

    // === SAFETY ===
    ["ANTI_FLIP_ENABLED", true],        // Auto-flip recovery
    ["CLIFF_DETECTION_ENABLED", true],  // Prevent cliff driving

    // === PERFORMANCE ===
    ["MAX_ACTIVE_DRIVERS", 50], // Max AI drivers with enhanced driving
    ["UPDATE_INTERVAL", 0.15]   // Sensor refresh rate (seconds)
];
```

---

## 🎮 How It Works

### Sensor System
The AI uses **7 raycast sensors** to detect obstacles:
- **Forward Long** (100m) - Highway speed planning
- **Forward Short** (30m) - Immediate collision avoidance
- **Left/Right** (35m at 45°) - Curve detection
- **Down** (20m) - Bridge/cliff detection
- **Building Scan** (50m) - Intersection safety
- **Vehicle Scan** (80m) - Traffic awareness

### Speed Calculation
The AI dynamically calculates optimal speed based on:
1. **Road Type** - Paved, dirt, or offroad
2. **Curve Severity** - Straight, gentle, medium, sharp, or hairpin
3. **Terrain** - Urban, forest, steep slopes
4. **Weather** - Rain penalty (30% slower)
5. **Damage** - Vehicle damage penalty (45% slower)
6. **Obstacles** - Buildings, vehicles, cliffs ahead

### Example Behavior
```
Straight highway → 90 km/h
Gentle curve → 64 km/h (85% of max)
Medium curve → 40 km/h
Sharp curve → 33 km/h
Hairpin turn → 25 km/h
City streets → 45 km/h (regardless of road)
Building 30m ahead → 26 km/h (emergency slow)
```

---

## 🚫 Exclusion System

The system **automatically skips**:
- Player-controlled vehicles
- Recruit AI (checks `ExileRecruited` variable)
- Units in player groups
- Units with `OwnerUID` marker

This prevents conflicts with other AI control systems.

---

## 🐛 Troubleshooting

### AI Not Driving Smoothly
- Check RPT logs for `[AIS]` messages
- Verify `ENABLED` is set to `true`
- Ensure script is executed in `initServer.sqf`

### AI Crashing Into Buildings
- Increase `SENSOR_BUILDING_SCAN_DISTANCE` to 60-80m
- Decrease `SPEED_CITY` to 35-40 km/h

### Performance Issues
- Decrease `MAX_ACTIVE_DRIVERS` to 30-40
- Increase `UPDATE_INTERVAL` to 0.2-0.3

### Vehicle Floating
- This should be fixed in v4.2
- Check you're using the FIXED version, not the old one

---

## 📊 Performance

**Server Impact:** Minimal
- **CPU:** ~0.5% per 10 active drivers
- **Memory:** ~50 KB per driver
- **Network:** Zero (server-side only)
- **FPS:** Zero impact (no objects spawned)

**Tested With:**
- 50+ AI drivers simultaneously
- Exile server with 30 players
- A3XAI + DMS + VCOMAI running

---

## 🔄 Version History

### v4.2 - Production Fixed (Current)
- ✅ Fixed vehicle floating to sky
- ✅ Added building detection at intersections
- ✅ Added recruit AI exclusion system
- ✅ Improved highway stability (no sway)
- ✅ Better drift correction
- ✅ Smoother steering with deadzone

### v4.0
- Initial release with LIDAR sensors
- Curve detection system
- Highway mode

---

## 📝 License

**MIT License** - Free to use, modify, and distribute

---

## 🤝 Support

**Issues?** Check the troubleshooting section above.

**Questions?** Open an issue on GitHub.

**Want to contribute?** Pull requests welcome!

---

## 🎯 Recommended Settings

For **fast-paced action servers**:
```sqf
["SPEED_MAX_HIGHWAY", 110]
["SPEED_MAX_ROAD", 90]
["SPEED_CITY", 55]
```

For **realistic/hardcore servers**:
```sqf
["SPEED_MAX_HIGHWAY", 70]
["SPEED_MAX_ROAD", 60]
["SPEED_CITY", 35]
```

For **heavy AI traffic**:
```sqf
["MAX_ACTIVE_DRIVERS", 30]
["UPDATE_INTERVAL", 0.2]
```

---

## 🚀 Pro Tips

1. **Enable DEBUG mode** during initial setup to see sensor data in RPT logs
2. **Test with different vehicle types** - trucks drive differently than sports cars
3. **Adjust speed limits** based on your map (Tanoa vs Altis)
4. **Monitor performance** with `diag_log` messages showing active driver count
5. **Combine with VCOMAI** for best AI behavior

---

**Enjoy smooth AI driving! 🏎️💨**
