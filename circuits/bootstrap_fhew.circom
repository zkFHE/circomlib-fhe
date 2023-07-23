pragma circom 2.1.0;

include "add.circom";
include "ntt.circom";
include "mul.circom";
include "rlwe.circom";
include "signed_decomposition.circom";
include "util.circom";
include "array_access.circom";

/*
    Accumulator update as given in (https://eprint.iacr.org/2020/086), 
    and following OpenFHE implementation in:
    
    Br is assumed to be a power of 2.
*/
template UpdateDM(n, N, q, Q, Br, Bg, bsk) {
    signal input acc_in[2][N];
    signal input a[n];
    signal output acc_out[2][N];

    var nbitsBr = log2(Br);
    var dr = logb(q, Br);
    var nbits = nbitsBr * dr;
    var dg = logb(Q, Bg);

    var acc_mid[2][N] = acc_in;
    for (var i=0; i<n; i++) {
        var a_minus = FastSubMod(q)([0, a[i]]);
        var a_bin[nbits] = Num2Bits(nbits)(a_minus);

        for (var j=0; j<dr; j++) {
            var a0_bin[nbitsBr];

            for (var l=0; l<nbitsBr; l++) {
                a0_bin[l] = a_bin[l + j*nbitsBr];
            }

            var key[2*dg][2][N] = ArrayAccessBinBSK(nbitsBr, dg, N)(bsk[i][j], a0_bin);

            acc_mid = AddToAccDM(N, Q, Bg)(acc_mid, key);
        }
    }
    acc_out <== acc_mid;
}

/*
    Given the accumulator (in) in RLWE and the key (key) in RGSW
    (both in NTT form), return the updated accumulator obtained by
    multiplying it by the key.

    As given in (https://eprint.iacr.org/2020/086), 
    and following OpenFHE implementation in:

*/
template AddToAccDM(N, Q, Bg) {
    var dg = logb(Q, Bg);
    signal input in[2][N];
    signal input key[2*dg][2][N];
    signal output out[2][N];

    signal acc[2][N];
    acc[0] <== INTT(N, Q)(in[0]);
    acc[1] <== INTT(N, Q)(in[1]);

    var acc_dec[2*dg][N] = SignedDigitDecomposeRLWE(Bg, N, Q)(acc);

    var acc_dec_ntt[2*dg][N];
    for (var i=0; i<2*dg; i++) {
        acc_dec_ntt[i] = NTT(N, Q)(acc_dec[i]);
    }
    
    out <== MulRlweRgsw(N, Q, dg)(acc_dec_ntt, key);
}