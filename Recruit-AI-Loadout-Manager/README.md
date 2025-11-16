# Recruit AI Loadout Manager v1.0

In-game menu system to customize recruit AI equipment, save loadout presets, and apply quick templates.

## Features

- **Interactive Menu**: Scroll menu to manage recruit loadouts
- **Weapon Customization**: Change weapons, attachments, and optics
- **Gear Management**: Modify uniforms, vests, helmets, and items
- **Loadout Presets**: Save and load custom configurations
- **Quick Templates**: Pre-made loadouts (CQB, Long Range, Stealth)
- **Cost System**: Poptabs-based upgrade economy
- **Persistent Storage**: Saves to profileNamespace
- **Per-Type Presets**: Different loadouts for AT, AA, and Sniper recruits

## Installation

1. Place the `Recruit-AI-Loadout-Manager` folder in your mission file
2. **Requires AI-Recruit-System** - Install first!
3. Add to `init.sqf`:
```sqf
[] execVM "AI-Recruit-System\recruit_ai.sqf";              // Load recruit system first
[] execVM "Recruit-AI-Loadout-Manager\fn_loadoutManager.sqf";
```

## Configuration

Edit the `LOADOUT_CONFIG` hashmap in `fn_loadoutManager.sqf`:

```sqf
LOADOUT_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["usePopTabsCost", true],             // Require payment
    ["baseCost", 500],                    // Base Poptabs cost
    ["weaponMultiplier", 2.0],            // Weapons cost 2x
    ["attachmentMultiplier", 1.0],
    ["itemMultiplier", 0.5],              // Items cost 0.5x
    ["saveToProfile", true],              // Persistent saves
    ["maxPresets", 5],                    // Max presets per type

    // Equipment pools (customize available gear)
    ["rifles", [...]],
    ["sniperRifles", [...]],
    ["launchers", [...]],
    ["optics", [...]],
    ["muzzles", [...]],
    // ... etc
];
```

## Usage

### Access the Manager
1. Look at your recruit
2. Scroll mouse wheel
3. Select **"Manage Recruit Loadouts"**
4. Choose which recruit to customize

### Menu Options

#### 1. Change Weapon
- Select from available weapon pool
- Cost: 1000 Poptabs (baseCost × 2.0)
- Pools:
  - AT: Rifles + Launchers (AT)
  - AA: Rifles + Launchers (AA)
  - Sniper: Sniper Rifles

#### 2. Change Attachments
- Optics (Aco, Holosight, MRCO, DMS, LRPS, etc.)
- Suppressors (by caliber)
- Pointers (Flashlight, IR Laser)
- Cost: 500 Poptabs per attachment

#### 3. Change Gear
- Uniforms (Combat, Ghillie)
- Vests (Plate Carrier, Tactical, Chestrig)
- Helmets (Helmet, Booniehat, Watchcap)
- Items (Medical, Tools, Optics, GPS)
- Cost: 250 Poptabs per item

#### 4. Apply Template
Pre-configured loadouts for different roles:

| Template | Description | Multiplier |
|----------|-------------|------------|
| CQB | Close quarters, red dots, flashlights | 3x (1500 Poptabs) |
| Long Range | Magnified optics, rangefinders | 3x (1500 Poptabs) |
| Stealth | Suppressors, NVG, ghillie suits | 3x (1500 Poptabs) |

#### 5. Save Current Loadout
- Saves recruit's current equipment
- Name your preset (e.g., "Urban Sniper")
- Max 5 presets per recruit type
- Persists across server restarts

#### 6. Load Saved Loadout
- Select from your saved presets
- Instantly applies to recruit
- Free to load (already paid for)

## Template Examples

### AT Recruit Templates

**CQB Template**
- Primary: MXC (Carbine)
- Suppressor + Holosight
- Launcher: NLAW
- Plate Carrier II
- Close range anti-tank

**Long Range Template**
- Primary: SPAR-02 (Marksman)
- MRCO Optic
- Launcher: Titan AT
- Rangefinder
- Long range precision

**Stealth Template**
- Primary: MX (Suppressed)
- NVS Optic + IR Laser
- Launcher: RPG-32
- Ghillie Suit + NVG
- Covert operations

### AA Recruit Templates

**CQB Template**
- Primary: MXC
- Aco Sight
- Launcher: Titan AA
- Fast anti-air response

**Long Range Template**
- Primary: MX
- Hamr Optic
- Launcher: Titan AA
- Area air denial

