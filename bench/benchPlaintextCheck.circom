pragma circom 2.1.0;

include "circuits/mod.circom";
include "circuits/mul.circom";
include "circuits/ntt.circom";
include "circuits/ring.circom";
include "circuits/noise_flooding.circom";

template BenchPlaintextCheckWithNTT(l, n, t, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    var roots[l][n];
    signal input w[n];

    LtConstantN(t, n)(w);
    signal w_ntt[l][n] <== NTTsPlain(l, n, q1, q2, q3, q4, q5, q6, roots)(w);
}

template BenchPlaintextCheckWithNTTRing(t) {
    signal input w;
    LtConstantRing(t)(w);
    signal w_ntt <== NTTRing(8092)(w);
}
