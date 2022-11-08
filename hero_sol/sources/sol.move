module hero_sol::sol {
    use game::hero::{Self, Hero};
    use game::adventure::slay_boar;
    use ctf::random::rand_u64_range;
    use sui::tx_context::TxContext;

    public entry fun random(ctx: &mut TxContext) {
        assert!(rand_u64_range(0, 100, ctx) == 0, 1337);
    }

    public entry fun kill_slay_boar(hero: &mut Hero, ctx: &mut TxContext) {
        let i = 150;
        while (i > 0) {
            slay_boar(hero, ctx);
            i = i - 1;
        };
        hero::level_up(hero);
    }
}

