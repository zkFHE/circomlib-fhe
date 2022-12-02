pragma circom 2.1.0;
include "add.circom";
component main {public [in1, in2]} = AddPoly(16, (1<<56));
