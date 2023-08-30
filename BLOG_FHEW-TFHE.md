# A primer to the FHEW & TFHE schemes

Header: 
- This blog post is part of a series in the zkFHEW/zkTFHE project
- Link to repo and circom circuits
- Link to other blog posts and parent

## FHE schemes
- what is FHE?

```fig
timeline!
```

- Two branches: RLWE (handled elsewhere), and *LWE*-based
- Specifics of LWE: bits/smallint, heavy use of fast bootstrapping
- Genealogy: FHEW first, then TFHE

## Notation (write this last, after all the rest)
<!-- Or add notation inline? -->
- Integer arithmetic
- Polynomial/cyclotomic rings
- LWE
- Intuition about the sizes of parameters/standards
- Paragraph: choice of distribution for "small" secrets is non-trivial, and has implications on algorithms (see accumulator update later). We focus on ternary and follow OpenFHE. 

## Overview

```fig
overview of FHEW/TFHE 'lifetime', from inputs to outputs

add input/output spaces
make distinction of phases explicit?
```

```fig
Concrete parameters for building a NAND gate
```

## Building blocks

We can distinguish two major phases in the functional bootstrapping:

1. Accumulator phase: deals with the more complex RLWE and RGSW ciphertexts.

2. Modulus and key switching phase: deals only with the simpler LWE ciphertexts.

We will start by describing the simpler second phase before delving into the accumulator.
### LWE phase

The LWE symmetric encryption scheme is characterized by:

- Dimension: $n$ ($n \approx 512$)
- Message modulus: $t$ ($t=2$ for binary messages)
- Message space: $\mathbb{Z}_t$
- Ciphertext modulus: $q$ (we will assume that $t$ divides $q$) ($q \approx 1024$)
- Ciphertext space: $\mathbb{Z}_q$
- Key space: $\mathbb{Z}_q^n$ (in practice we will work with the subset $\mathbb{Z}_3 ^n \cong \{-1,0,1\}^n$)

Given a message $m \in \mathbb{Z}_t$, its encryption under a key $s \in \mathbb{Z}_q^n$ is an LWE ciphertext of the form:

$$
    (a, b) = (a, a \cdot s + mq/t + e) \in \mathbb{Z}_q^{n} \times \mathbb{Z}_q
$$
where
- the mask $a \leftarrow \mathbb{Z}_q^n$ is sampled uniformly at random,
- the noise $e$ is small and sampled from some gaussian distribution.

We will say that $(a,b)$ is an LWE encryption of $m$ or $(a, b) \in \mathrm{LWE}_s^q(m)$. We will omit $q$ and/or $s$ whenever they are not relevant or can be inferred from the context.

Given a ciphertext $(a',b') \in \mathbb{Z}_q^{n+1}$, it is decrypted as follows:

$$
    m' = \lfloor t(b-a \cdot s)/q\rceil  \mod t
$$

- Give an intution on its security. Remark importance of noise and the problems of having too much noise.

<!-- No polynomials in the first few building blocks, only LWE ciphertexts -->

### Addition / Subtraction

The LWE encryption scheme is additively homomorphic. Given two LWE ciphertexts $(a, b), (a', b') \in \mathbb{Z}_q^{n+1}$ then
$$
    (a, b) + (a', b') = (a + a', b + b') \in \mathbb{Z}_q^{n+1},
$$
where the sum of the masks $a + a'$ is performed component-wise, and all the sums are performed modulo $q$.

### Modulus-Switching

- Allows to change the modulus of an LWE ciphertext.

- Given $(a,b) \in \mathrm{LWE}^Q(m)$ and a target modulus $q$, the following operation will be performed to all the components of the ciphertext:
$$
    [x]_{Q:q} = \lfloor qx/Q \rceil
$$
- Overall,
$$
    \mathrm{ModSwitch}(a, b) = (([a_1]_{Q:q}, \dots, [a_n]_{Q:q}), [b]_{Q:q}) \in \mathrm{LWE}^q(m).
$$

### Key-Switching

