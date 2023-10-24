pragma circom 2.1.0;

include "circuits/lwe.circom";
include "circuits/util.circom";

template BenchLweKeySwitchSmall() {
    var n = 512;
    var Qks = 1<<14;
    var Bks = 128;
    var N = 1; // N = 1024;

    // the number of constraints is linear in N
    // multiply the result by 1024 to get the real one

    var ksk[N][logb(Qks,Bks)][Bks][n+1];

    signal input a_in[N];
    signal input b_in;
    (_, _) <-- KeySwitch(n, N, Qks, Bks, ksk)(a_in, b_in);
}
