pragma circom 2.1.0;

include "bootstrap_tfhe.circom";

template BenchAddToAccCGGI() {
    var N = 1024;
    var Q = 134215681;
    var Bg = 128;
    var dg = 4;
    var roots[N];

    var c;
    var acc_ntt[2][N];
    var key1[2*dg][2][N], key2[2*dg][2][N];
    
    var out[2][N] = AddToAccCGGI(N, Q, Bg, roots)(c, acc_ntt, key1, key2);
}
