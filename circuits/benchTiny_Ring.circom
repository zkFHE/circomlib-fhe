pragma circom 2.1.0;

include "ntt.circom";
include "noise_flooding.circom";
include "ring.circom";


template BenchTinyNTTRing() {
	signal input in1[2];
	signal input in2[2];
	signal mul[2];
	signal out[3];
	signal tmp1;
	signal tmp2;

	out[0] <== in1[0] * in2[0];

	tmp1 <== in1[0] * in2[1];
	tmp2 <== in1[1] * in2[0];
	out[1] <== tmp1 + tmp2;
	
	out[2] <== in1[1] * in2[1];
}
