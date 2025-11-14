/**
 * Warbands Skills Configuration
 * Adapted from Mount & Blade for Arma 3 Exile
 *
 * Skill Types:
 * - Personal: Affects only the player
 * - Party: Affects the player's group/faction
 * - Leader: Only leader's level counts
 */

class WB_Skills
{
    // COMBAT SKILLS (Personal - based on Strength in M&B)
    class IronFlesh
    {
        displayName = "Iron Flesh";
        type = "personal";
        attribute = "combat";
        description = "Increases health and damage resistance";
        maxLevel = 10;
        effect = "2% damage reduction per level, +10 HP per level";
    };

    class PowerStrike
    {
        displayName = "Power Strike";
        type = "personal";
        attribute = "combat";
        description = "Increases melee and close combat damage";
        maxLevel = 10;
        effect = "8% melee damage increase per level";
    };

    class Marksmanship
    {
        displayName = "Marksmanship";
        type = "personal";
        attribute = "combat";
        description = "Increases ranged weapon accuracy and damage";
        maxLevel = 10;
        effect = "5% accuracy and 7% damage per level";
        note = "Replaces Power Draw from M&B for firearms";
    };

    class WeaponMaster
    {
        displayName = "Weapon Master";
        type = "personal";
        attribute = "combat";
        description = "Faster weapon proficiency gain and better handling";
        maxLevel = 10;
        effect = "Faster reload, reduced recoil, better weapon handling";
    };

    class Shield
    {
        displayName = "Shield Mastery";
        type = "personal";
        attribute = "combat";
        description = "Better use of ballistic shields and cover";
        maxLevel = 10;
        effect = "8% damage reduction when using shields/cover";
    };

    // TACTICAL SKILLS (Personal/Party - based on Agility in M&B)
    class Athletics
    {
        displayName = "Athletics";
        type = "personal";
        attribute = "tactical";
        description = "Increases movement speed and stamina";
        maxLevel = 10;
        effect = "5% speed increase per level, faster stamina recovery";
    };

    class Driving
    {
        displayName = "Driving";
        type = "personal";
        attribute = "tactical";
        description = "Better vehicle handling and speed";
        maxLevel = 10;
        effect = "Improved vehicle performance and reduced fuel consumption";
        note = "Replaces Riding from M&B";
    };

    class MountedGunnery
    {
        displayName = "Mounted Gunnery";
        type = "personal";
        attribute = "tactical";
        description = "Better accuracy when shooting from vehicles";
        maxLevel = 10;
        effect = "10% accuracy bonus per level from vehicles";
        note = "Replaces Horse Archery from M&B";
    };

    class Looting
    {
        displayName = "Looting";
        type = "party";
        attribute = "tactical";
        description = "Increases loot from battles and raids";
        maxLevel = 10;
        effect = "10% more loot per level, faster looting speed";
    };

    // LEADERSHIP SKILLS (Party/Leader - based on Intelligence in M&B)
    class Trainer
    {
        displayName = "Trainer";
        type = "personal";
        attribute = "leadership";
        description = "Grants experience to party members daily";
        maxLevel = 10;
        effect = "Train troops faster, stacks with multiple trainers";
    };

    class Tracking
    {
        displayName = "Tracking";
        type = "party";
        attribute = "leadership";
        description = "See enemy movement on map, track parties";
        maxLevel = 10;
        effect = "Greater track visibility and information";
    };

    class Tactics
    {
        displayName = "Tactics";
        type = "party";
        attribute = "leadership";
        description = "Better combat positioning and reinforcements";
        maxLevel = 10;
        effect = "+1 battle advantage per 2 levels";
    };

    class Pathfinding
    {
        displayName = "Pathfinding";
        type = "party";
        attribute = "leadership";
        description = "Increases party movement speed on map";
        maxLevel = 10;
        effect = "3% map speed increase per level";
    };

    class Spotting
    {
        displayName = "Spotting";
        type = "party";
        attribute = "leadership";
        description = "Increases sight range and detection";
        maxLevel = 10;
        effect = "10% sight range increase per level";
    };

    class InventoryManagement
    {
        displayName = "Inventory Management";
        type = "leader";
        attribute = "leadership";
        description = "Increases carrying capacity";
        maxLevel = 10;
        effect = "6 extra slots per level (60 max)";
    };

    class WoundTreatment
    {
        displayName = "Wound Treatment";
        type = "party";
        attribute = "leadership";
        description = "Faster healing for wounded troops";
        maxLevel = 10;
        effect = "20% faster healing per level";
    };

    class Surgery
    {
        displayName = "Surgery";
        type = "party";
        attribute = "leadership";
        description = "Saves troops from death in combat";
        maxLevel = 10;
        effect = "4% chance to save downed troops per level";
    };