**Stealth Template**
- Primary: SPAR-01 (Suppressed)
- NVS Optic
- Launcher: Titan AA
- Hidden air defense

### Sniper Recruit Templates

**CQB Template**
- Primary: EBR (DMR)
- DMS Optic + Bipod
- Plate Carrier
- Mid-range marksman

**Long Range Template**
- Primary: LRR (.408)
- LRPS Optic + Bipod
- Ghillie Suit
- Extreme range elimination

**Stealth Template**
- Primary: DMR-03 (Suppressed)
- SOS Optic + Bipod
- Ghillie + NVG
- Silent overwatch

## Cost Breakdown

| Item Type | Base Cost | Multiplier | Final Cost |
|-----------|-----------|------------|------------|
| Weapon | 500 | 2.0x | **1000 Poptabs** |
| Attachment | 500 | 1.0x | **500 Poptabs** |
| Item/Gear | 500 | 0.5x | **250 Poptabs** |
| Template | 500 | 6.0x | **1500 Poptabs** |

### Example Scenarios

**Scenario 1: Upgrading Sniper to Stealth**
1. Apply Stealth Template: 1500 Poptabs
2. Total: **1500 Poptabs**
3. Result: Full ghillie loadout with suppressed DMR

**Scenario 2: Custom AT Build**
1. Change weapon to SPAR-02: 1000 Poptabs
2. Add DMS optic: 500 Poptabs
3. Add suppressor: 500 Poptabs
4. Change vest to Plate Carrier II: 250 Poptabs
5. Add rangefinder: 250 Poptabs
6. Total: **2500 Poptabs**
7. Save as "Custom Marksman AT": Free
8. Load on other AT recruits: Free

## Preset Management

### Saving Presets
```
1. Customize recruit loadout
2. Open menu → "Save Current Loadout"
3. Enter preset name
4. Preset saved to profileNamespace
5. Available for all recruits of same type
```

### Loading Presets
```
1. Open menu → "Load Saved Loadout"
2. Select preset from list
3. Loadout applied instantly
4. No cost (already paid during customization)
```

### Deleting Presets
```
1. Open menu → "Manage Presets"
2. Select preset to delete
3. Confirm deletion
4. Preset removed from storage
```

## Integration

### With AI-Recruit-System
- **Required**: Detects recruits via `ExileRecruited` flag
- **Ownership**: Checks player UID matches recruit owner
- **Types**: Reads `RecruitType` variable (AT, AA, Sniper)

### With Exile Mod
- **Poptabs**: Uses `ExileMoney` variable
- **Payment**: Automatically deducts costs
- **Balance Check**: Prevents purchases without funds

### With CBA
- Optional CBA_fnc_waitAndExecute for player connection handling
- Falls back to vanilla if CBA not present

## Performance

- **No Server Load**: Client-side menu processing
- **Lightweight**: Only active when menu open
- **Persistent**: Saves don't impact server performance
- **Instant Apply**: Loadout changes immediate

## Troubleshooting

### Menu not appearing
- Check recruit system is loaded first
- Verify recruit has `ExileRecruited = true`
- Ensure you own the recruit (UID match)
- Look within 5m of recruit

### Can't afford upgrades
- Check Poptabs balance (`systemChat format ["%1", player getVariable "ExileMoney"]`)
- Reduce costs in config (`baseCost` and multipliers)
- Set `usePopTabsCost = false` for free upgrades (testing)

### Presets not saving
- Check `saveToProfile = true`
- Verify profileNamespace permissions
- Max 5 presets per type (delete old ones)

### Templates not working
- Ensure recruit type matches template (AT/AA/Sniper)
- Check template name spelling (case-sensitive)
- Verify weapon classnames exist in your mods

## Advanced: Custom Templates

Add your own templates by editing `LOADOUT_fnc_getTemplateLoadout`:

```sqf
case "MyCustom": {
    _loadout = [
        ["YOUR_WEAPON", "suppressor", "pointer", "optic", [], [], ""],
        ["YOUR_LAUNCHER", "", "", "", [], [], ""],
        [],
        ["YOUR_UNIFORM", [["FirstAidKit", 3]]],
        ["YOUR_VEST", []],
        [],
        ["YOUR_HELMET", ""],
        [],
        ["YOUR_BINOCULAR", "", "", "", [], [], ""]
    ];
};
```

## Changelog

### v1.0 (2025-01-XX)
- Initial release
- 3 templates per recruit type
- Preset save/load system
- Poptabs integration
- Scroll menu interface
- Persistent storage
