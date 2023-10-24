pragma circom 2.1.0;

include "circuits/bootstrap_fhew.circom";

template BenchUpdateDMSmall() {
    var n = 1; // n = 512;
    var N = 512; // N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Br = 32;
    var Bg = 128;
    var dr = logb(q, Br);
    var dg = logb(Q, Bg);

    // the number of constraints is linear in n and close to linear in N
    // multiply the result by 1024 to get the real one
    
    var bsk[n][dr][Br][2*dg][2][N];
    var roots[N];

    var acc_in[2][N];
    var a[n];
    
    var acc_out[2][N] = UpdateDM(n, N, q, Q, Br, Bg, bsk, roots)(acc_in, a);
}
