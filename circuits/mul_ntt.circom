pragma circom 2.1.0;

include "ntt.circom";

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

template parallel MulNTT(L, N, q1, q2, q3) {
	signal input in1[L][N];
	signal input in2[L][N];
	signal output out[L][N];
	
	var q[L] = [q1, q2, q3];
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

component main {public [in1, in2]} = MulNTT(3, 512, (1<<60), (1<<61), 0);
