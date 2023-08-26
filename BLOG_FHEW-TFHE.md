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

- Two branches: RLWE (handled elsewhere), and _LWE_-based
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

### Key-Switching

### Accumulator Phase

#### RLWE & RGSW ciphertexts

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
