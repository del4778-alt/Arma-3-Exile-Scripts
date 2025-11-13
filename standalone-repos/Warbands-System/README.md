# ⚔️ Warbands System - Fallout 4 S.P.E.C.I.A.L. Edition

**Mount & Blade meets Fallout 4 in Arma 3 Exile**

Transform your Exile server into a dynamic faction warfare sandbox with village conquest, fortress sieges, AI companions, prisoner ransoms, and RPG-style character progression using Fallout 4's S.P.E.C.I.A.L. system.

---

## ✨ Features

### 🏰 Core Systems

#### Faction Warfare
- **4 Factions**: WEST (NATO), EAST (CSAT), GUER (AAF), CIV (Civilians)
- **Dynamic Relations**: Factions can be hostile, neutral, or friendly
- **Faction Treasury**: Shared wealth system (starts at 10,000 per faction)
- **Join Any Faction**: Players choose their allegiance

#### Village System
- **Claimable Villages**: Conquer villages for your faction
- **Upgrades**: Blacksmith, Arena, Barracks, Market
- **Passive Income**: Villages generate money for faction treasury
- **Defend Villages**: AI defenders spawn when under attack

#### Fortress System
- **Build Fortresses**: Construct defensive strongholds
- **Garrison System**: AI defenders protect your fortress
- **Siege Warfare**: Attack enemy fortresses
- **Random Events**: Automatic siege events every 1-2 hours

#### Companion System
- **Recruit Companions**: Hire skilled AI followers
- **XM8 Integration**: Manage companions via XM8 menu
- **Profession System**: Companions have specializations
- **Upgrade System**: Level up companions over time

#### Prisoner & Ransom System
- **Capture Enemies**: Take down enemies to capture them
- **Prison Management**: Hold prisoners at your fortress
- **Ransom Demands**: Extort money from enemy factions
- **Rescue Missions**: Players can rescue captured allies

#### Contract System
- **Mercenary Contracts**: Accept faction contracts for money
- **Dynamic Missions**: Defend villages, attack fortresses, escort convoys
- **Reputation System**: Build standing with factions
- **Bounty Hunting**: Hunt down marked targets

### 🎲 Fallout 4 S.P.E.C.I.A.L. System

Every troop and player uses Fallout 4's attribute system:

- **S** - Strength (melee damage, carry weight)
- **P** - Perception (spotting distance, accuracy)
- **E** - Endurance (health, stamina)
- **C** - Charisma (leadership, trading)
- **I** - Intelligence (XP gain, skill learning)
- **A** - Agility (movement speed, reload speed)
- **L** - Luck (critical hits, loot quality)

**Example Troop Progression:**
```
Recruit (Lvl 1): S:3, P:3, E:3, C:2, I:2, A:3, L:3
Veteran (Lvl 5): S:5, P:5, E:5, C:3, I:3, A:5, L:4
Elite (Lvl 10): S:7, P:7, E:7, C:5, I:5, A:7, L:6
```

---

## 📦 Installation

### Step 1: Download
Click the green **Code** button → **Download ZIP**

### Step 2: Extract
Extract the entire `warbands` folder to your mission:
```
YourMission.Map/warbands/
```

Your folder structure should look like:
```
warbands/
├── WB_Init_Server.sqf
├── WB_Init_Client.sqf
├── config/
├── fortress/
├── functions/
├── systems/
├── ui/
└── xm8/
```

### Step 3: Server Initialization
Add to `initServer.sqf`:
```sqf
// Warbands System - Server
call compile preprocessFileLineNumbers "warbands\WB_Init_Server.sqf";
```

### Step 4: Client Initialization
Add to `initPlayerLocal.sqf`:
```sqf
// Warbands System - Client
if (hasInterface) then {
    call compile preprocessFileLineNumbers "warbands\WB_Init_Client.sqf";
};
```

### Step 5: XM8 Integration (Optional)
If using XM8 apps, the warbands menu will appear automatically.

### Step 6: Restart Server
Restart your server and enjoy faction warfare!

---

## ⚙️ Configuration

### Faction Relations
Edit `WB_Init_Server.sqf` to change faction relationships:

