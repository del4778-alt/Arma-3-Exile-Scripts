/**
 * Warbands - Fallout 4 SPECIAL + Perks System
 * Replaces Mount & Blade skills with Fallout 4 character system
 * Optimized for Arma 3 gun combat
 */

/**
 * SPECIAL Attributes (Base Stats)
 * Each starts at 1, can go up to 10
 * Costs 1 point per level
 */
class WB_SPECIAL
{
    class Strength
    {
        displayName = "Strength";
        description = "Raw physical power. Increases melee damage and carry weight.";
        startValue = 1;
        maxValue = 10;
        effect = "+10 carry weight per point";
    };

    class Perception
    {
        displayName = "Perception";
        description = "Environmental awareness. Better accuracy and detection range.";
        startValue = 1;
        maxValue = 10;
        effect = "+5% accuracy per point, +10m spotting range";
    };

    class Endurance
    {
        displayName = "Endurance";
        description = "Fitness and resilience. More health and stamina.";
        startValue = 1;
        maxValue = 10;
        effect = "+25 HP per point, +10% stamina regen";
    };

    class Charisma
    {
        displayName = "Charisma";
        description = "Charm and personality. Better prices and speech success.";
        startValue = 1;
        maxValue = 10;
        effect = "-2% buy prices per point, +5% persuasion success";
    };

    class Intelligence
    {
        displayName = "Intelligence";
        description = "Mental acuity. More experience gain and faster hacking.";
        startValue = 1;
        maxValue = 10;
        effect = "+3% XP gain per point";
    };

    class Agility
    {
        displayName = "Agility";
        description = "Nimbleness and reflexes. Faster movement and reload.";
        startValue = 1;
        maxValue = 10;
        effect = "+2% move speed per point, faster reloads";
    };

    class Luck
    {
        displayName = "Luck";
        description = "Fate's favor. Better loot, more crits, and random rewards.";
        startValue = 1;
        maxValue = 10;
        effect = "+3% crit chance per point, +5% better loot";
    };
};

/**
 * Combat Perks (Gun-focused for Arma 3)
 */
class WB_CombatPerks
{
    // Rifle Perks
    class Rifleman
    {
        displayName = "Rifleman";
        description = "Keep your distance long and your kill-count high.";
        attribute = "Perception";
        attributeRequired = 2;
        maxRank = 5;
        ranks[] = {
            "Rank 1: +20% damage with non-automatic rifles",
            "Rank 2: +40% damage and improved hip-fire accuracy",
            "Rank 3: +60% damage and +25% range",
            "Rank 4: +80% damage and -25% recoil",
            "Rank 5: +100% damage and chance to cripple limbs"
        };
    };

    class Commando
    {
        displayName = "Commando";
        description = "Rigorous combat training means automatic weapons do more damage.";
        attribute = "Agility";
        attributeRequired = 2;
        maxRank = 5;
        ranks[] = {
            "Rank 1: +20% damage with automatic weapons",
            "Rank 2: +40% damage and better hip-fire",
            "Rank 3: +60% damage and faster reload",
            "Rank 4: +80% damage and -30% recoil",
            "Rank 5: +100% damage and improved suppression"
        };
    };

    class Gunslinger
    {
        displayName = "Gunslinger";
        description = "Channel the power of the Old West with pistols.";
        attribute = "Agility";
        attributeRequired = 1;
        maxRank = 5;
        ranks[] = {
            "Rank 1: +25% damage with pistols",
            "Rank 2: +50% damage and faster draw",
            "Rank 3: +75% damage and +25% hip-fire accuracy",
            "Rank 4: +100% damage and -50% recoil",
            "Rank 5: +125% damage and disarm chance"
        };
    };

    class Sniper
    {
        displayName = "Sniper";
        description = "It's all about focus. Superior long-range accuracy.";
        attribute = "Perception";
        attributeRequired = 5;
        maxRank = 3;
        ranks[] = {
            "Rank 1: +25% accuracy with scoped weapons, hold breath longer",
            "Rank 2: +50% accuracy, -50% scope sway",
            "Rank 3: +75% accuracy, headshots do massive bonus damage"
        };
    };

