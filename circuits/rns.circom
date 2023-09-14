pragma circom 2.1.0; 

include "util.circom";
include "mod.circom";

template parallel ToRNS(l, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in;
    signal output out[l];

    for (var i = 0; i < l; i++) {
        out[i] <== parallel Mod(q[i])(in);
    }
}

template parallel ToRNSs(l, n, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in[n];
    signal output out[l][n];
    signal aux[n][l];
    
    component toRNS[n];
    for (var i = 0; i < n; i++) {
        toRNS[i] = parallel ToRNS(l, q1, q2, q3, q4, q5, q6);

        in[i] ==> toRNS[i].in; 
        toRNS[i].out ==> aux[i];
        
        for (var j = 0; j < l; j++) { // Needed since indexes are switched
            aux[i][j] ==> out[j][i]; 
        }
    }
}

template parallel FromRNSHint(l, mq1, mq2, mq3, mq4, mq5, mq6) {
    var mq[6] = [mq1, mq2, mq3, mq4, mq5, mq6];
    signal input in[l];
    signal output out;

    var aux = in[0] * mq[0];
    for (var i = 1; i < l; i++) {
        aux += in[i] * mq[i];
    }
    aux ==> out;
}

template parallel FromRNS(l, q1, q2, q3, q4, q5, q6) {
    assert(l == 3); // TODO: generalize for general l
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in[l];
    signal output out;
    
    var Q[3] = [q2 * q3, q1 * q3, q1 * q2];
    var tmp[l][2] = [extended_gcd(Q[0], q1), extended_gcd(Q[1], q2), extended_gcd(Q[2], q3)];
    var m[l] = [tmp[0][0], tmp[1][0], tmp[2][0]];
    
    var aux = in[0] * m[0] * Q[0];
    for (var i = 1; i < l; i++) {
        aux += in[i] * m[i] * Q[i];
    }
    aux ==> out;
}

template parallel FromRNSs(l, n, q1, q2, q3) {
    signal input in[l][n];
    signal aux[n][l];
    signal output out[n];
    
    component fromRNS[n]; 
    
    assert(0 < l && l <= 3);
    if (l == 1) {
        out <== in[0];
    } else {
        var Q[6];
        if (l == 2) { Q = [q2, q1]; }
        if (l == 3) { Q = [q2 * q3, q1 * q3, q1 * q2]; }
        
        var tmp[l][2] = [extended_gcd(Q[0], q1), extended_gcd(Q[1], q2), extended_gcd(Q[2], q3)];
        var mq[6] = [Q[0] * tmp[0][0], Q[1] * tmp[1][0], Q[2] *  tmp[2][0]];
        
        for (var i = 0; i < n; i++) {
            fromRNS[i] = parallel FromRNSHint(l, mq[0], mq[1], mq[2], -1, -1, -1); // TODO: FIXME
            for (var j = 0; j < l; j++) {
                aux[i][j] <== in[j][i];
            }
            fromRNS[i].in <== aux[i];
            fromRNS[i].out ==> out[i];
        }
    }
}
