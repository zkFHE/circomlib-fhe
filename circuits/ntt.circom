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

// based on https://github.com/microsoft/SEAL/blob/206648d0e4634e5c61dcf9370676630268290b59/native/src/seal/util/dwthandler.h#L202
template parallel NTT(n, q, roots) {
    signal input values[n];
    var aux[n];
    var size[n];
    signal output out[n];
    
    var r; 
    var u; var size_u;
    var v; var size_v;
    
    var gap = 1;
    var size_q = log2(q);
    var inp_size = size_q;
    var size_r = size_q;
    var size_max = 252;
    
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
                // r = *++roots;
                root_idx += 1;
                r = roots[root_idx];
                // x = values + offset;
                x_idx = offset;
                // y = x + gap;
                y_idx = x_idx + gap;
                for (var j = 0; j < gap; j++) {
                    // u = *x;
                    u = aux[x_idx];
                     size_u = size[x_idx];

                    // v = *y;
                    v = aux[y_idx];
                    size_v = size[y_idx];

                    // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
                    aux[x_idx] = guard(add(u, v));
                    size[x_idx] = size_add(size_u, size_v); 
                    if (size[x_idx] + 1 + size_r > size_max) {
                        aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                        size[x_idx] = size_q;
                    }
                    x_idx++;

                    // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
                    aux[y_idx] = mul_root(sub(q, u, v), r); 
                    size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
                    if (size[y_idx] + 1 + size_r > size_max) {
                        aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                        size[y_idx] = size_q;
                    }
                    y_idx++;
                }
                offset += gap << 1;
            }
        } else {
            for (var i = 0; i < m; i++) {
                // r = *++roots;
                root_idx += 1; 
                r = roots[root_idx];
                // x = values + offset;
                x_idx = offset;
                // y = x + gap;
                y_idx = x_idx + gap;
                for (var j = 0; j < gap; j += 4) {
                    // u = *x;
                    u = aux[x_idx];
                     size_u = size[x_idx];

                    // v = *y;
                    v = aux[y_idx];
                    size_v = size[y_idx];

                    // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
                    aux[x_idx] = guard(add(u, v));
                    size[x_idx] = size_add(size_u, size_v); 
                    if (size[x_idx] + 1 + size_r > size_max) {
                        aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                        size[x_idx] = size_q;
                    }
                    x_idx++;

                    // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
                    aux[y_idx] = mul_root(sub(q, u, v), r); 
                    size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
                    if (size[y_idx] + 1 + size_r > size_max) {
                        aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                        size[y_idx] = size_q;
                    }
                    y_idx++;

                    // u = *x;
                    u = aux[x_idx];
                     size_u = size[x_idx];

                    // v = *y;
                    v = aux[y_idx];
                    size_v = size[y_idx];

                    // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
                    aux[x_idx] = guard(add(u, v));
                    size[x_idx] = size_add(size_u, size_v); 
                    if (size[x_idx] + 1 + size_r > size_max) {
                        aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                        size[x_idx] = size_q;
                    }
                    x_idx++;

                    // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
                    aux[y_idx] = mul_root(sub(q, u, v), r); 
                    size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
                    if (size[y_idx] + 1 + size_r > size_max) {
                        aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                        size[y_idx] = size_q;
                    }
                    y_idx++;

                    // u = *x;
                    u = aux[x_idx];
                     size_u = size[x_idx];

                    // v = *y;
                    v = aux[y_idx];
                    size_v = size[y_idx];

                    // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
                    aux[x_idx] = guard(add(u, v));
                    size[x_idx] = size_add(size_u, size_v); 
                    if (size[x_idx] + 1 + size_r > size_max) {
                        aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                        size[x_idx] = size_q;
                    }
                    x_idx++;

                    // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
                    aux[y_idx] = mul_root(sub(q, u, v), r); 
                    size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
                    if (size[y_idx] + 1 + size_r > size_max) {
                        aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                        size[y_idx] = size_q;
                    }
                    y_idx++;

                    // u = *x;
                    u = aux[x_idx];
                     size_u = size[x_idx];

                    // v = *y;
                    v = aux[y_idx];
                    size_v = size[y_idx];

                    // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
                    aux[x_idx] = guard(add(u, v));
                    size[x_idx] = size_add(size_u, size_v); 
                    if (size[x_idx] + 1 + size_r > size_max) {
                        aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                        size[x_idx] = size_q;
                    }
                    x_idx++;

                    // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
                    aux[y_idx] = mul_root(sub(q, u, v), r); 
                    size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
                    if (size[y_idx] + 1 + size_r > size_max) {
                        aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                        size[y_idx] = size_q;
                    }
                    y_idx++;
                }
                offset += gap << 1;
            }
        }
        gap <<= 1;
    }

    // r = *++roots;
    root_idx += 1;
    // x = values;
    x_idx = 0;
    // y = x + gap;
    y_idx = x_idx + gap;
    
    if (gap < 4) {
        for (var j = 0; j < gap; j++) {
            // u = *x;
            u = aux[x_idx];
            size_u = size[x_idx];

            // v = *y;
            v = aux[y_idx];
            size_v = size[y_idx];

            // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
            aux[x_idx] = guard(add(u, v));
            size[x_idx] = size_add(size_u, size_v); 
            if (size[x_idx] + 1 + size_r > size_max) {
                aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                size[x_idx] = size_q;
            }
            x_idx++;

            // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
            aux[y_idx] = mul_root(sub(q, u, v), r); 
            size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
            if (size[y_idx] + 1 + size_r > size_max) {
                aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                size[y_idx] = size_q;
            }
            y_idx++;
        }
    } else {
        for (var j = 0; j < gap; j += 4) {
            // u = *x;
            u = aux[x_idx];
            size_u = size[x_idx];

            // v = *y;
            v = aux[y_idx];
            size_v = size[y_idx];

            // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
            aux[x_idx] = guard(add(u, v));
            size[x_idx] = size_add(size_u, size_v); 
            if (size[x_idx] + 1 + size_r > size_max) {
                aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                size[x_idx] = size_q;
            }
            x_idx++;

            // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
            aux[y_idx] = mul_root(sub(q, u, v), r); 
            size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
            if (size[y_idx] + 1 + size_r > size_max) {
                aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                size[y_idx] = size_q;
            }
            y_idx++;

            // u = *x;
            u = aux[x_idx];
            size_u = size[x_idx];

            // v = *y;
            v = aux[y_idx];
            size_v = size[y_idx];

            // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
            aux[x_idx] = guard(add(u, v));
            size[x_idx] = size_add(size_u, size_v); 
            if (size[x_idx] + 1 + size_r > size_max) {
                aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                size[x_idx] = size_q;
            }
            x_idx++;

            // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
            aux[y_idx] = mul_root(sub(q, u, v), r); 
            size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
            if (size[y_idx] + 1 + size_r > size_max) {
                aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                size[y_idx] = size_q;
            }
            y_idx++;

            // u = *x;
            u = aux[x_idx];
            size_u = size[x_idx];

            // v = *y;
            v = aux[y_idx];
            size_v = size[y_idx];

            // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
            aux[x_idx] = guard(add(u, v));
            size[x_idx] = size_add(size_u, size_v); 
            if (size[x_idx] + 1 + size_r > size_max) {
                aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                size[x_idx] = size_q;
            }
            x_idx++;

            // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
            aux[y_idx] = mul_root(sub(q, u, v), r); 
            size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
            if (size[y_idx] + 1 + size_r > size_max) {
                aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                size[y_idx] = size_q;
            }
            y_idx++;

            // u = *x;
            u = aux[x_idx];
            size_u = size[x_idx];

            // v = *y;
            v = aux[y_idx];
            size_v = size[y_idx];

            // *x++ = arithmetic_.guard(arithmetic_.add(u, v));
            aux[x_idx] = guard(add(u, v));
            size[x_idx] = size_add(size_u, size_v); 
            if (size[x_idx] + 1 + size_r > size_max) {
                aux[x_idx] = ModBound(q, (1 << size[x_idx]))(aux[x_idx]);
                size[x_idx] = size_q;
            }
            x_idx++;

            // *y++ = arithmetic_.mul_root(arithmetic_.sub(q, u, v), r);
            aux[y_idx] = mul_root(sub(q, u, v), r); 
            size[y_idx] = size_mul(size_add(size_u, size_v), size_r);
            if (size[y_idx] + 1 + size_r > size_max) {
                aux[y_idx] = ModBound(q, (1 << size[y_idx]))(aux[y_idx]);
                size[y_idx] = size_q;
            }
            y_idx++;
        }
    }
        
    // Final reduction mod q
    for (var i = 0; i < n; i++) {
        if (size[i] == size_q) {
            out[i] <== aux[i];
        } else {
            out[i] <== ModBound(q, (1 << size[i]))(aux[i]);
        }
    }
}

template NTTs(l, n, q1, q2, q3, q4, q5, q6, roots) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in[l][n];
    signal output out[l][n];
    
    for (var i = 0; i < l; i++) {
        out[i] <== parallel NTT(n, q[i], roots[i])(in[i]);
    }
}

template NTTsPlain(l, n, q1, q2, q3, q4, q5, q6, roots) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
    signal input in[n];
    signal output out[l][n];
    
    for (var i = 0; i < l; i++) {
        out[i] <== parallel NTT(n, q[i], roots[i])(in);
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

template INTT(n, q, roots) {
    signal input in[n]; 
    signal output out[n];
    
    out <== NTT(n, q, roots)(in); // TODO: add real implementation, but this has roughly the same complexity
}

template INTTs(l, n, q1, q2, q3, q4, q5, q6, roots) {
    signal input in[l][n]; 
    signal output out[l][n];
    
    out <== NTTs(l, n, q1, q2, q3, q4, q5, q6, roots)(in); // TODO: add real implementation, but this has roughly the same complexity
}
