pragma circom 2.1.0;

include "add.circom";

component main {public [in1, in2]} = AddPolys(3, 2, 13, 15, 19);