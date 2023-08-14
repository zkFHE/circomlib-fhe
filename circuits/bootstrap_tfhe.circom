pragma circom 2.1.0;

include "add.circom";
include "ntt.circom";
include "rlwe.circom";
include "signed_decomposition.circom";
include "util.circom";
include "array_access.circom";
include "circomlib/circuits/comparators.circom";

// return (X^exponent - 1) in Z_Q[X]/(X^N+1) in NTT form
// 0 <= exponent < 2N
template GetBinomial(N, Q, roots) {
    signal input exponent;
    signal output out[N];

    var binomial[N];
    var match;

    for (var i=0; i<N; i++) {
        match = IsEqual()([exponent, i]);
        binomial[i] = match;
    }
    for (var i=N; i<2*N; i++) {
        match = IsEqual()([exponent, i]);
        binomial[i-N] += match*(Q-1);
    }
    
    binomial[0] = FastSubMod(Q)([binomial[0], 1]);

    out <== NTT(N, Q, roots)(binomial);
}


/*
    Accumulator update as given in (https://eprint.iacr.org/2020/086), 
    and following OpenFHE implementation in:
    https://github.com/openfheorg/openfhe-development/blob/802b2265dd0033be4ec96aeffb9a6559523170b1/src/binfhe/lib/rgsw-acc-cggi.cpp
*/
template UpdateCGGI(n, N, q, Q, Bg, bsk, roots) {
    signal input acc_in[2][N];
    signal input a[n];
    signal output acc_out[2][N];

    var modSwitch = 2*N\q;
    var acc_mid[2][N] = acc_in;
    for (var i=0; i<n; i++) {
        var a_minus = FastSubMod(q)([0, a[i]]);
        var c = a_minus * modSwitch;
        acc_mid = AddToAccCGGI(N, Q, Bg, roots)(c, acc_mid, bsk[0][i][0], bsk[0][i][1]);
    }
    acc_out <== acc_mid;
}

/*
    Given the accumulator (in) in RLWE and the keys (key1, key2) in RGSW
    (all in NTT form), return the updated accumulator obtained by
    computing: ACC := ACC + (ACC x key1)*binomial + (ACC x key2)*binomialNeg.

    As given in (https://eprint.iacr.org/2020/086), 
    and following OpenFHE implementation in:
    https://github.com/openfheorg/openfhe-development/blob/802b2265dd0033be4ec96aeffb9a6559523170b1/src/binfhe/lib/rgsw-acc-cggi.cpp

    Assumes 4*dg*(Q-1)^3 + 2*(Q-1) <= 2^252 (to delay modular reduction)
*/
template AddToAccCGGI(N, Q, Bg, roots) {
    var dg = logb(Q, Bg);
    signal input c;
    signal input acc_ntt[2][N];
    signal input key1[2*dg][2][N], key2[2*dg][2][N];
    signal output out[2][N];

    signal acc[2][N];
    acc[0] <== INTT(N, Q, roots)(acc_ntt[0]);
    acc[1] <== INTT(N, Q, roots)(acc_ntt[1]);

    var acc_dec[2*dg][N] = SignedDigitDecomposeRLWE(Bg, N, Q)(acc);

    var acc_dec_ntt[2*dg][N];
    for (var i=0; i<2*dg; i++) {
        acc_dec_ntt[i] = NTT(N, Q, roots)(acc_dec[i]);
    }

    var exponent = c;
    var exponent_neg = FastSubMod(2*N)([0, c]);
    var binomial[N] = GetBinomial(N, Q, roots)(exponent); // X^c - 1
    var binomial_neg[N] = GetBinomial(N, Q, roots)(exponent_neg); // X^{-c} - 1
    
    var acc_mid[2][N];
    var tmp[2][N];
    var bound = 0;

    // tmp := (ACC x key1)*binomial
    tmp = MulRlweRgswNoMod(N, dg)(acc_dec_ntt, key1);
    tmp[0] = MulPointwiseNoMod(N)(tmp[0], binomial);
    tmp[1] = MulPointwiseNoMod(N)(tmp[1], binomial);
    bound += 2*dg*(Q-1)*(Q-1)*(Q-1);

    // acc_mid := ACC + (ACC x key1)*binomial
    acc_mid = AddRLWENoMod(N)(acc_ntt, tmp);
    bound += Q-1;

    // tmp := (ACC x key2)*binomialNeg
    tmp = MulRlweRgswNoMod(N, dg)(acc_dec_ntt, key2);
    tmp[0] = MulPointwiseNoMod(N)(tmp[0], binomial_neg);
    tmp[1] = MulPointwiseNoMod(N)(tmp[1], binomial_neg);
    bound += 2*dg*(Q-1)*(Q-1)*(Q-1);

    // acc_mid := ACC + (ACC x key1)*binomial + (ACC x key2)*binomialNeg
    acc_mid = AddRLWENoMod(N)(acc_mid, tmp);
    bound += Q-1;

    // reduction mod Q
    for (var i=0; i<2; i++) {
        for (var j=0; j<N; j++) {
            out[i][j] <== ModBound(Q, bound)(acc_mid[i][j]);
        }
    }
}
