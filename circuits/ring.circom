pragma circom 2.1.0;

template parallel Num2BitsRing(n) {
	signal input in;
	signal output out[n];
	var lc1=0;

	var e2=1;
	for (var i = 0; i<n; i++) {
		out[i] <-- (in >> i) & 1;
		out[i] * (out[i] -1 ) === 0;
		lc1 += out[i] * e2;
		e2 = e2+e2;
	}

	lc1 === in;
}


template parallel LtConstantRing(ct) {
		signal input in;
		signal res;

		var n = log2(ct);

		component n2b = Num2BitsRing(n+1);
		n2b.in <== in + (1<<n) - ct;
		1-n2b.out[n] === 1;
}
