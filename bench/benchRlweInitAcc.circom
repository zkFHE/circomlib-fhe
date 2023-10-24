pragma circom 2.1.0;

include "circuits/bootstrap.circom";
include "circuits/util.circom";

template BenchInitAcc() {
    var N = 1024;
    var q = 1024;
    var f[q];

    var in;
    
    var out[2][N] = InitAcc(N, q, f)(in);
}
