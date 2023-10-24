pragma circom 2.1.0;

include "add.circom";
include "mod.circom";
include "fast_compconstant.circom";
include "util.circom";
include "array_access.circom";
include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/comparators.circom";

// addition of LWE ciphertexts: (a1, b1) + (a2, b2)
template AddLWE(n, q) {
    signal input a1[n], b1;
    signal input a2[n], b2;
    signal output a_out[n], b_out;

    for (var i=0; i<n; i++) {
        a_out[i] <== FastAddMod(q)([a1[i], a2[i]]);
    }
    b_out <== FastAddMod(q)([b1, b2]);
}

// subtraction of LWE ciphertexts: (a1, b1) - (a2, b2)
template SubLWE(n, q) {
    signal input a1[n], b1;
    signal input a2[n], b2;
    signal output a_out[n], b_out;

    for (var i=0; i<n; i++) {
        a_out[i] <== FastSubMod(q)([a1[i], a2[i]]);
    }
    b_out <== FastSubMod(q)([b1, b2]);
}

// compute round((q*in)/Q) mod q
template ModSwitchInt(q, Q) {
    assert(log2(q)+log2(Q) < 252);
    signal input in;
    signal output out;
    
    signal prod <== q * in;
    signal quot <-- prod \ Q;
    signal rem <-- prod % Q;

    prod === Q * quot + rem; // correct division
    LtConstant(Q)(rem); // rem < Q
    LtConstant(q)(quot); // quot < q

    var nbits = log2(Q)+1;
    signal {binary} rem2_bits[nbits] <== Num2Bits(nbits)(2*rem);

    signal {binary} bit_add <== IsGeqtConstant(Q, nbits)(rem2_bits);

    // total <== quot + (2*rem < Q) ? 0 : 1
    signal total <== quot + bit_add;

    // reduce mod q
    signal {binary} iszero <== IsEqual()([total, q]);
    out <== (1-iszero)*total;
}

// switches LWE ciphertext from modulus Q to modulus q
template ModSwitch(n, q, Q) {
    assert(log2(q)+log2(Q) < 252);

    signal input a_in[n], b_in;
    signal output a_out[n], b_out;

    for (var i = 0; i < n; i++) {
        a_out[i] <== ModSwitchInt(q, Q)(a_in[i]);
    }
    b_out <== ModSwitchInt(q, Q)(b_in);
}

// switches from key with dimension N to key with dimension n
// the base Bks is assumed to be a power of 2
// ksk has dimension N x logb(Qks,Bks) x Bks x (n+1)
template KeySwitch(n, N, Qks, Bks, ksk) {
    signal input a_in[N], b_in;
    signal output a_out[n], b_out;

    var a[n], b;
    
    var nbitsB = log2(Bks);
    var dks = logb(Qks, Bks);
    var nbits = nbitsB * dks;
    
    for (var i=0; i<n; i++) {
        a[i] = 0;
    }
    b = b_in;

    signal {binary} a_bin[N][nbits];
    signal {binary} a0_bin[N][dks][nbitsB];
    for (var i=0; i<N; i++) {

        a_bin[i] <== Num2Bits(nbits)(a_in[i]);

        for (var j=0; j<dks; j++) {
            
            for (var l=0; l<nbitsB; l++) {
                a0_bin[i][j][l] <== a_bin[i][l + j*nbitsB];
            }

            var key[n+1] = ArrayAccess2DBin(nbitsB, n+1)(ksk[i][j], a0_bin[i][j]);
            // key = [a_1,..., a_n, b]

            var key_a[n];
            for (var h=0; h<n; h++) {
                key_a[h] = key[h];
            }
            var key_b = key[n];

            (a, b) = SubLWE(n, Qks)(a, b, key_a, key_b);
        }
    }

    a_out <== a;
    b_out <== b;
}
