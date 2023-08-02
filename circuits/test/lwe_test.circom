pragma circom 2.1.0;

include "lwe.circom";

template TestAddLWE() {
    log("\n********** TEST AddLWE **********\n");

    var n = 18;
    var q = 8;

    var a1[n]    = [2, 1, 6, 6, 5, 0, 3, 2, 6, 2, 3, 1, 1, 2, 5, 2, 2, 6];
    var a2[n]    = [7, 0, 3, 2, 2, 3, 2, 1, 3, 3, 1, 1, 7, 2, 0, 0, 7, 4];
    var a_res[n] = [1, 1, 1, 0, 7, 3, 5, 3, 1, 5, 4, 2, 0, 4, 5, 2, 1, 2];

    var b1    = 3;
    var b2    = 5;
    var b_res = 0;

    var (a_out[n], b_out) = AddLWE(n, q)(a1, b1, a2, b2);
    
    var RESULT = 1;
    for (var i=0; i<n; i++) {
        RESULT = RESULT && (a_out[i] == a_res[i]);
    }
    RESULT = RESULT && (b_out == b_res);

    log("RESULT: ", RESULT);
    signal output result <-- RESULT;
}

template TestSubLWE() {
    log("\n********** TEST SubLWE **********\n");
    
    var n = 18;
    var q = 8;

    var a1[n]    = [6, 1, 2, 0, 1, 1, 4, 2, 0, 5, 7, 6, 4, 3, 0, 1, 0, 6];
    var a2[n]    = [6, 7, 4, 7, 2, 0, 2, 4, 4, 2, 2, 5, 7, 5, 0, 7, 3, 5];
    var a_res[n] = [0, 2, 6, 1, 7, 1, 2, 6, 4, 3, 5, 1, 5, 6, 0, 2, 5, 1];

    var b1    = 3;
    var b2    = 5;
    var b_res = 6;

    var (a_out[n], b_out) = SubLWE(n, q)(a1, b1, a2, b2);
    
    var RESULT = 1;
    for (var i=0; i<n; i++) {
        RESULT = RESULT && (a_out[i] == a_res[i]);
    }
    RESULT = RESULT && (b_out == b_res);

    log("RESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

template TestRoundDiv() {
    log("\n********** TEST RoundDiv **********\n");

    var n = 8;
    var num[n] = [4, 5, 7, 6, 3, 4, 4, 0];
    var den[n] = [2, 2, 3, 4, 3, 8, 9, 5];
    var res[n] = [2, 3, 2, 2, 1, 1, 0, 0];

    var out[n];
    for (var i=0; i<n; i++) {
        out[i] = RoundDiv()(num[i], den[i]);
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

template TestRoundDivQ() {
    log("\n********** TEST RoundDivQ **********\n");

    var n = 8;
    var num[n] = [4, 5, 7, 6, 3, 4, 4, 0];
    var den[n] = [2, 2, 3, 4, 3, 8, 9, 5];
    var res[n] = [2, 3, 2, 2, 1, 1, 0, 0];

    var out[n];
    for (var i=0; i<n; i++) {
        out[i] = RoundDivQ(den[i])(num[i]);
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

template TestModSwitch() {
    log("\n********** TEST ModSwitch **********\n");

    var n = 15;
    var q = 8;
    var Q = 16;
    var a[n] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
    var b = 15;

    var a_res[n];
    for (var i=0; i<n; i++) {
        var quot = q*a[i] \ Q;
        var rem = q*a[i] % Q;
        a_res[i] = (quot + ((2*rem < Q) ? 0 : 1)) % q;
    }
    var b_quot = q*b \ Q;
    var b_rem = q*b % Q;
    var b_res = (b_quot + ((2*b_rem < Q) ? 0 : 1)) % q;
    

    var (a_out[n], b_out) = ModSwitch(n, q, Q)(a, b);


    var RESULT = 1;
    for (var i=0; i<n; i++) {
        RESULT = RESULT && (a_out[i] == a_res[i]);
    }
    RESULT = RESULT && (b_out == b_res);

    log("RESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}

template TestKeySwitch() {
    log("\n********** TEST KeySwitch **********\n");

    var n = 2;
    var N = 4;
    var Qks = 16;
    var Bks = 4;
    var dks = logb(Qks, Bks);
    var ksk[N][dks][Bks][n+1] = [
        [[[2, 0, 11], [5, 6, 2], [7, 7, 15], [3, 9, 10]],
         [[1, 15, 10], [11, 5, 8], [4, 12, 13], [8, 12, 15]]],

        [[[15, 5, 4], [11, 8, 0], [7, 9, 13], [9, 0, 15]],
         [[10, 7, 11], [4, 10, 4], [12, 7, 8], [9, 14, 4]]],

        [[[12, 10, 2], [2, 6, 2], [9, 6, 4], [9, 4, 15]],
         [[15, 2, 2], [6, 9, 15], [7, 13, 11], [5, 11, 2]]],

        [[[4, 14, 9], [10, 6, 14], [7, 13, 3], [14, 9, 3]],
         [[8, 14, 7], [10, 13, 3], [13, 8, 8], [14, 2, 3]]]
  ];

    var a_in[N] = [9, 15, 5, 2];
    var b_in = 7;

    var a_res[n];
    for (var i=0; i<n; i++) {
        a_res[i] = 0;
    }
    var b_res = b_in;

    for (var i=0; i<N; i++) {
        var atmp = a_in[i];
        for (var j=0; j<dks; j++) {
            var a0 = (atmp % Bks);

            var key[n+1] = ksk[i][j][a0];
            var key_a[n];
            for (var h=0; h<n; h++) {
                key_a[h] = key[h];
            }
            var key_b = key[n];

            (a_res, b_res) = SubLWE(n, Qks)(a_res, b_res, key_a, key_b);
            
            atmp \= Bks;
        }
    }


    var (a_out[n], b_out) = KeySwitch(n, N, Qks, Bks, ksk)(a_in, b_in);


    var RESULT = 1;
    for (var i=0; i<n; i++) {
        RESULT = RESULT && (a_out[i] == a_res[i]);
    }
    RESULT = RESULT && (b_out == b_res);

    log("RESULT: ", RESULT, "\n");
    signal output result <-- RESULT;
}


template TestAll() {
    log("\n******************** TESTING lwe.circom ********************\n\n");

    var total = 1;
    var res;

    res = TestAddLWE()();
    total = total && res;

    res = TestSubLWE()();
    total = total && res;

    res = TestRoundDiv()();
    total = total && res;

    res = TestRoundDivQ()();
    total = total && res;

    res = TestModSwitch()();
    total = total && res;

    res = TestKeySwitch()();
    total = total && res;

    log("********************\n", "TOTAL RESULT: ", total, "\n********************\n");
}

component main = TestAll();