```sqf
WB_FactionRelations = createHashMapFromArray [
    ["WEST_EAST", -50],    // NATO vs CSAT (hostile)
    ["WEST_GUER", 0],      // NATO vs AAF (neutral)
    ["WEST_CIV", 25],      // NATO vs Civilians (friendly)
    // ... etc
];

// Values:
// -100 to -20 = Hostile (will attack)
// -20 to 20   = Neutral
// 20 to 100   = Friendly (will help)
```

### Faction Treasury
Starting wealth per faction:

```sqf
WB_Treasury_WEST = 10000;  // NATO
WB_Treasury_EAST = 10000;  // CSAT
WB_Treasury_GUER = 10000;  // AAF
WB_Treasury_CIV = 10000;   // Civilians
```

### Siege Event Frequency
Random siege events configuration:

```sqf
[] spawn {
    sleep 600; // Wait 10 minutes before first siege

    while {true} do {
        sleep 3600 + (random 3600); // Every 1-2 hours

        if (random 1 < 0.3) then { // 30% chance
            // Trigger siege
        };
    };
};
```

Change values:
- Initial delay: `600` = 10 minutes
- Event interval: `3600 + (random 3600)` = 1-2 hours
- Siege chance: `0.3` = 30%

---

## 🎮 How To Play

### Joining a Faction
1. Open XM8 menu
2. Navigate to Warbands app
3. Choose "Join Faction"
4. Select WEST, EAST, GUER, or CIV
5. Confirm selection

### Claiming a Village
1. Travel to an unclaimed village
2. Open XM8 → Warbands → "Claim Village"
3. Pay claim cost (default: 5000)
4. Village now generates passive income for your faction

### Upgrading Villages
Available upgrades:
- **Blacksmith** - Craft weapons and armor
- **Arena** - Train troops, watch fights, place bets
- **Barracks** - Recruit AI troops
- **Market** - Better trading prices

Cost: 2000-5000 per upgrade

### Building a Fortress
1. Choose location
2. Open XM8 → Warbands → "Build Fortress"
3. Select fortress type (template)
4. Pay construction cost
5. Fortress spawns with AI garrison

### Attacking a Fortress (Siege)
1. Approach enemy fortress
2. Open XM8 → Warbands → "Start Siege"
3. Choose attack strategy
4. Fight AI defenders
5. Capture or destroy fortress

