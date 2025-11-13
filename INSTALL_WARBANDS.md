# Exile Warbands System - Installation Guide

## Overview
This guide provides complete instructions for installing the Exile Warbands System into your Exile.Altis mission folder. The Warbands system transforms Exile into a Mount & Blade-style world with faction-based gameplay, featuring fortresses, trade, and war across Altis.

## What is Warbands?
The Warbands system adds:
- **Faction Control**: Dynamic territories controlled by AI factions
- **Fortresses**: Buildable faction strongholds with garrisons
- **AI Armies**: Autonomous warbands that patrol and engage in combat
- **Trade Caravans**: Economic system with faction traders
- **Persistent World**: Territory changes persist across server restarts
- **Player Integration**: Join factions, claim villages, and participate in the power struggle

---

## Installation Steps

### Step 1: Prepare Your Mission Folder

Your mission folder should be located at:
```
Arma 3\mpmissions\Exile.Altis\
```

**IMPORTANT**: Back up your existing `Exile.Altis` folder before proceeding!

### Step 2: Copy Files from This Repository

From this repository, copy the following to your mission folder:

1. **Warbands Directory** (Required)
   ```
   Exile.Altis/warbands/
   ```
   This contains all the warbands system files including:
   - `config/` - Configuration files for factions, zones, economy
   - `functions/` - Core warbands functions
   - `fortress/` - Fortress building and garrison systems
   - `systems/` - Treasury and other game systems
   - `ui/` - User interface elements

2. **Modified Core Files** (Required)

   The following files have been pre-configured with warbands integration:
   - `Exile.Altis/description.ext` - Includes warbands configs and remote exec permissions
   - `Exile.Altis/initServer.sqf` - Includes warbands initialization code
   - `Exile.Altis/initPlayerLocal.sqf` - Includes client hook comments

### Step 3: Verify Folder Structure

Your `Exile.Altis` folder should now contain:

```
Exile.Altis/
├── warbands/
│   ├── config/
│   │   ├── WB_CfgCompanions.hpp
│   │   ├── WB_CfgEconomy.hpp
│   │   ├── WB_CfgFactions.hpp
│   │   ├── WB_CfgMarket.hpp
│   │   ├── WB_CfgProfessions.hpp
│   │   ├── WB_CfgTroops.hpp
│   │   ├── WB_CfgZones.hpp
│   │   └── WB_Settings.hpp
│   ├── fortress/
│   │   ├── fortress_templates/
│   │   │   ├── fortress_civilian.sqf
│   │   │   ├── fortress_east.sqf
│   │   │   ├── fortress_independent.sqf
│   │   │   └── fortress_west.sqf
│   │   ├── fn_buildFortress.sqf
│   │   ├── fn_registerFortress.sqf
│   │   └── fn_spawnGarrison.sqf
│   ├── functions/
│   ├── systems/
│   └── ui/
├── description.ext
├── initServer.sqf
├── initPlayerLocal.sqf
└── [other existing mission files...]
```

### Step 4: Configure Fortress Positions (Optional)

By default, fortresses spawn at these Altis locations:
- **Kavala (KAV)**: [3584,13060,0] - West faction
- **Pyrgos (PYR)**: [16868,12862,0] - East faction
- **Athira (ATH)**: [13961,18764,0] - Independent faction
- **Civilian (CIV)**: [25500,21300,0] - Civilian faction

To change fortress positions, edit `initServer.sqf` and locate:
```sqf
WB_fortressPositions = [
    ["KAV", [3584,13060,0], 90,  "warbands\fortress\fortress_templates\fortress_west.sqf"],
    ["PYR", [16868,12862,0],270, "warbands\fortress\fortress_templates\fortress_east.sqf"],
    ["ATH", [13961,18764,0],180, "warbands\fortress\fortress_templates\fortress_independent.sqf"],
    ["CIV", [25500,21300,0],180, "warbands\fortress\fortress_templates\fortress_civilian.sqf"]
];
```

### Step 5: Pack the Mission File

Use one of the following tools to pack your mission folder:

**Option A: Mikero's PBOProject** (Recommended)
1. Install PBOProject from https://mikero.bytex.digital/Downloads
2. Right-click your `Exile.Altis` folder
3. Select "PBO Folder (via MakePbo)"
4. The `Exile.Altis.pbo` file will be created

**Option B: Arma 3 Tools**
1. Open Arma 3 Tools from Steam
2. Launch "Addon Builder"
3. Select your `Exile.Altis` folder as source
4. Click "Pack" to create `Exile.Altis.pbo`

### Step 6: Deploy to Server

1. Copy `Exile.Altis.pbo` to your server's `mpmissions` directory:
   ```
   Server\mpmissions\Exile.Altis.pbo
   ```

2. Update your server config (`server.cfg`) to use this mission:
   ```
   class Missions
   {
       class ExileMod
       {
           template = "Exile.Altis";
           difficulty = "ExileRegular";
       };
   };
   ```

---

## Server Requirements

### Required Mods
- **Exile Mod** - Base Exile mod
- **CBA_A3** - Community Base Addons (required for advanced scripting)