    class Heavy Gunner
    {
        displayName = "Heavy Gunner";
        description = "Carry big guns and deal devastating damage.";
        attribute = "Strength";
        attributeRequired = 5;
        maxRank = 5;
        ranks[] = {
            "Rank 1: +20% damage with heavy weapons (LMG, MMG, launchers)",
            "Rank 2: +40% damage and -20% weapon weight",
            "Rank 3: +60% damage and faster spin-up",
            "Rank 4: +80% damage and improved hip-fire",
            "Rank 5: +100% damage and chance to stagger enemies"
        };
    };

    class Demolition Expert
    {
        displayName = "Demolition Expert";
        description = "The bigger the boom, the better.";
        attribute = "Perception";
        attributeRequired = 5;
        maxRank = 4;
        ranks[] = {
            "Rank 1: +25% explosive damage and radius",
            "Rank 2: +50% explosive damage, mines are harder to detect",
            "Rank 3: +75% explosive damage, can disarm enemy mines",
            "Rank 4: +100% explosive damage, explosives have double radius"
        };
    };

    // Critical Hit Perks
    class Critical Banker
    {
        displayName = "Critical Banker";
        description = "Save up critical hits for when you need them.";
        attribute = "Luck";
        attributeRequired = 7;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Store 1 critical hit",
            "Rank 2: Store 2 critical hits",
            "Rank 3: Store 3 critical hits and +15% crit chance"
        };
    };

    class Better Criticals
    {
        displayName = "Better Criticals";
        description = "Advanced training for enhanced critical hits.";
        attribute = "Luck";
        attributeRequired = 6;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Critical hits do +50% damage",
            "Rank 2: Critical hits do +100% damage",
            "Rank 3: Critical hits do +150% damage and ignore armor"
        };
    };

    class Bloody Mess
    {
        displayName = "Bloody Mess";
        description = "More violent death animations and +5% damage.";
        attribute = "Luck";
        attributeRequired = 3;
        maxRank = 4;
        ranks[] = {
            "Rank 1: +5% damage to all attacks",
            "Rank 2: +10% damage to all attacks",
            "Rank 3: +15% damage to all attacks",
            "Rank 4: +15% damage and enemies have chance to explode"
        };
    };
};

/**
 * Crafting & Utility Perks
 */
class WB_CraftingPerks
{
    class Gun Nut
    {
        displayName = "Gun Nut";
        description = "Shoot better, modify better, with access to weapon mods.";
        attribute = "Intelligence";
        attributeRequired = 3;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Unlock Rank 1 weapon mods (scopes, grips)",
            "Rank 2: Unlock Rank 2 weapon mods (suppressors, magazines)",
            "Rank 3: Unlock Rank 3 weapon mods (advanced barrels, stocks)",
            "Rank 4: Unlock Rank 4 weapon mods (master mods, unique attachments)"
        };
    };

    class Armorer
    {
        displayName = "Armorer";
        description = "Protect yourself from the dangers of the Wasteland.";
        attribute = "Strength";
        attributeRequired = 3;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Unlock Rank 1 armor mods (basic plates)",
            "Rank 2: Unlock Rank 2 armor mods (improved protection)",
            "Rank 3: Unlock Rank 3 armor mods (advanced materials)",
            "Rank 4: Unlock Rank 4 armor mods (legendary upgrades)"
        };
    };

    class Science
    {
        displayName = "Science!";
        description = "Take full advantage of advanced technology.";
        attribute = "Intelligence";
        attributeRequired = 6;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Hack terminals, unlock Rank 1 energy weapon mods",
            "Rank 2: Faster hacking, Rank 2 energy weapon mods",
            "Rank 3: Advanced hacking, Rank 3 energy weapon mods",
            "Rank 4: Master hacking, Rank 4 energy weapon mods"
        };
    };

    class Scrapper
    {
        displayName = "Scrapper";
        description = "Waste not, want not. Salvage more from scrapping items.";
        attribute = "Intelligence";
        attributeRequired = 5;
        maxRank = 2;
        ranks[] = {
            "Rank 1: Get more materials when scrapping weapons and armor",
            "Rank 2: Get rare components from scrapped items"
        };
    };

    class Locksmith
    {
        displayName = "Locksmith";
        description = "Your bobby pins never break, and picking locks is a breeze.";
        attribute = "Perception";
        attributeRequired = 4;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Pick Advanced locks",
            "Rank 2: Pick Expert locks, faster picking",
            "Rank 3: Pick Master locks",
            "Rank 4: Unbreakable bobby pins, instantly pick any lock"
        };
    };
};

