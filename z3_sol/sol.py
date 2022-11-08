from z3 import *


def solve_plaintext():
    data = [19, 16, 17, 11, 9, 21, 18, 2,
            3, 22, 7, 4, 25, 21, 5, 7,
            23, 6, 23, 5, 13, 3, 5, 9,
            16, 12, 22, 14, 3, 14, 12, 22,
            18, 4, 3, 9, 2, 19, 5, 16,
            7, 20, 1, 11, 18, 23, 4, 15,
            20, 5, 24, 9, 1, 12, 5, 16,
            10, 7, 2, 1, 21, 1, 25, 18,
            22, 2, 2, 7, 25, 15, 7, 10]
    key = [25, 11, 6, 166, 91, 25, 558, 19, 2]

    i = 0
    while i < 63:
        solver = Solver()
        p11 = Int("p11")
        p21 = Int("p21")
        p31 = Int("p31")
        solver.add(p11 > 0)
        solver.add(p21 > 0)
        solver.add(p31 > 0)
        solver.add(data[i + 0 + 9] ==
                   (key[0] * p11 + key[1] * p21 + key[2] * p31) % 26)
        solver.add(data[i + 1 + 9] ==
                   (key[3] * p11 + key[4] * p21 + key[5] * p31) % 26)
        solver.add(data[i + 2 + 9] ==
                   (key[6] * p11 + key[7] * p21 + key[8] * p31) % 26)
        if solver.check() == sat:
            m = solver.model()
            print("%s" % m.evaluate(p11), end=', ')
            print("%s" % m.evaluate(p21), end=', ')
            print("%s" % m.evaluate(p31), end=', ')
        i += 3

    exit(0)


def solve_key():
    solver = Solver()

    p11_1 = Int("p11_1")
    p21_1 = Int("p21_1")
    p31_1 = Int("p31_1")
    solver.add(p11_1 == 4)
    solver.add(p21_1 == 15)
    solver.add(p31_1 == 11)
    p11_2 = Int("p11_2")
    p21_2 = Int("p21_2")
    p31_2 = Int("p31_2")
    solver.add(p11_2 == 0)
    solver.add(p21_2 == 13)
    solver.add(p31_2 == 4)
    p11_3 = Int("p11_3")
    p21_3 = Int("p21_3")
    p31_3 = Int("p31_3")
    solver.add(p11_3 == 19)
    solver.add(p21_3 == 19)
    solver.add(p31_3 == 19)

    a11 = Int("a11")
    a12 = Int("a12")
    a13 = Int("a13")
    a21 = Int("a21")
    a22 = Int("a22")
    a23 = Int("a23")
    a31 = Int("a31")
    a32 = Int("a32")
    a33 = Int("a33")
    solver.add(a11 >= 0)
    solver.add(a12 >= 0)
    solver.add(a13 >= 0)
    solver.add(a21 >= 0)
    solver.add(a22 >= 0)
    solver.add(a23 >= 0)
    solver.add(a31 >= 0)
    solver.add(a32 >= 0)
    solver.add(a33 >= 0)

    c11_1 = Int("c11_1")
    c21_1 = Int("c21_1")
    c31_1 = Int("c31_1")
    solver.add(c11_1 == 19)
    solver.add(c21_1 == 16)
    solver.add(c31_1 == 17)
    c11_2 = Int("c11_2")
    c21_2 = Int("c21_2")
    c31_2 = Int("c31_2")
    solver.add(c11_2 == 11)
    solver.add(c21_2 == 9)
    solver.add(c31_2 == 21)
    c11_3 = Int("c11_3")
    c21_3 = Int("c21_3")
    c31_3 = Int("c31_3")
    solver.add(c11_3 == 18)
    solver.add(c21_3 == 2)
    solver.add(c31_3 == 3)

    solver.add(c11_1 == ((a11 * p11_1) + (a12 * p21_1) + (a13 * p31_1)) % 26)
    solver.add(c21_1 == ((a21 * p11_1) + (a22 * p21_1) + (a23 * p31_1)) % 26)
    solver.add(c31_1 == ((a31 * p11_1) + (a32 * p21_1) + (a33 * p31_1)) % 26)
    solver.add(c11_2 == ((a11 * p11_2) + (a12 * p21_2) + (a13 * p31_2)) % 26)
    solver.add(c21_2 == ((a21 * p11_2) + (a22 * p21_2) + (a23 * p31_2)) % 26)
    solver.add(c31_2 == ((a31 * p11_2) + (a32 * p21_2) + (a33 * p31_2)) % 26)
    solver.add(c11_3 == ((a11 * p11_3) + (a12 * p21_3) + (a13 * p31_3)) % 26)
    solver.add(c21_3 == ((a21 * p11_3) + (a22 * p21_3) + (a23 * p31_3)) % 26)
    solver.add(c31_3 == ((a31 * p11_3) + (a32 * p21_3) + (a33 * p31_3)) % 26)

    if solver.check() == sat:
        m = solver.model()
        print("%s" % m.evaluate(a11), end=', ')
        print("%s" % m.evaluate(a12), end=', ')
        print("%s" % m.evaluate(a13), end=', ')
        print("%s" % m.evaluate(a21), end=', ')
        print("%s" % m.evaluate(a22), end=', ')
        print("%s" % m.evaluate(a23), end=', ')
        print("%s" % m.evaluate(a31), end=', ')
        print("%s" % m.evaluate(a32), end=', ')
        print("%s" % m.evaluate(a33))
    # exit(0)


