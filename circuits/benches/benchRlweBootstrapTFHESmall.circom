pragma circom 2.1.0;

include "bootstrap.circom";
include "util.circom";

template BenchBootstrapTFHESmall() {
    var mode = 1;
    var n = 1; // n = 512;
    var N = 128; // N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Qks = 1 << 14;
    var Bks = 128;
    var Bg = 128;
    var Br = -1; // not needed

    var dks = logb(Qks, Bks);
    var dg = logb(Q, Bg);

    var ksk[N][dks][Bks][n+1];
    var bsk[1][n][2][2*dg][2][N];
    var f[q];
    var roots[N];

    var a[n], b;
    
    var (a_out[n], b_out) = Bootstrap(mode, n, N, q, Q, Qks, Bks, Bg, Br, ksk, bsk, f, roots)(a, b);
}
