pragma circom 2.1.0;

include "add.circom";
include "util.circom";
include "mod.circom";
include "ntt.circom";
include "circomlib/circuits/multiplexer.circom";

template parallel MulPointwise(N, q) {
	signal input in1[N]; 
	signal input in2[N]; 
	signal output out[N];
	
	for (var i = 0; i < N; i++) {
		out[i] <== Mod(q)(in1[i] * in2[i]);
	}
}

template parallel MulsPointwise(L, N, q1, q2, q3) {
	signal input in1[L][N]; 
	signal input in2[L][N]; 
	signal output out[L][N];
	
	var q[L] = [q1, q2, q3]; 
	for (var i = 0; i < L; i++) {
		if (q[i] != 0) {
			out[i] <== MulPointwise(N, q[i])(in1[i], in2[i]);
		}
	}
}


template parallel MulPointwiseNoMod(N) {
	signal input in1[N]; 
	signal input in2[N]; 
	signal output out[N];
	
	for (var i = 0; i < N; i++) {
		out[i] <== in1[i] * in2[i];
	}
}

template parallel MulsPointwiseNoMod(L, N) {
	signal input in1[L][N]; 
	signal input in2[L][N]; 
	signal output out[L][N];
	
	for (var i = 0; i < L; i++) {
		out[i] <== MulPointwiseNoMod(N)(in1[i], in2[i]);
	}
}

template parallel MulNTT(L, N, q1, q2, q3) {
	signal input in1[L][N];
	signal input in2[L][N];
	signal output out[L][N];
	
	var q[L]; 
	assert(0 < L && L <= 3);
	if (L == 1) {q = [q1]; }
	if (L == 2) {q = [q2]; }
	if (L == 3) {q = [q3]; }

	for (var i = 0; i < L; i++) {
		if (q[i] == 0) {
			// TODO: add explicit constraint that out === 0, or do we discard this in a higher protocol level?
		} else {
			var tmp1[N] = NTT(N, q[i])(in1[i]);
			var tmp2[N] = NTT(N, q[i])(in2[i]);
			var tmp[N] = MulPointwise(N, q[i])(tmp1, tmp2);
			out[i] <== INTT(N, q[i])(tmp);
		}
	}
}

template parallel MulPolySchoolbook(N, q) {
	signal input in1[N];
	signal input in2[N];
	var tosum[N][2*N];
	signal output out[N];
	
	var l;
	var n = N-1;
	for (var k = 0; k <= n; k++) {
		for (var i = 0; i <= k; i++) {
			tosum[k][i] = in1[i] * in2[k-i];
		}
		
		// Reduce mod (X^N + 1)
		l = k + N;
		var len2 = min(n, l) - max(0, l-n) + 1;
		var idx = 0;
		for (var i = max(0, l-n); i <= min(n, l); i++) {
			tosum[k][k+idx+1] = 2*q - (in1[i] * in2[l-i]);
			idx += 1;
		}
		out[k] <== SumK(2*N, k + 1 + len2, q, 2*log2(q))(tosum[k]);
	}
}
