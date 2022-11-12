pragma circom 2.1.0;

include "util.circom";
include "rns.circom";
include "add.circom";

template AddRNS(L, N, q1, q2, q3) {
	signal input in1[L][N];
	signal input in2[L][N];
	signal output out[L][N];
	
	var q = q1 * q2 * q3;
	component add = parallel AddPoly(N, q);
	
	add.in1 <== parallel FromRNSs(L, N, q1, q2, q3)(in1);
	add.in2 <== parallel FromRNSs(L, N, q1, q2, q3)(in2);
	out <== parallel ToRNSs(L, N, q1, q2, q3)(add.out);
}

component main {public [in1, in2]} = AddRNS(3, 2, 13, 15, 19);