/**
 * Stealth & Survival Perks
 */
class WB_StealthPerks
{
    class Sneak
    {
        displayName = "Sneak";
        description = "Become whisper, become shadow.";
        attribute = "Agility";
        attributeRequired = 3;
        maxRank = 5;
        ranks[] = {
            "Rank 1: Harder to detect while sneaking",
            "Rank 2: Much harder to detect, move faster while sneaking",
            "Rank 3: Nearly invisible while sneaking and stationary",
            "Rank 4: No longer trigger floor traps, can place live grenades in pockets",
            "Rank 5: Running does not affect stealth"
        };
    };

    class Ninja
    {
        displayName = "Ninja";
        description = "Trained as a shadow warrior. Sneak attacks do massive damage.";
        attribute = "Agility";
        attributeRequired = 7;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Sneak attacks do 2.5x damage",
            "Rank 2: Sneak attacks do 3.5x damage",
            "Rank 3: Sneak attacks do 4.5x damage with ranged weapons and 10x with melee"
        };
    };

    class Mister Sandman
    {
        displayName = "Mister Sandman";
        description = "As a Sandman, you can instantly kill sleeping people.";
        attribute = "Agility";
        attributeRequired = 4;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Silently kill sleeping people, +15% damage with silenced weapons",
            "Rank 2: +30% damage with silenced weapons",
            "Rank 3: +50% damage with silenced weapons"
        };
    };
};

/**
 * Survival & Utility Perks
 */
class WB_SurvivalPerks
{
    class Medic
    {
        displayName = "Medic";
        description = "Knowledge of the human body boosts stimpak effectiveness.";
        attribute = "Intelligence";
        attributeRequired = 2;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Stimpaks restore 40% more health",
            "Rank 2: Stimpaks restore 60% more health, RadAway works twice as fast",
            "Rank 3: Stimpaks restore 80% more health",
            "Rank 4: Stimpaks restore 100% more health and cure addictions"
        };
    };

    class Lifegiver
    {
        displayName = "Lifegiver";
        description = "You embody wellness! Instantly gain +20 maximum Health.";
        attribute = "Endurance";
        attributeRequired = 3;
        maxRank = 3;
        ranks[] = {
            "Rank 1: +20 maximum Health",
            "Rank 2: +40 maximum Health",
            "Rank 3: +60 maximum Health and slowly regenerate health"
        };
    };

    class Chemist
    {
        displayName = "Chemist";
        description = "Any chems you take last twice as long.";
        attribute = "Intelligence";
        attributeRequired = 7;
        maxRank = 4;
        ranks[] = {
            "Rank 1: Chems last 50% longer",
            "Rank 2: Chems last 100% longer",
            "Rank 3: Chems last 150% longer and -50% addiction chance",
            "Rank 4: Chems last 200% longer and no addiction"
        };
    };

    class Strong Back
    {
        displayName = "Strong Back";
        description = "Carry that weight! Gain +25 carry weight.";
        attribute = "Strength";
        attributeRequired = 6;
        maxRank = 5;
        ranks[] = {
            "Rank 1: +25 carry weight",
            "Rank 2: +50 carry weight",
            "Rank 3: +75 carry weight, can run while overencumbered",
            "Rank 4: +100 carry weight",
            "Rank 5: +100 carry weight and fast travel while overencumbered"
        };
    };

    class Lone Wanderer
    {
        displayName = "Lone Wanderer";
        description = "Who needs friends? +25% damage and -30% damage taken when alone.";
        attribute = "Charisma";
        attributeRequired = 3;
        maxRank = 3;
        ranks[] = {
            "Rank 1: +25% damage, -15% damage taken when alone",
            "Rank 2: +50% damage, -30% damage taken when alone",
            "Rank 3: +75% damage, -45% damage taken, +50 carry weight when alone"
        };
    };

    class Action Boy
    {
        displayName = "Action Boy/Girl";
        description = "There's no time to waste! Faster stamina regeneration.";
        attribute = "Agility";
        attributeRequired = 5;
        maxRank = 3;
        ranks[] = {
            "Rank 1: +25% stamina regeneration",
            "Rank 2: +50% stamina regeneration",
            "Rank 3: +75% stamina regeneration, sprint costs no stamina"
        };
    };
};

/**
 * Social & Economy Perks
 */