    class FirstAid
    {
        displayName = "First Aid";
        type = "party";
        attribute = "leadership";
        description = "Heroes recover health after battles";
        maxLevel = 10;
        effect = "5% health recovery per level";
    };

    class Engineer
    {
        displayName = "Engineer";
        type = "party";
        attribute = "leadership";
        description = "Build fortifications and upgrades faster";
        maxLevel = 10;
        effect = "Faster building, lower upgrade costs";
    };

    // SOCIAL SKILLS (Personal/Leader - based on Charisma in M&B)
    class Persuasion
    {
        displayName = "Persuasion";
        type = "personal";
        attribute = "social";
        description = "Better negotiation and recruitment";
        maxLevel = 10;
        effect = "4% recruitment success, better trade deals";
    };

    class PrisonerManagement
    {
        displayName = "Prisoner Management";
        type = "leader";
        attribute = "social";
        description = "Hold more prisoners, better conversion";
        maxLevel = 10;
        effect = "+5 prisoner slots, reduced escape chance";
    };

    class Leadership
    {
        displayName = "Leadership";
        type = "leader";
        attribute = "social";
        description = "Command more troops, better morale";
        maxLevel = 10;
        effect = "+5 troop slots, -5% wages, +5% morale per level";
    };

    class Trade
    {
        displayName = "Trade";
        type = "party";
        attribute = "social";
        description = "Better trading prices and profits";
        maxLevel = 10;
        effect = "-5% trade penalty per level";
    };

    // NEW SKILLS FOR ARMA 3 EXILE
    class Explosives
    {
        displayName = "Explosives";
        type = "personal";
        attribute = "combat";
        description = "Better use of explosives and mines";
        maxLevel = 10;
        effect = "Increased blast radius and damage";
    };

    class Piloting
    {
        displayName = "Piloting";
        type = "personal";
        attribute = "tactical";
        description = "Fly aircraft better, reduced crashes";
        maxLevel = 10;
        effect = "Better aircraft handling and fuel efficiency";
    };

    class Medicine
    {
        displayName = "Medicine";
        type = "personal";
        attribute = "leadership";
        description = "Heal yourself and others more effectively";
        maxLevel = 10;
        effect = "50% more health restored per medkit use";
    };

    class Lockpicking
    {
        displayName = "Lockpicking";
        type = "personal";
        attribute = "tactical";
        description = "Open locked vehicles and containers";
        maxLevel = 10;
        effect = "Faster lockpicking, higher success rate";
    };

    class Scavenging
    {
        displayName = "Scavenging";
        type = "party";
        attribute = "tactical";
        description = "Find more resources while looting";
        maxLevel = 10;
        effect = "15% chance to find rare items per level";
    };
};

/**
 * Skill Point Costs
 * Based on Mount & Blade progression
 */
class WB_SkillCosts
{
    // Cost to upgrade to next level
    // Formula: level * multiplier
    multiplier = 1;

    // Experience needed per level
    class ExperiencePerLevel
    {
        level_1 = 100;
        level_2 = 300;
        level_3 = 600;
        level_4 = 1000;
        level_5 = 1500;
        level_6 = 2100;
        level_7 = 2800;
        level_8 = 3600;
        level_9 = 4500;
        level_10 = 5500;
    };

    // Skill points per player level
    skillPointsPerLevel = 1;

    // Party skill bonus (from M&B)
    // If leader has skill level 2-4: +1 bonus
    // If leader has skill level 5-7: +2 bonus
    // If leader has skill level 8-9: +3 bonus
    // If leader has skill level 10: +4 bonus
};

/**
 * Skill Effects Integration
 * How skills affect gameplay
 */
class WB_SkillEffects
{
    // These are applied via event handlers and periodic checks
    // See warbands/systems/WB_SkillSystem.sqf for implementation

    class DamageModifiers
    {
        ironFlesh = 0.02;        // 2% damage reduction per level
        powerStrike = 0.08;      // 8% melee damage per level
        marksmanship = 0.07;     // 7% ranged damage per level
        shield = 0.08;           // 8% shield damage reduction per level
        explosives = 0.10;       // 10% explosive damage per level
    };

    class SpeedModifiers
    {
        athletics = 0.05;        // 5% speed increase per level
        driving = 0.08;          // 8% vehicle speed per level
        pathfinding = 0.03;      // 3% map speed per level
    };

    class CapacityModifiers
    {
        inventoryManagement = 6;  // +6 slots per level
        prisonerManagement = 5;   // +5 prisoner slots per level
        leadership = 5;           // +5 troop slots per level
    };

    class EconomyModifiers
    {
        trade = 0.05;            // -5% trade penalty per level
        leadership = 0.05;       // -5% troop wages per level
        looting = 0.10;          // +10% loot per level
    };
};