### Optional Mods (Recommended)
- **LAMBS Danger FSM** or **VCOM AI** - Enhanced AI behavior for warbands
- **Headless Client** - Load balancing for better server performance

### Server Startup Parameters

Example startup command:
```bash
arma3server.exe \
  -mod=@Exile;@CBA_A3; \
  -serverMod=@VCOM_AI;@LAMBS_Danger; \
  -config=server.cfg \
  -name=ExileServer \
  -filePatching
```

---

## Post-Installation Verification

### 1. Check Server Logs

After starting your server, check `server.rpt` for these initialization messages:

```
[SERVER] Starting Exile server initialization...
[SERVER] All Elite AI systems loaded!
[WB] Server bootstrap: Exile ready.
[SERVER] Warbands system initialized!
```

If you see initialization errors, review your file paths and folder structure.

### 2. Verify Map Markers

Connect to your server and check the map. You should see markers for:
- Kavala fortress (West)
- Pyrgos fortress (East)
- Athira fortress (Independent)
- Civilian fortress

### 3. Test Faction Systems

1. Look for faction AI patrols (warbands) near fortresses
2. Check for trade caravans moving between settlements
3. Verify that players can interact with faction traders
4. Test joining a faction and claiming territory

---

## Configuration Files

### Warbands Settings (`warbands/config/WB_Settings.hpp`)
Configure global warbands parameters:
- Strategic cycle timing
- Economic rates
- Combat settings
- Simulation distances

### Faction Configuration (`warbands/config/WB_CfgFactions.hpp`)
Define faction properties:
- Starting resources
- Relations with other factions
- Territory control

### Zone Configuration (`warbands/config/WB_CfgZones.hpp`)
Define territorial zones:
- Zone names and positions
- Resource values
- Control requirements

### Economy Configuration (`warbands/config/WB_CfgEconomy.hpp`)
Set economic parameters:
- Trade good prices
- Production rates
- Tax rates

---

## Troubleshooting

### Problem: Fortresses Don't Spawn

**Solution**:
- Check `server.rpt` for errors
- Verify file paths in `initServer.sqf` use backslashes (`\`) not forward slashes
- Ensure fortress template files exist in `warbands/fortress/fortress_templates/`

### Problem: No Warbands Appear

**Solution**:
- Verify Dynamic Simulation is enabled (check `enableDynamicSimulationSystem true` in `initServer.sqf`)
- Check that CBA_A3 mod is loaded on the server
- Review `WB_CfgFactions.hpp` for faction definitions

### Problem: Remote Exec Errors

**Solution**:
- Ensure `CfgRemoteExec` in `description.ext` includes all warbands functions
- Check that `mode = 1` is set in `CfgRemoteExec`
- Verify allowed targets are set to `2` for warbands functions

### Problem: Players Can't Interact with System

**Solution**:
- Verify `WB_fnc_professionInit` is configured as `postInit = 1` in `description.ext`
- Check client logs for initialization errors
- Ensure UI files are present in `warbands/ui/`

---

## Support and Credits

### Original Warbands System
- Repository: https://github.com/del4778-alt/Exile-Warbands-Altis
- Inspired by Mount & Blade faction mechanics

### Exile Mod
- Website: https://www.exilemod.com
- Forum: https://www.exilemod.com/forums

### Community Resources
- Exile Discord: https://discord.gg/exile
- Arma 3 Modding: https://community.bistudio.com/wiki/Arma_3

---

## Advanced Customization

### Custom Fortress Templates

Create new fortress templates by duplicating and modifying files in:
```
warbands/fortress/fortress_templates/
```

Each template defines:
- Building compositions
- Defense structures
- Garrison spawn points

### Faction Balancing

Edit `warbands/config/WB_CfgFactions.hpp` to adjust:
- Starting troops and resources
- Relations and alliances
- Victory conditions

### Economy Tuning

Modify `warbands/config/WB_CfgEconomy.hpp` to change:
- Trade prices
- Production speeds
- Resource consumption rates

---

## Performance Optimization

### For Low-Population Servers (< 20 players)
- Reduce warband spawn frequency
- Decrease simulation distances
- Limit number of concurrent caravans

### For High-Population Servers (> 40 players)
- Use Headless Client for AI processing
- Enable Dynamic Simulation aggressively
- Consider limiting fortress garrison sizes

### Recommended Settings
Edit `initServer.sqf`:
```sqf
"Group" setDynamicSimulationDistance 1200;  // Standard
"Group" setDynamicSimulationDistance 800;   // Low-end servers
"Group" setDynamicSimulationDistance 1600;  // High-end servers
```

---

## Version Information

- **Warbands System Version**: 1.0
- **Compatible Exile Version**: 1.0.4+
- **Required Arma 3 Version**: 1.96+
- **CBA Version**: 3.15.0+

---

## License

This integration follows the licenses of:
- Exile Mod: APL-SA License
- Warbands System: Check original repository
- Your server modifications: Your discretion

---

**Installation Date**: 2025-11-12
**Last Updated**: 2025-11-12
**Maintained By**: del4778-alt

For issues or questions, please refer to the original repository or Exile community forums.
