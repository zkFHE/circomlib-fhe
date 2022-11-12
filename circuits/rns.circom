pragma circom 2.1.0; 

include "util.circom";
include "mod_q.circom";

template parallel ToRNS(L, q1, q2, q3) {
	assert(L == 3);
	signal input in;
	signal output out[L];
	
	var q[L] = [q1, q2, q3];
	component modQ[L];
	for (var i = 0; i < L; i++) {
		modQ[i] = parallel Mod(q[i]);
		in ==>	modQ[i].in; modQ[i].out ==> out[i];
	}
}

template parallel ToRNSs(L, N, q1, q2, q3) {
	signal input in[N];
	signal output out[L][N];
	signal aux[N][L];
	
	component toRNS[N];
	for (var i = 0; i < N; i++) {
		toRNS[i] = parallel ToRNS(L, q1, q2, q3);

		in[i] ==> toRNS[i].in; 
		toRNS[i].out ==> aux[i];
		
		for (var j = 0; j < L; j++) { // Needed since indexes are switched
			aux[i][j] ==> out[j][i]; 
		}
	}
}

template parallel FromRNSHint(L, mq1, mq2, mq3) {
	assert(L == 3);
	signal input in[L];
	signal output out;
	
	var mq[L] = [mq1, mq2, mq3];
	
	var aux = in[0] * mq[0];
	for (var i = 1; i < L; i++) {
		aux += in[i] * mq[i];
	}
	aux ==> out;
}

template parallel FromRNS(L, q1, q2, q3) {
	assert(L == 3);
	signal input in[L];
	signal output out;
	
	var Q[L] = [q2 * q3, q1 * q3, q1 * q2];
	var tmp[L][2] = [extended_gcd(Q[0], q1), extended_gcd(Q[1], q2), extended_gcd(Q[2], q3)];
	var m[L] = [tmp[0][0], tmp[1][0], tmp[2][0]];
	
	var aux = in[0] * m[0] * Q[0];
	for (var i = 1; i < L; i++) {
		aux += in[i] * m[i] * Q[i];
	}
	aux ==> out;
}

template parallel FromRNSs(L, N, q1, q2, q3) {
	signal input in[L][N];
	signal aux[N][L];
	signal output out[N];
	
	component fromRNS[N]; 
	
	var Q[L] = [q2 * q3, q1 * q3, q1 * q2];
	var tmp[L][2] = [extended_gcd(Q[0], q1), extended_gcd(Q[1], q2), extended_gcd(Q[2], q3)];
	var mq[L] = [Q[0] * tmp[0][0], Q[1] * tmp[1][0], Q[2] *  tmp[2][0]];
	
	for (var i = 0; i < N; i++) {
		fromRNS[i] = parallel FromRNSHint(L, mq[0], mq[1], mq[2]);
		for (var j = 0; j < L; j++) {
			aux[i][j] <== in[j][i];
		}
		fromRNS[i].in <== aux[i];
		fromRNS[i].out ==> out[i];
	}
}
