# Elite AI Recruit System v3.9.2 - Arma 3 ExileMod

An advanced AI recruitment system for Arma 3 ExileMod that automatically spawns and manages elite AI squadmates with god-tier combat capabilities.

## 🎯 Features

### Core Functionality
- **Automatic Squad Management**: Spawns 3 elite AI squadmates (Anti-Air, Anti-Tank, Sniper)
- **God-Tier Combat Skills**: All skills maxed at 1.0 (perfect accuracy, spotting, reload speed)
- **Ultra-Aggressive Behavior**: COMBAT + RED mode - AI actively hunts and engages enemies
- **Enhanced Movement**: 1.4x speed boost - AI moves faster than players
- **Fearless Combat**: allowFleeing 0 - AI never retreats or surrenders
- **Perfect Accuracy**: EXTREME mode enabled - ignores suppression, perfect aim

### AI Roles & Loadouts

#### 🎯 Anti-Air Specialist (AA)
- **Primary Weapon**: Navid MMG (9.3mm) with ARCO optic, IR laser, bipod
- **Launcher**: Titan AA (pre-loaded, ready to fire)
- **Equipment**: Rangefinder, smoke grenades, HE grenades
- **Magazine Count**: 3x 150-round belts

#### 🚀 Anti-Tank Specialist (AT)
- **Primary Weapon**: AK-12 (7.62mm) with full attachments (optic, suppressor, bipod, IR laser)
- **Launcher**: RPG-42 Alamut (pre-loaded)
- **Equipment**: Rangefinder, toolkits, smoke & HE grenades
- **Magazine Count**: 8x 30-round mags

#### 🎯 Sniper
- **Primary Weapon**: GM6 Lynx .50 cal with LRPS optic
- **Ammunition**: APDS (armor-piercing) rounds
- **Equipment**: Laser designator, rangefinder, advanced medical supplies
- **Magazine Count**: 8x 5-round mags
- **Note**: GM6 only supports optics (no suppressors or bipods)

### Advanced Features

#### 🚗 Vehicle Management
- **Instant Teleport Boarding**: AI teleports into vehicles within 300m radius
- **Smart Seat Assignment**: AI fills Driver → Commander → Gunner → Cargo positions
- **Auto-Exit**: AI automatically exits when player dismounts
- **Speed-Based Logic**: Safe exits only when vehicle is slow/stopped

#### 🎯 Combat Intelligence
- **Enhanced Detection**: 1500m visual detection, 2000m audio detection
- **Enemy Callouts**: Audio warnings with distance and direction
- **Tactical Awareness**: AI identifies threats, vehicles, and provides combat feedback
- **Target Validation**: Verifies targets are actual enemies before engaging

#### 🔄 Squad Management
- **VEE Formation**: Maintains tactical VEE formation automatically
- **Auto-Follow**: AI stays close and maintains formation distance
- **Respawn Handling**: Cleans up AI on player death, respawns after 15s cooldown
- **Auto-Rearm**: Checks ammo every 30s, auto-resupplies from nearby ammo sources

#### ⚔️ Faction Configuration
- **RESISTANCE/INDEPENDENT Faction**: AI belongs to this faction
- **Hostile to EAST**: Automatically engages EAST (enemy) units
- **Neutral to WEST**: Configurable for future zombie/AI compatibility

## 📋 Requirements

- **Arma 3**: Any version
- **ExileMod**: Any version
- **Server Access**: Ability to modify mission files
- **No ACE Required**: Uses only Exile and vanilla Arma 3 items

## 🔧 Installation

### Method 1: Mission File Installation (Client-Side)

1. **Download the Script**
   ```
   Download recruit_ai.sqf from this repository
   ```

2. **Add to Mission Root**
   - Extract your mission PBO (e.g., `Exile.Altis.pbo`)
   - Place `recruit_ai.sqf` in the root folder of your mission

3. **Edit init.sqf**
   - Open (or create) `init.sqf` in the mission root
   - Add this line at the bottom:
   ```sqf
   [] execVM "recruit_ai.sqf";
   ```

4. **Repack Mission PBO**
   - Repack your mission folder as a PBO
   - Upload to server's `MPMissions` folder
   - Restart mission/server

### Method 2: Server-Side Installation (Recommended)

1. **Add to Server Addon**
   - Place `recruit_ai.sqf` in your server addon folder
   - Example: `@ExileServer\addons\exile_server\scripts\`

2. **Modify config.cpp**
   - Add reference to the script in your server config
   ```cpp
   class CfgExileCustomCode
   {
       ExileServer_object_player_createBambi = "exile_server\scripts\recruit_ai.sqf";
   };
   ```

3. **Alternative: Direct Execution**
   - Add to your server's `initServer.sqf`:
   ```sqf
   [] execVM "path\to\recruit_ai.sqf";
   ```

### Method 3: Player addAction (Optional - For Manual Spawning)

If you want players to manually recruit AI:

```sqf
player addAction [
    "Recruit Elite Squad",
    {
        [] execVM "recruit_ai.sqf";
    },
    [],
    1.5,
    true,
    true,
    "",
    "true",
    5
];
```

## ⚙️ Configuration

Edit these variables at the top of the script to customize behavior:

```sqf
// Maximum AI squadmates (default: 3)
private _maxSquadmates = 3;

