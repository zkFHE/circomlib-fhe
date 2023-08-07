pragma circom 2.1.0;

include "add.circom";
include "lwe.circom";
include "bootstrap.circom";

/*
    NAND Gate. Given two LWE ciphertexts (a1, b1), (a2, b2) encrypting some
    messages m1 and m2, return an LWE ciphertext (a_out, b_out) encrypting
    m1 NAND m2.
        - mode: 0 -> FHEW (DM bootstrap); 1 -> TFHE (CGGI boostrap)
        - (n, q): LWE parameters. It is assumed that q|2N.
        - (N, Q): RLWE parameters for bootstrapping
        - Qks: modulus for key switching
        - Bks: base for key switching (power of 2)
        - Bg: gadget base
        - Br: refreshing base (only needed for FHEW mode) (power of 2)
        - ksk: key switching key (dimensions: N x ceil(log_{Bks}(Q)) x Bks x (n+1))
        - bsk: bootstrapping key (dimensions:
            - mode 0: n x ceil(log_{Br}(q)) x Br x 2*ceil(log_{Bg}(Q)) x 2 x N
            )
    See https://eprint.iacr.org/2020/086.pdf Section 3.2
*/
template NAND(mode, n, N, q, Q, Qks, Bks, Bg, Br, ksk, bsk) {
    signal input a1[n], b1;
    signal input a2[n], b2;
    signal output a_out[n], b_out;

    signal (a_sum[n], b_sum) <== AddLWE(n, q)(a1, b1, a2, b2);

    // f maps [3q/8, 7q/8)-> -Q/8; [-q/8, 3q/8)-> Q/8
    var f[q];
    var Q8 = Q\8 + 1;
    var Q8Neg = Q - Q8;
    for (var i=0; i<q; i++) {
        f[i] = (3*q <= 8*i && 8*i < 7*q) ? Q8Neg : Q8;
    }

    signal (a_mid0[N], b_mid0) <== BootstrapCore(mode, n, N, q, Q, Bg, Br, bsk, f)(a_sum, b_sum);

    // add Q/8 to get back to Q/4 (mod 2) arithmetic
    signal a_mid1[N] <== a_mid0;
    signal b_mid1 <== FastAddMod(Q)([b_mid0, Q8]);
    
    // switch to modulus Qks
    signal (a_mid2[N], b_mid2) <== ModSwitch(N, Qks, Q)(a_mid1, b_mid1);

    // switch to original key with dimension n
    signal (a_mid3[n], b_mid3) <== KeySwitch(n, N, Qks, Bks, ksk)(a_mid2, b_mid2);

    // switch to original modulus q
    (a_out, b_out) <== ModSwitch(n, q, Qks)(a_mid3, b_mid3);
}
