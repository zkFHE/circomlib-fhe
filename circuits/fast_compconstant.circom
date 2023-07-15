pragma circom 2.1.0;

include "circomlib/circuits/bitify.circom";
include "util.circom";

// Returns 1 if in (in binary) > ct
// OPTIMIZATION: number of constraints depends on bound on bit-size of in, instead of on 254-bits upper-bound
// Improvement over https://github.com/iden3/circomlib/blob/21af0988f8bf1ea5ab2828a52d2d01b3af49e9ef/circuits/compconstant.circom#L29
template CompConstantBound(ct, nbits) {
    assert(nbits > 0);
    signal input in[nbits];
    signal output out;

    var n = (nbits % 2 == 0) ? nbits : nbits + 1;
    var in_ext[n];
    for (var i=0; i<nbits; i++) {
        in_ext[i] = in[i];
    }
    if (n > nbits) {
        in_ext[n-1] = 0;
    }

    var n_half = n >> 1;
    signal parts[n_half];
    
    var ct_l;
    var ct_u;
    var sig_l;
    var sig_u;

    var acc=0;

    var a = 1;

    for (var i=0;i<n_half; i++) {
        ct_l = (ct >> (i*2)) & 1;
        ct_u = (ct >> (i*2+1)) & 1;
        sig_l = in_ext[i*2];
        sig_u = in_ext[i*2+1];

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

    component num2bits = Num2Bits(n_half+1);
    num2bits.in <== acc;
    out <== num2bits.out[n_half];
}

// Returns 1 if in > ct
// Assumes ct > 1 and log2(in) <= log2(ct)
template FastCompConstant(ct) {
    assert(ct > 0);
	var n = log2(ct);
    signal input in;
    signal bits[n] <== Num2Bits(n)(in);
    signal output out <== CompConstantBound(ct, n)(bits);
}

// Returns 1 if in (in binary) > ct
template IsGtConstant(ct, nbits) {
    assert(nbits > 0);
    signal input in[nbits];
    signal output out <== CompConstantBound(ct, nbits)(in);
}

// Returns 1 if in (in binary) >= ct
template IsGeqtConstant(ct, nbits) {
    assert(nbits > 0);
    signal input in[nbits];
    signal output out <== CompConstantBound(ct-1, nbits)(in);
}

// Returns 1 if in (in binary) < ct
template IsLtConstant(ct, nbits) {
    assert(nbits > 0);
    signal input in[nbits];
    var geqt = CompConstantBound(ct-1, nbits)(in);
    signal output out <== 1-geqt;
}

// Returns 1 if in (in binary) <= ct
template IsLeqtConstant(ct, nbits) {
    assert(nbits > 0);
    signal input in[nbits];
    var gt = CompConstantBound(ct, nbits)(in);
    signal output out <== 1-gt;
}

// Enforces in < ct
template parallel LtConstant(ct) {
	signal input in;
	var n = log2(ct);

	component n2b = Num2Bits(n+1);
	n2b.in <== in + (1<<n) - ct;
	1-n2b.out[n] === 1;
}

// Enforces in[i] < ct for all i
template parallel LtConstantN(ct, N) {
	signal input in[N];
	
	for (var i = 0; i < N; i++) {
		parallel LtConstant(ct)(in[i]);
	}
}