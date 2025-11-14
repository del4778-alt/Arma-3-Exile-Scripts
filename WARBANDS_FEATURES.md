# Exile Warbands - Complete Feature Guide
## Mount & Blade: Warband/Bannerlord for Arma 3 Exile

---

## Table of Contents
1. [Overview](#overview)
2. [Faction System](#faction-system)
3. [Skills & Progression](#skills--progression)
4. [Companion System](#companion-system)
5. [Contract & Mission System](#contract--mission-system)
6. [Siege Warfare](#siege-warfare)
7. [Prisoner & Ransom System](#prisoner--ransom-system)
8. [Village Upgrades](#village-upgrades)
9. [Economy & Trading](#economy--trading)
10. [XM8 Integration](#xm8-integration)
11. [Configuration](#configuration)

---

## Overview

Exile Warbands transforms your Exile server into a persistent Mount & Blade-style sandbox where factions battle for control of Altis. Players can join factions, level up skills, hire companions, complete contracts, siege fortresses, and build their renown through honorable (or dishonorable) deeds.

### Key Features
- **4 Factions**: West, East, Independent, and Civilian factions each with their own territories
- **20+ Skills**: Character progression with Mount & Blade-inspired skills
- **8 Companions**: Hire specialized NPCs with unique skills to join your party
- **10+ Contract Types**: Dynamic missions for income and renown
- **Siege System**: Epic fortress battles with attackers vs defenders
- **Prisoner Management**: Ransom, recruit, or exchange captured enemies
- **Village Upgrades**: Build improvements to increase production
- **Full Exile Integration**: Uses poptabs (Exile currency) throughout

---

## Faction System

### Available Factions

#### Kingdom of Altis (WEST)
- **Territory**: Western Altis, centered at Kavala
- **Playstyle**: Democratic kingdom with balanced military and trade
- **Starting Relations**: Friendly with Civilians, Hostile to East

#### Eastern Empire (EAST)
- **Territory**: Eastern Altis, centered at Pyrgos
- **Playstyle**: Military empire focused on conquest
- **Starting Relations**: Hostile to West and Independent

#### Free Companies (INDEPENDENT)
- **Territory**: Central Altis, centered at Athira
- **Playstyle**: Mercenary bands, flexible alliances
- **Starting Relations**: Neutral to most, selective wars

#### Merchant Guild (CIVILIAN)
- **Territory**: Southern trading posts
- **Playstyle**: Trade-focused, avoid direct conflict
- **Starting Relations**: Friendly trade partners

### Joining a Faction

**Via XM8 App:**
1. Open XM8 (default: U key)
2. Navigate to "Warbands" app
3. Select "Join a Faction"
4. Choose your faction

**Effects of Joining:**
- Start at Rank 0 (Recruit)
- Begin earning renown and honor
- Access faction contracts
- Can claim villages for your faction
- Participate in sieges

### Faction Ranks
0. **Recruit** - New member
1. **Soldier** - Proven in battle
2. **Veteran** - Experienced warrior
3. **Elite** - Respected fighter
4. **Commander** - Can order caravans and minor operations
5. **Lord/Lady** - Can order sieges, full faction privileges

**Rank Progression:**
- Earn **Renown** through contracts, battles, and sieges
- Renown required: 50/100/250/500/1000 for ranks 1-5

---

## Skills & Progression

### Skill System Overview

Exile Warbands features **20 skills** adapted from Mount & Blade, organized into 4 categories:

#### Combat Skills (Personal)
- **Iron Flesh**: +10 HP and 2% damage reduction per level
- **Marksmanship**: +7% ranged damage and 5% accuracy per level
- **Power Strike**: +8% melee/close combat damage per level
- **Weapon Master**: Faster reload, reduced recoil, better handling
- **Shield Mastery**: 8% damage reduction when using shields/cover
- **Explosives**: +10% explosive damage and radius per level

#### Tactical Skills (Personal/Party)
- **Athletics**: +5% movement speed per level
- **Driving**: Better vehicle handling, reduced fuel consumption
- **Mounted Gunnery**: +10% accuracy from vehicles per level
- **Piloting**: Better aircraft handling and fuel efficiency
- **Looting** (Party): +10% loot from battles per level
- **Lockpicking**: Faster lockpicking, higher success
- **Scavenging** (Party): 15% chance to find rare items per level

#### Leadership Skills (Party/Leader)
- **Trainer**: Grant XP to party members daily (stacks)
- **Tracking** (Party): See enemy tracks on map
- **Tactics** (Party): +1 battle advantage per 2 levels
- **Pathfinding** (Party): +3% map movement speed per level
- **Spotting** (Party): +10% sight range per level
- **Inventory Management** (Leader): +6 inventory slots per level
- **Wound Treatment** (Party): +20% healing speed per level
- **Surgery** (Party): 4% chance to save downed troops per level
- **First Aid** (Party): Heroes recover 5% health after battle per level
- **Engineer** (Party): Faster building, lower upgrade costs
- **Medicine**: +50% medkit effectiveness per level

#### Social Skills (Personal/Leader)
- **Persuasion**: +4% recruitment success, better trade deals
- **Prisoner Management** (Leader): +5 prisoner slots, reduced escape chance
- **Leadership** (Leader): +5 troop slots, -5% wages, +5% morale per level
- **Trade** (Party): -5% trade penalty per level

### How Skills Work

**Skill Types:**
- **Personal**: Only affects your character
- **Party**: Uses highest level from you or companions (with leader bonus)
- **Leader**: Only your level counts (not companions)

**Party Skill Bonus (Mount & Blade System):**
If you have the skill yourself, you get a bonus to party skill effectiveness:
- Level 0-1: +0 bonus
- Level 2-4: +1 bonus
- Level 5-7: +2 bonus
- Level 8-9: +3 bonus
- Level 10: +4 bonus

**Example**: Your companion has Looting 10. You have Looting 5.
- Effective Looting = 10 (companion's) + 2 (your bonus) = 12
- Result: 120% more loot!

### Leveling and Skill Points

**Gaining Experience:**
- Kill enemies: 100 XP per kill
- Complete contracts: XP based on difficulty
- Win sieges: Massive XP rewards
- Companion kills also grant you XP

**Leveling Up:**
- Each level requires increasing XP (Level 1: 100, Level 2: 300, Level 3: 600, etc.)
- Gain 1 skill point per level
- Max skill level: 10
- View progress in XM8 > Warbands > View Skills

---

## Companion System

### What are Companions?

Companions are specialized NPCs you can hire to join your party. They have pre-trained skills, level up through combat, and provide passive bonuses through the party skill system.

### Available Companions

1. **Marksman Viktor** (3000 poptabs)
   - Skills: Marksmanship 8, Spotting 6, Tactics 4
   - Specialty: Long-range combat and reconnaissance

2. **Engineer Sofia** (3500 poptabs)
   - Skills: Engineer 9, Explosives 7, Inventory Management 5
   - Specialty: Fortifications and demolitions

3. **Medic Andreas** (4000 poptabs)
   - Skills: Medicine 9, First Aid 8, Surgery 7
   - Specialty: Keeping your party alive

4. **Sergeant Dimitri** (4500 poptabs)
   - Skills: Leadership 8, Trainer 9, Tactics 6
   - Specialty: Training troops and commanding

5. **Scout Elena** (3000 poptabs)
   - Skills: Tracking 9, Spotting 8, Pathfinding 7
   - Specialty: Navigation and intelligence

6. **Trader Marcus** (2500 poptabs)
   - Skills: Trade 9, Persuasion 7, Inventory Management 6
   - Specialty: Economy and negotiations

7. **Driver Ivan** (3000 poptabs)
   - Skills: Driving 9, Piloting 6, Engineer 4
   - Specialty: Vehicle operations

8. **Grenadier Hassan** (3500 poptabs)
   - Skills: Explosives 9, Power Strike 7, Iron Flesh 6
   - Specialty: Heavy weapons and demolitions

### Finding Companions

Companions spawn in major towns:
- Kavala
- Athira
- Pyrgos
- Sofia

Look for NPCs wandering near trader zones. You'll get a notification when near an available companion.

### Hiring Companions

**Method 1 - Direct Interaction:**
1. Approach companion (< 5m)
2. Use action menu: "Hire [Name]"
3. Confirm payment

**Method 2 - XM8:**
1. XM8 > Warbands > Manage Companions
2. View nearby companions
3. Select and hire

### Companion Benefits

**Combat:**
- Fight alongside you
- Use their specialized skills
- Gain experience and level up
- Can be equipped with your gear

**Party Skills:**
- Contribute their highest skills to party
- Stack with your skills for bonuses
- Multiple trainers = massive XP gain
- Multiple surgeons = fewer losses

**Example Party:**
You (Leadership 5) + Sergeant Dimitri (Leadership 8) + Scout Elena (Tracking 9)
- Effective Leadership: 8 + 2 (your bonus) = 10
- Effective Tracking: 9 + 0 (you don't have it) = 9
- Result: +50 troop slots, -50% wages, +50% morale, see tracks from far away!

---

## Contract & Mission System

### Contract Overview

Contracts are dynamic missions generated every 10 minutes for each faction. Accept contracts through XM8 to earn **poptabs** and **renown**.

### Contract Types

#### 1. Escort Caravan
- **Objective**: Protect a trade caravan from Point A to Point B
- **Reward**: 500-1500 poptabs, 5-15 renown
- **Difficulty**: Easy-Medium
- **Tips**: Stay with the caravan, watch for ambushes

#### 2. Capture Enemy Officer
- **Objective**: Locate and capture alive an enemy faction officer
- **Reward**: 750-2250 poptabs, 10-30 renown
- **Difficulty**: Hard
- **Tips**: Use non-lethal takedowns, bring zip ties

#### 3. Clear Bandit Camp
- **Objective**: Eliminate all bandits at a camp
- **Reward**: 500-1500 poptabs, 5-15 renown
- **Difficulty**: Medium
- **Tips**: Bring firepower, use tactics

#### 4. Raid Enemy Village (Dishonorable)
- **Objective**: Raid enemy village for supplies
- **Reward**: 600-1800 poptabs, NEGATIVE honor
- **Difficulty**: Hard
- **Tips**: Fast in, fast out, expect retaliation

#### 5. Defend Fortress
- **Objective**: Reinforce fortress garrison against attack
- **Reward**: 1000-3000 poptabs, 15-45 renown
- **Difficulty**: Very Hard
- **Tips**: Bring your party, use defensive positions

#### 6. Assassinate Target (Dishonorable)
- **Objective**: Eliminate enemy commander, leave no witnesses
- **Reward**: 1500-4500 poptabs, NEGATIVE honor
- **Difficulty**: Very Hard
- **Tips**: Stealth is key, silenced weapons

#### 7. Deliver Message
- **Objective**: Deliver urgent message to outpost
- **Reward**: 250-750 poptabs, 5-15 renown
- **Difficulty**: Easy
- **Tips**: Speed matters, avoid combat

#### 8. Collect Taxes
- **Objective**: Collect taxes from village, return with funds
- **Reward**: 500-1500 poptabs, 5-15 renown
- **Difficulty**: Easy-Medium
- **Tips**: Villagers may resist

#### 9. Patrol Territory
- **Objective**: Visit multiple patrol points, report enemy activity
- **Reward**: 500-1500 poptabs, 5-15 renown
- **Difficulty**: Easy
- **Tips**: Good for exploring map

#### 10. Rescue Prisoner
- **Objective**: Rescue allied officer from enemy captivity
- **Reward**: 750-2250 poptabs, 10-30 renown
- **Difficulty**: Hard
- **Tips**: Assault or stealth, get in/out quickly

### Contract Mechanics

**Accepting Contracts:**
1. XM8 > Warbands > Available Contracts
2. View contract details (reward, difficulty, expiration)
3. Accept (must be faction member)
4. Mission markers appear on map

**Contract Rewards:**
- **Poptabs**: Exile currency, direct to your locker
- **Renown**: Increases rank in faction
- **Honor**: Honorable contracts gain honor, dishonorable lose it
- **Faction Treasury**: 10% of reward goes to faction treasury

**Contract Failure:**
- Lose renown
- Cannot accept same contract type for 1 hour
- Faction reputation decreases

**Contract Expiration:**
- Most contracts: 24 hours
- Urgent deliveries: 30 minutes
- Check time remaining in XM8

---

## Siege Warfare

### What is a Siege?

Sieges are large-scale fortress battles where one faction attacks another's fortress. These are the pinnacle of Warbands combat, offering massive rewards and shifting the balance of power.

### Siege Phases

#### 1. Preparation (5 minutes)
- Attacker camp spawns 300-500m from fortress
- Defenders receive reinforcements
- Players can join either side
- Siege markers appear on map
- Global notification sent

#### 2. Assault (Until victory/defeat)
- Full combat begins
- Attackers push toward fortress
- Defenders hold positions
- Victory determined by total elimination or timer

#### 3. Resolution
- Winner claims fortress (if attackers won)
- 30% of loser's treasury transferred
- Participants receive rewards
- Siege markers remain for 10 minutes

### Joining a Siege

**Automatic Participation:**
- If you're near the fortress when siege starts
- If you're in the attacking/defending faction

**Manual Participation:**
1. Travel to siege location (marked on map)
2. Join attacker camp or fortress defenders
3. Fight for your faction

### Siege Rewards

**For Winners:**
- Defenders: 750 poptabs + 75 renown
- Attackers: 500 poptabs + 50 renown (+ fortress control)
- Massive XP rewards (500-1000 XP)
- Honor bonuses
- Loot from battlefield

**For Losers:**
- No rewards
- Lose honor
- Lose faction territory (if defenders)

### Initiating a Siege

**Requirements:**
- Rank 4 (Commander) or higher
- Hostile relations with target faction (< -20)
- Faction treasury funds for siege preparations

**Process:**
1. XM8 > Warbands > Kingdom Actions > Order Siege
2. Select target fortress
3. Confirm (costs faction treasury)
4. Siege begins in 5 minutes

### Random Sieges

Every 1-2 hours, there's a 30% chance of a random siege between hostile factions. These are automatic and don't require player initiation.

---

## Prisoner & Ransom System

### Capturing Prisoners

**Methods:**
- Knock out enemies (non-lethal damage)
- Use zip ties on unconscious enemies
- Capture during contracts ("Capture Officer" mission)
- Loot prisoners from defeated warbands

**Prisoner Types:**
1. **Regular Bandits/Enemies**: No faction affiliation
2. **Faction Members**: Belong to West/East/GUER/CIV factions

### Managing Regular Prisoners

**Options:**

#### 1. Recruit
- **Success Chance**: 25% base + 4% per Persuasion level
- **Result**: Prisoner joins your faction as rank 0 recruit
- **Benefits**: Adds to your party, can become companion
- **Requirements**: None

#### 2. Sell as Slave
- **Price**: 150-250 poptabs
- **Result**: Immediate cash
- **Honor**: No change
- **Best for**: Quick money

#### 3. Execute
- **Result**: Prisoner killed
- **Honor**: -10 honor
- **Consequences**: May affect faction relations
- **When to use**: Never (dishonorable)

#### 4. Release
- **Result**: Prisoner freed
- **Honor**: +5 honor
- **Benefits**: Prisoner may remember kindness
- **Best for**: Roleplay, honor gain

### Managing Faction Prisoners

**Options:**

#### 1. Demand Ransom
- **Amount**: 500 + (250 × prisoner rank) poptabs
- **Source**: Deducted from faction treasury
- **Split**: 80% to your faction, 20% to you
- **Renown**: +10 renown
- **Requirements**: Faction must have sufficient funds
- **Honor**: Neutral
- **Example**: Capture Rank 3 enemy = 1250 poptabs ransom

#### 2. Persuade to Defect
- **Success Chance**: 15% + 4% per Persuasion level + 0.1% per honor - 5% per prisoner rank
- **Result**: Prisoner switches to your faction
- **Honor**: -5 honor (considered stealing)
- **Benefits**: Gain experienced soldier
- **Risk**: -10 honor if failed

#### 3. Exchange Prisoners
- **Requirements**: Enemy faction holds allied prisoners
- **Result**: 1-for-1 prisoner trade
- **Honor**: +15 honor
- **Faction Relations**: +10 with enemy faction
- **Best for**: Recovering important allies

#### 4. Execute (Severe)
- **Result**: Officer killed
- **Honor**: -25 honor
- **Faction Relations**: -50 with their faction
- **Consequences**: Declared war, heavy penalties
- **When to use**: Almost never

#### 5. Release
- **Result**: Prisoner freed
- **Honor**: +10 honor
- **Faction Relations**: +20 with their faction
- **Benefits**: Improved diplomacy, possible alliance
- **Best for**: Peace-building

### Prisoner Management Strategy

**Honor Playthrough:**
- Release or exchange all prisoners
- Never execute
- Build +100 honor for benefits
- Improves faction relations

**Profit Playthrough:**
- Ransom high-rank prisoners
- Sell regular prisoners
- Recruit occasionally
- Maximize poptabs income

**Power Playthrough:**
- Persuade officers to defect
- Build experienced army
- Don't care about honor
- Strongest military force

### Prisoner System Integration

**With Exile:**
- Uses poptabs (Exile currency)
- Prisoners held in Exile "virtual" system
- Zip ties required (Exile item)

**With Skills:**
- Persuasion affects recruitment
- Prisoner Management increases prisoner slots
- Leadership affects prisoner loyalty

**With Factions:**
- Ransoms come from faction treasuries
- Exchanges help faction members
- Prisoner treatment affects relations

---

## Village Upgrades

### Village System Overview

10 villages across Altis can be upgraded by faction members (Rank 3+). Upgrades cost poptabs from faction treasury and provide passive income, recruit bonuses, and strategic advantages.

### Villages List

1. **Kavala** (WEST) - Level 1
2. **Athira** (GUER) - Level 1
3. **Pyrgos** (EAST) - Level 1
4. **Sofia** (CIV) - Level 1
5. **Agios Dionysios** (Neutral) - Level 1
6. **Zaros** (Neutral) - Level 1
7. **Poliakko** (Neutral) - Level 1
8. **Katalaki** (Neutral) - Level 1
9. **Panagia** (Neutral) - Level 1
10. **Selakano** (Neutral) - Level 1

**Village Levels:**
- Villages start at Level 1
- Each 3 upgrades = +1 level
- Higher level = more production
- Max level: No hard cap

### Available Upgrades

#### Defensive Upgrades

**Walls** (5000 poptabs base)
- Physical H-Barrier walls around village
- Improves defense in battles
- Prerequisite for higher-level upgrades

**Watchtower** (2500 poptabs base)
- Adds guard tower with 2 NPC guards
- Early warning system
- Spotting range bonus

#### Economic Upgrades

**Market** (3000 poptabs base)
- Adds market stalls and trader NPC
- **Production Bonus**: +200 poptabs/10 min
- Unlocks advanced trading

**Mill** (2500 poptabs base)
- Adds grain mill building
- **Production Bonus**: +150 poptabs/10 min
- Food production

**Workshop** (4500 poptabs base)
- Adds craftsman workshop
- **Production Bonus**: +100 poptabs/10 min
- Craft repairs and modifications

**Warehouse** (4000 poptabs base)
- Large storage building
- **Production Bonus**: +50 poptabs/10 min
- Increases village storage capacity

#### Military Upgrades

**Barracks** (6000 poptabs base)
- Military quarters with 5 NPC recruits
- Recruitment bonus
- Faster troop training

**Training Ground** (3500 poptabs base)
- Combat training area with targets
- Troops train faster (+20% XP gain)
- Unlock advanced troop types

#### Special Upgrades

**Inn** (2000 poptabs base)
- Tavern/rest area
- Morale bonus
- Recruit companions here

**Stable** (3000 poptabs base)
- Vehicle garage
- Store vehicles safely
- Reduced repair costs

**Smithy** (5000 poptabs base)
- Blacksmith with forge
- Craft/repair weapons and armor
- Improved gear quality

**School** (8000 poptabs base)
- Education facility
- **Major Bonus**: All troops gain +1 skill level
- Very expensive, very powerful

### Upgrade Costs

**Base Cost** × (1 + 0.3 × Village Level)

Example:
- Walls at Level 1: 5000 poptabs
- Walls at Level 3: 5000 × 1.6 = 8000 poptabs

### Village Production

**Base Production**: 100 × village level (every 10 minutes)

**Upgrade Bonuses** (added to base):
- Market: +200
- Mill: +150
- Workshop: +100
- Warehouse: +50

**Example**: Level 3 village with Market + Mill + Workshop
- Base: 100 × 3 = 300
- Upgrades: 200 + 150 + 100 = 450
- **Total**: 750 poptabs every 10 minutes = **4500/hour**

### How to Upgrade

**Requirements:**
- Rank 3 (Elite) or higher
- Village must be controlled by your faction
- Sufficient funds in faction treasury

**Process:**
1. XM8 > Warbands > Kingdom Actions > Upgrade Village
2. Select village
3. Choose upgrade type
4. Confirm (deducts from faction treasury)
5. Buildings spawn immediately

**Engineer Skill Bonus:**
- Each level of Engineer reduces cost by 3%
- Level 10 Engineer = 30% cheaper upgrades!
- Also builds 25% faster

### Village Strategies

**Economic Build (Merchant Guild):**
1. Market → Warehouse → Mill → Workshop
2. Focus on passive income
3. Build School for long-term power

**Military Build (Eastern Empire):**
1. Barracks → Training Ground → Walls → Watchtower
2. Maximize troop quality
3. Strong defense

**Balanced Build (Kingdom of Altis):**
1. Walls → Barracks → Market → Inn
2. Defense + economy + morale
3. Flexible for any situation

---

## Economy & Trading

### Currency System

**Poptabs** (Exile currency) is used for everything:
- Contract rewards
- Hiring companions
- Paying ransoms
- Village upgrades
- Player trading

**Integration with Exile:**
- All Warbands transactions use Exile's money system
- Stored in player locker (safe)
- Can be dropped/stolen on death (based on server rules)
- Visible in XM8 and Exile menu

### Faction Treasuries

Each faction has a **central treasury**:

**Income Sources:**
- 10% of all contract rewards
- Ransoms (80% share)
- Village production
- Passive income from territories (100/zone/10min)
- Player donations

**Expenses:**
- Village upgrades
- Siege preparations
- Caravan sends
- Troop wages (future feature)

**Viewing Treasury:**
- XM8 > Warbands > View Treasury
- Shows current balance
- Recent transactions
- Income/expense breakdown

### Trading & Trade Skill

**Trade Skill Benefits:**
- Reduces buy prices by 5% per level
- Increases sell prices by 5% per level
- Level 10 Trade = 50% better deals!
- Stacks with companion Trade skill

**Trade Routes** (future):
- Player can run caravans between towns
- Buy low, sell high
- Risk of bandit attacks

### Looting Bonuses

**Looting Skill:**
- +10% loot from all sources per level
- Level 10 = +100% loot!
- Affects:
  - Enemy bodies
  - Crates
  - Vehicles
  - Buildings

**Scavenging Skill:**
- 15% chance per level to find rare items
- Level 10 = can find almost anything
- Works on:
  - Dead bodies
  - Wrecks
  - Abandoned buildings

**Example:**
You (Looting 5, Scavenging 3) + Companion (Looting 8)
- Effective Looting: 8 + 2 (bonus) = 10 = **+100% loot**
- Scavenging: 3 = **45% rare item chance**
- Result: Every search = double loot + almost half chance for rare gear!

### Making Money in Warbands

**Low Risk:**
1. Delivery contracts (250-750 poptabs)
2. Patrol contracts (500-1500 poptabs)
3. Sell regular prisoners (150-250 each)
4. Village production income (passive)

**Medium Risk:**
1. Escort caravans (500-1500 poptabs)
2. Clear bandit camps (500-1500 poptabs)
3. Tax collection (500-1500 poptabs)
4. Ransom prisoners (500-2000 poptabs)

**High Risk:**
1. Capture officer (750-2250 poptabs)
2. Defend fortress (1000-3000 poptabs)
3. Raid villages (600-1800 poptabs + loot)
4. Assassination (1500-4500 poptabs)
5. Siege victories (500-750 + fortress)

**Best Money-Making Strategy:**
1. Level Trade skill to 10 (or hire Trader Marcus companion)
2. Level Looting and Scavenging skills
3. Accept multiple contracts simultaneously
4. Sell all prisoner captures
5. Participate in every siege
6. Upgrade villages for passive income

**Expected Earnings:**
- Beginner (Level 1-5): 1000-2000 poptabs/hour
- Intermediate (Level 6-10): 3000-5000 poptabs/hour
- Advanced (Level 10+, companions): 7000-15000 poptabs/hour
- Villages (late game): 5000-20000 poptabs/hour passive

---

## XM8 Integration

### Accessing Warbands

**Default Key:** U (Exile XM8 default)
- Open XM8
- Click "Warbands" app icon
- Shortcut: Shift+K to open Warbands directly

### XM8 Main Screen

**Left Column - Player Status:**
- Current Faction
- Rank & Rank Name
- Renown (progress to next rank)
- Honor (scale: -100 to +100)
- Troops commanded
- Companions in party

**Right Column - Actions:**
Faction Commands (if in faction):
- View Treasury
- Available Contracts
- Recruit Troops
- Manage Prisoners

Kingdom Actions (if Rank 4+):
- Declare War
- Propose Peace
- Upgrade Village
- Order Siege (Rank 4+)
- Send Caravan (Rank 4+)

Arena:
- Join Arena Queue
- Spectate Arena

Character:
- View Skills
- Manage Companions

Join Options (if no faction):
- Join Kingdom of Altis
- Join Eastern Empire
- Join Free Companies
- Join Merchant Guild

### XM8 Sub-Screens

#### View Treasury
- Faction balance
- Recent income
- Recent expenses
- Your contribution (all-time)
- Top contributors

#### Available Contracts
- List of all contracts
- Filter by type/difficulty
- Contract details (reward, time, objective)
- Accept button

#### View Skills
- All 20 skills
- Your current levels
- Skill points available
- Improve skill button
- Effective skill (with companion bonus)

#### Manage Companions
- List of hired companions
- Companion details (name, level, skills)
- Dismiss companion button
- Nearby companions for hire

---

## Configuration

### Server Configuration

**File**: `warbands/config/WB_Settings.hpp`

**Key Settings:**
```cpp
class WB_Settings
{
    // Strategic cycle timing
    strategicCycleInterval = 300;  // 5 minutes

    // Combat settings
    battleAdvantageBase = 10;      // Starting troops in battle

    // Economic rates
    treasuryIncomeMultiplier = 1.0; // Adjust income

    // Simulation distances
    groupSimDistance = 1200;       // AI activation range
};
```

### Fortress Positions

**File**: `Exile.Altis/initServer.sqf`

Modify fortress locations:
```sqf
WB_fortressPositions = [
    ["KAV", [3584,13060,0], 90,  "warbands\fortress\fortress_templates\fortress_west.sqf"],
    // Add more fortresses or change positions
];
```

### Skill Balancing

**File**: `warbands/config/WB_CfgSkills.hpp`

Adjust skill effects:
```cpp
class DamageModifiers
{
    ironFlesh = 0.02;  // Change damage reduction per level
    marksmanship = 0.07; // Change damage bonus
};
```

### Contract Generation

**File**: `warbands/systems/WB_ContractSystem.sqf`

Modify contract rewards:
```sqf
_reward = (500 + (random 1000)) * _difficulty; // Adjust base reward
_renownReward = 5 * _difficulty; // Adjust renown
```

### Companion Templates

**File**: `warbands/systems/WB_CompanionSystem.sqf`

Add new companions or modify existing:
```sqf
WB_CompanionTemplates = [
    [
        "Your Companion Name",
        "Biography",
        "Unit_Class_Name",
        createHashMapFromArray [["SkillName", level]],
        hireCostInPoptabs
    ],
    // Add more...
];
```

---

## Tips & Strategies

### For New Players

1. **Join Civilian Faction First**
   - Easiest faction for beginners
   - Focuses on trade, not war
   - Build skills safely

2. **Start with Simple Contracts**
   - Delivery missions = easy money
   - Patrol routes = learn the map
   - Avoid sieges until Level 5+

3. **Hire Medic Andreas Early**
   - Medicine 9 saves your life
   - Surgery prevents death
   - Best first companion

4. **Level These Skills First**
   - Iron Flesh (survival)
   - Marksmanship (kill power)
   - Looting (more money)
   - Leadership (party size)

### For Advanced Players

1. **Optimal Companion Combo**
   - Medic Andreas (Medicine 9)
   - Sergeant Dimitri (Trainer 9)
   - Scout Elena (Tracking 9)
   - Engineer Sofia (Engineer 9)
   - Result: Heal anything, train fast, see everything, build cheap

2. **Honor vs Dishonor Paths**
   - **Honor (+100)**: Better recruitment, faction relations, morale bonuses
   - **Dishonor (-100)**: More intimidation, prisoners fear you, better at raiding

3. **Faction Treasury Control**
   - Donate often to show loyalty
   - Upgrade key villages first
   - Control treasury = control faction

4. **Siege Mastery**
   - Attack at night (harder to defend)
   - Bring full companion party
   - Focus defenders first, then fortress
   - Win fast = lower casualties

### Roleplay Ideas

1. **Mercenary Captain**
   - Join Free Companies
   - Switch factions for contracts
   - Build renown with all factions
   - Stay neutral in wars

2. **Noble Lord**
   - Join Kingdom of Altis
   - Upgrade all your villages
   - Manage treasury wisely
   - Defend territory honorably

3. **Bandit King**
   - Stay independent or join GUER
   - Raid enemy villages
   - Execute prisoners (dishonorable)
   - Build fear-based empire

4. **Trader Tycoon**
   - Join Merchant Guild
   - Level Trade to 10
   - Hire Trader Marcus
   - Upgrade all markets
   - Avoid combat, buy peace

---

## Troubleshooting

### Common Issues

**Q: I can't join a faction**
- **A**: Make sure you're not already in one. Leave current faction first via XM8.

**Q: Companions won't follow me**
- **A**: Re-join them to your group: Select companion > "Join Group" in action menu.

**Q: Skills don't seem to work**
- **A**: Some skills require certain conditions (Athletics only works on foot, Driving only in vehicles).

**Q: Contract disappeared**
- **A**: Contracts expire after 24 hours (or 30 min for delivery). Check expiration time before accepting.

**Q: Can't upgrade village**
- **A**: Need Rank 3+, village must be controlled by your faction, faction treasury must have funds.

**Q: Prisoner escaped**
- **A**: Level Prisoner Management skill. Each level reduces escape chance by 5%.

**Q: Faction treasury empty**
- **A**: Treasury fills from passive income (territories) and contract completions. Donate poptabs to boost it.

**Q: Siege won't start**
- **A**: Need Rank 4+, factions must be hostile (< -20 relations), faction treasury must have funds.

---

## Credits & Support

**Original Mount & Blade Concept:**
- TaleWorlds Entertainment

**Exile Warbands Development:**
- Based on Mount & Blade: Warband mechanics
- Adapted for Arma 3 Exile mod
- Fully integrated with Exile currency and systems

**Exile Mod:**
- Website: https://www.exilemod.com

**Repository:**
- https://github.com/del4778-alt/Arma-3-Exile-Scripts

---

**Version:** 1.0.0
**Last Updated:** 2025-11-12
**Compatible Exile Version:** 1.0.4+
**Required Mods:** Exile, CBA_A3

---

## Quick Reference

### Keyboard Shortcuts
- **U**: Open XM8
- **Shift+K**: Open Warbands directly
- **T**: Interact with nearby companion

### Command Hierarchy
1. Leave Faction
2. Propose Peace
3. Declare War
4. Order Siege (Rank 4+)
5. Send Caravan (Rank 4+)

### Skill Priority
**Must-Have:** Iron Flesh, Marksmanship, Leadership
**Nice-to-Have:** Athletics, Looting, Medicine
**Late-Game:** Engineering, Trade, Trainer

### Money Priority
1. Accept all simple contracts
2. Sell regular prisoners
3. Ransom faction prisoners
4. Build market in villages
5. Participate in sieges

---

*For more information, check the repository or Exile community forums.*
