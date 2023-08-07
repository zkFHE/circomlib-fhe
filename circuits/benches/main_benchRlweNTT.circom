pragma circom 2.1.0;

include "ntt.circom";

// compile with -O1
component main = NTT(1024, 134215681);