def asset_vector(solver, vec, start_index, data):
    for offset in range(len(data)):
        solver.add(vec[start_index + offset] == data[offset])


def all_unsigned(solver, vec):
    for offset in range(len(vec)):
        solver.add(vec[offset] >= 0)


def lower_26(solver, vec):
    for offset in range(len(vec)):
        solver.add(vec[offset] < 26)


if __name__ == "__main__":
    solve_key()
    solve_plaintext()

    for j in range(13, 15):
        solver = Solver()
        plaintext_len = j

        if plaintext_len % 3 != 0:
            if (3 - (plaintext_len % 3)) == 2:
                plaintext_len += 2
                plaintext = IntVector("plaintext", plaintext_len)
                solver.add(plaintext[plaintext_len - 1] == 0)
                solver.add(plaintext[plaintext_len - 2] == 0)
            else:
                plaintext_len += 1
                plaintext = IntVector("plaintext", plaintext_len)
                solver.add(plaintext[plaintext_len - 1] == 0)
        else:
            plaintext = IntVector("plaintext", plaintext_len)

        complete_plaintext = IntVector("complete_plaintext", 9 + plaintext_len)
        solver.add(complete_plaintext[0] == 4)
        solver.add(complete_plaintext[1] == 15)
        solver.add(complete_plaintext[2] == 11)
        solver.add(complete_plaintext[3] == 0)
        solver.add(complete_plaintext[4] == 13)
        solver.add(complete_plaintext[5] == 4)
        solver.add(complete_plaintext[6] == 19)
        solver.add(complete_plaintext[7] == 19)
        solver.add(complete_plaintext[8] == 19)
        for i in range(9, plaintext_len+9):
            solver.add(complete_plaintext[i] == plaintext[i-9])

        key = IntVector("key", 9)
        a11 = Int("a11")
        a12 = Int("a12")
        a13 = Int("a13")
        a21 = Int("a21")
        a22 = Int("a22")
        a23 = Int("a23")
        a31 = Int("a31")
        a32 = Int("a32")
        a33 = Int("a33")
        solver.add(a11 == key[0])
        solver.add(a12 == key[1])
        solver.add(a13 == key[2])
        solver.add(a21 == key[3])
        solver.add(a22 == key[4])
        solver.add(a23 == key[5])
        solver.add(a31 == key[6])
        solver.add(a32 == key[7])
        solver.add(a33 == key[8])

        data = [19, 16, 17, 11, 9, 21, 18, 2,
                3, 22, 7, 4, 25, 21, 5, 7,
                23, 6, 23, 5, 13, 3, 5, 9,
                16, 12, 22, 14, 3, 14, 12, 22,
                18, 4, 3, 9, 2, 19, 5, 16,
                7, 20, 1, 11, 18, 23, 4, 15,
                20, 5, 24, 9, 1, 12, 5, 16,
                10, 7, 2, 1, 21, 1, 25, 18,
                22, 2, 2, 7, 25, 15, 7, 10]
        complete_ciphertext = IntVector("complete_ciphertext", len(data))
        ciphertext = IntVector("ciphertext", len(data))
        asset_vector(solver, ciphertext, 0, data)

        for i in range(0, plaintext_len + 9, 3):
            p11 = Int("p11_%s" % i)
            p21 = Int("p21_%s" % i)
            p31 = Int("p31_%s" % i)
            solver.add(p11 == complete_plaintext[i+0])
            solver.add(p21 == complete_plaintext[i+1])
            solver.add(p31 == complete_plaintext[i+2])

            c11 = Int("c11_%s" % i)
            c21 = Int("c21_%s" % i)
            c31 = Int("c31_%s" % i)
            solver.add(c11 == ((a11 * p11) + (a12 * p21) + (a13 * p31)) % 26)
            solver.add(c21 == ((a21 * p11) + (a22 * p21) + (a23 * p31)) % 26)
            solver.add(c31 == ((a31 * p11) + (a32 * p21) + (a33 * p31)) % 26)

            solver.add(complete_ciphertext[i + 0] == c11)
            solver.add(complete_ciphertext[i + 1] == c21)
            solver.add(complete_ciphertext[i + 2] == c31)

        for i in range(len(data)):
            solver.add(ciphertext[i] == complete_ciphertext[i])

        all_unsigned(solver, plaintext)
        all_unsigned(solver, complete_plaintext)
        all_unsigned(solver, ciphertext)
        all_unsigned(solver, complete_ciphertext)
        all_unsigned(solver, key)
        lower_26(solver, ciphertext)
        lower_26(solver, complete_ciphertext)

        print(solver.sexpr())
        print(plaintext_len, solver.check())
        if solver.check() == sat:
            m = solver.model()
            final_plaintext = []
            final_key = []
            for i in range(plaintext_len):
                final_plaintext.append(m.evaluate(plaintext[i],
                                                  model_completion=True))
            for i in range(9):
                final_key.append(m.evaluate(key[i], model_completion=True))
            print("plaintext = %s" % final_plaintext)
            print("key = %s" % final_key)
            exit(0)
