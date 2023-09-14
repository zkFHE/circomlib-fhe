pragma circom 2.1.0;

include "add.circom";
include "util.circom";
include "mod.circom";
include "ntt.circom";
include "circomlib/circuits/multiplexer.circom";

// assumes all elements are already mod q
template FastMulPointwise(N, q) {
    signal input in1[N]; 
    signal input in2[N]; 
    signal output out[N];
    
    for (var i = 0; i < N; i++) {
        out[i] <== ModBound(q, (q-1)*(q-1))(in1[i] * in2[i]);
    }
}

template parallel MulPointwise(N, q) {
    signal input in1[N]; 
    signal input in2[N]; 
    signal output out[N];
    
    for (var i = 0; i < N; i++) {
        out[i] <== Mod(q)(in1[i] * in2[i]);
    }
}

template parallel MulsPointwise(l, N, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in1[l][N]; 
    signal input in2[l][N]; 
    signal output out[l][N];
    
    for (var i = 0; i < l; i++) {
        if (q[i] != 0) {
            out[i] <== MulPointwise(N, q[i])(in1[i], in2[i]);
        }
    }
}

template parallel MulPointwiseNoMod(N) {
    signal input in1[N]; 
    signal input in2[N]; 
    signal output out[N];
    
    for (var i = 0; i < N; i++) {
        out[i] <== in1[i] * in2[i];
    }
}

template parallel MulsPointwiseNoMod(l, N) {
    signal input in1[l][N]; 
    signal input in2[l][N]; 
    signal output out[l][N];
    
    for (var i = 0; i < l; i++) {
        out[i] <== MulPointwiseNoMod(N)(in1[i], in2[i]);
    }
}

template parallel MulNTT(l, N, q1, q2, q3, q4, q5, q6, roots) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in1[l][N];
    signal input in2[l][N];
    signal output out[l][N];

    for (var i = 0; i < l; i++) {
        if (q[i] == 0) {
            // TODO: add explicit constraint that out === 0, or do we discard this in a higher protocol level?
        } else {
            var tmp1[N] = NTT(N, q[i], roots[i])(in1[i]);
            var tmp2[N] = NTT(N, q[i], roots[i])(in2[i]);
            var tmp[N] = MulPointwise(N, q[i])(tmp1, tmp2);
            out[i] <== INTT(N, q[i], roots[i])(tmp);
        }
    }
}

template parallel MulPolySchoolbook(N, q) {
    signal input in1[N];
    signal input in2[N];
    var tosum[N][2*N];
    signal output out[N];
    
    var l;
    var n = N-1;
    for (var k = 0; k <= n; k++) {
        for (var i = 0; i <= k; i++) {
            tosum[k][i] = in1[i] * in2[k-i];
        }
        
        // Reduce mod (X^N + 1)
        l = k + N;
        var len2 = min(n, l) - max(0, l-n) + 1;
        var idx = 0;
        for (var i = max(0, l-n); i <= min(n, l); i++) {
            tosum[k][k+idx+1] = 2*q - (in1[i] * in2[l-i]);
            idx += 1;
        }
        out[k] <== SumK(2*N, k + 1 + len2, q, 2*log2(q))(tosum[k]);
    }
}

/* TODO
template parallel MulCtxtCtxtSchoolbook(l, N, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    
    signal input in1[2][l][N];
    signal input in2[2][l][N];
    signal output out[3][l][N];
    
    for (var i = 0; i < l; i++) {
        out[i] <== MulPolySchoolbook(N, q[i])(in1[i], in2[i]);
    }
}
*/

// Compute assuming both inputs are in NTT form
template parallel MulCtxtCtxt(l, n, q1, q2, q3, q4, q5, q6) {
    signal input in1[2][l][n];
    signal input in2[2][l][n];
    signal tmp1[l][n];
    signal tmp2[l][n];
    signal output out[3][l][n];

    out[0] <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in1[0], in2[0]);

    tmp1 <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in1[0], in2[1]);
    tmp2 <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in1[1], in2[0]);
    out[1] <== parallel FastAddMods(l, n, q1, q2, q3, q4, q5, q6)(tmp1, tmp2);

    out[2] <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in1[1], in2[1]);
}

template parallel FastDoubleMod(q) {
    // Requires in to be in Z/qZ
    // OPTIMIZATION: use multiplication with constant 2 instead of addition
    // This generates fewer labels, but has not influence on the number of constraints
    signal input in; // both inputs need to be in Z/qZ
    signal sum <== 2* in;
    signal quotient <-- sum \ q; // quotient is either 0 or 1
    signal output out <-- sum % q;

    LtConstant(q)(out); // Check that remainder is less than q
    quotient * q + out === sum; // Check that quotient and remainder are correct
    quotient * (quotient - 1) === 0; // Check that quotient is in {0, 1}
}

template parallel FastDoubleMods(l, n, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in[l][n];
    signal output out[l][n];

    for (var i = 0; i < l; i++) {
        for (var j = 0; j < n; j++) {
            out[i][j] <== parallel FastDoubleMod(q[i])(in[i][j]);
        }
    }
}

// Compute assuming both inputs are in NTT form
template parallel SquareCtxt(l, n, q1, q2, q3, q4, q5, q6) {
    signal input in[2][l][n];
    signal tmp[l][n];
    signal output out[3][l][n];

    out[0] <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in[0], in[0]);

    tmp <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in[0], in[1]);
    out[1] <== parallel FastDoubleMods(l, n, q1, q2, q3, q4, q5, q6)(tmp);

    out[2] <== parallel MulsPointwise(l, n, q1, q2, q3, q4, q5, q6)(in[1], in[1]);
}

// Compute assuming both inputs are in NTT form
template parallel SquareCtxtRing() {
    signal input in[2];

    signal output out[3];

    out[0] <== in[0] * in[0];
    out[1] <== 2 * in[0] * in[1];
    out[2] <== in[1] * in[1];
}

// Compute assuming both inputs are in NTT form
template parallel SquareCtxtNoMod(n) {
    signal input in[2][n];
    signal tmp[n];
    signal output out[3][n];

    out[0] <== parallel MulPointwiseNoMod(n)(in[0], in[0]);

    tmp <== parallel MulPointwiseNoMod(n)(in[0], in[1]);
    for (var i = 0; i < n; i++) {
        out[1][i] <== 2*tmp[i];
    }

    out[2] <== parallel MulPointwiseNoMod(n)(in[1], in[1]);
}
