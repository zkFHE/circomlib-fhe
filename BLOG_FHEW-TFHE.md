# A primer to the FHEW & TFHE schemes

Header: 
- This blog post is part of a series in the zkFHEW/zkTFHE project
- Link to repo and circom circuits
- Link to other blog posts and parent

## Fully Homomorphic Encryption: FHEW & TFHE

Fully Homomorphic Encryption (FHE) is a cryptographic primitive that allows to perform computations on encrypted data. A general use case starts with a client sending its encrypted data to a server. The server will then process that encrypted data without learning its content and will send back the encrypted result that only the client can decrypt. The big efficiency improvements achieved in this primitive in the last few years have fostered the design and development of many privacy-enhancing technologies. <!-- reference examples? -->

```fig
diagram of client-server communication
```

The security of most FHE constructions rely on the introduction of some small random noise into the ciphertexts. While that noise is meant to make it infeasible for attackers to decrypt without knowing the key, it also raises some issues. The noise increases when performing computations and ciphertexts can only withstand a certain amount of noise before they become useless. In 2009, Gentry solved this problem introducing the so-called bootstrapping procedure that lowers the noise of a ciphertext without having access to the decryption key, hence constructing the first fully homomorphic encryption scheme [Gen09].

Since Gentry's work, a variety of FHE schemes have been proposed with important efficiency improvements <!-- add references?-->. As the bootstrapping is one the main bottlenecks, different approaches have been presented to deal with this costly operation, such as simultaneously refreshing the noise of many ciphertexts in the same bootstrapping or performing as many operations as possible before bootstrapping. The FHEW scheme [DM15] focused instead on simplifying the setting and supports a fast bootstrapping procedure tailored for ciphertexts encrypting a single bit. The TFHE scheme [CGGI16, CGGI20] subsequently improved on it and is part of the state of the art in terms of FHE schemes for boolean and short integer operations (up to 8 bits). More recently, two new variants have been proposed in [LMK+23] and [XZD+23].


```fig
timeline (include new proposals?)
```

