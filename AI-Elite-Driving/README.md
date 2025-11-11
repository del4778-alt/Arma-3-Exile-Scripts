# AI Elite Driving System

**Enhanced AI vehicle handling and combat driving for Arma 3 Exile servers.**

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![Arma 3](https://img.shields.io/badge/Arma%203-compatible-green.svg)

---

## 🎯 Features

- ✅ **Side-specific configuration** (BLUFOR, OPFOR, Independent, Civilian)
- ✅ **Dynamic speed adjustment** based on threat level
- ✅ **Vehicle-type awareness** (light/heavy/armored)
- ✅ **Combat vs. safe driving modes**
- ✅ **Automatic headlight control**
- ✅ **Damage-based speed reduction**
- ✅ **Realistic AI behavior**

---

## 📥 Quick Download

**Download just this script:**
- [AI_EliteDriving.sqf](AI_EliteDriving.sqf) - Right-click → Save As

**Or clone the repository:**
```bash
git clone https://github.com/del4778-alt/Arma-3-Exile-Scripts.git
cd Arma-3-Exile-Scripts/AI-Elite-Driving
```

---

## 🚀 Installation

### Step 1: Add Script to Mission

Place `AI_EliteDriving.sqf` in your mission folder:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    └── AI_EliteDriving.sqf
```

### Step 2: Initialize from initServer.sqf

Add to your `initServer.sqf`:
```sqf
// Load Elite AI Driving
if (isServer) then {
    [] execVM "scripts\AI_EliteDriving.sqf";
};
```

### Step 3: Restart Server

---

## ⚙️ Configuration

### Configure Which Sides Use Elite Driving

Edit around line 15 in the script:

```sqf
// Configure which sides use Elite Driving
ELITE_DRIVING_SIDES = [
    independent,  // AI missions (DMS, VEMF, etc.)
    east,         // OPFOR AI
    west          // BLUFOR AI
    // civilian   // Uncomment to include civilians
];
```

**Available sides:**
- `independent` - Independent faction (most AI missions)
- `east` - OPFOR/Eastern forces
- `west` - BLUFOR/Western forces
- `civilian` - Civilian vehicles

### Adjust Speed Parameters

Edit in the script:

```sqf
// Combat Speed (enemies nearby)
_combatSpeed = 40;  // km/h

// Safe Speed (no threats)
_safeSpeed = 80;    // km/h

// Update Interval
_updateInterval = 5; // seconds
```

---

## 📊 How It Works

### Speed Adjustment Logic

1. **Threat Detection**
   - Checks for enemies within 500m
   - Adjusts speed based on threat level

2. **Vehicle Type Awareness**
   - Light vehicles: Faster speeds
   - Heavy vehicles: Moderate speeds
   - Armored vehicles: Combat-oriented speeds

3. **Combat Mode**
   - Enemies nearby: Reduced speed (40 km/h)
   - Enables tactical maneuvering

4. **Safe Mode**
   - No enemies: Normal speed (80 km/h)
   - Efficient travel

5. **Damage-Based Reduction**
   - Damaged vehicles slow down
   - Realistic mechanical limitations

---

## 🎮 Features Explained

### Dynamic Speed Adjustment
AI vehicles automatically adjust speed based on:
- Proximity to enemies
- Vehicle damage state
- Vehicle type
- Terrain difficulty

### Automatic Headlight Control
- Lights on during night/low visibility
- Lights off during day
- Automatic toggle based on time

### Realistic Behavior
- AI drivers react to threats
- Slow down for damaged vehicles
- Maintain formation speed
- Avoid excessive speeds on rough terrain

---

## 🔧 Performance

| Aspect | Impact |
|--------|--------|
| CPU Usage | Very Low |
| Check Frequency | Every 5 seconds per vehicle |
| Memory | Minimal |
| Network | None (server-side only) |

---

## 🎯 Use Cases

### AI Mission Mods
Perfect for:
- **DMS (Defent's Mission System)**
- **VEMF Reloaded**
- **Occupation**
- **Custom AI missions**

### Server Events
- AI convoys
- Patrol vehicles
- Enemy vehicle patrols
- Dynamic AI spawns

### Exile Gameplay
- Enhances AI vehicle behavior
- More challenging AI encounters
- Realistic AI driving
- Better AI tactical response

---

## 🆘 Troubleshooting

### AI Vehicles Not Slowing Down

**Check:**
- Script is loaded (check RPT logs)
- Correct side is configured in `ELITE_DRIVING_SIDES`
- No script errors in RPT

**Solution:**
Ensure your AI spawning script runs AFTER Elite Driving initialization.

### Vehicles Too Slow/Fast

**Adjust:**
```sqf
_combatSpeed = 60;  // Increase from 40
_safeSpeed = 100;   // Increase from 80
```

### Script Not Working for Custom AI

**Make sure:**
AI vehicles belong to a side in `ELITE_DRIVING_SIDES`.

Check AI side:
```sqf
_side = side _vehicle;
diag_log format ["Vehicle side: %1", _side];
```

---

## 📝 Default Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Combat Speed | 40 km/h | Speed when enemies nearby |
| Safe Speed | 80 km/h | Speed when no threats |
| Update Interval | 5 seconds | How often to check vehicles |
| Threat Range | 500m | Enemy detection distance |

---

## 🔄 Compatibility

### ✅ Works With:
- DMS Mission System
- VEMF Reloaded
- Occupation
- A3XAI
- Custom AI spawning scripts
- Exile Mod

### ⚠️ May Conflict With:
- Other AI driving enhancement mods
- Scripts that override vehicle behavior
- Mods that lock AI vehicle speeds

---

## 💡 Tips

### For Best Results:
1. Configure only the sides you actually use
2. Adjust speeds based on your server's AI difficulty
3. Test with different vehicle types
4. Monitor performance with many vehicles

### Recommended Settings:
```sqf
// Balanced for most servers
_combatSpeed = 40;
_safeSpeed = 80;
_updateInterval = 5;
```

### Aggressive AI:
```sqf
_combatSpeed = 60;
_safeSpeed = 100;
_updateInterval = 3;
```

### Conservative/Tactical:
```sqf
_combatSpeed = 30;
_safeSpeed = 60;
_updateInterval = 7;
```

---

## 📈 Version History

### v1.0 - Latest
- Side-specific configuration
- Dynamic speed adjustment
- Vehicle-type awareness
- Combat/safe modes
- Headlight automation
- Damage-based reduction

---

## 🆘 Support

### Reporting Issues
Include:
- Server RPT logs
- AI spawn method (DMS, VEMF, etc.)
- Vehicle types affected
- Side configuration

### Resources
- **GitHub Issues:** [Report a bug](https://github.com/del4778-alt/Arma-3-Exile-Scripts/issues)
- **Arma 3 Forums:** https://forums.bohemia.net/

---

## 📄 License

Free to use and modify for your Arma 3 server.
Please give credit if you redistribute.

---

## 🙏 Credits

- **Script Author:** del4778-alt
- **Arma 3 Community:** Inspiration and support

---

**Last Updated:** 2025
**Version:** 1.0
**Tested On:** Arma 3 v2.18+, Exile 1.0.4+
