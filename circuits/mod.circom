pragma circom 2.1.0;

include "fast_compconstant.circom";
include "util.circom";

// assumes 1 < q <= 2^252, 0 <= in <= 2^252
template parallel Mod(q) {
    signal input in;
    signal output out;

    out <== ModBound(q, 1 << 252)(in);
}

// return in % q, given that 0 <= in <= b
// assumes 1 < q <= 2^252, 0 <= b <= 2^252
template ModBound(q, b) {
    signal input in;
    signal quotient;
    signal output out;

    quotient <-- in \ q;
    out <-- in % q;

    LtConstant(q)(out);

    var bound_quot = b \ q + 1;
    LtConstant(bound_quot)(quotient);

    in === quotient * q + out;
}
