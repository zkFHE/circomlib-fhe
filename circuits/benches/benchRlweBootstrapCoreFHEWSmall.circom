pragma circom 2.1.0;

include "bootstrap.circom";
include "util.circom";

template BenchBootstrapCoreFHEWSmall() {
    var mode = 0;
    var n = 1; // n = 512;
    var N = 256; // N = 1024;
    var q = 1024;
    var Q = 134215681;
    var Bg = 128;
    var Br = 32;

    var dr = logb(q, Br);
    var dg = logb(Q, Bg);

    var bsk[n][dr][Br][2*dg][2][N];
    var f[q];

    var a[n], b;
    
    var (a_out[N], b_out) = BootstrapCore(mode, n, N, q, Q, Bg, Br, bsk, f)(a, b);
}
