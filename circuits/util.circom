pragma circom 2.1.0;

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
