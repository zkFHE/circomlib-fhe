# Circom circuits for FHEW & TFHE

Implementation in Circom of the FHEW and TFHE schemes following the description from [FHEW: Bootstrapping Homomorphic Encryption in less than a second](https://eprint.iacr.org/2014/816) and [Bootstrapping in FHEW-like Cryptosystems](https://eprint.iacr.org/2020/086), as well as the implementation from [OpenFHE](https://github.com/openfheorg/openfhe-development).

## Circuits:

- `add.circom`: modular addition and subtraction of integers and polynomials.
- `array_access.circom`: access to array elements pointed by signal indices.
- `bootstrap_fhew.circom`: accumulator update for FHEW scheme.
- `bootstrap_tfhe.circom`: accumulator update for TFHE scheme.
- `fast_compconstant.circom`: fast comparisons between signals and constants.
- `lwe.circom`: addition, subtraction, modulus switching and key switching of LWE ciphertexts.
- `mod.circom`: modular reduction.
- `mul.circom`: point-wise multiplication, multiplication of polynomials and ciphertexts.
- `nand.circom`: bootstrapped NAND gate.
- `ntt.circom`: Number Theoretic Transform (NTT).
- `rlwe.circom`: addition of RLWE ciphertexts and RLWE-RGSW multiplication.
- `signed_decomposition.circom`: signed digit decomposition of integers and RLWE ciphertexts.
- `util.circom`: min, max, logarithms and extended-gcd functions.
- `benches`: collection of benchmarks for circuits
- `test`: collection of unit tests for circuits