// Detection ranges
RECRUIT_VEHICLE_BOARD_RADIUS = 300;      // Vehicle auto-board distance
RECRUIT_DETECTION_RADIUS = 1500;          // Enemy visual detection
RECRUIT_AUDIO_DETECTION_RADIUS = 2000;    // Sound detection
RECRUIT_CALLOUT_INTERVAL = 8;             // Enemy callout frequency (seconds)
RECRUIT_REARM_CHECK_INTERVAL = 30;        // Ammo check interval (seconds)
RECRUIT_RESPAWN_COOLDOWN = 15;            // Delay after respawn (seconds)
```

### Customizing AI Roles

To modify AI loadouts, edit the `RECRUIT_fnc_rearmUnit` function (starts at line 180).

### Changing Faction Relations

Modify the faction configuration section (lines 54-75) to change who AI fights:

```sqf
// Make AI hostile to EAST
RESISTANCE setFriend [EAST, 0];
EAST setFriend [RESISTANCE, 0];

// Make AI friendly to WEST
RESISTANCE setFriend [WEST, 1];
WEST setFriend [RESISTANCE, 1];
```

## 🎮 Usage

### Automatic Mode (Default)
- AI automatically spawns when you join the server
- Maximum of 3 AI squadmates at all times
- Respawns automatically after death (15s cooldown)

### In-Game Controls
- **Vehicle Boarding**: Get within 300m of a vehicle, AI auto-boards
- **Formations**: AI maintains VEE formation automatically
- **Following**: AI follows player, maintains distance
- **Combat**: AI engages enemies independently and aggressively

### Chat Commands & Feedback
- System messages appear in chat for:
  - AI spawn notifications
  - Enemy contact callouts (with distance and direction)
  - Vehicle boarding status
  - Rearm notifications
  - Respawn cooldown status

## 🐛 Troubleshooting

### AI Not Spawning
- Check that script is called from `init.sqf`
- Verify no script errors in RPT logs
- Confirm 15-second respawn cooldown has passed
- Check `RECRUIT_RespawnInProgress` flag isn't stuck

### AI Not Following
- Verify VEE formation is set: `(group player) setFormation "VEE"`
- Check AI are in same group as player
- Confirm AI have `ExileRecruited` variable set

### AI Not Boarding Vehicles
- Check vehicle is within 300m
- Verify vehicle has empty seats
- Ensure vehicle isn't moving too fast
- Check that player is already in vehicle

### AI Fleeing from Combat
- Should never happen with this script (allowFleeing = 0)
- If it occurs, check that setBehaviour "COMBAT" is applied
- Verify all skills are set to 1.0

### Script Errors
- Check RPT logs in: `C:\Users\[YourName]\AppData\Local\Arma 3\`
- Common issues:
  - Missing semicolons
  - Invalid weapon/item classnames
  - Syntax errors after modifications

## 📝 Changelog

### v3.9.2 (Latest)
- ✅ Removed invalid GM6 Lynx attachments (optic only)
- ✅ Removed redundant NVGoggles (helmet has built-in NVG)
- ✅ Fixed duplicate weapon loadouts
- ✅ Cleaned up gear assignment logic

### v3.9.1
- ✅ Fixed checkVisibility syntax error (line 126)
- ✅ Fixed nearestObjects performance issue (line 406)
- ✅ Fixed rearm logic critical bug (line 483)
- ✅ AT specialist now uses AK-12 with full attachments
- ✅ Sniper now uses GM6 Lynx .50 cal with APDS rounds

### v3.9
- ✅ Fixed cleanup system for orphaned AI
- ✅ Added respawn cooldown system
- ✅ Fixed "Object not found" errors
- ✅ Improved unit validation checks

## ⚠️ Warnings

### Performance Considerations
- **High-End AI**: These AI are extremely resource-intensive
- **Server Impact**: May affect server FPS with many players
- **Recommended**: Test on development server first
- **Monitor**: Watch server performance and adjust `_maxSquadmates` if needed

### Balance Considerations
- **Extremely Powerful**: AI have perfect accuracy and god-tier skills
- **PvP Impact**: May create balance issues in PvP servers
- **Difficulty**: Makes PvE content significantly easier
- **Recommendation**: Consider reducing skill values for balanced gameplay

### Known Limitations
- GM6 Lynx only supports optics (engine limitation)
- AI may struggle with complex vehicle maneuvers
- Heavy vehicle traffic may cause boarding issues
- Large-scale battles may impact performance

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly on a development server
4. Submit a pull request with detailed description

## 📄 License

This script is provided as-is for Arma 3 ExileMod communities.
Free to use, modify, and distribute with credit.

## 🙏 Credits

- **Author**: [Your Name/Handle]
- **Version**: 3.9.2 (Final)
- **Tested On**: Arma 3 v2.18+ / ExileMod 1.0.4+
- **Community**: ExileMod Community

## 📞 Support

- **Issues**: Report bugs via GitHub Issues
- **Questions**: Check ExileMod forums or Discord
- **Updates**: Watch this repository for updates

---

### Quick Start Summary
1. Download `recruit_ai.sqf`
2. Add to mission root
3. Add `[] execVM "recruit_ai.sqf";` to `init.sqf`
4. Repack PBO and restart server
5. AI spawns automatically on player join

**Enjoy your elite AI squad!** 🎯🚁💥
