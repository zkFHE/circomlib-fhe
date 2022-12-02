pragma circom 2.1.0;
include "mod.circom";
include "mul.circom";
include "noise_flooding.circom";
template BenchMedium(l, n, t, q1, q2, q3, q4, q5, q6) {
 var secparam = 128;
 var l_out = l-1;

 var q[6] = [q1, q2, q3, q4, q5, q6];
 signal input in[2][l][n];
 signal input w[n];
 signal input noise[secparam][3][l_out][n];
 signal input b[secparam];
 signal diff[2][l][n];
 signal mul[3][l][n];
 signal out[3][l_out][n];
 signal output flooded[3][l_out][n];
 LtConstantN(t, n)(w);
 for (var i = 0; i < l; i++) {
  assert(t < q[i]);
  for (var j = 0; j < n; j++) {
   diff[0][i][j] <== parallel FastSubMod(q[i])([in[0][i][j], w[j]]);
  }
 }
 diff[1] <== in[1];
 mul <== parallel SquareCtxt(l, n, q1, q2, q3, q4, q5, q6)(diff);
 for (var i = 0; i < l_out; i++) {
     for (var j = 0; j < n; j++) {
      out[0][i][j] <== mul[0][i][j];
      out[1][i][j] <== mul[1][i][j];
      out[2][i][j] <== mul[2][i][j];
     }
 }
 flooded <== NoiseFlooding(secparam, 3, 1, n, q1, q2, q3, q4, q5, q6)(out, noise, b);
}
component main {public [in, noise]} = BenchMedium(3, 16384, 1073643521, 35184371138561, 70368743292929, 70368743489537, 0, 0, 0);