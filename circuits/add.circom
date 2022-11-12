pragma circom 2.1.0;

include "util.circom";
include "rns.circom";
include "mod_q.circom";
include "circomlib/circuits/multiplexer.circom";


template parallel SumK(N, k, q, inp_size) {
	// assert(q < (1 << 62));
	assert(k > 1);
	assert (k <= N);
	
	signal input in[N]; // only sum first k entries
	var aux;
	signal output out;
	signal tmp;
	
	var batch_size = 254 - inp_size; // How many elements in Z_q can be added without overflowing in Z_p
	
	if (batch_size >= k) {
		aux = in[0];
		for (var i = 1; i < k; i++) {
			aux += in[i];
		}
		out <== parallel Mod(q)(aux);
	} else {
		aux = in[0];
		for (var i = 1; i <= batch_size; i++) {
			aux += in[i];
		}
		tmp <== parallel Mod(q)(aux);
		var aux[k-batch_size];
		aux[0] = tmp;
		for(var i = 0; i < k-batch_size-1; i++) {
			aux[i+1] = in[batch_size+i+1];
		}
		out <== SumK(k-batch_size, k-batch_size, q, inp_size)(aux);
	}
}

template parallel AddModQ(k, q) {
	// assert(q < (1 << 62));
	assert(k > 1);
	
	signal input in[k];
	var aux;
	signal output out;
	signal tmp;
	
	var logQ = log2(q);
	var batch_size = 254 - logQ; // How many elements in Z_q can be added without overflowing in Z_p
	
	if (batch_size >= k) {
		aux = in[0];
		for (var i = 1; i < k; i++) {
			aux += in[i];
		}
		out <== parallel Mod(q)(aux);
	} else {
		aux = in[0];
		for (var i = 1; i <= batch_size; i++) {
			aux += in[i];
		}
		tmp <== parallel Mod(q)(aux);
		var aux[k-batch_size];
		aux[0] = tmp;
		for(var i = 0; i < k-batch_size-1; i++) {
			aux[i+1] = in[batch_size+i+1];
		}
		out <== AddModQ(k-batch_size, q)(aux);
	}
}

template parallel AddPoly(N, q) {
	signal input in1[N];
	signal input in2[N];
	signal output out[N];
	
	for (var i = 0; i < N; i++) {
		out[i] <== parallel AddModQ(2, q)([in1[i], in2[i]]);
	}
}

template parallel AddPolys(L, N, q1, q2, q3) {
	signal input in1[L][N];
	signal input in2[L][N];
	signal output out[L][N];
	
	var q[L] = [q1, q2, q3]; // Workaround, circom does not allow array arguments to templates
	
	component add[L];
	for (var i = 0; i < L; i++) {
		if (q[i] > 0) { // For parameter choices with less levels, set q_i to 0 and skip circuit generation
			add[i] = parallel AddPoly(N, q[i]);
			add[i].in1 <== in1[i];
			add[i].in2 <== in2[i];
			add[i].out ==> out[i];
		}
	}
}

