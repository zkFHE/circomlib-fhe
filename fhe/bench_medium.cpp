#include "seal/seal.h"
#include <iostream>
#include <cassert>

using namespace std;
using namespace seal;


#define N 8192
#define LOG_T 30

#define SEC_PARAM 128
// Most recent and smallest estimate from "Securing Approximate Homomorphic Encryption using Differential Privacy" [LMSS21](https://eprint.iacr.org/2022/816) for lambda = 128 and s = 64
#define NOISE_BITS 45

int main() {
    EncryptionParameters parms(scheme_type::bgv);
    size_t poly_modulus_degree = N;
    parms.set_poly_modulus_degree(poly_modulus_degree);

    //parms.set_coeff_modulus(CoeffModulus::BFVDefault(poly_modulus_degree));
    parms.set_coeff_modulus(CoeffModulus::Create(poly_modulus_degree, {45, 45, 45, 45}));
    parms.set_plain_modulus(PlainModulus::Batching(poly_modulus_degree, LOG_T));
    SEALContext context(parms);

    cout << "[PARAM] Parameter validation (success): "
         << context.parameter_error_message() << endl;
    auto qualifiers = context.first_context_data()->qualifiers();
    cout << "[PARAM] Batching enabled: " << boolalpha << qualifiers.using_batching
         << endl;
    cout << "[PARAM] poly_modulus_degree N=" << parms.poly_modulus_degree() << endl;
    cout << "[PARAM] plain_modulus t=" << parms.plain_modulus().bit_count() << " bits" << endl;
    size_t coeff_modulus_bit_count = 0;
    cout << "[PARAM] coeff_modulus log(q)=";
    for (auto q_i: parms.coeff_modulus()) {
        coeff_modulus_bit_count += q_i.bit_count();
        if (q_i != parms.coeff_modulus()[0]) {
            cout << " + ";
        }
        cout << q_i.bit_count();
    }
    cout << " = " << coeff_modulus_bit_count << " bits" << endl;
    cout << "[PARAM] coeff_modulus.size=" << parms.coeff_modulus().size() << endl;

    KeyGenerator keygen(context);
    SecretKey secret_key = keygen.secret_key();
    PublicKey public_key;
    keygen.create_public_key(public_key);
    Encryptor encryptor(context, public_key);
    Evaluator evaluator(context);
    Decryptor decryptor(context, secret_key);


    BatchEncoder batch_encoder(context);
    size_t slot_count = batch_encoder.slot_count();
    size_t row_size = slot_count / 2;

    vector<uint64_t> pod_matrix(slot_count);
    for (size_t i = 0; i < row_size; i++) {
        pod_matrix[i] = (uint64_t) i;
        pod_matrix[row_size + i] = (uint64_t) 3 * i;
    }

    vector<uint64_t> zeros(slot_count, 0ULL);

    auto start = chrono::high_resolution_clock::now();
    Plaintext x_plain, zero_plain;
    batch_encoder.encode(pod_matrix, x_plain);
    batch_encoder.encode(zeros, zero_plain);

    Ciphertext x_encrypted;
    vector<Ciphertext> zeros_encrypted(SEC_PARAM);
    encryptor.encrypt(x_plain, x_encrypted);
    for (int i = 0; i < SEC_PARAM; i++) {
        encryptor.encrypt(zero_plain, zeros_encrypted[i]);
        evaluator.mod_switch_to_next_inplace(zeros_encrypted[i]); // Match levels of output ciphertext
    }
    auto end = chrono::high_resolution_clock::now();


    cout << "[NOISE] Noise budget in freshly encrypted x: " << decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;
    cout << "[NOISE] Fresh encryption noise: "
         << coeff_modulus_bit_count - decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;

    cout << "=======================================" << endl;
    cout << "[TIME][CLIENT] Encode+Encrypt\t" << chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;

    start = chrono::high_resolution_clock::now();
    Plaintext w_plain;
    batch_encoder.encode(pod_matrix, w_plain);
    end = chrono::high_resolution_clock::now();
    cout << "[TIME][SERVER] Encode\t" << chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;

    // Perform computation
    start = chrono::high_resolution_clock::now();
    evaluator.sub_plain_inplace(x_encrypted, w_plain);
    evaluator.multiply_inplace(x_encrypted, x_encrypted);
    end = chrono::high_resolution_clock::now();
    auto time = chrono::duration_cast<chrono::microseconds>(end - start).count();

    const auto noise_budget_before_noise_flooding = decryptor.invariant_noise_budget(x_encrypted);
    cout << "[NOISE] Noise budget before noise flooding: " << decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;
    auto noise_flooding_budget = NOISE_BITS; //  * ceil(log2(SEC_PARAM / 2));
    cout << "[NOISE] Required remaining noise budget:  " << noise_flooding_budget << " bits" << endl;

    start = chrono::high_resolution_clock::now();
    evaluator.mod_switch_to_next_inplace(x_encrypted);
    end = chrono::high_resolution_clock::now();
    time += chrono::duration_cast<chrono::microseconds>(end - start).count();

    cout << "[NOISE] Noise budget after modswitch: " << decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;
    assert(decryptor.invariant_noise_budget(x_encrypted) >= noise_flooding_budget);

    // Add noise flooding
    start = chrono::high_resolution_clock::now();
    // In reality, each selector bit is chosen u.a.r., so this would be a binomial distribution Binom(n=SEC_PARAM, p=0.5)
    for (int i = 0; i < SEC_PARAM / 2; i++) {
        evaluator.add_inplace(x_encrypted, zeros_encrypted[i]); // Noise flooding
    }
    end = chrono::high_resolution_clock::now();
    cout << "[TIME][SERVER] Eval\t" << time + chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;

    // Decrypt + Decode
    start = chrono::high_resolution_clock::now();
    Plaintext res_plain;
    decryptor.decrypt(x_encrypted, res_plain);
    vector<uint64_t> res;
    batch_encoder.decode(res_plain, res);
    end = chrono::high_resolution_clock::now();
    cout << "[TIME][CLIENT] Decrypt+Decode\t" << chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;


    // Compute total size in bytes, see https://github.com/microsoft/SEAL/issues/88
    unsigned long long size =
            (1 + SEC_PARAM) * x_encrypted.size() * parms.coeff_modulus().size() * parms.poly_modulus_degree() * 8;
    cout << "[SPACE] Ciphertext size\t" << size
         << " B"
         << endl;
    cout << endl;
}

