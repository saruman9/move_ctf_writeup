fn main() {
    let mut plaintext = vec![
        184, 14, 2015, 58, 43, 1118, 71, 72, 1649, 156, 123, 3154, 92, 65, 1760, 102, 66, 1866,
        194, 156, 3965, 26, 6, 316, 575, 71, 6670, 53, 43, 1070, 182, 140, 3633, 163, 134, 3361,
        86, 63, 1675, 184, 164, 3967, 7, 4, 121, 189, 156, 3902, 114, 97, 2399, 56, 7, 650, 28, 10,
        388, 15, 37, 624, 65, 4, 695,
    ];
    let key = vec![25, 11, 6, 166, 91, 25, 558, 19, 2];
    // let mut ciphertext = vec![
    //     19, 16, 17, 11, 9, 21, 18, 2, 3, 22, 7, 4, 25, 21, 5, 7, 23, 6, 23, 5, 13, 3, 5, 9, 16, 12,
    //     22, 14, 3, 14, 12, 22, 18, 4, 3, 9, 2, 19, 5, 16, 7, 20, 1, 11, 18, 23, 4, 15, 20, 5, 24,
    //     9, 1, 12, 5, 16, 10, 7, 2, 1, 21, 1, 25, 18, 22, 2, 2, 7, 25, 15, 7, 10,
    // ];
    println!("{:03?}", encrypt(&mut plaintext, &key));
    // println!("{:03?}", decrypt(&mut ciphertext, &key));
}

// fn decrypt(ciphertext: &mut Vec<u64>, key: &[u64]) -> Vec<u64> {
//     let ciphertext = ciphertext.to_vec();
//     let (_, mut ciphertext) = ciphertext.split_at(9);
//     let mut ciphertext = ciphertext.to_vec();
//     let c31 = ciphertext.remove(0);
//     let c21 = ciphertext.remove(0);
//     let c11 = ciphertext.remove(0);
//     todo!();
// }

fn encrypt(plaintext: &mut Vec<u64>, key: &[u64]) -> Vec<u64> {
    assert!(plaintext.len() > 3);
    let mut plaintext_len = plaintext.len();

    if plaintext_len % 3 != 0 {
        if (3 - plaintext_len % 3) == 2 {
            plaintext.push(0);
            plaintext.push(0);
            plaintext_len += 2;
        } else {
            plaintext.push(0);
            plaintext_len += 1;
        }
    }
    let mut complete_plaintext = vec![4, 15, 11, 0, 13, 4, 19, 19, 19];
    plaintext_len += 9;
    complete_plaintext.append(plaintext);

    let a11 = key[0];
    let a12 = key[1];
    let a13 = key[2];
    let a21 = key[3];
    let a22 = key[4];
    let a23 = key[5];
    let a31 = key[6];
    let a32 = key[7];
    let a33 = key[8];
    assert!(key.len() == 9);
    let mut ciphertext = Vec::new();
    let mut i = 0;
    while i < plaintext_len {
        let p11 = complete_plaintext[i];
        let p21 = complete_plaintext[i + 1];
        let p31 = complete_plaintext[i + 2];

        let c11 = ((a11 * p11) + (a12 * p21) + (a13 * p31)) % 26;
        let c21 = ((a21 * p11) + (a22 * p21) + (a23 * p31)) % 26;
        let c31 = ((a31 * p11) + (a32 * p21) + (a33 * p31)) % 26;

        ciphertext.push(c11);
        ciphertext.push(c21);
        ciphertext.push(c31);

        i += 3;
    }
    ciphertext
}
