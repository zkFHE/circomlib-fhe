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
```

```fig
Concrete parameters for building a NAND gate
```

## Building blocks
### LWE ciphertexts
- mask + value
- intuition of why this is secure/hard

<!-- No polynomials in the first few building blocks, only LWE ciphertexts -->

### Addition / Subtraction
- component-wise mod q, (additively) homomorphic property

### Modulus-Switching

### Key-Switching

### RLWE & RGSW ciphertexts

### Accumulators
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
