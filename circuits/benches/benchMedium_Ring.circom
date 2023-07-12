pragma circom 2.1.0;

include "ring.circom";
include "mul.circom";
include "ntt.circom";
include "noise_flooding.circom";

template BenchMediumNTTRing(t) {
	var secparam = 128;
	
	signal input in[2];
	signal input w;
	signal input noise[secparam][3];
	signal input b[secparam];
	signal diff[2];
	signal mul[3];
	signal out[3];
	signal output flooded[3];
	var modSwitchMask = 2; // TODO: this would be a constant mask, i.e., a ring element
	
	LtConstantRing(t)(w);
	signal w_ntt <== NTTRing(8092)(w);
	
	diff[0] <== in[0] - w_ntt;
	diff[1] <== in[1];
	
	mul <== parallel SquareCtxtRing()(diff);
	out[0] <== mul[0] * modSwitchMask;
	out[1] <== mul[1] * modSwitchMask;
	out[2] <== mul[2] * modSwitchMask;
	
	flooded <== NoiseFloodingRing(secparam, 3)(out, noise, b);
}

