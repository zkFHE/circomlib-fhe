pragma circom 2.0.0;

include "ntt.circom";

component main {public [in]} = NTTs(3, 512, (1<<60), (1<<61), (1<<62));
