pragma circom 2.1.0;

include "circuits/array_access.circom";

template BenchArrayAccess2DBin() {
    var k = 7;
    var n = 513;

    var arr[1<<k][n];
    signal {binary} index_bin[k];
    for (var i=0; i<k; i++) {
        index_bin[i] <== 1;
    }

    var out[n] = ArrayAccess2DBin(k, n)(arr, index_bin);
}
