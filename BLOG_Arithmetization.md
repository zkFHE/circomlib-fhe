# Arithmetization of FHEW & TFHE

Fully Homomorphic Encryption (FHE) allows to perform computations on encrypted data, making it particularly useful for providing privacy to outsourced computations. The privacy guarantees of FHE schemes can however be threatened by malicious servers with access to a partial decryption oracle, i.e., when servers can distinguish whether the ciphertext sent to the client decrypted correctly or not. Moreover, in many settings the client would like to receive some guarantee of the correctness of the computation that the server has performed. Both issues can be addressed by combining FHE with Zero-Knowledge Proofs (ZKPs). This way, the server can attach to the result of the computation a proof of correctness, while hiding the server's private inputs from the client. That combination, however, raises some challenges.

## What is the role of R1CS constraints and what do they look like?

In order to be able to prove some computation, it needs to be in the right form. The general idea is to express computations as an arithmetic circuit, which defines a collection of R1CS constraints. These constraints in a Rank-1 constraint system (R1CS) can be then introduced into a ZKP system.

The variables of a circuit are called signals. The circuit takes some input signals, computes a series of intermediate signals and finally outputs one or more output signals. R1CS constraints determine the relation between these signals, i.e., how one signal is obtained from the others, and those relations are defined by the addition and multiplication gates of the circuit.

Circuits are defined over some finite field $\mathbb{F}_p$ for some large prime $p$. In this sense, their addition and multiplications gates perform additions and multiplications modulo $p$. Moreover, all the signals of the circuits, and hence all the values that appear in the R1CS constraints, are in $\mathbb{F}_p$.

Given a circuit with signals $s_1, \dots, s_n$, the R1CS constraints are equations of the form

$$(a_1 \cdot s_1 + \dots + a_n \cdot s_n) \cdot (b_1 \cdot s_1 + \dots + b_n \cdot s_n) + (c_1 \cdot s_1 + \dots + c_n \cdot s_n) = 0,$$

where $a_i, b_i, c_i \in \mathbb{F}_p$ for all $i \in \{0, \dots, n\}$.

Note that those equations can be constant, linear or quadratic equations. Those are the types of expressions that we will need to transform our computations into.

## Challenges of arithmetizing FHEW & TFHE

In order to prove FHE computations via ZKPs, as we have seen in the last section, we will need to express those computations as an arithmetic circuit over some finite field $\mathbb{F}_p$ so as to generate the R1CS constraints that can be later introduced into the ZKP system.

We will focus on FHEW and TFHE, two FHE schemes that stand out for their fast bootstrapping operation. In a previous blog post [], we provide a thorough description of all the operations that those schemes involve. Based on those operations, we can point out some of the challenges to overcome when arithmetizing those FHE schemes:

- Mismatch between the rings from FHE ($\mathbb{Z}_q$ and $\mathbb{Z}_Q[X]/(X^N+1)$) with respect to the finite field $\mathbb{F}_p$ for R1CS.
- Rounding in the modulus switching.
- Multiple digit decompositions in different bases and signed decomposition.
- Array accesses to indices that are not known statically, e.g. in the key switching, or in FHEW's accumulator update.
- Heavy use of Number Theoretic Transforms (NTTs).
- Big RLWE-RGSW multiplication with many modular reductions.

In the next few sections we will go into detail about how to approach the arithmetization of some particular operations. The example code will be written in Circom, a language tailored to arithmetic circuits and the definition of R1CS constraints. For a full arithmetization of FHEW and TFHE in Circom check out our repository [].  

## Warmup: Modular Reduction

The mismatch between the rings that FHE schemes use, i.e, $\mathbb{Z}_q$ and $\mathbb{Z}_Q[X]/(X^N+1)$ with respect to the finite field $\mathbb{F}_p$ of R1CS, requires us to perform reductions modulo $q$ or $Q$ so as to emulate the rings inside the finite field. As a reference, in practice we deal with $q=1024$, $Q\approx 2^{27}$ and $N=1024$, whereas the prime field modulus of circom is $p \approx 2^{254}.$

Therefore, the modular reduction is a core operation that needs arithmetizing. While it is not a complex operation, it is a good example to showcase how to arithmetize with Circom and how to optimize the number of constraints.

A first approach to arithmetize the modular reduction could look as follows:

```
template Mod(q) {
    signal input in;
    signal quotient;
    signal output out;

    quotient <-- in \ q;
	out <-- in % q;

    in === quotient * q + out;

	LtConstant(q)(out);
}
```

The template works with an input signal `in`, an intermediate signal `quotient` and an output signal `out`. It also receives a parameter $q$, which is the modulus for the reduction. The idea of the template is to compute `in % q` and put it in the output signal `out`. 

The assignment `out <-- in % q` would suffice if we just wanted to compute the result. However, we also want to introduce the constraints relating the signal input `in` to the output signal `out`, and the operator `%` doesn't fit with the R1CS constraints we need to generate. Therefore, the assingment we have just shown is an unsafe one, it performs the computation without constraining the signals. On the contrary, whenever we assign an expression that can directly form an R1CS constraint we can use the operator `<==`.

