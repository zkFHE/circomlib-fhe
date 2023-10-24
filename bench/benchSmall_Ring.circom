pragma circom 2.1.0;

include "circuits/ntt.circom";
include "circuits/noise_flooding.circom";
include "circuits/ring.circom";


template BenchSmallNTTRing(t) {
    var secparam = 128;

    signal input in[2];
    signal input noise[secparam][2];
    signal input w1;
    signal input w2;
    signal input b[secparam];
    signal mul[2];
    signal out[2];
    signal output flooded[2];

    LtConstantRing(t)(w1);
    LtConstantRing(t)(w2);
    
    signal w1_ntt <== NTTRing(8092)(w1);
    signal w2_ntt <== NTTRing(8092)(w2);

    mul[0] <== in[0] * w1_ntt;
    mul[1] <== in[1] * w1_ntt;

    out[0] <== mul[0] + w2_ntt;
    out[1] <== mul[1];

    flooded <== NoiseFloodingRing(secparam, 2)(out, noise, b);
}
