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
    https://github.com/openfheorg/openfhe-development/blob/802b2265dd0033be4ec96aeffb9a6559523170b1/src/binfhe/lib/rgsw-acc-dm.cpp
    
    The refreshing base Br is assumed to be a power of 2.
*/
template UpdateDM(n, N, q, Q, Br, Bg, bsk, roots) {
    signal input acc_in[2][N];
    signal input a[n];
    signal output acc_out[2][N];

    var nbitsBr = log2(Br);
    var dr = logb(q, Br);
    var nbits = nbitsBr * dr;
    var dg = logb(Q, Bg);

    var acc_mid[2][N] = acc_in;
    signal {binary} a_bin[n][nbits];
    signal {binary} a0_bin[n][dr][nbitsBr];
    for (var i=0; i<n; i++) {
        var a_minus = FastSubMod(q)([0, a[i]]);
        a_bin[i] <== Num2Bits(nbits)(a_minus);

        for (var j=0; j<dr; j++) {
            
            for (var l=0; l<nbitsBr; l++) {
                a0_bin[i][j][l] <== a_bin[i][l + j*nbitsBr];
            }

            var key[2*dg][2][N] = ArrayAccessBSKBin(nbitsBr, dg, N)(bsk[i][j], a0_bin[i][j]);

            acc_mid = AddToAccDM(N, Q, Bg, roots)(acc_mid, key);
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
    https://github.com/openfheorg/openfhe-development/blob/802b2265dd0033be4ec96aeffb9a6559523170b1/src/binfhe/lib/rgsw-acc-dm.cpp
*/
template AddToAccDM(N, Q, Bg, roots) {
    var dg = logb(Q, Bg);
    signal input in[2][N];
    signal input key[2*dg][2][N];
    signal output out[2][N];

    signal acc[2][N];
    acc[0] <== INTT(N, Q, roots)(in[0]);
    acc[1] <== INTT(N, Q, roots)(in[1]);

    var acc_dec[2*dg][N] = SignedDigitDecomposeRLWE(Bg, N, Q)(acc);

    var acc_dec_ntt[2*dg][N];
    for (var i=0; i<2*dg; i++) {
        acc_dec_ntt[i] = NTT(N, Q, roots)(acc_dec[i]);
    }
    
    out <== MulRlweRgsw(N, Q, dg)(acc_dec_ntt, key);
}
