# A3XAI Elite Edition - Simple Deployment Guide

## ✅ INSTALLATION (SAME AS ORIGINAL A3XAI)

### Step 1: Copy Files

Copy the `@A3XAI` folder to your Arma 3 server directory:

```
YourServer/
├── @ExileServer/
├── @A3XAI/              ← Copy this folder here
│   ├── addons/
│   │   ├── a3xai.pbo
│   │   └── a3xai_config.pbo
│   └── README.md
└── arma3server.exe
```

### Step 2: Update Startup Parameters

Add `@A3XAI` to your server startup parameters:

**Before:**
```
-serverMod=@ExileServer;
```

**After:**
```
-serverMod=@ExileServer;@A3XAI;
```

### Step 3: Start Server

That's it! The system auto-initializes.

---

## 🔧 CONFIGURATION (OPTIONAL)

### To Change Settings:

**1. Unpack a3xai_config.pbo:**
   - Navigate to: `@A3XAI/addons/`
   - Use PBO Manager or similar tool
   - Unpack `a3xai_config.pbo`

**2. Edit config.cpp:**
   - Open `config.cpp` in text editor
   - Change values as needed
   - Save file

**3. Repack a3xai_config.pbo:**
   - Use PBO Manager to repack
   - Replace in `@A3XAI/addons/`

**4. Restart server**

---

## 📝 QUICK SETTINGS

### Common Settings to Adjust:

```cpp
// In config.cpp (inside a3xai_config.pbo)

A3XAI_maxAIGlobal = 150;              // Lower if performance issues
A3XAI_minServerFPS = 20;              // Lower to allow spawning at lower FPS
A3XAI_spawnDistanceMin = 500;         // Distance from players
A3XAI_spawnDistanceMax = 2000;        // Maximum spawn distance

A3XAI_enableMissionMarkers = 1;       // 1=show markers, 0=hide
A3XAI_poptabsReward = 1;              // 1=give poptabs, 0=don't

// Blacklist zones (trader cities, etc.)
A3XAI_blacklistZones = [
    ["TraderCity", [14599, 16797, 0], 750]  // [name, [x,y,z], radius]
];
```

---

## ✔️ VERIFICATION

### Check RPT Log:

After server starts, look for:

```
[A3XAI] A3XAI ELITE EDITION v1.0.0
[A3XAI] Initialized in XXXms
[A3XAI] Max AI: 150 | Grid Size: 1000m
```

### Test AI Spawning:

1. Join server
2. Wait 30-60 seconds
3. Check for AI spawning nearby (500-2000m away)
4. Check RPT for spawn messages

### Monitor Performance:

Performance reports appear in RPT every 5 minutes:
```
[A3XAI] Server FPS: 42.3 (avg: 41.8)
[A3XAI] AI Units: 87/150
```

---

## 🛠️ DEVELOPMENT MODE (Folders Instead of PBOs)

For easier testing, you can use **folders** instead of PBOs:

### Structure:
```
@A3XAI/
├── addons/
│   ├── a3xai/              ← Folder (not PBO)
│   │   ├── config.cpp
│   │   ├── init.sqf
│   │   ├── functions/
│   │   └── scripts/
│   └── a3xai_config/       ← Folder (not PBO)
│       └── config.cpp
```

**When ready for production:** Pack folders into PBOs.

---

## 📦 BUILDING PBOs

### Option 1: PBO Manager (Windows - GUI)
1. Right-click folder (`a3xai` or `a3xai_config`)
2. Select "Pack into PBO"
3. Save as `a3xai.pbo` or `a3xai_config.pbo`

### Option 2: pack_pbo.py (Linux - Script)
```bash
# Pack main code
python3 pack_pbo.py \
    "@A3XAI/addons/a3xai" \
    "@A3XAI/addons/a3xai.pbo" \
    "A3XAI"

# Pack config
python3 pack_pbo.py \
    "@A3XAI/addons/a3xai_config" \
    "@A3XAI/addons/a3xai_config.pbo" \
    "A3XAI"
```

---

## 🎯 WHAT'S INCLUDED

### In a3xai.pbo (Main Code):
- All 49 function files
- Initialization system
- Monitoring scripts
- Mission types
- Spawn systems

### In a3xai_config.pbo (Configuration):
- config.cpp with all settings
- Easy to edit and repack
- No code changes needed

---

## 🚀 PERFORMANCE TIPS

### For Small Servers (< 20 players):
```cpp
A3XAI_maxAIGlobal = 80;
A3XAI_spawnDistanceMax = 1500;
```

### For Large Servers (50+ players):
```cpp
A3XAI_maxAIGlobal = 200;
A3XAI_spawnDistanceMax = 2500;
```

### For Low-Performance Hardware:
```cpp
A3XAI_maxAIGlobal = 60;
A3XAI_minServerFPS = 15;
A3XAI_spawnDistanceMax = 1000;
```

### With Headless Client:
```cpp
A3XAI_maxAIGlobal = 250;  // HC handles the load
// HC is auto-detected, no other config needed
```

---

## ❓ TROUBLESHOOTING

### "No AI spawning!"
- Check if players are online
- Check server FPS (must be above `A3XAI_minServerFPS`)
- Check RPT for errors
- Verify not in blacklist zone

### "Too many AI!"
- Lower `A3XAI_maxAIGlobal`
- Increase `A3XAI_spawnDistanceMin`

### "Server lagging!"
- Enable Headless Client
- Lower `A3XAI_maxAIGlobal`
- Increase `A3XAI_minServerFPS` threshold

### "Missions not spawning!"
- Wait 10 minutes (first mission spawn delay)
- Check `A3XAI_enableMissionMarkers` in config
- Check RPT for mission spawn messages

---

## 📖 FULL DOCUMENTATION

See included documentation files:
- **README.md** - Quick start guide
- **A3XAI_ELITE_INSTALLATION_GUIDE.md** - Complete guide
- **A3XAI_ELITE_PHASE2_COMPLETE.md** - Feature list
- **A3XAI_ELITE_REVIEW_AND_IMPROVEMENTS.md** - Technical details

---

## ✅ CHECKLIST

- [ ] Copied `@A3XAI` folder to server directory
- [ ] Added `@A3XAI` to startup parameters
- [ ] (Optional) Configured `a3xai_config.pbo`
- [ ] Started server
- [ ] Checked RPT logs for initialization
- [ ] Verified AI spawning
- [ ] Monitored performance

---

**That's it! Drop-in replacement for original A3XAI with enhanced features!**

**Version:** 1.0.0 Elite Edition
**Status:** Production Ready