- Additional elements:
    - specific modulus for key switching $Q_{ks}$
    - key swithing base $B_{ks}$

- Input: ciphertext $(a,b) \in \mathrm{LWE}^{Q_{ks}}_z(m)$ under secret key $z \in \Z_{Q_{ks}}^N$

- Output: ciphertext in $\mathrm{LWE}^{Q_{ks}}_s(m)$ under secret key $s \in \Z_{Q_{ks}}^n$

- Requires key switching key $\mathcal{K}=\{k_{i,j,v}\}$:
    $$
        k_{i,j,v} \in \mathrm{LWE}^{Q_{ks}}_s(vz_iB^j_ {ks}), 
    $$
    $$
        i \in \{1,\dots,N\}, \; j \in \{0,\dots, d_{ks}-1 \}, \; v \in \{0,\dots,B_{ks}-1\}, \; d_{ks} = \lceil \log_{B_{ks}}Q_{ks} \rceil
    $$

- Decomposing $a_i = \sum_j a_{i,j}B^j_ {ks}, \; i \in \{1,\dots, N\}, \; a_{i,j} \in \{0,\dots,B_{ks}-1\}$, then
    $$
        \mathrm{KeySwitch}((a,b), \mathcal{K}) = (\textbf{0},b) - \sum_{i,j}k_{i,j,a_{i,j}}
    $$

<!-- Include pseudocode showing loops in more detail?-->

### Accumulator Phase

- The accumulator allows to perform the core operation of the bootstrapping, i.e., the homomorphic decryption of the ciphertext.

- It involves three main operations: the initialization of the accumulator, its update, and the extraction of the resulting LWE ciphertext from the accumulator. The update operation is the only operation in which the FHEW and TFHE schemes differ.

- Since we will need to multiply ciphertexts and the LWE encryption scheme is not multiplicatively homomorphic, we will need to rely on more complex schemes: Ring-LWE (RLWE) and Ring-GSW (RGSW).

#### RLWE ciphertexts

The Ring-LWE (RLWE) encryption scheme is characterized by:

- Dimension: $N$ ($N \approx 1024$)
- Cyclotomic Ring: $\mathcal{R} = \mathbb{Z}[X]/(X^N+1)$ ($\mathcal{R} \cong \mathbb{Z}^N$)
- Message modulus: $t$ ($t=2$ for binary messages)
- Message space: $\mathcal{R}_t = \mathbb{Z}_t[X]/(X^N+1) \cong \mathbb{Z}_t^N$
- Ciphertext modulus: $Q$ ($Q$ prime $\approx 2^{27}$)
- Ciphertext space: $\mathcal{R}_Q = \mathbb{Z}_Q[X]/(X^N+1) \cong \mathbb{Z}_Q^N$
- Key space: $\mathcal{R} \cong \mathbb{Z}^N$ (in practice we will work with the subset $\{-1,0,1\}^n$)


- Warning, we're going to go back and forth between evaluation and representation forms for polynomials.
  
#### Initialization
- Common to both schemes
- Explain using f = id, then show that you can replace this with a "useful" f that has to have some properties (i.e., negacyclic)

<!-- Do we want to explain how to get a negacyclic f' from a given f -->

##### Fast polynomial multiplication via NTT
- Why NTT?

#### Update
<!-- This is where FHEW/TFHE differ -->
- Assume there's some magic RLWE-RGSW mult algorithm
- Show how FHEW first
- TFHE does it differently

<!-- We present the case for the ternary key distribution, not the binary case as for Zama, and not the general case as in Micciancio-Polyakov paper.  -->
<!-- Security of binary keys is not super well-understood, and ternary is a "safe" choice of distribution.  -->


##### RLWE-RGSW multiplication
- signed bit decomposition

<!-- How does TFHE using a single signed decomp fit here? Or elsewhere? -->

#### Extraction
- Subtlety: re-ordering of the components
- Know more? Let us know!


## Conclusion

An intro to FHEW and TFHE
- show their differences and similarities
- Relation to the OpenFHE implementation
- Acknowledgements and further ressources
  
Footer: repeat header
