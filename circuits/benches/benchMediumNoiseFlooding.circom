pragma circom 2.1.0;

include "mod.circom";
include "mul.circom";
include "ntt.circom";
include "ring.circom";
include "noise_flooding.circom";

template BenchMediumNoiseFlooding(l, n, t, q1, q2, q3, q4, q5, q6) {
	var secparam = 128;
    var l_out = l-1;
    var q[6] = [q1, q2, q3, q4, q5, q6];

	signal input out[3][l_out][n];
	signal input noise[secparam][3][l_out][n];
	signal input b[secparam];
    signal output flooded[3][l_out][n];
    flooded <== NoiseFlooding(secparam, 3, l_out, n, q1, q2, q3, q4, q5, q6)(out, noise, b);
}

template BenchMediumNoiseFloodingRing(t) {
	var secparam = 128;

	signal input noise[secparam][3];
    signal input b[secparam];
	signal input out[3];
   	signal output flooded[3];

	flooded <== NoiseFloodingRing(secparam, 3)(out, noise, b);
}