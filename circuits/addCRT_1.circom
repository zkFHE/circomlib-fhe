pragma circom 2.0.0;

include "util.circom";
include "add.circom";

template AddCRT(L, N, q1, q2, q3) {
	signal input in1[L][N];
	signal input in2[L][N];
	signal output out[L][N];
	
	var q = q1 * q2 * q3;
	
	component fromCRTs[2];
	fromCRTs[0] = parallel FromCRTs(L, N, q1, q2, q3);
	fromCRTs[1] = parallel FromCRTs(L, N, q1, q2, q3);
	component add = parallel AddPoly(N, q);
	component toCRT = parallel ToCRTs(L, N, q1, q2, q3);
	
	fromCRTs[0].in <== in1;
	fromCRTs[0].out ==> add.in1;
	fromCRTs[1].in <== in2;
	fromCRTs[1].out ==> add.in2;
	add.out ==> toCRT.in;
	toCRT.out ==> out;
}

component main {public [in1, in2]} = AddCRT(3, 512, 13, 15, 19);
//component main {public [in1, in2]} = AddPolys(3, 512, 13, 15, 19);
