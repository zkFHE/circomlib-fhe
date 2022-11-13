pragma circom 2.1.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/compconstant.circom";
include "circomlib/circuits/binsum.circom";
include "util.circom";


template LtConstant(ct) {
    // assert(ct >= 1);
    signal input in;
    signal bits[254];
    signal res;

    bits <== Num2Bits_strict()(in);
    res <== CompConstant(ct-1)(bits);
    res === 0;
}



template Mod(q) {
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
