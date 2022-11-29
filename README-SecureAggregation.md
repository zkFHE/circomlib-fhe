# Zero-Knowledge Proofs for Secure Aggregation

## RLWE-based HE + zkSNARKs
`circuits/main_SecAgg_RLWE+ZKP.circom`: circuit for range checks + proof of correct encryptions
`fhe/secure_aggregation.cpp`: SEAL code for encryptions

### Setup
Similarly to the EC-based HE + Bulletproofs construction, the clients have a share $sk_i$ of the collective secret key $sk$ (with $sk_i \in R_q$ ). Each client outputs an encryption of its values $c_w = Enc_{sk_i}(\vec{w})$, as well as an encryption of $c_0 = Enc_{sk_i}(\vec{0})$. 

The server can then aggregate both ciphertexts over all client inputs, check consistency using the aggregated $c_0$ (which should decrypt to $0$ if all clients where honest), and decrypt the aggregated $c_w$. 

At the moment there is a single proof for the range check, the use of the same secret key in both encryptions, and the range proofs/correct encryption for both values. 

This setup assumes that the clients already have a share of the collective secret key, as well as knowledge of the public value $a \in R_q$ needed for encryption. 

HE parameters: 
- \#values $n = 2^{13} = 8192 \text{ bits}$
- Range check for $L_\infty = 8 \text{ bits}$
- Plaintext modulus $log_2(t) > log_2(n) + 8 \text{ bits} = 21 \text{ bits}$ 
- Ciphertext modulus $log_2(q) = 162 bits \ge log_2(n) + log_2(t) + \text{noise flooding size} = 13 + 21 + 128$
- HE polynomial degree $N = 2^{13} = 8192 \text{ bits}$ (secure for $q$ as above, this is not directly related to $n$) 
- Security level (cf. [Homomorphic Encryption Standard](https://homomorphicencryption.org/wp-content/uploads/2018/11/HomomorphicEncryptionStandardv1.1.pdf)) $128 < \lambda < 192$

## EC-based HE + zkSNARKs
