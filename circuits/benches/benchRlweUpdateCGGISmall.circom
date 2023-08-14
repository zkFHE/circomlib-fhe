pragma circom 2.1.0;

include "bootstrap_tfhe.circom";

template BenchUpdateCGGISmall() {
    var n = 1; // n = 512;
    var N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Bg = 128;
    var dg = logb(Q, Bg);

    // the number of constraints is linear in n
    // multiply the result by 512 to get the real one
    
    var bsk[1][n][2][2*dg][2][N];
    var roots[N];

    var acc_in[2][N];
    var a[n];
    
    var acc_out[2][N] = UpdateCGGI(n, N, q, Q, Bg, bsk, roots)(acc_in, a);
}
