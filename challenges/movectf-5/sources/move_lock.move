module movectf::move_lock {
    
    // [*] Import dependencies
    use std::vector;

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
 
    // [*] Structs
    struct ResourceObject has key, store {
        id : UID,
        balance: u128,
        q1: bool
    }
 
    struct Flag has copy, drop {
        user: address,
        flag: bool
    }
 
    // [*] Module initializer
    fun init(ctx: &mut TxContext) {
        transfer::share_object(ResourceObject {
            id: object::new(ctx),
            balance: 100,
            q1: false,
        })
    }
 
    // [*] Public functions
    public entry fun movectf_unlock(data1 : vector<u64>, data2 : vector<u64>, resource_object: &mut ResourceObject, _ctx: &mut TxContext) {
        
        let encrypted_flag : vector<u64> = vector[19, 16, 17, 11, 9, 21, 18, 
                                                  2, 3, 22, 7, 4, 25, 21, 5, 
                                                  7, 23, 6, 23, 5, 13, 3, 5, 
                                                  9, 16, 12, 22, 14, 3, 14, 12, 
                                                  22, 18, 4, 3, 9, 2, 19, 5, 
                                                  16, 7, 20, 1, 11, 18, 23, 4, 
                                                  15, 20, 5, 24, 9, 1, 12, 5, 
                                                  16, 10, 7, 2, 1, 21, 1, 25, 
                                                  18, 22, 2, 2, 7, 25, 15, 7, 10];

        if (movectf_lock(data1, data2) == encrypted_flag) {
            if (!resource_object.q1) {
                resource_object.q1 = true;
            }
        }

    }

    fun movectf_lock(data1 : vector<u64>, data2 : vector<u64>) : vector<u64> {
        
        let input1 = copy data1;
        let plaintext = &mut input1;
        let plaintext_length = vector::length(plaintext);
        assert!(plaintext_length > 3, 0);

        if ( plaintext_length % 3 != 0) {
            if (3 - (plaintext_length % 3) == 2) {
                vector::push_back(plaintext, 0);
                vector::push_back(plaintext, 0);
                plaintext_length = plaintext_length + 2;
            }
            else {
                vector::push_back(plaintext, 0);
                plaintext_length = plaintext_length + 1;
            }
        };

        let complete_plaintext = vector::empty<u64>();
        vector::push_back(&mut complete_plaintext, 4);
        vector::push_back(&mut complete_plaintext, 15);
        vector::push_back(&mut complete_plaintext, 11);
        vector::push_back(&mut complete_plaintext, 0);
        vector::push_back(&mut complete_plaintext, 13);
        vector::push_back(&mut complete_plaintext, 4);
        vector::push_back(&mut complete_plaintext, 19);
        vector::push_back(&mut complete_plaintext, 19);
        vector::push_back(&mut complete_plaintext, 19);
        vector::append(&mut complete_plaintext, *plaintext);
        plaintext_length = plaintext_length + 9;

        let input2 = copy data2;
        let key = &mut input2;
        let a11 = *vector::borrow(key, 0);
        let a12 = *vector::borrow(key, 1);
        let a13 = *vector::borrow(key, 2);
        let a21 = *vector::borrow(key, 3);
        let a22 = *vector::borrow(key, 4);
        let a23 = *vector::borrow(key, 5);
        let a31 = *vector::borrow(key, 6);
        let a32 = *vector::borrow(key, 7);
        let a33 = *vector::borrow(key, 8);
        
        assert!(vector::length(key) == 9, 0);
        
        let i : u64 = 0;
        let ciphertext = vector::empty<u64>();
        while (i < plaintext_length) {
            let p11 = *vector::borrow(&mut complete_plaintext, i+0);
            let p21 = *vector::borrow(&mut complete_plaintext, i+1);
            let p31 = *vector::borrow(&mut complete_plaintext, i+2);

            let c11 = ( (a11 * p11) + (a12 * p21) + (a13 * p31) ) % 26;
            let c21 = ( (a21 * p11) + (a22 * p21) + (a23 * p31) ) % 26;
            let c31 = ( (a31 * p11) + (a32 * p21) + (a33 * p31) ) % 26;

            vector::push_back(&mut ciphertext, c11);
            vector::push_back(&mut ciphertext, c21);
            vector::push_back(&mut ciphertext, c31);

            i = i + 3;
        };    

        ciphertext
        
    }

    public entry fun get_flag(resource_object: &ResourceObject, ctx: &mut TxContext) {
        if (resource_object.q1) {
            event::emit(Flag { user: tx_context::sender(ctx), flag: true })
        }
    }
}
