pragma circom 2.1.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/binsum.circom";
include "circomlib/circuits/compconstant.circom";
include "util.circom";

// Returns 1 if in (in binary) > ct
// OPTIMIZATION: number of constraints depends on bit-size of constant, instead of on 254-bits upper-bound
// Improvement over https://github.com/iden3/circomlib/blob/21af0988f8bf1ea5ab2828a52d2d01b3af49e9ef/circuits/compconstant.circom#L29
template FastCompConstant(ct) {
    assert(ct > 0);
    // n is the smallest even number >= ct's bitsize
	var ct_bitsize = log2(ct);
	var n;
	assert(ct_bitsize >= 1);
	if (ct_bitsize % 2 == 0) {
	    n = ct_bitsize;
	} else {
	    n = ct_bitsize + 1;
	}
	var n_half = n \ 2;

    signal input in;
    signal bits[n] <== Num2Bits(n)(in);
    signal output out;

    signal parts[n_half];

    var ct_l;
    var ct_u;
    var sig_l;
    var sig_u;

    var acc=0;

    var a = 1;

    for (var i = 0; i < n_half-1; i++) {
        ct_l = (ct >> (i*2)) & 1;
        ct_u = (ct >> (i*2+1)) & 1;
        sig_l = bits[i*2];
        sig_u = bits[i*2+1];

        if (ct_l == 0 && ct_u == 0) {
            parts[i] <== sig_l + sig_u - sig_l*sig_u;
        } else if (ct_l == 1 && ct_u == 0) {
            parts[i] <==  sig_l + 2*sig_u - sig_l*sig_u - 1;
        } else if (ct_l == 0 && ct_u ==1) {
            parts[i] <==  sig_l*sig_u + sig_u - 1;
        } else parts[i] <==  sig_l*sig_u - 1;

        acc = acc + parts[i]*a;
        a = a * 2;
    }

    acc = acc + a - 1;

    component num2bits = Num2Bits(n_half);
    num2bits.in <== acc;
    out <== num2bits.out[n_half-1];
}

/*
template LtPow2(n) {
    // Enforces in < 2^n
    signal input in;
    component bits = Num2Bits(n);
    bits.in <== in;
}
*/

template parallel LtConstant(ct) {
	signal input in;
/*
	component compconstant = FastCompConstant(ct-1);
	compconstant.in <== in;
	//compconstant.out === 0;
*/

	signal res;
	var n = log2(ct);

	component n2b = Num2Bits(n+1);
	n2b.in <== in + (1<<n) - ct;
	1-n2b.out[n] === 1;
}

template parallel LtConstantN(ct, N) {
	signal input in[N];
	
	for (var i = 0; i < N; i++) {
		parallel LtConstant(ct)(in[i]);
	}
}

template parallel Mod(q) {
	signal input in;
	signal quotient;
	signal output out;

	var p = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // TODO: define modularly
	var delta = p \ q; // TODO: ceil? round?

	quotient <-- in \ q;
	out <-- in % q;
   
	parallel LtConstant(q-1)(out);
	parallel LtConstant(delta-1)(quotient); // TODO: or delta?

	in === quotient * q + out;
} 
