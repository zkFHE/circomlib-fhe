pragma circom 2.1.0;

// Implementation follows https://eprint.iacr.org/2020/086.pdf Section 3.

include "add.circom";
include "ntt.circom";
include "lwe.circom";
include "bootstrap_fhew.circom";
include "bootstrap_tfhe.circom";

/*
    Initialize accumulator given the body 'in' of an LWE ciphertext (_, in).
    Return an accumulator in RLWE in coefficient form for the function f.
        - q: modulus for 'in'. It is assumed that q|2N.
        - N: RLWE dimension.
        - f: function which maps Z_q to Z_Q and is assumed to be negacyclic, 
             i.e., f(v + q/2) = -f(v). (Array of dimension q)
*/
template InitAcc(N, q, f) {
    signal input in;
    signal output out[2][N];

    for (var i=0; i<N; i++) {
        out[0][i] <== 0;
    }

    var qHalf = q>>1;
    var factor = 2*N\q;
    var c[N];

    for (var i=0; i<N; i++) {
        c[i] = 0;
    }

    for (var i=0; i<qHalf; i++) {
        var index = FastSubMod(q)([in, i]);
        c[i*factor] = ArrayAccess1D(q)(f, index);
    }
    
    out[1] <== c;
}

/*
    Return the updated accumulator 'acc_out' in RLWE (coefficient form) given
    the accumulator 'acc_in' in RLWE (coefficient form) and the mask 'a' for an 
    LWE ciphertext (a,_).
        - mode: 0 -> FHEW (DM bootstrap); 1 -> TFHE (CGGI boostrap)
        - (n, q): LWE parameters
        - (N, Q): RLWE parameters
        - Bg: gadget base
        - Br: refreshing base (only needed for FHEW mode) (power of 2)
        - bsk: bootstrapping key (dimensions:
            - mode 0: n x ceil(log_{Br}(q)) x Br x 2*ceil(log_{Bg}(Q)) x 2 x N
            - mode 1: 1 x n x 2 x 2*dg x 2 x N
            )
        - roots: powers of a root of unity for NTTs. (Array of dimension N)
*/
template UpdateAcc(mode, n, N, q, Q, Bg, Br, bsk, roots) {
    signal input acc_in[2][N];
    signal input a[n];
    signal output acc_out[2][N];

    if (mode == 0) {
        acc_out <== UpdateDM(n, N, q, Q, Br, Bg, bsk, roots)(acc_in, a);
    }
    else if(mode == 1) {
        acc_out <== UpdateCGGI(n, N, q, Q, Bg, bsk, roots)(acc_in, a);
    }
}

/*
    Extract an LWE ciphertext (a, b) given an RLWE accumulator 'in' in
    coefficient form.
        - N: RLWE dimension
    
    Warning: 'a' needs to be reordered if we want it to match the original
    bootstrapping key. Otherwise, the difference of keys can be dealt with
    in the key switching procedure
*/
template ExtractFromAcc(N) {
    signal input in[2][N];
    signal output a[N];
    signal output b;

    a <== in[0];
    b <== in[1][0];
}

/*
    Core operations for the bootstrapping of LWE ciphertexts.
        - mode: 0 -> FHEW (DM bootstrap); 1 -> TFHE (CGGI boostrap)
        - (n, q): LWE parameters for (a_in, b_in). It is assumed that q|2N.
        - (N, Q): LWE parameters for (a_out, b_out)
        - Bg: gadget base
        - Br: refreshing base (only needed for FHEW mode) (power of 2)
        - bsk: bootstrapping key (dimensions:
            - mode 0: n x ceil(log_{Br}(q)) x Br x 2*ceil(log_{Bg}(Q)) x 2 x N
            - mode 1: 1 x n x 2 x 2*dg x 2 x N
            )
        - f: function to compute while bootstrapping. It maps Z_q to Z_Q and
             is assumed to be negacyclic, i.e., f(v + q/2) = -f(v).
             (Array of dimension q)
        - roots: powers of a root of unity for NTTs. (Array of dimension N)
*/
template BootstrapCore(mode, n, N, q, Q, Bg, Br, bsk, f, roots) {
    signal input a_in[n], b_in;
    signal output a_out[N], b_out;

    var acc[2][N] = InitAcc(N, q, f)(b_in);

    acc = UpdateAcc(mode, n, N, q, Q, Bg, Br, bsk, roots)(acc, a_in);

    (a_out, b_out) <== ExtractFromAcc(N)(acc);
}

/*
    (Functional) bootstrapping of an LWE ciphertext. Given the encryption of 
    some message m as an LWE ciphertext, return an LWE ciphertext (under the 
    same parameters) with less noise and encrypting f(m).
        - mode: 0 -> FHEW (DM bootstrap); 1 -> TFHE (CGGI boostrap)
        - (n, q): LWE parameters. It is assumed that q|2N.
        - (N, Q): RLWE parameters for internal accumulator
        - Qks: modulus for key switching
        - Bks: base for key switching (power of 2)
        - Bg: gadget base
        - Br: refreshing base (only needed for FHEW mode) (power of 2)
        - ksk: key switching key (dimensions: N x ceil(log_{Bks}(Q)) x Bks x (n+1))
        - bsk: bootstrapping key (dimensions:
            - mode 0: n x ceil(log_{Br}(q)) x Br x 2*ceil(log_{Bg}(Q)) x 2 x N
            - mode 1: 1 x n x 2 x 2*dg x 2 x N
            )
        - f: function to compute while bootstrapping. It maps Z_q to Z_Q and
             is assumed to be negacyclic, i.e., f(v + q/2) = -f(v).
             (Array of dimension q)
        - roots: powers of a root of unity for NTTs. (Array of dimension N)
*/
template Bootstrap(mode, n, N, q, Q, Qks, Bks, Bg, Br, ksk, bsk, f, roots) {
    signal input a_in[n], b_in;
    signal output a_out[n], b_out;

    signal (a_mid0[N], b_mid0) <== BootstrapCore(mode, n, N, q, Q, Bg, Br, bsk, f, roots)(a_in, b_in);

    signal (a_mid1[N], b_mid1) <== ModSwitch(N, Qks, Q)(a_mid0, b_mid0);

    signal (a_mid2[n], b_mid2) <== KeySwitch(n, N, Qks, Bks, ksk)(a_mid1, b_mid1);

    (a_out, b_out) <== ModSwitch(n, q, Qks)(a_mid2, b_mid2);
}
