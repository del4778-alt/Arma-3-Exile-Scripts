# A3XAI Elite Edition - Installation

## INSTALL (2 Steps)

**1. Copy `@A3XAI` to your server directory**

**2. Add to startup:**
```
-serverMod=@ExileServer;@A3XAI;
```

**Done!** System auto-starts.

---

## CONFIGURE (Optional)

**1. Unpack:** `@A3XAI/addons/a3xai_config.pbo`

**2. Edit:** `config.cpp`

**3. Repack:** `a3xai_config.pbo`

**4. Restart server**

---

## FILES

```
@A3XAI/
├── addons/
│   ├── a3xai.pbo          ← Main code (don't edit)
│   └── a3xai_config.pbo   ← Configuration (edit this)
└── README.md
```

---

## SETTINGS (config.cpp)

```cpp
A3XAI_maxAIGlobal = 150;              // Max AI units
A3XAI_minServerFPS = 20;              // FPS threshold
A3XAI_enableMissionMarkers = 1;       // Show markers
A3XAI_poptabsReward = 1;              // Give poptabs

// Blacklist zones
A3XAI_blacklistZones = [
    ["TraderCity", [14599, 16797, 0], 750]
];
```

---

## VERIFY

Check RPT log for:
```
[A3XAI] A3XAI ELITE EDITION v1.0.0
[A3XAI] Initialized successfully
```

---

## NEW FEATURES

✅ 5 Mission Types (convoy, crash, camp, hunter, rescue)
✅ 100x Faster Spawns (spatial grid)
✅ Advanced Vehicle AI (stuck detection)
✅ Headless Client Support (auto)
✅ EAD Integration (auto)
✅ Kill Streak Rewards
✅ Smart Performance Management

---

**That's it! Drop-in replacement for original A3XAI.**

See `README.md` for full documentation.
