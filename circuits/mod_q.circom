pragma circom 2.0.0;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/compconstant.circom";
include "circomlib/circuits/binsum.circom";

template LtConstant(ct) {
//    assert(ct >= 1);
    signal input in;
    signal bits[254];
    signal res;

    component ToBits = Num2Bits_strict();
    component GtEq = CompConstant(ct-1);

    ToBits.in <== in;
    ToBits.out ==> bits;
    
    GtEq.in <== bits;
    GtEq.out ==> res;
    res === 0;
}


template Mod(q) {
    signal input in;
    signal k;
    signal output out;

    var p = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // TODO: define modularly
    var delta = p \ q; // TODO: ceil? round?

    k <-- in \ q;
    out <-- in % q;
  
    component LtQ = LtConstant(q-1);  
    component LtDelta = LtConstant(delta-1); // TODO: or delta?  
 
    LtQ.in <== out;

    LtDelta.in <== k;
  
    in === k * q + out;
} 
