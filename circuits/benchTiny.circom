pragma circom 2.1.0;

include "mod.circom";
include "mul.circom";
include "noise_flooding.circom";

template BenchTinyNTT(l, n, t, q1, q2, q3, q4, q5, q6) {
	var q[6] = [q1, q2, q3, q4, q5, q6];
	
	signal input in1[2][l][n];
	signal input in2[2][l][n];
	signal output out[3][l][n];
	
	out <== MulCtxtCtxt(l, n, q1, q2, q3, q4, q5, q6)(in1, in2);
}

