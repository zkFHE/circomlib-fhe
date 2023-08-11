pragma circom 2.1.0;

include "bootstrap_fhew.circom";

template BenchAddToAccDM() {
    var N = 1024;
    var Q = 134215681;
    var Bg = 128;
    var dg = 4;
    var roots[N];

    var key[2*dg][2][N];
    var in[2][N];
    
    var out[2][N] = AddToAccDM(N, Q, Bg, roots)(in, key);
}
