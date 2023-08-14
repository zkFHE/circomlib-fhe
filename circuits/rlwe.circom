pragma circom 2.1.0;

include "add.circom";
include "mul.circom";

// Addition of RLWE ciphertexts
template AddRLWE(N, Q) {
    signal input c1[2][N];
    signal input c2[2][N];
    signal output out[2][N];

    out[0] <== AddPoly(N, Q)(c1[0], c2[0]);
    out[1] <== AddPoly(N, Q)(c1[1], c2[1]);
}

// Addition of RLWE ciphertexts without modular reduction
template AddRLWENoMod(N) {
    signal input c1[2][N];
    signal input c2[2][N];
    signal output out[2][N];

    out[0] <== AddPolyNoMod(N)(c1[0], c2[0]);
    out[1] <== AddPolyNoMod(N)(c1[1], c2[1]);
}

/*
    Multiplication of an RLWE ciphertext times a RGSW ciphertext.
    The RLWE ciphertext is given in decomposed form:
    (a_0, b_0, a_1, b_1,..., a_{dg-1}, b_{dg-1}).
    The RGSW ciphertext (c,c') is given as the 2*dg RLWE ciphertexts
    arranged as: (c_0, c'_0, c_1, c'_1,..., c_{dg-1}, c'_{dg-1}).
    All polynomials are assumed to be in NTT form.
    Assumes 2*dg*(Q-1)*(Q-1) <= 2^252 (to delay the modular reduction)
*/
template MulRlweRgsw(N, Q, dg) {
    signal input rlwe[2*dg][N];
    signal input rgsw[2*dg][2][N];
    signal output out[2][N];

    signal out_no_mod[2][N] <== MulRlweRgswNoMod(N, dg)(rlwe, rgsw);
    
    var bound = 2*dg*(Q-1)*(Q-1);
    for (var i=0; i<2; i++) {
        for (var j=0; j<N; j++) {
            out[i][j] <== ModBound(Q, bound)(out_no_mod[i][j]);
        }
    }
}

template MulRlweRgswNoMod(N, dg) {
    signal input rlwe[2*dg][N];
    signal input rgsw[2*dg][2][N];
    signal output out[2][N];

    var sum[N];
    for (var i=0; i<N; i++) {
        sum[i] = 0;
    }
    for (var i=0; i<2*dg; i++) {
        var prod[N] = MulPointwiseNoMod(N)(rlwe[i], rgsw[i][0]);
        sum = AddPolyNoMod(N)(sum, prod);
    }
    out[0] <== sum;

    for (var i=0; i<N; i++) {
        sum[i] = 0;
    }
    for (var i=0; i<2*dg; i++) {
        var prod[N] = MulPointwiseNoMod(N)(rlwe[i], rgsw[i][1]);
        sum = AddPolyNoMod(N)(sum, prod);
    }
    out[1] <== sum;
}
