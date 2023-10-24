pragma circom 2.1.0;

include "circuits/bootstrap_tfhe.circom";

template BenchGetBinomial() {
    var N = 1024;
    var Q = 134215681;
    var roots[N];

    var index;
    var out[N] = GetBinomial(N, Q, roots)(index);
}
