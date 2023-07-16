pragma circom 2.1.0;

include "util.circom";
include "fast_compconstant.circom";
include "circomlib/circuits/bitify.circom";

// Given in (in binary) an integer mod Q, return its signed decomposition
// in base Bg. Denoting dg = ceil(log_{Bg}(Q)), the output is a vector of 
// dg components where each component is in the range [0, Bg/2)U[Q-Bg/2, Q)
// and in = sum_i(out[i]*Bg^i) mod Q.
// Bg is assumed to be a power of 2.
// in is assumed to allow for a signed decomposition of dg digits
template SignedDigitDecomposeInner(Bg, Q) {
    var dg = logb(Q, Bg);
    var nbitsBg = log2(Bg);
    var nbits = dg * nbitsBg;

    signal input in[nbits];
    signal output out[dg];

    var carry = 0;
    signal digits[dg], neg_digits[dg];
    for (var i=0; i<dg; i++) {
        var digit = carry;
        var powerof2 = 1;
        for (var j=0; j<nbitsBg; j++) {
            digit += powerof2 * in[j + i*nbitsBg];
            powerof2 <<= 1;
        }
        digits[i] <== digit;
        var bits_digit[nbitsBg] = Num2Bits(nbitsBg)(digits[i]);
        carry = IsGeqtConstant(Bg>>1, nbitsBg)(bits_digit);
        var neg_digit = digits[i] - Bg + Q;
        out[i] <== carry*(neg_digit - digits[i]) + digits[i];
    }
}

// Given in an integer mod Q, return its signed decomposition in base Bg.
// Denoting dg = ceil(log_{Bg}(Q)), the output is a vector of dg components 
// where each component is in the range [0, Bg/2]U[Q-Bg/2, Q)
// and in = sum_i(out[i]*Bg^i) mod Q.
// Bg is assumed to be a power of 2.
template SignedDigitDecompose(Bg, Q) {
    var dg = logb(Q, Bg);
    var nbits = log2(Bg) * dg;

    signal input in;
    signal output out[dg];

    var bits_in[nbits] = Num2Bits(nbits)(in);
    var is_neg = IsGeqtConstant(Q>>1, nbits)(bits_in);
    var neg_in = Q - in;
    var bits_neg_in[nbits] = Num2Bits(nbits)(neg_in);

    signal bits[nbits];
    for (var i=0; i<nbits; i++) {
        bits[i] <== is_neg*(bits_neg_in[i] - bits_in[i]) + bits_in[i];
    }

    var dec[dg] = SignedDigitDecomposeInner(Bg, Q)(bits);

    signal neg_out[dg];
    for (var i=0; i<dg; i++){
        var iszero = IsZero()(dec[i]);
        neg_out[i] <== (1-iszero) * (Q-dec[i]);
        out[i] <== is_neg*(neg_out[i] - dec[i]) + dec[i];
    }
}

// Given an RLWE ciphertext in = (a,b) = (a[N], b[N]), return the 2*dg
// polynomials obtained by signed-decomposing a and b in base Bg and arranged
// as (a_0, b_0, a_1, b_1,..., a_{dg-1}, b_{dg-1})
template SignedDigitDecomposeRLWE(Bg, N, Q) {
    signal input in[2][N];
    var dg = logb(Q, Bg);
    signal output out[2*dg][N];

    for (var i=0; i<2; i++) {
        for (var j=0; j<N; j++) {
            var dec[dg] = SignedDigitDecompose(Bg, Q)(in[i][j]);
            for (var l=0; l<dg; l++) {
                out[i + 2*l][j] <== dec[l];
            }
        }
    }
}