### Capturing Enemies
1. Down an enemy (don't kill)
2. Approach body
3. Select "Capture Prisoner"
4. Enemy sent to your prison

### Managing Prisoners
1. Open XM8 → Warbands → "Prisoner Management"
2. View captured enemies
3. Options:
   - **Ransom** - Demand money for release
   - **Recruit** - Convert to your faction
   - **Execute** - Remove permanently
   - **Release** - Free without payment

### Accepting Contracts
1. Open XM8 → Warbands → "Contracts"
2. View available missions
3. Accept contract
4. Complete objective
5. Return for payment + reputation

---

## 🏰 Fortress Templates

### fortress_west.sqf (NATO)
- Modern bunkers
- Sandbag defenses
- Watchtowers
- Heavy MG emplacements

### fortress_east.sqf (CSAT)
- Concrete walls
- Guard towers
- Vehicle barriers
- Mortar positions

### fortress_independent.sqf (AAF)
- Watchtowers
- Camo netting
- Light fortifications
- Mobile defenses

### fortress_civilian.sqf (Civilians)
- Makeshift barriers
- Civilian buildings
- Improvised defenses
- Minimal firepower

---

## 📊 S.P.E.C.I.A.L. System Details

### Troop Levels & Stats

**Level 1 - Recruit**
```
S: 3  P: 3  E: 3  C: 2  I: 2  A: 3  L: 3
Health: 100
Accuracy: 60%
Speed: 1.0x
```

**Level 5 - Veteran**
```
S: 5  P: 5  E: 5  C: 3  I: 3  A: 5  L: 4
Health: 150
Accuracy: 80%
Speed: 1.1x
```

**Level 10 - Elite**
```
S: 7  P: 7  E: 7  C: 5  I: 5  A: 7  L: 6
Health: 200
Accuracy: 95%
Speed: 1.3x
```

### Stat Effects

**Strength (S)**
- Melee damage: +5% per point
- Carry capacity: +10 kg per point
- Recoil control: +2% per point

**Perception (P)**
- Spot distance: +20m per point
- Accuracy: +3% per point
- Target acquisition: +5% per point

**Endurance (E)**
- Health: +10 HP per point
- Stamina: +15% per point
- Damage resistance: +2% per point

**Charisma (C)**
- Trade prices: -5% per point
- Companion loyalty: +10% per point
- Ransom negotiation: +8% per point

**Intelligence (I)**
- XP gain: +5% per point
- Skill learning: +10% per point
- Critical damage: +3% per point

**Agility (A)**
- Movement speed: +3% per point
- Reload speed: +5% per point
- Aim speed: +4% per point

**Luck (L)**
- Critical chance: +2% per point
- Loot quality: +5% per point
- Random event bonus: +3% per point

---

## 🐛 Troubleshooting

### Warbands Menu Not Appearing
- Verify client init is in `initPlayerLocal.sqf`
- Check RPT logs for `[WB]` messages
- Ensure XM8 mod is installed (if using XM8 integration)

### Villages Not Spawning
- Check server init executed successfully
- Villages may need manual placement (check config files)
- Verify map compatibility

### Fortresses Not Building
- Ensure sufficient funds in faction treasury
- Check build location (may need clear ground)
- Verify template files exist

### Prisoners Not Capturing
- Enemy must be downed, not killed
- Check if prison exists at fortress
- Verify ransom system loaded

---

## 📈 Performance

**Server Impact:** Moderate
- **CPU:** ~2-5% (depends on active fortresses)
- **Memory:** ~5-10 MB
- **Network:** Low (most logic server-side)

**Recommended For:**
- 10-50 player servers
- Dedicated servers preferred
- 4+ GB RAM

**Scales With:**
- Number of active fortresses (3-10 recommended)
- Concurrent sieges (1-2 max)
- AI garrison sizes (10-30 per fortress)

---

## 🔄 Version History

### v2.0 - S.P.E.C.I.A.L. Edition (Current)
- ✅ Fallout 4 S.P.E.C.I.A.L. system integration
- ✅ Troop level progression
- ✅ Stat-based combat bonuses
- ✅ RPG-style character development

### v1.0 - Mount & Blade Edition
- Initial release
- Village conquest
- Fortress sieges
- Prisoner system
- Contract missions

---

## 📝 License

**MIT License** - Free to use, modify, and distribute

---

## 🤝 Support

**Issues?** Check the troubleshooting section above.

**Questions?** Open an issue on GitHub.

**Want to contribute?** Pull requests welcome!

---

## 🎯 Faction Strategy Guide

### WEST (NATO) - Technology
- **Strengths:** Best weapons, heavy armor
- **Weaknesses:** Expensive troops, slow
- **Best For:** Defensive play, fortress holding

### EAST (CSAT) - Numbers
- **Strengths:** Cheap troops, large armies
- **Weaknesses:** Lower quality gear
- **Best For:** Aggressive expansion, village farming

### GUER (AAF) - Mobility
- **Strengths:** Fast troops, guerrilla tactics
- **Weaknesses:** Weak fortifications
- **Best For:** Hit-and-run, contract missions

### CIV (Civilians) - Economics
- **Strengths:** Best trade prices, highest income
- **Weaknesses:** Weakest military
- **Best For:** Trading, mercenary contracts, wealth building

---

## 🚀 Advanced Features

### Companion Professions
- **Warrior** - Combat specialist (+damage, +health)
- **Trader** - Merchant (+bartering, +income)
- **Scout** - Reconnaissance (+spotting, +speed)
- **Medic** - Healer (+healing, +survivability)
- **Engineer** - Builder (+fortification, +repairs)

### Arena System
- Organize AI vs AI fights
- Players can bet on outcomes
- Train companions through combat
- Unlock special abilities

### Blacksmith Crafting
- Forge weapons from materials
- Upgrade armor quality
- Repair damaged equipment
- Unlock legendary items

---

**Build your warband and conquer the wasteland! ⚔️🏰**
