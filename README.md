# Move CTF (Nov 5 — Nov 7 / 2022) Writeup

Thanks to the organizers. It was interesting.

Disclaimer: I write everything from memory, so there may be mistakes in both the code and the text.

## `checkin` (100)

- Source: [movectf-1](https://github.com/movebit/movectf-1)
- Deploy:

```shell
$ sui client publish --gas-budget 10000 --path ./challenges/movectf-1
$ export PACKAGE_ADDRESS=0x...
```

The first task, it's the simplest. It was included in the CTF, apparently, in order to teach participants how to use the system (although a few days before that, exactly the same task had already been posted).

For all challenges, it was necessary to create an account (Sui wallet or address in a blockchain network, call it what you want), then transfer some gas (`SUI`) to it from your wallet (or get gas from a faucet).

```shell
sui client transfer-sui --to $ACCOUNT_ADDRESS --sui-coin-object-id 0x... --gas-budget 100 --amount 1000000
```

After that, you had to deploy a smart contract to a blockchain (this is done automatically, just click on `Deploy` button, see Fig. 1 below). As a result, you should get a transaction ID, from which you can find out an address of the deployed package and other objects that were created as a result of executing the `init` function.

![Interface of a challenge](https://user-images.githubusercontent.com/4244396/200733697-e2cbdb99-2667-41e2-a995-37da3fba8517.png)
> Fig. 1. Just press `Deploy` button

To get a flag, in all tasks you need to call `get_flag` function from a smart contract, as well as in this challenge. The `Flag` event occurs inside `get_flag` with `flag` field set to `true`. Thus, the system reads information about the transaction (an ID of which you'll input) and checks for the presence of an event.

Summary:

```shell
sui client call --gas-budget 10000 --package $PACKAGE_ADDRESS --module "checkin" --function "get_flag" | jq ".[1].events"
```

## `simple game` (400)

- Source: [movectf-6](https://github.com/movebit/movectf-6)
- Deploy:

```shell
$ sui client publish --gas-budget 10000 --path ./challenges/movectf-6
$ export PACKAGE_ADDRESS=0x... # and change addresses of `ctf` and `game` packages in `Move.toml`
$ export HERO=0x...
```

A "simple game", but not a simple challenge, judging by the number of assigned points.

Investigating the smart contract code, we understand that we are facing a primitive RPG game in which we need to kill monsters (easier and more difficult) and loot them. In order for `get_flag` function to work, it is necessary to provide it with `TreasuryBox` as an argument, which can be looted only in the following cases:

- you have to kill a boss monster;
- random must be kind to you so that 0 came up on a d100 virtual dice (on a real dice it would be one).

In addition, in `get_flag` function, the first thing that happens is the destruction of `TreasuryBox`, and then with the help of the same dice, a fate of a occurrence of `Flag` event is decided.

That is, there are at least two calls of the random function on our way. You should definitely look into this the random function (or trust fate and brute force random)! In `random.move` file, the CTF creators explicitly hint to us that it is necessary to hack the random function:

```move
/// @title pseudorandom
/// @notice A pseudo random module on-chain.
/// @dev Warning:
/// The random mechanism in smart contracts is different from
/// that in traditional programming languages. The value generated
/// by random is predictable to Miners, so it can only be used in
/// simple scenarios where Miners have no incentive to cheat. If
/// large amounts of money are involved, DO NOT USE THIS MODULE to
/// generate random numbers; try a more secure way.
```

Of course, it could have been a trick, so I glanced at the game code again. But everything pointed to the random function, or rather to `seed` function responsible for seed generation.

```move
fun seed(ctx: &mut TxContext): vector<u8> {
```

The function operates only with `ctx` argument, therefore we need to do something with this `ctx: &mut TxContext`. Since I'm still a complete noob in Move, I started looking for an opportunity to modify the `TxContext` by reading the documentation, Sui's whitepaper, studying Sui CLI. If I understood everything correctly, then this argument cannot be modified, it is created inside a VM on nodes. *Here I got a little desperate, lost a lot of time, and started to investigate the smart contract code again in useless.* Then the thought appeared: "maybe nothing is added to `TxContext` by a node, but it only does calculations using an input data received from a transaction?..". Since I am also a Rust developer, it was easier for me to find the answer to the question by researching Sui code. Everything pointed to the fact that `TxContext` could be precomputed.

To calculate `TxContext` I used Rust SDK. Unfortunately, it was not possible to create a separate project due to a dependency error (now you can read [issue](https://github.com/MystenLabs/sui/issues/5887)). There was no time to fix the error, so I chose another way to use Rust SDK: I created a file `hero.rs` in the directory with examples for `sui-sdk` crate ([commit 34944fe5](https://github.com/saruman9/sui/commit/34944fe5c2966c1944e8075e466b0bc4a45114c2)). Fortunately, it worked.

Now we need to understand what `TxContext` should be so that the dice always come up on the side with 0. To do this, just repeat all the operations ([`seed`](https://github.com/movebit/movectf-6/blob/aaa3694518897ee304e8f0e88d48314aacea52cd/sources/random.move#L23-L35), [`bytes_to_u64`](https://github.com/movebit/movectf-6/blob/aaa3694518897ee304e8f0e88d48314aacea52cd/sources/random.move#L37-L45)) in Rust code ([`seed`](https://github.com/saruman9/sui/blob/34944fe5c2966c1944e8075e466b0bc4a45114c2/crates/sui-sdk/examples/hero.rs#L78-L88), [`bytes_to_u64`](https://github.com/saruman9/sui/blob/34944fe5c2966c1944e8075e466b0bc4a45114c2/crates/sui-sdk/examples/hero.rs#L138-L155)).

So that a new `TxContext` is generated each time I changed a count of gas, I think it was possible not to do it. Also, due to the fact that `move_call` function constantly makes a request for a signature of a function from a package, the working time of all this DIY was greatly increased, but I didn't have time to figure out how it could be optimized.

In order to get the treasure, it was necessary to kill a boss monster. To kill a boss with a higher probability, it was necessary [to level up on small monsters](./hero_sol/sources/sol.move). At the same time, during the killing of a boss, it is necessary to get 0 on the dice, and for this it was necessary [to calculate future changes in `TxContext`](https://github.com/saruman9/sui/blob/34944fe5c2966c1944e8075e466b0bc4a45114c2/crates/sui-sdk/examples/hero.rs#L74-L77):

- calling [`object::new`](https://github.com/MystenLabs/sui/blob/a149bdaea53276c205a1ccf1ecb21b19ad81cdb2/crates/sui-framework/sources/object.move#L107-L113) ,
- i.e. calling [`new_object(ctx: &mut TxContext)`](https://github.com/MystenLabs/sui/blob/a149bdaea53276c205a1ccf1ecb21b19ad81cdb2/crates/sui-framework/sources/tx_context.move#L52-L58)

increment of a value in the field [`ids_created`](https://github.com/MystenLabs/sui/blob/a149bdaea53276c205a1ccf1ecb21b19ad81cdb2/crates/sui-framework/sources/tx_context.move#L34), which affected a generation of `seed`.

After the treasure is in our hands, we need to calculate `TxContext` again so that everything is not in waste, because in `get_flag` function, the treasure is first destroyed, and then the dice is checked:

```move
let TreasuryBox { id } = box;
object::delete(id);
let d100 = random::rand_u64_range(0, 100, ctx);
if (d100 == 0) {
    event::emit(Flag { user: tx_context::sender(ctx), flag: true });
}
```

Summary:

```shell
$ export WALLET_ADDRESS=$(sui client active-address)
$ sui client publish --path ./hero_sol --gas-budget 10000
$ export SOLUTION_ADDRESS=0x...
$ sui client call --gas-budget 1000000 --package $SOLUTION_ADDRESS --module "sol" --function "kill_slay_boar" --args $HERO
$ cd sui # use `sui` repo and `move_ctf_2022` branch from https://github.com/saruman9/sui
$ cargo run --example hero -- -p $PACKAGE_ADDRESS -m adventure -f slay_boar_king -o 4 $HERO
$ export TREASURY_BOX=0x...
$ cargo run --example hero -- -p $PACKAGE_ADDRESS -m inventory -f get_flag $TREASURY_BOX
```

## `flash loan` (200)

- Source: [movectf-4](https://github.com/movebit/movectf-4)
- Deploy:

```shell
$ sui client publish --gas-budget 10000 --path ./challenges/movectf-4
$ export PACKAGE_ADDRESS=0x... # and change address of `movectf` package in `Move.toml`
$ export LENDER=0x...
```

To be honest, I'm still not sure that I solved this task correctly, because it seemed too easy to me.

Starting from the end: in order for `Flag` event to be generated, it is necessary that `FlashLender` has no money in the account. So let's borrow from them, [call `get_flag` and immediately return the debt](./flash_sol/sources/module.move):

```move
let (coins, receipt) = flash::loan(lender, 1000, ctx);
flash::get_flag(lender, ctx);
flash::repay(lender, coins);
flash::check(lender, receipt);
```

Summary:

```shell
$ sui client publish --path ./flash_sol --gas-budget 10000
$ export SOLUTION_ADDRESS=0x...
$ sui client call --json --gas-budget 10000 --package $SOLUTION_ADDRESS --module sol --function main --args $LENDER | jq ".[1].events"
```

## `move lock` (300)

- Source: [movectf-5](https://github.com/movebit/movectf-5)
- Deploy:

```shell
$ sui client publish --gas-budget 10000 --path ./challenges/movectf-5
$ export PACKAGE_ADDRESS=0x... # and change address of `movectf` package in `Move.toml`
$ export LENDER=0x...
$ export RESOURCE_OBJECT=0x...
```

Again, we start from the end: in order for `Flag` event to be generated, it is necessary that `resource_object.q1 == true`. This will be true only under one condition — the return of `movectf_lock` function must be equal to `encrypted_flag`.

Two arguments are used by `movectf_lock` function, later we will understand that these are `plaintext` and `key`, and at the output we get `ciphertext`. After looking at the function code, the first thing I thought about was SMT Solver, for example, Z3, which helped me out more than once when writing keygen or tricky exploits.

Here I will not describe Z3 and its API, I will only tell you about the problems I encountered. My first attempt was [to implement the entire code](https://github.com/saruman9/move_ctf_writeup/blob/164ca06010804d42eb8e4dfeb8412d3eef0c7710/z3_sol/sol.py#L144-L250) head-on. In the during of developing, I ran the script every time, checking a speed. After writing the last constraint ([`ciphertext == complete_ciphertext`](https://github.com/saruman9/move_ctf_writeup/blob/164ca06010804d42eb8e4dfeb8412d3eef0c7710/z3_sol/sol.py#L226-L227)), Z3 hung deadly, could not check a satisfiability of even one iteration. In desperate attempts, I tried to add additional constraints to make it easier for Z3, but I was only able to get a satisfiability check, but a model was built indefinitely (everything was worked on a laptop, i.e. a mobile processor was used, maybe this is also the reason). In general, I have killed a lot of time optimizing the solver constraints. Much later, I decided to read the smart contract code thoughtfully. Here I found that it is possible to calculate the `key` ([`solve_key`](https://github.com/saruman9/move_ctf_writeup/blob/164ca06010804d42eb8e4dfeb8412d3eef0c7710/z3_sol/sol.py#L41-L122)) without problems, there is more than enough input data, you can even solve equations, SMT Solver is not needed here at all. Well, then I calculated `plaintext` ([`solve_plaintext`](https://github.com/saruman9/move_ctf_writeup/blob/164ca06010804d42eb8e4dfeb8412d3eef0c7710/z3_sol/sol.py#L4-L38)).

I tried to pass the resulting answer — of course, a mistake. In general, I had [to rewrite the encryption algorithm in Rust](./encrypt) (it was not difficult, a primitive Move code is practically copied to Rust) to fix a bunch of arithmetic errors that I made when porting the Move code to Python Z3.

Summary:

```shell
$ python ./z3_sol/sol.py
$ sui client call --gas-budget 1000000 --package $PACKAGE_ADDRESS --module "move_lock" --function "movectf_unlock" --args "[184, 14, ..., 65, 4, 695]" "[25, 11, 6, ..., 19, 2]" $RESOURCE_OBJECT
$ sui client call --json --gas-budget 1000000 --package $PACKAGE_ADDRESS --module "move_lock" --function "get_flag" --args $RESOURCE_OBJECT | jq ".[1].events"
```
