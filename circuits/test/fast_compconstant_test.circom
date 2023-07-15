pragma circom 2.1.0;

include "fast_compconstant.circom";

template TestCompConstantBound() {
    log("\n********** TEST CompConstantBound **********\n");

    var n = 7;
    var test[n][2] = [[3, 2], [3, 3], [3, 4], [8, 15], [8, 16], [8, 2], [1<<23, (1<<24)-1]];
    var res[n] = [0, 0, 1, 1, 1, 0, 1];

    var out[n];
    for (var i=0; i<n; i++) {
        var bits[24] = Num2Bits(24)(test[i][1]);
        out[i] = CompConstantBound(test[i][0], 24)(bits);
    }

    var RESULT = 1;
    for (var i=0; i<n; i++) {
        var check = (out[i] == res[i]);
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

component main = TestCompConstantBound();
