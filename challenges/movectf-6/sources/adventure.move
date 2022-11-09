// SPDX-License-Identifier: Apache-2.0

/// Example of a game character with basic attributes, inventory, and
/// associated logic.
module game::adventure {
    use game::inventory;
    use game::hero::{Self, Hero};
    use ctf::random;

    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// A creature that the hero can slay to level up
    struct Monster<phantom T> has key {
        id: UID,
        /// Hit points before the boar is slain
        hp: u64,
        /// Strength of this particular boar
        strength: u64,
        /// Defense of this particular boar
        defense: u64,
    }

    struct Boar {}
    struct BoarKing {}

    /// Event emitted each time a Hero slays a Boar
    struct SlainEvent<phantom T> has copy, drop {
        /// Address of the user that slayed the boar
        slayer_address: address,
        /// ID of the Hero that slayed the boar
        hero: ID,
        /// ID of the now-deceased boar
        boar: ID,
    }

    // TODO: proper error codes
    /// The hero is too tired to fight
    const EHERO_TIRED: u64 = 1;
    /// Trying to remove a sword, but the hero does not have one
    const ENO_SWORD: u64 = 4;
    const ENO_ARMOR: u64 = 5;


    /// Boar attributes values
    const BOAR_MIN_HP: u64 = 80;
    const BOAR_MAX_HP: u64 = 120;
    const BOAR_MIN_STRENGTH: u64 = 5;
    const BOAR_MAX_STRENGTH: u64 = 15;
    const BOAR_MIN_DEFENSE: u64 = 4;
    const BOAR_MAX_DEFENSE: u64 = 6;

    /// BoarKing attributes values
    const BOARKING_MIN_HP: u64 = 180;
    const BOARKING_MAX_HP: u64 = 220;
    const BOARKING_MIN_STRENGTH: u64 = 20;
    const BOARKING_MAX_STRENGTH: u64 = 25;
    const BOARKING_MIN_DEFENSE: u64 = 10;
    const BOARKING_MAX_DEFENSE: u64 = 15;

    fun create_monster<T>(
        min_hp: u64, max_hp: u64,
        min_strength: u64, max_strength: u64,
        min_defense: u64, max_defense: u64,
        ctx: &mut TxContext
    ): Monster<T> { 
        let id = object::new(ctx);       
        let hp = random::rand_u64_range(min_hp, max_hp, ctx);
        let strength = random::rand_u64_range(min_strength, max_strength, ctx);
        let defense = random::rand_u64_range(min_defense, max_defense, ctx);
        Monster<T> {
            id,
            hp,
            strength,
            defense,
        }
    }

    // --- Gameplay ---

    /// Fight with the monster
    /// return: 0: tie, 1: hero win, 2: monster win;
    fun fight_monster<T>(hero: &Hero, monster: &Monster<T>): u64 {
        let hero_strength = hero::strength(hero);
        let hero_defense = hero::defense(hero);
        let hero_hp = hero::hp(hero);
        let monster_hp = monster.hp;
        // attack the monster until its HP goes to zero
        let cnt = 0u64; // max fight times
        let rst = 0u64; // 0: tie, 1: hero win, 2: monster win;
        while (monster_hp > 0) {
            // first, the hero attacks
            let damage = if (hero_strength > monster.defense) {
                hero_strength - monster.defense
            } else {
                0
            };
            if (damage < monster_hp) {
                monster_hp = monster_hp - damage;
                // then, the boar gets a turn to attack. if the boar would kill
                // the hero, abort--we can't let the boar win!
                let damage = if (monster.strength > hero_defense) {
                    monster.strength - hero_defense
                } else {
                    0
                };
                if (damage >= hero_hp) {
                    rst = 2;
                    break
                } else {
                    hero_hp = hero_hp - damage;
                }
            } else {
                rst = 1;
                break
            };
            cnt = cnt + 1;
            if (cnt > 20) {
                break
            }
        };
        rst
    }

    public entry fun slay_boar(hero: &mut Hero, ctx: &mut TxContext) {
        assert!(hero::stamina(hero) > 0, EHERO_TIRED);
        let boar = create_monster<Boar>(
            BOAR_MIN_HP, BOAR_MAX_HP,
            BOAR_MIN_STRENGTH, BOAR_MAX_STRENGTH,
            BOAR_MIN_DEFENSE, BOAR_MAX_DEFENSE,
            ctx
        );
        let fight_result = fight_monster<Boar>(hero, &boar);
        hero::decrease_stamina(hero, 1);
        // hero takes their licks
        if (fight_result == 1) {
            hero::increase_experience(hero, 1);

            let d100 = random::rand_u64_range(0, 100, ctx);
            if (d100 < 10) {
                let sword = inventory::create_sword(ctx);
                hero::equip_or_levelup_sword(hero, sword, ctx);
            } else if (d100 < 20) {
                let armor = inventory::create_armor(ctx);
                hero::equip_or_levelup_armor(hero, armor, ctx);
            };
        };
        // let the world know about the hero's triumph by emitting an event!
        event::emit(SlainEvent<Boar> {
            slayer_address: tx_context::sender(ctx),
            hero: hero::id(hero),
            boar: object::uid_to_inner(&boar.id),
        });
        let Monster<Boar> { id, hp: _, strength: _, defense: _} = boar;
        object::delete(id);
    }

    public entry fun slay_boar_king(hero: &mut Hero, ctx: &mut TxContext) {
        assert!(hero::stamina(hero) > 0, EHERO_TIRED);
        let boar = create_monster<BoarKing>(
            BOARKING_MIN_HP, BOARKING_MAX_HP,
            BOARKING_MIN_STRENGTH, BOARKING_MAX_STRENGTH,
            BOARKING_MIN_DEFENSE, BOARKING_MAX_DEFENSE,
            ctx
        );
        let fight_result = fight_monster<BoarKing>(hero, &boar);
        hero::decrease_stamina(hero, 2);
        // hero takes their licks
        if (fight_result == 1) { // hero won
            hero::increase_experience(hero, 2);

            let d100 = random::rand_u64_range(0, 100, ctx);
            if (d100 == 0) {
                let box = inventory::create_treasury_box(ctx);
                transfer::transfer(box, tx_context::sender(ctx));
            };
        };
        // let the world know about the hero's triumph by emitting an event!
        event::emit(SlainEvent<BoarKing> {
            slayer_address: tx_context::sender(ctx),
            hero: hero::id(hero),
            boar: object::uid_to_inner(&boar.id),
        });
        let Monster<BoarKing> { id, hp: _, strength: _, defense: _} = boar;
        object::delete(id);
    }
}
