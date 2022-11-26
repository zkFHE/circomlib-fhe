pragma circom 2.1.0;
include "mod.circom";
include "mul.circom";
include "noise_flooding.circom";
template BenchSmall(l, n, t, q1, q2, q3, q4, q5, q6) {
 var secparam = 128;
 var q[6] = [q1, q2, q3, q4, q5, q6];
 signal input in[2][l][n];
 signal input noise[secparam][2][l][n];
 signal input w1[n];
 signal input w2[n];
 signal input b[secparam];
 signal mul[2][l][n];
 signal out[2][l][n];
 signal output flooded[2][l][n];
 LtConstantN(t, n)(w1);
 LtConstantN(t, n)(w2);
 for (var i = 0; i < l; i++) {
  assert(t < q[i]);
  mul[0][i] <== MulPointwise(n, q[i])(in[0][i], w1);
  mul[1][i] <== MulPointwise(n, q[i])(in[1][i], w1);
 }
 for (var i = 0; i < l; i++) {
  for (var j = 0; j < n; j++) {
   out[0][i][j] <== parallel FastAddMod(q[i])([mul[0][i][j], w2[j]]);
  }
 }
 out[1] <== mul[1];
 flooded <== NoiseFlooding(secparam, 2, l, n, q1, q2, q3, q4, q5, q6)(out, noise, b);
}
component main {public [in, noise]} = BenchSmall(1, 16384, 1073643521, 576460752302473217, 1152921504606683137, 1152921504606748673, 0, 0, 0);
