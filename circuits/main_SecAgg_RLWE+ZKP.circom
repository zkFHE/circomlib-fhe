pragma circom 2.1.0;

include "mod.circom";
include "mul.circom";

// Range proofs on each input, range proof on secret key and error, encryption of inputs, encryption of 0
template RLWE_ZKP(n, t, q) {
	signal input in[n];
	signal input sk[n];
	signal input a_in[n];	
	signal input a_cons[n];	
	signal input err_in[n];
	signal input err_cons[n];
	
	signal tmp[n];
	signal tmp2[n];
 
	signal output out_in[2][n];
	signal output out_cons[2][n];

	// Range checks	
	LtConstantN((1<<8), n)(in);	// Range check for inputs
	for (var i = 0; i < n; i++) {
		tmp[i] <== sk[i] * (sk[i]-1); // tmp == 0 <=> sk == 0 || sk == 1
		tmp2[i] <== tmp[i] * (sk[i]+1); // tmp2 == 0 <=> sk \in {-1, 0, 1}
		tmp2[i] === 0;
	}
	LtConstantN(19, n)(err_in);	// Range check for error
	LtConstantN(19, n)(err_cons);	// Range check for error
	LtConstantN(q, n)(a_in);
	LtConstantN(q, n)(a_cons);
	

	// Encryption of inputs
	// Symmetric encryption using BGV: (c[0], c[1]) = ([-(as+te)]_q, a)
	signal unreduced_in[n];
	for (var i = 0; i < n; i++) {
		unreduced_in[i] <== -a_in[i] * sk[i] - t * err_in[i] + in[i]; // TODO: no need to check for overflow mod p here?
		out_in[0][i] <== parallel Mod(q)(unreduced_in[i]); 
		out_in[1][i] <== a_in[i];
	}

	signal unreduced_cons[n];
	for (var i = 0; i < n; i++) {
		unreduced_cons[i] <== -a_cons[i] * sk[i] - t * err_cons[i]; // TODO: no need to check for overflow mod p here?
		out_cons[0][i] <== parallel Mod(q)(unreduced_cons[i]); 
		out_cons[1][i] <== a_cons[i];
	}
}

component main = RLWE_ZKP((1<<13), (1<<21), (1<<56));
