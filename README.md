# Circom Circuit Library for Fully Homomorphic Encryption

## Description
Thus repository contains a library of circuit templates for Fully Homomorphic Encryption (FHE) computations in the [circom](https://github.com/iden3/circom) language, a high-level domain-specific language for zero-knowledge proofs. You can learn more about circom by reading the [circom docs](https://docs.circom.io/). 

The circuits implement schemes based on Ring Learning With Errors (RLWE) such as BGV (and a stripped-down version of CKKS), as well as the LWE schemes FHEW and TFHE. The references for the scheme implementations are shown below: 

| Scheme | Reference Paper | Reference Implementation |
|---|---|---|
| BGV | <ul> <li> [Fully Homomorphic Encryption without Bootstrapping](https://eprint.iacr.org/2011/277) </li> <li> [Revisiting Homomorphic Encryption Schemes for Finite Fields](https://eprint.iacr.org/2021/204) </li> </ul> | [SEAL](https://github.com/microsoft/seal) |
| FHEW/TFHE | <ul> <li>[FHEW: Bootstrapping Homomorphic Encryption in less than a second](https://eprint.iacr.org/2014/816) </li> <li> [Bootstrapping in FHEW-like Cryptosystems](https://eprint.iacr.org/2020/086) </li> </ul> | [OpenFHE](https://github.com/openfheorg/openfhe-development) |

## Organisation

This repository contains 3 main folders: `circuits`, `test`, and `bench`: 

### Circuits
[circuits](circuits/)<br>
├─ [mod.circom](circuits/mod.circom) ┄┄ modular reduction <br>
├─ [add.circom](circuits/add.circom) ┄┄ modular addition and subtraction of integers and polynomials    <br>
├─ [mul.circom](circuits/mul.circom)point-wise multiplication, multiplication of polynomials and ciphertexts <br>
├─ [rns.circom](circuits/rns.circom) Residue Number System (RNS) operations <br>
├─ [ntt.circom](circuits/ntt.circom) ┄┄ Number Theoretic Transform (NTT) <br>
├─ [signed_decomposition.circom](circuits/signed_decomposition.circom) ┄┄ signed digit decomposition of integers and RLWE ciphertexts <br>
├─ [array_access.circom](circuits/array_access.circom) ┄┄ access to array elements pointed by signal indices <br>
├─ [lwe.circom](circuits/lwe.circom) ┄┄ addition, subtraction, modulus switching and key switching of LWE ciphertexts <br>
├─ [rlwe.circom](circuits/rlwe.circom) ┄┄ addition of RLWE ciphertexts and RLWE-RGSW multiplication <br>
├─ [bootstrap.circom](circuits/bootstrap.circom) ┄┄ accumulator initialization and extractor, common to FHEW and TFHE  <br>
├─ [bootstrap_fhew.circom](circuits/bootstrap_fhew.circom) ┄┄ accumulator update for FHEW scheme   <br>
├─ [bootstrap_tfhe.circom](circuits/bootstrap_tfhe.circom) ┄┄ accumulator update for TFHE scheme   <br>
├─ [fast_compconstant.circom](circuits/fast_compconstant.circom) ┄┄ fast comparisons between signals and constants <br>
├─ [nand.circom](circuits/nand.circom) ┄┄ bootstrapped NAND gate <br>
├─ [noise_flooding.circom](circuits/noise_flooding.circom) ┄┄ simple additive noise flooding for RLWE ciphertexts <br>
├─ [ring.circom](circuits/ring.circom) ┄┄ operations assuming the underlying algebra is the ring $Z_{q_1\dots q_L}[X]/(X^N+1)$, useful for ring-based ZKP such as [Rinocchio](https://github.com/zkfhe/ringSNARK) <br>
├─ [util.circom](circuits/util.circom) ┄┄ min, max, logarithms and extended-gcd functions <br>
├─ [circomlib/](circuits/circomlib/)  ┄┄ the circomlib repo, imported as a git submodule <br>
└─ ...

### Benchmarks
[bench](bench/) contains templates and circom files for various FHE (sub-)computations, as well as executables to run them. 

### Test
[test](test/) contains tests (written as circom templates with known test vectors) for various FHE (sub-)computations. 