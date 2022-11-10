pragma circom 2.0.0;

include "add.circom";

component main {public [in1, in2]} = AddPolys(3, 512, 13, 15, 19);
