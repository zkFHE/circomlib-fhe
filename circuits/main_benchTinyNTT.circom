pragma circom 2.1.0;

include "benchTiny.circom";

component main {public [in1, in2]} = BenchTinyNTT(2, 2, 1073692673, 576460752303210497, 1152921504606748673, 0, 0, 0, 0);
