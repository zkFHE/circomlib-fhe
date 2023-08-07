pragma circom 2.1.0;

include "bootstrap.circom";
include "util.circom";

template BenchInitAcc() {
    var N = 1024;
    var q = 1024;
    var Q = 134215681;
    var f[q];

    var in;
    
    var out[2][N] = InitAcc(N, q, Q, f)(in);
}
