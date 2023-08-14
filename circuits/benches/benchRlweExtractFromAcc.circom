pragma circom 2.1.0;

include "bootstrap.circom";

template BenchExtractFromAcc() {
    var N = 1024;
    var Q = 134215681;
    var roots[N];

    var in[2][N];
    var (a[N], b) = ExtractFromAcc(N, Q, roots)(in);
}
