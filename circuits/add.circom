pragma circom 2.1.0;

include "util.circom";
include "rns.circom";
include "mod.circom";
include "circomlib/circuits/multiplexer.circom";

template parallel FastAddMod(q) {
	signal input in[2]; // both inputs need to be in Z/qZ
	signal sum <== in[0] + in[1];
	signal quotient <-- sum \ q; // quotient is either 0 or 1
	signal output out <-- sum % q;

	LtConstant(q)(out); // Check that remainder is less than q
	quotient * q + out === sum; // Check that quotient and remainder are correct
	quotient * (quotient - 1) === 0; // Check that quotient is in {0, 1}
}

template parallel FastAddMods(l, n, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
	signal input in1[l][n];
	signal input in2[l][n];
	signal output out[l][n];

	for (var i = 0; i < l; i++) {
		for (var j = 0; j < n; j++) {
			out[i][j] <== parallel FastAddMod(q[i])([in1[i][j], in2[i][j]]);
		}
	}
}

template parallel FastSubMod(q) {
	signal input in[2]; // both inputs need to be in Z/qZ
	signal sub <== in[0] + q - in[1];
	signal quotient <-- sub \ q; // quotient is either 0 or 1
	signal output out <-- sub % q;

	LtConstant(q)(out); // Check that remainder is less than q
	quotient * q + out === sub; // Check that quotient and remainder are correct
	quotient * (quotient - 1) === 0; // Check that quotient is in {0, 1}
}

template parallel FastSubMods(l, n, q) {
	signal input in1[l][n];
	signal input in2[l][n];
	signal output out[l][n];

	for (var i = 0; i < l; i++) {
		for (var j = 0; j < n; j++) {
			out[i][j] <== FastSubMod(q)([in1[i][j], in2[i][j]]);
		}
	}
}


template parallel SumK(n, k, q, inp_size) {
	// assert(q < (1 << 62));
	assert(k > 1);
	assert (k <= n);
	
	signal input in[n]; // only sum first k entries
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

template parallel AddPoly(n, q) {
	signal input in1[n];
	signal input in2[n];
	signal output out[n];
	
	for (var i = 0; i < n; i++) {
		out[i] <== parallel FastAddMod(q)([in1[i], in2[i]]);
	}
}

template AddPolyNoMod(n) {
    signal input in1[n];
    signal input in2[n];
	signal output out[n];
	
	for (var i = 0; i < n; i++) {
		out[i] <== in1[i] + in2[i];
	}
}

template parallel AddPolys(l, n, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
	signal input in1[l][n];
	signal input in2[l][n];
	signal output out[l][n];
		
	component add[l];
	for (var i = 0; i < l; i++) {
	    add[i] <== parallel AddPoly(n, q[i])(in1, in2);
	}
}

