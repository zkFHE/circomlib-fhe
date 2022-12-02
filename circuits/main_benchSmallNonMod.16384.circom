pragma circom 2.1.0;
include "mod.circom";
include "mul.circom";
include "noise_flooding.circom";

template BenchSmallNoMod(n, t) {
 var secparam = 128;
 signal input in[2][n];
 signal input noise[secparam][2][n];
 signal input w1[n];
 signal input w2[n];
 signal input b[secparam];
 signal mul[2][n];
 signal out[2][n];
 signal output flooded[2][n];
 LtConstantN(t, n)(w1);
 LtConstantN(t, n)(w2);
  mul[0] <== MulPointwiseNoMod(n)(in[0], w1);
  mul[1] <== MulPointwiseNoMod(n)(in[1], w1);

 for (var i = 0; i < n; i++) {
   out[0][i] <== mul[0][i] + w2[i];
 }
 out[1] <== mul[1];
 flooded <== NoiseFloodingNoMod(secparam, 2, n)(out, noise, b);
}
component main {public [in, noise]} = BenchSmallNoMod(16384, 1073643521);