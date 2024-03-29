pragma circom 2.1.0;

include "circuits/array_access.circom";
include "circuits/circomlib/circuits/bitify.circom";


template TestArrayAccess2D() {
    log("\n********** TEST ArrayAccess2D **********\n");

    var N = (1<<4);
    var n = 2;
    var arr[N][2] = [[69, 60], [93, 85], [20, 3], [63, 89], [57, 61], [11, 7], [94, 39], [67, 71], [64, 73], [98, 39], [31, 80], [27, 94], [62, 34], [66, 42], [79, 17], [58, 25]];

    var out[N][2];
    for (var i=0; i<N; i++) {
        out[i] = ArrayAccess2D(N, n)(arr, i);
    }

    var RESULT = 1;
    for (var i=0; i<N; i++) {
        var check = (out[i][0] == arr[i][0] && out[i][1] == arr[i][1]);
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

template TestArrayAccess2DBin() {
    log("\n********** TEST ArrayAccess2DBin **********\n");

    var k = 4;
    var n = 2;
    var arr[1<<k][2] = [[69, 60], [93, 85], [20, 3], [63, 89], [57, 61], [11, 7], [94, 39], [67, 71], [64, 73], [98, 39], [31, 80], [27, 94], [62, 34], [66, 42], [79, 17], [58, 25]];

    var out[1<<k][2];
    signal {binary} bin_dec[1<<k][k];
    for (var i=0; i<(1<<k); i++) {
        bin_dec[i] <== Num2Bits(k)(i);
        out[i] = ArrayAccess2DBin(k, n)(arr, bin_dec[i]);
    }

    var RESULT = 1;
    for (var i=0; i<(1<<k); i++) {
        var check = (out[i][0] == arr[i][0] && out[i][1] == arr[i][1]);
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}


template TestArrayAccess2DBin2() {
    log("\n********** TEST ArrayAccess2DBin2 **********\n");

    var k = 4;
    var n = 2;
    var arr[1<<k][2] = [[69, 60], [93, 85], [20, 3], [63, 89], [57, 61], [11, 7], [94, 39], [67, 71], [64, 73], [98, 39], [31, 80], [27, 94], [62, 34], [66, 42], [79, 17], [58, 25]];

    var out[1<<k][2];
    signal {binary} bin_dec[1<<k][k];
    for (var i=0; i<(1<<k); i++) {
        bin_dec[i] <== Num2Bits(k)(i);
        out[i] = ArrayAccess2DBin2(k, n)(arr, bin_dec[i]);
    }

    var RESULT = 1;
    for (var i=0; i<(1<<k); i++) {
        var check = (out[i][0] == arr[i][0] && out[i][1] == arr[i][1]);
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

template TestArrayAccessBSKBin() {
    log("\n********** TEST ArrayAccessBSKBin **********\n");

    var k = 2;
    var dg = 2;
    var N = 3;
    var bsk[1<<k][2*dg][2][N] = [
                                [[[78, 62, 28], [74, 51, 38]],
                                 [[65, 54, 76], [56, 90, 70]],
                                 [[77, 22, 16], [16, 33, 36]],
                                 [[76, 87, 51], [39, 5, 75]]],

                                [[[24, 22, 99], [55, 32, 16]],
                                 [[79, 69, 63], [86, 73, 83]],
                                 [[56, 39, 19], [59, 29, 56]],
                                 [[59, 69, 6], [37, 52, 88]]],

                                [[[71, 98, 0], [47, 54, 21]],
                                 [[35, 44, 91], [73, 61, 88]],
                                 [[89, 50, 63], [56, 71, 88]],
                                 [[14, 30, 28], [97, 45, 59]]],

                                [[[96, 83, 31], [12, 20, 81]],
                                 [[93, 39, 92], [1, 27, 77]],
                                 [[66, 43, 17], [69, 15, 28]],
                                 [[2, 43, 33], [18, 47, 74]]]
                                ];

    var out[1<<k][2*dg][2][N];
    signal {binary} bin_dec[1<<k][k];
    for (var i=0; i<(1<<k); i++) {
        bin_dec[i] <== Num2Bits(k)(i);
        out[i] = ArrayAccessBSKBin(k, dg, N)(bsk, bin_dec[i]);
    }

    var RESULT = 1;
    for (var i=0; i<(1<<k); i++) {
        var check = 1;
        for (var j=0; j<2*dg; j++) {
            for(var k=0; k<N; k++) {
                check = check & (out[i][j][0][k] == bsk[i][j][0][k] && out[i][j][1][k] == bsk[i][j][1][k]);
            }
        }
        log("Test", i, "->", check);
        RESULT = RESULT && check;
    }
    log("\nRESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

template TestAll() {
    log("\n******************** TESTING array_access.circom ********************\n\n");

    var total = 1;
    var res;

    res = TestArrayAccess2D()();
    total = total && res;

    res = TestArrayAccess2DBin()();
    total = total && res;

    res = TestArrayAccess2DBin2()();
    total = total && res;

    res = TestArrayAccessBSKBin()();
    total = total && res;

    log("********************\n", "TOTAL RESULT: ", total, "\n********************\n");
}

component main = TestAll();