There are several explanations of the fundamentals of FHEW and/or TFHE schemes ([DM15], [CGGI20], [MP21], [J22], [ZAMA's post]). Implementation-wise the main references are OpenFHE's implementation of FHEW and TFHE [OpenFHE], and ZAMA's implementation of TFHE [TFHE-rs]. Despite the variety of resources, the use of different notations and levels of abstraction in the explanations and the highly optimized code of the implementations make it hard to relate them to each other. The aim of this blog post is thus to bridge the gap between theory and practice by providing a thorough yet simple description of all the operations that these schemes involve. With that in mind, our focus will not be that much on *why* they work  but rather on *how* they work with descriptions close to the implementation level.

Particularly useful was the work by Daniele Micciancio and Yuri Polyakov [MP21] describing the differences between FHEW and TFHE in a unified framework. That is the framework that this post will follow. In particular, we will consider both schemes in the integer setting (instead of describing TFHE in the Torus setting), we will consider ternary secret keys for both schemes (instead of the binary keys that TFHE originally proposed but for which there is less assurance about their security) and we will describe FHEW with certain optimizations of TFHE that can be applied to both schemes.

## Functional Boostrapping - Overview

The FHEW and TFHE schemes focus on boolean and short integer computations and stand out for their fast bootstrapping procedure. Interestingly, their bootstrapping operation not only refreshes the noise of the ciphertext, but it can also be configured to compute a function at the same time. That is the reason why it is also referred to as a functional bootstrapping or programmable bootstrapping.

```figure
diagram of functional bootstrapping reducing noise while computing a function
```

Circuits can be generally obtained by the application of several functional bootstrapping operations. For instance, any boolean circuit can be expressed in terms of NAND gates, and a bootstrapped NAND gate can be constructed by applying a functional bootstrapping to the sum of two encrypted bits - we will see how at the end of the post. This use of the bootstrapping operation is called gate bootstrapping.

```fig
circuit composed of NAND gates
```

In essence, the description of the FHEW and TFHE schemes comes down to the description of their functional bootstrapping procedures. Their structure is as follows: 

```fig
overview of FHEW/TFHE 'lifetime', from inputs to outputs

add input/output spaces
make distinction of phases explicit
```

We can distinguish two major phases in the functional bootstrapping: the accumulator phase, that deals with the more complex RLWE and RGSW ciphertexts, and the LWE phase, that deals with the simpler LWE ciphertexts. 

It is also important to note that the only algorithmic difference between both schemes is the accumulator update, also known as the blind rotation procedure. The rest of the operations are the same for both schemes.

For expository purposes, we will start by describing the simpler LWE phase before delving into the accumulator.

## LWE phase

An important part of the functional bootstrapping only deals with LWE ciphertexts. Let's see how these ciphertexts look like and what operations are performed with them.

### LWE ciphertexts

Given a message $m \in \mathbb{Z}_t$, an LWE encryption of $m$ under a key $s \in \mathbb{Z}_q^n$ is a LWE ciphertext of the form:

$$
    (a, b) = (a, \;\;(a \cdot s + \tilde{m} + e)\mod q) \in \mathbb{Z}_q^{n} \times \mathbb{Z}_q
$$

where
- $\tilde{m} = (q/t)m \in \mathbb{Z}_q$ is the encoding of m
- $n$ is the dimension (in practice $n \approx 512$)
- $t$ is the message modulus ($t = 2$ for binary messages)
- $\mathbb{Z}_t$ is the message space
- $q$ is the ciphertext modulus (in practice $q = 1024$)
- $s \in \mathbb{Z}_q^n$ is the key (in practice we will work with keys in the subset $\mathbb{Z}_3 ^n \cong \{-1,0,1\}^n$)
- $a \leftarrow \mathbb{Z}_q^n$ is a uniformly at random sampled mask
- $e \in \mathbb{Z}_q$ is a small noise or error sampled at random

```figure
diagram of an LWE ciphertext
```


We define the error of a ciphertext to be $\mathrm{err}(a, b)=(b-a \cdot s-\tilde{m}) \mod q$ and will consider it to be in the centered interval $[-q/2, q/2)$. Note that for a fresh encryption we have $\mathrm{err}(a, b)=e$. We will say that $(a,b)$ is an LWE encryption of $\tilde{m}$ or $(a, b) \in \mathrm{LWE}_s^q(\tilde{m})$ as long as $|\mathrm{err}(a, b)| < q/(2t)$. 

Given a ciphertext $(a',b') \in \mathbb{Z}_q^{n+1}$, it is decrypted as follows:

$$
    \tilde{m}' = \lfloor t(b-a \cdot s)/q\rceil  \mod t
$$

The rounding operation takes care of the small added noise. However, for the decryption to work correctly the noise needs to be $|\mathrm{err}(a',b')| < q/(2t)$. The noise growth that occurs when performing computations with ciphertexts justify the need for refreshing their noise with a bootstrapping procedure.

The security of this encryption scheme relies on the hardness asumption of the Learning With Errors (LWE) problem. Essentially, because of the introduction of the small noise or error $e$, it is assumed to be infeasible for an attacker to decrypt without knowing the secret key $s$.

<!-- No polynomials in the first few building blocks, only LWE ciphertexts -->

### Addition & Subtraction

The LWE encryption scheme is additively homomorphic. Given two LWE ciphertexts $(a, b) \in \mathrm{LWE}_s^q(\tilde{m}), (a', b') \in \mathrm{LWE}_s^q(\tilde{m}')$ then

$$
    (a'', b'') = (a, b) + (a', b') = (a + a', b + b') \in \mathbb{Z}_q^{n+1},
$$

where the sum of the masks $a + a'$ is performed component-wise, and all the sums are performed modulo $q$. We have that $\mathrm{err}(a'',b'')=\mathrm{err}(a,b)+\mathrm{err}(a',b')$, and so we will have $(a'', b'') \in \mathrm{LWE}_s^q(\tilde{m}+\tilde{m}')$ as long as $|\mathrm{err}(a,b)+\mathrm{err}(a',b')| < q/(2t).$

```figure
diagram of LWE addition
```

Similarly, LWE ciphertexts can be subtracted by considering the subtraction modulo $q$.

### Modulus Switching

The modulus switching procedure allows to change the modulus of an LWE ciphertext.

Given $(a,b) \in \mathrm{LWE}^Q_s(\tilde{m})$ encrypted with modulus $Q$ and a target modulus $q$, the following operation will be performed to all the components of the ciphertext:

$$
    [x]_{Q:q} = \lfloor qx/Q \rceil
$$

Overall,

$$
    \mathrm{ModSwitch}(a, b) = (([a_1]_{Q:q}, \dots, [a_n]_{Q:q}), [b]_{Q:q}) \in \mathrm{LWE}^q_s(\tilde{m}).
$$

### Key Switching

The key switching procedure allows to change the key under which a LWE ciphertext is encrypted. This method is parametrized by a key switching modulus $Q_{ks}$ (in practice $Q_{ks} \approx 2^{14}$) and a key switching base $B_{ks}$ (in practice $B_{ks} \approx 128$). We can denote the number of digits of $Q_{ks}$ under base $B_{ks}$ as $d_{ks} = \lceil \log_{B_{ks}}Q_{ks} \rceil$.

Given a LWE ciphertext $(a,b) \in \mathrm{LWE}^{Q_{ks}}_z(\tilde{m})$ under secret key $z \in \mathbb{Z}_{Q_{ks}}^N$ and a key switching key $\mathrm{KSK}$, this operation returns a LWE ciphertext in $\mathrm{LWE}^{Q_{ks}}_s(\tilde{m})$ under secret key $s \in \mathbb{Z}_{Q_{ks}}^n$.


The key switching key is of the form $\mathrm{KSK}=\{\mathrm{ksk}_{i,j,v}\}$ where:

$$
    k_{i,j,v} \in \mathrm{LWE}^{Q_{ks}}_s(vz_iB^j_ {ks}), 
$$

$$
    i \in \{1,\dots,N\}, \; j \in \{0,\dots, d_{ks}-1 \}, \; v \in \{0,\dots,B_{ks}-1\}.
$$

Note that this method not only changes the encryption key, but also the dimension of the LWE ciphertext from a dimension $N$ (in practice $N = 1024$) to a dimension $n$ (in practice $n \approx 512$). 

The key switching works by decomposing under the base $B_{ks}$ each component of the mask $a$ of the input LWE ciphertext:

$$
a_i = \sum_{j=0}^{d_{ks}-1} a_{i,j}B^j_ {ks}, \; i \in \{1,\dots, N\}, \; a_{i,j} \in \{0,\dots,B_{ks}-1\}.
$$

By obtaining the decomposition, the output of the method is:
$$
    \mathrm{KeySwitch}((a,b), \mathrm{KSK}) = (\textbf{0},b) - \sum_{i,j}k_{i,j,a_{i,j}}
$$

We can consider the LWE ciphertexts to be pairs of the form `(a[n], b)` and the key switching key to be a 3D array of size $N \times d_{ks} \times B_{ks}$ whose components are LWE ciphertexts.

```
Key Switching

INPUT: (a[N], b), K[N][dks][Bks] of (x[n], y)
OUTPUT: (a'[n], b')

(a', b') := ([0,..,0], b)
FOR i=0 to N-1
    c := a[i]
    FOR j=0 to dks-1
        digit := c % Bks
        key := K[i][j][digit]
        (a', b') := (a', b') - key
        c := c / Bks
    ENDFOR
ENDFOR

RETURN (a', b') 
```

## Accumulator Phase

The accumulator allows to perform the core operation of the functional bootstrapping, i.e., given a function $\mathrm{f}$ and an LWE ciphertext encrypting some encoded message $\tilde{m}$, it will return an LWE ciphertext with less noise encrypting $\mathrm{f}(\tilde{m})$. That LWE ciphertext that will be extracted from the accumulator will have different dimension, modulus and encryption key with respect to the input ciphertext. That is the reason why a later phase of modulus and key switching is needed. Note that the function $\mathrm{f}$ can be set to be the identity function if we just want to refresh the noise of the ciphertext.

The rough idea of the accumulator is to initialize a polynomial that stores the images of the function $\mathrm{f}$ in its coefficients. The update or blind rotation step will rotate the coefficients of the polynomial according to the given LWE ciphertext. Finally, the constant term of the polynomial will be extracted to construct the output LWE ciphertext. The part where FHEW and TFHE differ is in how they perform the update step.

In this phase we will work with more complex ciphertexts that deal with polynomials and that will allow us to multiply ciphertexts: Ring-LWE (RLWE) and Ring-GSW (RGSW) ciphertexts.

### RLWE ciphertexts

The Ring-LWE (RLWE) scheme is analogous to the LWE scheme, but using polynomials instead of elements in $\mathbb{Z}_q$. We will only consider RLWE ciphertexts with one polynomial in the mask (instead of $n$ components as we did for LWE). Additionally, we will assume that messages are already encoded to the proper space.

The polynomials we will work with are elements of the cyclotomic ring $\mathcal{R} = \mathbb{Z}[X]/(X^N+1)$. As such, they can be expressed as polynomials of degree strictly less than N. Instead of working with coefficients in $\mathbb{Z}$, we will usually restrict them to $\mathbb{Z}_Q$ for some modulus $Q \in \mathbb{N}$. Hence, we will consider $\mathcal{R}_Q = \mathbb{Z}_Q[X]/(X^N+1)$. Note that we can identify $\mathcal{R}_Q$ with $\mathbb{Z}_Q^N$ and so implementation-wise we can see an element of $\mathcal{R}_Q$ as an array of $N$ components each of them storing one coefficient of the polynomial as an integer in $\{0,..,Q-1\}$.

Given a message $m \in \mathcal{R}_Q$, an RLWE ciphertext encrypting $m$ can be computed as:

$$
    (A, B) = (A, A \cdot z + m + e) \in \mathcal{R}_Q \times \mathcal{R}_Q,
$$

where

- $N$ is the dimension of the cyclotomic ring (in practice $N = 1024$)
- $Q$ is the prime ciphertext modulus (in practice $Q \approx 2^{27}$)
- $z \in \mathcal{R}_Q$ is the key (in practice we will work with keys in the "subset" $\{-1,0,1\}^N$)
- $a \leftarrow \mathcal{R}_Q$ is a uniformly at random sampled mask (by sampling each of the N coefficients of the polynomial)
- $e \in \mathcal{R}_Q$ is a small noise sampled at random

```figure
diagram of an RLWE ciphertext, comparing it to a LWE ciphertext
```

We will say that $(A, B)$ is a RLWE encryption of $m$ or that $(A, B)
 \in \mathrm{RLWE}_z^Q(m)$ as long as the noise is within boundaries.

The decryption procedure is analogous to that of LWE and the security of the scheme is based on the Ring-Learning With Errors (RLWE) hardness assumption which is analogous to the LWE one.

### RGSW ciphertexts

Ring-GSW (RGSW) ciphertexts are based on the work from [GSW] and can be seen as a collection of RLWE ciphertexts. They are parametrized by a gadget base $B_G$ (in practice $B_G \approx 128$) and we can denote the number of digits of $Q$ under base $B_G$ as $dg = \lceil \log_{B_G}(Q)\rceil$.

The RLWE encryption scheme

$$\mathrm{RLWE}_z^Q(m) \subseteq \mathcal{R}_Q \times \mathcal{R}_Q,$$

can be extended to the following RLWE' scheme

$$\mathrm{RLWE}_z^{'Q}(m) = (\mathrm{RLWE}_z^Q(m), \mathrm{RLWE}_z^Q(B_Gm), \dots, \mathrm{RLWE}_z^Q(B_G^{dg-1}m)) \subseteq (\mathcal{R}_Q^2)^{dg}$$

and finally we can obtain the RGSW ciphertexts as

$$\mathrm{RGSW}_z^Q(m)=(\mathrm{RLWE}_z^{'Q}(-s \cdot m), \mathrm{RLWE}_z^{'Q}(m)) \subseteq ((\mathcal{R}_Q^2)^{dg})^2$$

  
### Initialization

Given the second component $b \in \mathbb{Z}_q$ of a LWE ciphertext and a function $\mathrm{f}: \mathbb{Z}_q \to \mathbb{Z}_Q$, the accumulator is initiliazed to a noiseless encryption $(0,p) \in \mathrm{RLWE}(p)$ of the polynomial

$$
p(X) = \sum_{i=0}^{q/2} f(b-i) \cdot X^{i \cdot (2N/q)}
$$

Note that the range of the input function $\mathrm{f}$ is $\mathbb{Z}_Q$, so in general we will need to rescale the values of the images when working with a function mapping $\mathbb{Z}_q \to \mathbb{Z}_q$. We will see an example of this when going over the bootstrapped NAND gate.

Regarding the factor $2N/q$ in the exponent, it comes from the fact that we are dealing with a sparse embedding of $\mathbb{Z}_Q/(X^{q/2} + 1)$ to $\mathbb{Z}_Q/(X^{N} + 1)$. For this we need to impose that $q$ divides $2N$.

A pseudocode description of the method follows:

```
Accumulator Initialization

INPUT: b, f[q]
OUTPUT: (A[N], B[N])

(A, B) := ([0,..,0], [0,..,0])
FOR i=0 to q/2-1
    B[i * (2N/q)] := f[(b-i) % q]
ENDFOR

RETURN (A, B) 
```


### Update

The accumulator update or blind rotation is the core operation of the bootstrapping as well as its main bottleneck. It is a procedure that FHEW and TFHE perform differently: FHEW follows the approach from Alpein-Sherif-Peikert [] and TFHE the one from Gama-Izabachene-Nguyen-Xie [].

Given as inputs:
- the mask $a \in \mathbb{Z}_q^n$ of an LWE ciphertext $(a, b) \in \mathrm{LWE}_s^q(m)$, 
- the initialized accumulator $(A, B) \in \mathrm{RLWE}_z^Q(\sum_{i=0}^{q/2} f(b-i) \cdot X^{i \cdot (2N/q)})$ and 
- the bootstrapping key $\mathrm{BSK}$ consisting of a collection of RGSW ciphertexts encrypting the components of the key $s \in \mathbb{Z}_q^n$ under key $z \in \mathcal{R}_Q$, 

the blind rotation procedure returns an updated accumulator:

$$(A', B') \in \mathrm{RLWE}_z^Q\left(\sum_{i=0}^{q/2} f(b-i) \cdot X^{(i-\textbf{a} \cdot \textbf{s}) \cdot (2N/q)}\right).$$

With respect to the content of the input RLWE ciphertext, the output is multiplied by the monomial $X^{(-a \cdot s) \cdot (2N/q)}$. That factor essentially performs a rotation of the coefficients of the polynomial, taking into account that operations are computed modulo $X^N+1$ (so $X^N \equiv -1$ and $X^{2N} \equiv 1$). 

Fundamentally, FHEW and TFHE differ in how they multiply the content of the accumulator by $X^{(-a_j \cdot s_j) \cdot (2N/q)}$ for each step $j \in \{0,\dots,n-1\}$. 

In both cases, the schemes rely on a multiplication operation between RLWE and RGSW ciphertexts. Let's assume for now that we know how to multiply them and let 

$$\odot : \mathrm{RLWE} \times \mathrm{RGSW} \to \mathrm{RLWE}$$

denote that operation.

#### FHEW's Accumulator Update

The accumulator update of FHEW is parametrized by a refreshing base $B_r$ (in practice $B_r \approx 32$). We can denote the number of digits of $q$ in the base $B_r$ as $d_r = \lceil \log_{B_r}q \rceil$.

Given as inputs:
- the mask $a \in \mathbb{Z}_q^n$ of an LWE ciphertext $(a, b) \in \mathrm{LWE}_s^q(m)$, 
- the initialized accumulator $(A, B) \in \mathrm{RLWE}_z^Q(\sum_{i=0}^{q/2} f(b-i) \cdot X^{i \cdot (2N/q)})$ and 
- the bootstrapping key $\mathrm{BSK}=\{\mathrm{bsk}_{i,j,v}\}$ where

$$ \mathrm{bsk}_{i,j,v} \in \mathrm{RGSW}_z^Q(X^{vB_r^js_i \cdot (2N/q)}),$$

$$i \in \{0,\dots,n-1\}, \;\; j \in \{0,\dots,d_r-1\}, \;\; v \in \{0,\dots,B_r-1\}
$$

the blind rotation procedure returns an updated accumulator:

$$(A', B') \in \mathrm{RLWE}_z^Q\left(\sum_{i=0}^{q/2} f(b-i) \cdot X^{(i-\textbf{a} \cdot \textbf{s}) \cdot (2N/q)}\right).$$

This procedure has a similar idea to the key switching previously explained. For each $i \in \{0,\dots,n-1\}$ we will decompose $-a_i \;\mathrm{mod} \; q$ under the base $B_r$, i.e., 

$$-a_i \equiv \sum_{j=0}^{d_r-1}a_{i,j}B_r^j \mod q.$$ 

Then at each step $(i,j) \in \{0,\dots,n\} \times \{0,\dots,d_r-1\}$ we will update the current value $\mathrm{ACC}$ of the accumulator as $\mathrm{ACC} := \mathrm{ACC} \odot \mathrm{bsk}_{i,j,a_{i,j}}$.

As for the pseudocode version:

```
Accumulator Update - FHEW

INPUT: a[n], (A[N], B[N]) in RLWE, BSK[n][dr][Br] of RGSW ciphertexts
OUTPUT: (A'[N], B'[N]) in RLWE

(A', B') := (A, B)
FOR i=0 to n-1
    c := (-a[i] % q)
    FOR j=0 to dr-1
        digit := c % Br
        key := BSK[i][j][digit]
        (A', B') :=  (A', B') ⊙ key
        c := c/Br
    ENDFOR
ENDFOR

RETURN (A', B')
```

Note that whenever $a_{i,j}=0$ for some $i \in \{0,\dots,n-1\},\;j \in \{0,\dots d_r-1\}$, the respective $\mathrm{bsk}_{i,j,a_{i,j}}$ will just be an encryption of $1$. In that case, the multiplication $(A',B') \odot \mathrm{bsk}_{i,j,a_{i,j}}$ is redundant. Therefore, we can omit from $\mathrm{BSK}$ all the ciphertexts of the form $\mathrm{bsk}_{i,j,0}$ and only update the accumulator for those $(i,j)$ for which $a_{i,j} \neq 0$.

#### TFHE's Accumulator Update

The accumulator update procedure that we are going to describe is slightly different to TFHE's original version. The original construction strongly relies on the use of binary secret keys, but their security is currently not well-understood. While the construction can be adapted to keys with larger components, the performance decays as the size increases. In such situations, the Homomorphic Encryption Standard [] mentions the option of using ternary secret keys, i.e., with components uniformly distributed in $\{-1, 0, 1\}$. Fortunately, the performance of TFHE with ternary keys is close to the binary case by following the approach introduced in [JP22]. That is the version that OpenFHE implements and the one that we are going to cover.

Given as inputs:
- the mask $a \in \mathbb{Z}_q^n$ of an LWE ciphertext $(a, b) \in \mathrm{LWE}_s^q(m)$, 
- the initialized accumulator $(A, B) \in \mathrm{RLWE}_z^Q(\sum_{i=0}^{q/2} f(b-i) \cdot X^{i \cdot (2N/q)})$ and 
- the bootstrapping key $\mathrm{BSK}'=\{\mathrm{bsk}'_{i,j}\}$ where

$$ \mathrm{bsk}'_{i,j} \in \mathrm{RGSW}_z^Q(x_{i,j}),$$

$$s_i=x_{i,1} - x_{i,-1}, \;\;x_{i,j} \in \{0,1\}, \;\; x_{i,-1} \cdot x_{i,1} = 0,$$

$$i \in \{0,\dots,n-1\}, \;\; j \in \{-1, 1\}
$$

the blind rotation procedure returns an updated accumulator:

$$(A', B') \in \mathrm{RLWE}_z^Q\left(\sum_{i=0}^{q/2} f(b-i) \cdot X^{(i-\textbf{a} \cdot \textbf{s}) \cdot (2N/q)}\right).$$

The bootstrapping key $\mathrm{BSK}'$ is quite different from the bootstrapping key $\mathrm{BSK}$ from FHEW. In this case, we are leveraging the fact that $s \in \{-1,0,1\}^n$ to decompose each of its components as $s_i = x_{i,1} - x_{i,-1}$ where:

- If $s_i = -1$, then $x_{i,-1} = 1$ and $x_{i,1}=0$.
- If $s_i = 0$, then $x_{i,-1} = 0$ and $x_{i,1}=0$.
- If $s_i = 1$, then $x_{i,-1} = 0$ and $x_{i,1}=1$.

We will update the accumulator sequentially for each component $s_i$ of the mask. In each step $i \in \{0,\dots,n-1\}$, the value $\mathrm{ACC}$ of the accumulator will be updated as:

$$\mathrm{ACC} := \mathrm{ACC} + (X^{-a_i \cdot (2N/q)}-1) \cdot (\mathrm{ACC} \odot \mathrm{bsk}'_{i,1}) + (X^{a_i \cdot (2N/q)}-1) \cdot (\mathrm{ACC} \odot \mathrm{bsk}'_{i,-1})$$

To see this in pseudocode version:

```
Accumulator Update - TFHE

INPUT: a[n], (A[N], B[N]) in RLWE, BSK'[n][2] of RGSW ciphertexts
OUTPUT: (A'[N], B'[N]) in RLWE

(A', B') := (A, B)
FOR i=0 to n-1
    exp1 := (-a[i] % q) * (2N/q)
    exp2 := (-exp % 2N)

    prod1 := (A', B') ⊙ BSK'[i][0]
    prod2 := (A', B') ⊙ BSK'[i][1]

    (A', B') := (A', B') + (X^exp1 - 1)*prod1 + (X^exp2 - 1)*prod2
ENDFOR

RETURN (A', B')
```

#### RLWE-RGSW multiplication
- signed bit decomposition
- fast multiplication via NTTs
- show extended versions of FHEW & TFHE blind rotation

<!-- Note that TFHE requires half the number of NTTs and signed decompositions. -->

### Extraction

Given the accumulator 

$$(A, B) \in \mathrm{RLWE}_z^Q\left(\sum_{i=0}^{q/2} f(b-i) \cdot X^{(i-a\cdot s) \cdot (2N/q)}\right)$$ 

where $(a, b) \in \mathrm{LWE}_s^q(\tilde{m})$, we will extract a LWE ciphertext $(a',b') \in \mathrm{LWE}_{z'}^Q(\mathrm{f}(\tilde{m}))$.

The $N$ components of the mask $a'$ will be the $N$ coefficients of the mask $A$. Additionally, the second component $b'$ of the ciphertext will just be the constant term of the polynomial $B$.

Note that applying this method we will obtain a LWE ciphertext encrypted under the key $z'=(z_0,-z_{N-1},-z_{N-2},\dots,-z_1) \in \mathbb{Z}_Q^n$, where $z_i$ are the coefficients of the RLWE key $z \in \mathcal{R}_Q$ for $i  \in \{0,\dots,N-1\}$. If we want to obtain a LWE ciphertext encrypted under the original key $z$ (or more precisely, under its coefficients), we can apply a signed permutation to the mask. However, we can take care of this in the key switching procedure by switching directly from the key $z'$ to the key $s$.

The pseudocode of this method follows:

```
Extraction from the Accumulator

INPUT: (A[N], B[N])
OUTPUT: (a'[N], b')

(a', b') := (A, B[0])

RETURN (A, B) 
```

## Combining all together

## Example: bootstrapped NAND gate


## Conclusion

An intro to FHEW and TFHE
- show their differences and similarities
- Relation to the OpenFHE implementation
- Acknowledgements and further ressources

## Notation (write this last, after all the rest)
- Integer arithmetic
- Polynomial/cyclotomic rings
- LWE
- Intuition about the sizes of parameters/standards
- Paragraph: choice of distribution for "small" secrets is non-trivial, and has implications on algorithms (see accumulator update later). We focus on ternary and follow OpenFHE.

## References
  
Footer: repeat header
