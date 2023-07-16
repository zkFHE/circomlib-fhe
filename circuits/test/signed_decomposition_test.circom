pragma circom 2.1.0;

include "signed_decomposition.circom";
include "util.circom";

template TestSignedDigitDecompose() {
    log("\n********** TEST SignedDigitDecompose **********\n");

    var Bg = 128;
    var Q = 134215681;
    var dg = logb(Q, Bg);
    var n = 10;

    var in[n] = [12519551, 91951379, 56718232, 110141754, 131582537, 33107195, 18905772, 49680797, 133160896, Q-1];

    var out[n][dg];
    for (var i=0; i<n; i++) {
        out[i] = SignedDigitDecompose(Bg, Q)(in[i]);
    }

    var RESULT = 1;
    for (var i=0; i<n; i++) {
        var check = 1;
        var sum = 0;
        var power = 1;
        for (var j=0; j<dg; j++) {
            var x = out[i][j];
            check = check && (0 <= x && x < Q && (x <= Bg/2 || x >= Q - Bg/2));
            sum = (sum + x * power) % Q;
            power *= Bg;
        }
        check = check && (sum == in[i]);
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
}

component main = TestSignedDigitDecompose();