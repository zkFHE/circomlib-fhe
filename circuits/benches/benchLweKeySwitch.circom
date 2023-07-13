pragma circom 2.1.0;

include "lwe.circom";
include "util.circom";

template BenchLweKeySwitch() {
    var n = 512;
    var Q = 1<<14;
    var B = 128;
    var N = 1024;

    var fakeN = 1;
    // the number of constraints is linear in N
    // multiply the result by 1024 to get the real one

    var ksk[fakeN][logb(Q,B)][B][n+1];

    signal input a_in[fakeN];
    signal input b_in;
    (_, _) <-- KeySwitch(n, fakeN, Q, B, ksk)(a_in, b_in);
}