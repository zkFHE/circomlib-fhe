pragma circom 2.1.0;

include "array_access.circom";

template BenchArrayAccessBSKBin() {
    var k = 5;
    var dg = 4;
    var N = 128; // N= 1024;

    var bsk[1<<k][2*dg][2][N];
    signal {binary} index_bin[k];
    for (var i=0; i<k; i++) {
        index_bin[i] <== 1;
    }

    var out[2*dg][2][N] = ArrayAccessBSKBin(k, dg, N)(bsk, index_bin);
}