In order to constrain the signal `out`, we store the quotient of the division `in/q` in an intermediate signal `quotient <-- in \ q`. Note that in Circom, the operator `\` refers to the integer division. With such a signal, we can introduce a constraint expressing the equation of the division

```
in === quotient * q + out
```

Additionally, we need to constrain the signal `out` to be less that the modulus `q`. To do this, we can use the gadget `LtConstant(q)(out)` which precisely introduces the constraint `out < q` in an arithmetic way. In order to do so, that gadget introduces $\log_2(q)$ constraints.

If we were working over the integers, those two constraints would suffice, as there are unique quotient and remainder satisfying the division equation with a remainder less than the divisor. However, we are working inside $\mathbb{F}_p$, were the integer division doesn't behave as naturally. For instance, for $in' = 11$, $q' = 7$ and $p' = 23$ we have that

$$in' = 1 \cdot q' + 4 \mod p'$$

and

$$in' = 4 \cdot q' + 6 \mod p'.$$

The problem comes from the potential overflow of `quotient * q`. If that product is larger or equal than `p`, then it will be reduced modulo `p`. To avoid this, we need to introduce an upper bound on the quotient so as to enforce that it doesn't overflow. The following code introduces such a constraint:

```
template Mod(q) {
    signal input in;
    signal quotient;
    signal output out;

    quotient <-- in \ q;
	out <-- in % q;

    in === quotient * q + out;

	LtConstant(q)(out);

    var bound_quot = (2**253)\q;
    LtConstant(bound_quot)(quotient);
}
```

This approach assumes that the input `in` is less than $2^{253}$, what could be ensured in the functions that use this gadget, and bounds the quotient imposing `quotient < (2**253)\q`. This version works fine and we could even avoid introducing assumptions on the input by replacing $2^{253}$ with the actual value of Circom's prime $p$.

By compiling the circuit we can check the number of constraints that this gadget generates for a given modulus. Interestingly, the number of constraints is $254$ independently of the modulus used. Apart for the constraint for the division, the gadget `LtConstant(q)` introduces $\log_2(q)$ constraints and the gadget `LtConstant((2**253)\q)` introduces $\log_2(2^{253}/q) = 253 - \log_2(q)$ constraints.

Considering that we will make heavy use of the modular reduction, it is worth taking a closer look in case we can reduce the number of constraints. An example will hint at the solution. In the context of an RLWE-RGSW multiplication, we need to reduce modulo $Q$ values which can be at most $2^{57}$. However, with the gadget we just introduced, the quotient will be bounded assuming that the input can be up to $2^{253}$. Following the previous analysis, that bound on the quotient takes 226 out of the total 254 constraints.

Essentially, we can significantly reduce the number of constraints by introducing a tighter bound on the quotient based on a known bound on the input. We can modify our gadget to receive the bound on the input as a parameter.

```
template ModBound(q, b) {
    signal input in;
    signal quotient;
    signal output out;

    quotient <-- in \ q;
	out <-- in % q;

    in === quotient * q + out;

	LtConstant(q)(out);

    var bound_quot = b\q + 1;
    LtConstant(bound_quot)(quotient);
}
```

With this new approach, the number of constraints generated is $log_2(b) + 1$ assuming that $b >= q$. For the previous example, this results in 58 constraints, as opposed to the 254 from the other approach.

## Signed Decomposition

- Present latex
- Issue + solution
- High-level strategy
- Circom code with line numbers
- More detailed explanation of particular parts

## Addressing other challenges

As for addressing some of the other challenges that we faced, here is a list of solutions we found:

- Rounding. In order to compute $\lfloor x/q \rceil$, once we have obtained the quotient and remainder and constrained the division as $x = quot \cdot q + rem$, then we can use some comparison gadget to obtain the result computing

$$\lfloor x/q \rceil = quot + (2rem < q)\;?\;0\;:\;1$$

- Standard digit decomposition in different bases. Most of the parameters sets available for FHEW/TFHE used power-of-2 bases.  By assuming so, we can leverage the binary decomposition from `Num2Bits` to obtain the digits for those larger bases.

- Array access to indices unkown at compilation time. The idea is to perform a linear combination of all the elements of the array, where all the coefficients are 0 except the one corresponding to the element pointed by the index, which will be 1. We can use the `IsEqual` gadget to assign the coefficients to the linear combination. See [reference to circom blog post].

- NTTs: we adapted the NTT implemented by SEAL. We keep track of a bound on the size of the elements and only perform modular reductions right before they overflow the field modulus $p$.

- Big RLWE-RGSW multiplication: we delay all the modular reductions until after all the sums and multiplications have been performed, as the sizes of the parameters allow to do so. This results in a reduction of constraints by a factor of 10 compared to performing the modular reduction after each operation.

In many situations, the challenge is not that much about figuring out how to arithmetize some particular operation, but rather about how to obtain the least number of constraints while doing so.

## Numbers

- Number of lines of code
- Number of gadgets
- Number of constraints generated
- Breakdown of constraints per operation
- Highlight the bottlenecks
- Point at ways to minimize the number of constraints further: modular reductions accross functions.

## Conclusion

- Hard
- Iterative process
- Domain expertise: speeds up come from optimizing modular reduction e.g., which requires some analysis
- High level numbers: compare to zk-VM approach, works theoretically but orders in magnitud slower vs expert analysis
- If you want to know how to implement it with some high-assurance - stay tune for next blog post