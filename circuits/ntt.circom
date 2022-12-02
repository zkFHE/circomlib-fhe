pragma circom 2.1.0;

include "util.circom";
include "mod.circom";

function add(x, y) {
	return x + y;
}

function sub(q, x, y) {
	return x + q - y;
}

function guard(x) {
	return x;
}

function mul_root(x, r) {
	return x * r;
}

function size_add(s1, s2) {
	return max(s1, s2) + 1;
}

function size_mul(s1, s2) {
	return s1 + s2;
}

template parallel NTT(n, q) {
	signal input values[n];
	var aux[n];
	var size[n];
	signal output out[n];
	var roots[n]; // TODO: hard-code? C pre-processor? Making this a signal might make the circuit bigger than needed. Fill with dummy data for now
	roots[0] = 1;
	for (var i = 1; i < n; i++) {
		roots[i] = roots[i-1] * 34;
	}
	
	
	var r; 
	var u; var size_u;
	var v; var size_v;
	
	var gap = 1;
	var inp_size = log2(q);
	var size_r = log2(roots[n-1]); // TODO: check if this is a static upper bound
	var size_max = 252; // TODO: check how much
	
	
	for (var i = 0; i < n; i++) {
		aux[i] = values[i];
		size[i] = inp_size;
	}
	
	var root_idx = 0;
	var x_idx;
	var y_idx;

	for (var m = n >> 1; m > 1; m >>= 1) {
		var offset = 0;
		if (gap < 4) {
			for (var i = 0; i < m; i++) {
				root_idx += 1; 		// r = *++roots;
				r = roots[root_idx]; 	// r = *++roots;
				x_idx = offset; 	// x = values + offset;
				y_idx = x_idx + gap; 	// y = x + gap;
				for (var j = 0; j < gap; j++) {
					u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));

					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

				}
				offset += gap << 1;
			}
		} else {
			for (var i = 0; i < m; i++) {
				root_idx += 1; 		// r = *++roots;
				r = roots[root_idx]; 	// r = *++roots;
				x_idx = offset; 	// x = values + offset;
				y_idx = x_idx + gap; 	// y = x + gap;
				for (var j = 0; j < gap; j += 4) {
					u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

					u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

					u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

					u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
				}
				offset += gap << 1;
			}
		}
		gap <<= 1;
	}

/*
	if (scalar != nullptr)
	{
		r = *++roots;
		RootType scaled_r = arithmetic_.mul_root_scalar(r, *scalar);
		x = values;
		y = x + gap;
		if (gap < 4)
		{
		for (std::size_t j = 0; j < gap; j++)
		{
			u = arithmetic_.guard(*x);
			v = *y;
			*x++ = arithmetic_.mul_scalar(arithmetic_.guard(arithmetic_.add(u, v)), *scalar);
			*y++ = arithmetic_.mul_root(arithmetic_.sub(u, v), scaled_r);
		}
		}
		else
		{
		for (std::size_t j = 0; j < gap; j += 4)
		{
			u = arithmetic_.guard(*x);
			v = *y;
			*x++ = arithmetic_.mul_scalar(arithmetic_.guard(arithmetic_.add(u, v)), *scalar);
			*y++ = arithmetic_.mul_root(arithmetic_.sub(u, v), scaled_r);

			u = arithmetic_.guard(*x);
			v = *y;
			*x++ = arithmetic_.mul_scalar(arithmetic_.guard(arithmetic_.add(u, v)), *scalar);
			*y++ = arithmetic_.mul_root(arithmetic_.sub(u, v), scaled_r);

			u = arithmetic_.guard(*x);
			v = *y;
			*x++ = arithmetic_.mul_scalar(arithmetic_.guard(arithmetic_.add(u, v)), *scalar);
			*y++ = arithmetic_.mul_root(arithmetic_.sub(u, v), scaled_r);

			u = arithmetic_.guard(*x);
			v = *y;
			*x++ = arithmetic_.mul_scalar(arithmetic_.guard(arithmetic_.add(u, v)), *scalar);
			*y++ = arithmetic_.mul_root(arithmetic_.sub(u, v), scaled_r);
		}
		}
	}
	else
	{
	*/
		root_idx += 1; 		// r = *++roots;
		x_idx = 0; 		// x = values;
		y_idx = x_idx + gap; 	// y = x + gap;
		
		if (gap < 4) {
			for (var j = 0; j < gap; j++) {
				u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
			}
		} else {
			for (var j = 0; j < gap; j += 4) {
				u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

				u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

				u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);

				u = aux[x_idx]; 	// u = *x;
 					size_u = size[x_idx];
					v = aux[y_idx]; 	// v = *y;
					size_v = size[y_idx];
					size[x_idx] = size_add(size_u, size_v);
					size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					if (size[x_idx] >= size_max || size[y_idx] >= size_max) {
						aux[x_idx] = parallel Mod(q)(aux[x_idx]);
						aux[y_idx] = parallel Mod(q)(aux[y_idx]);
						size[x_idx] = size_add(size_u, size_v);
						size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
					}
					aux[x_idx] = guard(add(u, v)); 
					x_idx++; 	// *x++ = arithmetic_.guard(arithmetic_.add(u, v));
					aux[y_idx] = mul_root(sub(q, u, v), r); 
					y_idx++;	// *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
			}
		}
		
	// Final reduction mod q
	for (var i = 0; i < n; i++) {
		if (size[i] < log2(q)) {
			out[i] <== aux[i];
		} else {
			out[i] <== parallel Mod(q)(aux[i]);
		}
	}
	/*
	}
	*/
}

template NTTs(l, n, q1, q2, q3, q4, q5, q6) {
	var q[6] = [q1, q2, q3, q4, q5, q6];
	signal input in[l][n];
	signal output out[l][n];
	
	for (var i = 0; i < l; i++) {
		out[i] <== parallel NTT(n, q[i])(in[i]);
	}
}

template NTTsPlain(l, n, q1, q2, q3, q4, q5, q6) {
	var q[6] = [q1, q2, q3, q4, q5, q6];
	signal input in[n];
	signal output out[l][n];
	
	for (var i = 0; i < l; i++) {
		out[i] <== parallel NTT(n, q[i])(in);
	}
}

template NTTRing(n) {
	signal input values;
	signal aux[n-1];
	signal output out;
	
	// TODO: in the ring setting, these would be ring elements, i.e., polynomials
	var roots = 3; // TODO: hard-code? C pre-processor? Making this a signal might make the circuit bigger than needed. Fill with dummy data for now
	var curr_col = 3;
	
	// NTT(x) = F_0 * x + F_1 * x + ... + F_n * x, with F_0 = 1
	var sum = values;
	for (var i = 1; i < n; i++) {
		aux[i-1] <== curr_col * values;
		sum += aux[i-1];
		
		// Build next column of the DFT Vandermonde matrix
		// F(i, j) = r^(i*j) = r^(i*(j-1)) * r^i = F(i, j-1) * roots[i]
		curr_col = (curr_col * roots);
	}
	out <== sum;
	
}

template INTT(n, q) {
	signal input in[n]; 
	signal output out[n];
	
	out <== NTT(n, q)(in); // TODO: add real implementation, but this has roughly the same complexity
}

template INTTs(l, n, q1, q2, q3, q4, q5, q6) {
	signal input in[l][n]; 
	signal output out[l][n];
	
	out <== NTTs(l, n, q1, q2, q3, q4, q5, q6)(in); // TODO: add real implementation, but this has roughly the same complexity
}
