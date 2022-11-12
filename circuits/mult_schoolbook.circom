pragma circom 2.0.0;

include "add.circom";
include "util.circom";
include "mod_q.circom";
include "circomlib/circuits/multiplexer.circom";


template parallel MulPolySchoolbook(N, q) {
	signal input in1[N];
	signal input in2[N];
	signal tosum[N][2*N];
	signal test[2*N];
	signal output out[N];
	
	var l;
	var n = N-1;
	for (var k = 0; k <= n; k++) {
		for (var i = 0; i <= k; i++) {
			tosum[k][i] <== in1[i] * in2[k-i];
		}
		
		// Reduce mod (X^N + 1)
		l = k + N;
		var len2 = min(n, l) - max(0, l-n) + 1;
		var idx = 0;
		for (var i = max(0, l-n); i <= min(n, l); i++) {
			tosum[k][k+idx+1] <== 2*q - (in1[i] * in2[l-i]);
			idx += 1;
		}
//		out[k] <== AddModQ(2*N, q)(tosum[k]);
		out[k] <== SumK(2*N, k + 1 + len2, q, 2*log2(q))(tosum[k]);
	}
}


component main {public [in1, in2]} = MulPolySchoolbook(512, (1<<120));
