pragma circom 2.0.0;

include "mod_q.circom";

function min(x, y) {
	if (x > y) {
		return y;
	} else {
		return x;
	}
}

function max(x, y) {
	if (x > y) {
		return x;
	} else {
		return y;
	}
}

function log2(a) {
	if (a==0) {
		return 0;
	}
	var n = 1;
	var r = 1;
	while (n<a) {
		r++;
		n *= 2;
	}
	return r;
}

function extended_gcd(a, b) {
	var old_r = a; 	var r = b;
	var old_s = 1; 	var s = 0;
	var old_t = 0; 	var t = 1;
	var quotient;
	
	while (r != 0) {
		quotient = old_r \ r;
		old_r = r; r = old_r - quotient * r;
		old_s = s; s = old_s - quotient * s;
		old_t = t; t = old_t - quotient * t;
	}
	
	return [old_s, old_t]; // old_s * a + old_t * b == 1
}

template parallel ToCRT(L, q1, q2, q3) {
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

template parallel ToCRTs(L, N, q1, q2, q3) {
	signal input in[N];
	signal output out[L][N];
	signal aux[N][L];
	
	component toCRT[N];
	for (var i = 0; i < N; i++) {
		toCRT[i] = parallel ToCRT(L, q1, q2, q3);

		in[i] ==> toCRT[i].in; 
		toCRT[i].out ==> aux[i];
		
		for (var j = 0; j < L; j++) { // Needed since indexes are switched
			aux[i][j] ==> out[j][i]; 
		}
	}
}

template parallel FromCRTHint(L, mq1, mq2, mq3) {
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

template parallel FromCRT(L, q1, q2, q3) {
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

template parallel FromCRTs(L, N, q1, q2, q3) {
	signal input in[L][N];
	signal aux[N][L];
	signal output out[N];
	
	component fromCRT[N]; 
	
	var Q[L] = [q2 * q3, q1 * q3, q1 * q2];
	var tmp[L][2] = [extended_gcd(Q[0], q1), extended_gcd(Q[1], q2), extended_gcd(Q[2], q3)];
	var mq[L] = [Q[0] * tmp[0][0], Q[1] * tmp[1][0], Q[2] *  tmp[2][0]];
	
	for (var i = 0; i < N; i++) {
		fromCRT[i] = parallel FromCRTHint(L, mq[0], mq[1], mq[2]);
		for (var j = 0; j < L; j++) {
			aux[i][j] <== in[j][i];
		}
		fromCRT[i].in <== aux[i];
		fromCRT[i].out ==> out[i];
	}
}
