pragma circom 2.1.0;

include "add.circom";
include "mul.circom";

// Addition of RLWE ciphertexts (a1[N], b1[N]) + (a2[N], b2[N])
template AddRLWE(N, Q) {
    signal input a1[N], b1[N];
    signal input a2[N], b2[N];

    signal output a[N] <== AddPoly(N, Q)(a1, a2);
    signal output b[N] <== AddPoly(N, Q)(b1, b2);
}

/*
    Multiplication of an RLWE ciphertext times a RGSW ciphertext.
    The RLWE ciphertext is given in decomposed form:
    (a_0, b_0, a_1, b_1,..., a_{dg-1}, b_{dg-1}).
    The RGSW ciphertext (c,c') is given as the 2*dg RLWE ciphertexts
    arranged as: (c_0, c'_0, c_1, c'_1,..., c_{dg-1}, c'_{dg-1}).
    All polynomials are assumed to be in NTT form.
*/
template MulRlweRgsw(N, Q, dg) {
    signal input rlwe[2*dg][N];
    signal input rgsw[2*dg][2][N];
    signal output out[2][N];

    var sum[N];
    for (var i=0; i<N; i++) {
        sum[i] = 0;
    }
    
    for (var i=0; i<2*dg; i++) {
        var prod[N] = FastMulPointwise(N, Q)(rlwe[i], rgsw[i][0]);
        sum = AddPoly(N, Q)(sum, prod);
    }
    out[0] <== sum;

    for (var i=0; i<N; i++) {
        sum[i] = 0;
    }
    
    for (var i=0; i<2*dg; i++) {
        var prod[N] = FastMulPointwise(N, Q)(rlwe[i], rgsw[i][1]);
        sum = AddPoly(N, Q)(sum, prod);
    }
    out[1] <== sum;
}