class WB_SocialPerks
{
    class Cap Collector
    {
        displayName = "Cap Collector";
        description = "Buying and selling prices are better.";
        attribute = "Charisma";
        attributeRequired = 1;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Prices are 5% better",
            "Rank 2: Prices are 10% better and find more caps in containers",
            "Rank 3: Prices are 15% better and merchants have more caps"
        };
    };

    class Local Leader
    {
        displayName = "Local Leader";
        description = "Control and build complex structures at settlements.";
        attribute = "Charisma";
        attributeRequired = 6;
        maxRank = 2;
        ranks[] = {
            "Rank 1: Build stores and workbenches at settlements",
            "Rank 2: Build trade caravans between settlements"
        };
    };

    class Inspirational
    {
        displayName = "Inspirational";
        description = "You are the inspirational lighthouse. Companions do more damage.";
        attribute = "Charisma";
        attributeRequired = 8;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Companions do +10% damage",
            "Rank 2: Companions do +20% damage and take less damage",
            "Rank 3: Companions do +30% damage, take -30% damage, and cannot be killed"
        };
    };

    class Party Boy
    {
        displayName = "Party Boy/Girl";
        description = "Nobody has a good time like you! Alcohol buffs doubled.";
        attribute = "Endurance";
        attributeRequired = 7;
        maxRank = 3;
        ranks[] = {
            "Rank 1: Alcohol effects doubled, no addiction",
            "Rank 2: Alcohol effects tripled and +3 STR/END",
            "Rank 3: Alcohol effects quadrupled, heal while drunk"
        };
    };
};

/**
 * Special Advanced Perks
 */
class WB_AdvancedPerks
{
    class Concentrated Fire
    {
        displayName = "Concentrated Fire";
        description = "Successive attacks on the same target do more damage.";
        attribute = "Perception";
        attributeRequired = 10;
        maxRank = 3;
        ranks[] = {
            "Rank 1: +10% damage for each consecutive hit on same target",
            "Rank 2: +15% damage for each consecutive hit",
            "Rank 3: +20% damage for each consecutive hit, stacks up to 5 times"
        };
    };

    class Penetrator
    {
        displayName = "Penetrator";
        description = "Your shots ignore armor.";
        attribute = "Perception";
        attributeRequired = 9;
        maxRank = 2;
        ranks[] = {
            "Rank 1: Shots ignore 25% of target's armor",
            "Rank 2: Shots ignore 50% of target's armor"
        };
    };

    class Grim Reaper's Sprint
    {
        displayName = "Grim Reaper's Sprint";
        description = "Killing restores stamina instantly.";
        attribute = "Luck";
        attributeRequired = 8;
        maxRank = 3;
        ranks[] = {
            "Rank 1: 15% chance on kill to restore full stamina",
            "Rank 2: 25% chance on kill to restore full stamina",
            "Rank 3: 35% chance on kill to restore full stamina and health"
        };
    };

    class Four Leaf Clover
    {
        displayName = "Four Leaf Clover";
        description = "Each hit has a chance to fill your critical meter.";
        attribute = "Luck";
        attributeRequired = 9;
        maxRank = 4;
        ranks[] = {
            "Rank 1: 3% chance each hit fills critical meter",
            "Rank 2: 5% chance each hit fills critical meter",
            "Rank 3: 7% chance each hit fills critical meter",
            "Rank 4: 10% chance each hit fills critical meter"
        };
    };

    class Ricochet
    {
        displayName = "Ricochet";
        description = "Enemies have a chance to suffer their own damage when attacking.";
        attribute = "Luck";
        attributeRequired = 10;
        maxRank = 3;
        ranks[] = {
            "Rank 1: 10% chance to reflect damage",
            "Rank 2: 20% chance to reflect damage",
            "Rank 3: 30% chance to reflect damage and stun attacker"
        };
    };
};

/**
 * Perk Requirements System
 * Each perk requires minimum SPECIAL attribute level
 */
class WB_PerkRequirements
{
    // Format: [AttributeName, MinLevel, PerkPointCost]

    // Example: Rifleman Rank 1 requires Perception 2
    // Rifleman Rank 2 requires Perception 2 + Level 9
    // etc.

    levelRequirements[] = {
        2, 3, 5, 7, 9,     // Perk rank level requirements
        11, 13, 15, 17, 19
    };
};
