pragma circom 2.1.0;

include "circuits/ntt.circom";

template BenchNTT() {
    var N = 1024;
    var Q = 134215681;
    var roots[N];

    var in[N];
    var out[N] = NTT(N, Q, roots)(in);
}
