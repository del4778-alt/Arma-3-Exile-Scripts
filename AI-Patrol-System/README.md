# AI Patrol System

**Dynamic patrol routes for AI squads with intelligent waypoint placement and squad leader coordination.**

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![Arma 3](https://img.shields.io/badge/Arma%203-compatible-green.svg)

---

## 🎯 Features

- ✅ **Dynamic waypoint generation**
- ✅ **Squad leader coordination**
- ✅ **Automatic patrol route creation**
- ✅ **Building and cover awareness**
- ✅ **Looping patrol routes**
- ✅ **Configurable patrol radius and waypoint count**
- ✅ **Terrain-aware placement**

---

## 📥 Quick Download

**Download just this script:**
- [fn_aiPatrolSystem.sqf](fn_aiPatrolSystem.sqf) - Right-click → Save As

**Or clone the repository:**
```bash
git clone https://github.com/del4778-alt/Arma-3-Exile-Scripts.git
cd Arma-3-Exile-Scripts/AI-Patrol-System
```

---

## 🚀 Installation

### Step 1: Add Script to Mission

Place `fn_aiPatrolSystem.sqf` in your mission folder:
```
Exile.YourMap/
├── initServer.sqf
└── scripts/
    └── fn_aiPatrolSystem.sqf
```

### Step 2: Compile Function

Add to your `initServer.sqf`:
```sqf
// Compile AI Patrol Function
if (isServer) then {
    fnc_aiPatrolSystem = compile preprocessFileLineNumbers "scripts\fn_aiPatrolSystem.sqf";
};
```

### Step 3: Use in Your Scripts

---

## 💻 Usage

### Basic Patrol

```sqf
// Create patrol for a group around a position
[_aiGroup, _centerPosition, 200] call fnc_aiPatrolSystem;
```

### Advanced Patrol

```sqf
// Full parameters
[
    _aiGroup,           // Group to patrol
    _centerPosition,    // Center of patrol area [x,y,z]
    _radius,           // Patrol radius in meters
    _waypointCount     // Number of waypoints (optional, default: 4)
] call fnc_aiPatrolSystem;
```

### Example with DMS Mission

```sqf
// In your DMS mission file
_aiGroup = createGroup independent;

// Spawn AI units
for "_i" from 0 to 5 do {
    _unit = _aiGroup createUnit ["I_Soldier_F", _missionCenter, [], 0, "FORM"];
};

// Set up patrol with 6 waypoints in 150m radius
[_aiGroup, _missionCenter, 150, 6] call fnc_aiPatrolSystem;
```

### Example with VEMF

```sqf
// After VEMF spawns AI group
[_aiGroup, getPos _aiLeader, 200, 5] call fnc_aiPatrolSystem;
```

### Example with Custom AI

```sqf
// Create group
_grp = createGroup independent;

// Spawn units
_pos = [1000, 2000, 0];
for "_i" from 0 to 3 do {
    _unit = _grp createUnit ["O_Soldier_F", _pos, [], 5, "FORM"];
};

// Start patrol
[_grp, _pos, 250, 8] call fnc_aiPatrolSystem;
```

---

## ⚙️ Configuration

### Patrol Parameters

```sqf
[
    _aiGroup,          // The AI group
    _centerPosition,   // [x, y, z] or object
    _radius,          // 50 to 500 (recommended)
    _waypointCount    // 3 to 12 (default: 4)
] call fnc_aiPatrolSystem;
```

### Waypoint Timeout

Edit in the function:
```sqf
_waypointTimeout = [10, 20, 30];  // [min, mid, max] seconds

// More aggressive patrol:
_waypointTimeout = [5, 10, 15];

// Slower, defensive patrol:
_waypointTimeout = [20, 30, 40];
```

### Waypoint Behavior

Edit in the function:
```sqf
_wp setWaypointBehaviour "AWARE";   // or "SAFE", "COMBAT"
_wp setWaypointCombatMode "YELLOW"; // or "RED", "GREEN"
_wp setWaypointSpeed "LIMITED";     // or "NORMAL", "FULL"
```

---

## 📊 How It Works

### Waypoint Generation

1. **Calculate Perimeter Points**
   - Distributes waypoints evenly around circle
   - Uses radius to define patrol area

2. **Squad Leader Assignment**
   - First unit becomes squad leader
   - Other units follow leader's commands
   - Leader controls patrol route

3. **Waypoint Settings**
   - Type: Move
   - Timeout: Random delay at each point
   - Formation: Group stays together
   - Completion: Cycles back to start

4. **Loop Behavior**
   - Last waypoint cycles to first
   - Continuous patrol
   - Never ends until group eliminated

---

## 🎮 Features Explained

### Squad Leader Coordination
- First unit in group becomes leader
- Leader navigates waypoints
- Other units maintain formation
- Cohesive group movement

### Dynamic Waypoints
- Placed around perimeter of radius
- Avoid extreme terrain
- Distributed evenly
- Return to start point

### Patrol Behaviors

**AWARE Mode (Default):**
- Medium alertness
- Balanced speed
- Tactical movement

**SAFE Mode:**
- Low alertness
- Normal walking speed
- Casual patrol

**COMBAT Mode:**
- High alertness
- Combat ready
- Aggressive posture

---

## 💡 Usage Examples

### Small Building Patrol (50m)
```sqf
[_grp, getPos _building, 50, 4] call fnc_aiPatrolSystem;
```

### Town Patrol (200m)
```sqf
[_grp, _townCenter, 200, 8] call fnc_aiPatrolSystem;
```

### Perimeter Defense (500m)
```sqf
[_grp, _baseCenter, 500, 12] call fnc_aiPatrolSystem;
```

### Road Checkpoint
```sqf
[_grp, _roadPosition, 100, 6] call fnc_aiPatrolSystem;
```

---

## 🎯 Recommended Settings

### For Different Scenarios

#### **Building Interior**
```sqf
[_grp, _pos, 30, 3] call fnc_aiPatrolSystem;
```

#### **Small Compound**
```sqf
[_grp, _pos, 75, 4] call fnc_aiPatrolSystem;
```

#### **Town Patrol**
```sqf
[_grp, _pos, 150, 6] call fnc_aiPatrolSystem;
```

#### **Large Base**
```sqf
[_grp, _pos, 300, 10] call fnc_aiPatrolSystem;
```

#### **Perimeter Defense**
```sqf
[_grp, _pos, 500, 12] call fnc_aiPatrolSystem;
```

---

## 🔧 Advanced Customization

### Modify Waypoint Type

In the function, change:
```sqf
_wp = _group addWaypoint [_wpPos, 0];
_wp setWaypointType "MOVE";  // Change to "HOLD", "GUARD", etc.
```

**Available types:**
- `"MOVE"` - Move to position (default)
- `"HOLD"` - Hold position
- `"GUARD"` - Guard area
- `"PATROL"` - Patrol movement
- `"SCRIPTED"` - Custom script

### Add Completion Statement

```sqf
_wp setWaypointStatements [
    "true",
    "hint 'Waypoint reached!';"
];
```

### Custom Formation

```sqf
_wp setWaypointFormation "COLUMN";  // "LINE", "VEE", "WEDGE", etc.
```

---

## 🔄 Integration Examples

### DMS Mission Integration

```sqf
// In your DMS mission file after spawning AI
{
    if (count (units _x) > 0) then {
        [_x, _missionCenter, 200, 6] call fnc_aiPatrolSystem;
    };
} forEach [_AIGroup1, _AIGroup2, _AIGroup3];
```

### VEMF Integration

```sqf
// In VEMF config after AI spawn
{
    [_x, VEMFrMissionCenter, 150] call fnc_aiPatrolSystem;
} forEach VEMFrAIGroups;
```

### Occupation Integration

```sqf
// Hook into Occupation's AI spawn
PARAMS_OccupationSpawn = {
    params ["_group", "_position"];
    [_group, _position, 250, 8] call fnc_aiPatrolSystem;
};
```

---

## 📈 Performance

| Setting | Impact |
|---------|--------|
| Waypoint Count | Low - calculated once |
| Patrol Radius | None - only affects placement |
| Group Size | None - handled by game engine |
| Multiple Groups | Minimal - independent patrols |

**Performance Tips:**
- Keep waypoint count reasonable (4-12)
- Use appropriate radius for area
- Don't create thousands of simultaneous patrols

---

## 🆘 Troubleshooting

### AI Not Moving

**Check:**
- Group has units: `count (units _group) > 0`
- Group not empty
- Position is valid

**Solution:**
```sqf
if (count (units _group) > 0) then {
    [_group, _pos, 200] call fnc_aiPatrolSystem;
};
```

### Waypoints Too Close/Far

**Adjust radius:**
```sqf
// Too close
[_grp, _pos, 100, 4] call fnc_aiPatrolSystem;  // Increase to 200

// Too far
[_grp, _pos, 500, 4] call fnc_aiPatrolSystem;  // Decrease to 300
```

### AI Stuck

**Check terrain:**
- Waypoints may be on water
- Extreme elevation changes
- Buildings blocking path

**Solution:** Reduce radius or adjust center position

---

## 🔄 Compatibility

### ✅ Works With:
- **DMS** (Defent's Mission System)
- **VEMF Reloaded**
- **Occupation**
- **A3XAI**
- **Custom AI spawning**
- **Any AI group**

### ⚠️ Conflicts With:
- Scripts that override AI waypoints
- Mods that control AI movement
- Other patrol systems (use one only)

---

## 📝 Parameters Reference

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `_aiGroup` | GROUP | Yes | - | AI group to patrol |
| `_centerPosition` | ARRAY/OBJECT | Yes | - | Center point [x,y,z] |
| `_radius` | NUMBER | Yes | - | Patrol radius (meters) |
| `_waypointCount` | NUMBER | No | 4 | Number of waypoints |

---

## 💡 Tips & Best Practices

1. **Match radius to area**
   - Small buildings: 50-100m
   - Town sectors: 150-250m
   - Large bases: 300-500m

2. **Appropriate waypoint count**
   - Small patrols: 3-4 waypoints
   - Medium: 6-8 waypoints
   - Large: 10-12 waypoints

3. **Test your setup**
   - Spawn in-game and watch AI
   - Adjust based on behavior
   - Check for stuck units

4. **Use with vehicle patrols**
   ```sqf
   // AI in vehicles
   [_vehicleGroup, _pos, 800, 6] call fnc_aiPatrolSystem;
   ```

---

## 🆘 Support

### Reporting Issues
Include:
- Group size
- Position/map
- Radius and waypoint count
- AI behavior description

### Resources
- **GitHub Issues:** [Report a bug](https://github.com/del4778-alt/Arma-3-Exile-Scripts/issues)

---

## 📄 License

Free to use and modify for your Arma 3 server.
Please give credit if you redistribute.

---

## 🙏 Credits

- **Script Author:** del4778-alt
- **Arma 3 Community:** BIS functions and support

---

**Last Updated:** 2025
**Version:** 1.0
**Tested On:** Arma 3 v2.18+
