pragma circom 2.1.0;

include "bootstrap.circom";
include "util.circom";

template BenchBootstrapCoreTFHESmall() {
    var mode = 1;
    var n = 1; // n = 512;
    var N = 256; // N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Bg = 128;
    var Br = -1; // not needed

    var dg = logb(Q, Bg);

    var bsk[1][n][2][2*dg][2][N];
    var f[q];
    var roots[N];

    var a[n], b;
    
    var (a_out[N], b_out) = BootstrapCore(mode, n, N, q, Q, Bg, Br, bsk, f, roots)(a, b);
}
