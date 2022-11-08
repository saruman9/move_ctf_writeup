module flash_sol::sol{

    use sui::tx_context::TxContext;
    use movectf::flash::{Self, FlashLender};

    public entry fun main(lender: &mut FlashLender, ctx: &mut TxContext) {
        let (coins, receipt) = flash::loan(lender, 1000, ctx);
        flash::get_flag(lender, ctx);
        flash::repay(lender, coins);
        flash::check(lender, receipt);
    }
}
