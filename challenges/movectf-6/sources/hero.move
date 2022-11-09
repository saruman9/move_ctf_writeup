// SPDX-License-Identifier: Apache-2.0

/// Example of a game character with basic attributes, inventory, and
/// associated logic.
module game::hero {
    use game::inventory::{Self, Sword, Armor};

    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use std::option::{Self, Option};

    friend game::adventure;


    /// Our hero!
    struct Hero has key, store {
        id: UID,
        /// Level of the hero.
        level: u64,
        /// Stamina points, once exhausted, the hero can't fight.
        stamina: u64,
        /// Hit points. If they go to zero, the hero can't do anything
        hp: u64,
        /// Experience of the hero. Begins at zero
        experience: u64,
        /// Level of the hero. High level will have more high attributes
        
        /// Attributes of the hero. Increasing with level and weapons.
        strength: u64,
        defense: u64,
        
        /// The hero's inventory
        sword: Option<Sword>,
        armor: Option<Armor>,
    }

    const MAX_LEVEL: u64 = 2;
    const INITAL_HERO_HP: u64 = 100;
    const INITIAL_HERO_STRENGTH: u64 = 10;
    const INITIAL_HERO_DEFENSE: u64 = 5;
    const HERO_STAMINA: u64 = 200;

    // TODO: proper error codes
    /// The boar won the battle
    const EBOAR_WON: u64 = 0;
    /// The hero is too tired to fight
    const EHERO_TIRED: u64 = 1;
    /// Trying to initialize from a non-admin account
    const ENOT_ADMIN: u64 = 2;
    /// Not enough money to purchase the given item
    const EINSUFFICIENT_FUNDS: u64 = 3;
    /// Trying to remove a sword, but the hero does not have one
    const ENO_SWORD: u64 = 4;
    const ENO_ARMOR: u64 = 5;
    /// Assertion errors for testing
    const ASSERT_ERR: u64 = 6;
    const EHERO_REACH_MAX_LEVEL: u64 = 7;

    // --- Object creation ---
    fun init(ctx: &mut TxContext) {
        let hero = create_hero(ctx);
        transfer::share_object(hero);
    }

    /// Create a hero. 
    public(friend) fun create_hero(ctx: &mut TxContext): Hero {
        Hero {
            id: object::new(ctx),
            level: 1,
            stamina: HERO_STAMINA,
            hp: INITAL_HERO_HP,
            experience: 0,
            strength: INITIAL_HERO_STRENGTH,
            defense: INITIAL_HERO_DEFENSE,
            sword: option::none(),
            armor: option::none(),
        }
    }

    /// Strength of the hero when attacking
    public fun strength(hero: &Hero): u64 {
        // a hero with zero HP is too tired to fight
        if (hero.hp == 0) {
            return 0
        };

        let sword_strength = if (option::is_some(&hero.sword)) {
            inventory::strength(option::borrow(&hero.sword))
        } else {
            // hero can fight without a sword, but will not be very strong
            0
        };
        hero.strength + sword_strength
    }

    /// Defense of the hero when attacking
    public fun defense(hero: &Hero): u64 {
        // a hero with zero HP is too tired to fight
        if (hero.hp == 0) {
            return 0
        };

        let armor_defense = if (option::is_some(&hero.armor)) {
            inventory::defense(option::borrow(&hero.armor))
        } else {
            // hero can fight without a sword, but will not be very strong
            0
        };
        hero.defense + armor_defense
    }

    public fun hp(hero: &Hero): u64 {
        hero.hp
    }

    public fun experience(hero: &Hero): u64 {
        hero.experience
    }

    public fun stamina(hero: &Hero): u64 {
        hero.stamina
    }

    public(friend) fun increase_experience(hero: &mut Hero, experience: u64) {
        hero.experience = hero.experience + experience;
    }

    public(friend) fun id(hero: &Hero): ID {
        object::uid_to_inner(&hero.id)
    }

    public(friend) fun decrease_stamina(hero: &mut Hero, stamina: u64) {
        hero.stamina = hero.stamina - stamina;
    }

    public entry fun level_up(hero: &mut Hero) {
        assert!(hero.level < MAX_LEVEL, EHERO_REACH_MAX_LEVEL);
        if (hero.experience >= 100) {
            hero.level = hero.level + 1;
            hero.strength = hero.strength + INITIAL_HERO_STRENGTH;
            hero.defense = hero.defense + INITIAL_HERO_DEFENSE;
            hero.hp = hero.hp + INITAL_HERO_HP;
            hero.experience = hero.experience - 100;
        }
    }
    // --- Equipments ---
    /// Add `new_sword` to the hero's inventory and return the old sword
    /// (if any)
    public fun equip_or_levelup_sword(hero: &mut Hero, new_sword: Sword, ctx: &mut TxContext) {
        let sword = if (option::is_some(&hero.sword)) {
            let sword = option::extract(&mut hero.sword);
            inventory::level_up_sword(&mut sword, new_sword, ctx);
            sword
        } else {
            new_sword
        };
        option::fill(&mut hero.sword, sword);
    }

    /// Disarm the hero by returning their sword.
    /// Aborts if the hero does not have a sword.
    public fun remove_sword(hero: &mut Hero): Sword {
        assert!(option::is_some(&hero.sword), ENO_SWORD);
        option::extract(&mut hero.sword)
    }

    /// Add `new_sword` to the hero's inventory and return the old sword
    /// (if any)
    public fun equip_or_levelup_armor(hero: &mut Hero, new_armor: Armor, ctx: &mut TxContext) {
        let armor = if (option::is_some(&hero.armor)) {
            let armor = option::extract(&mut hero.armor);
            inventory::level_up_armor(&mut armor, new_armor, ctx);
            armor
        } else {
            new_armor
        };
        option::fill(&mut hero.armor, armor);
    }

    /// Disarm the hero by returning their armor.
    /// Aborts if the hero does not have a armor.
    public fun remove_armor(hero: &mut Hero): Armor {
        assert!(option::is_some(&hero.armor), ENO_ARMOR);
        option::extract(&mut hero.armor)
    }

    public fun destroy_hero(hero: Hero) {
        let Hero {id, level: _, stamina: _, hp: _, experience: _, strength: _, defense: _, sword, armor} = hero;
        object::delete(id);
        if (option::is_some(&sword)) {
            let sword = option::destroy_some(sword);
            inventory::destroy_sword(sword);
        } else {
            option::destroy_none(sword);
        };
        if (option::is_some(&armor)) {
            let armor = option::destroy_some(armor);
            inventory::destroy_armor(armor);
        } else {
            option::destroy_none(armor);
        };
    }
}
