pragma circom 2.1.0;

include "nand.circom";
include "util.circom";

template BenchNandFHEWSmall() {
    var mode = 0;
    var n = 1; // n = 512;
    var N = 128; // N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Qks = 1 << 14;
    var Bks = 128;
    var Bg = 128;
    var Br = 32;

    var dks = logb(Qks, Bks);
    var dr = logb(q, Br);
    var dg = logb(Q, Bg);

    var ksk[N][dks][Bks][n+1];
    var bsk[n][dr][Br][2*dg][2][N];
    var roots[N];

    var a1[n], b1, a2[n], b2;
    
    var (a_out[n], b_out) = NAND(mode, n, N, q, Q, Qks, Bks, Bg, Br, ksk, bsk, roots)(a1, b1, a2, b2);
}
