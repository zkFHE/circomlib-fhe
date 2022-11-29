#include "seal/seal.h"
#include <iostream>

using namespace std;
using namespace seal;

#define N 8192
#define LOG_T 22


int main() {
    EncryptionParameters parms(scheme_type::bgv);
    size_t poly_modulus_degree = N;
    parms.set_poly_modulus_degree(poly_modulus_degree);

    parms.set_coeff_modulus(CoeffModulus::Create(poly_modulus_degree, {54, 54, 54,
                                                                       55})); // Last modulus is special, and irrelevant for our setting
    parms.set_plain_modulus(PlainModulus::Batching(poly_modulus_degree, LOG_T));
    SEALContext context(parms);

    cout << "[PARAM] Parameter validation (success): "
         << context.parameter_error_message() << endl;
    auto qualifiers = context.first_context_data()->qualifiers();
    cout << "[PARAM] Batching enabled: " << boolalpha << qualifiers.using_batching
         << endl;
    cout << "[PARAM] poly_modulus_degree N=" << parms.poly_modulus_degree() << endl;
    cout << "[PARAM] plain_modulus log(t)=" << parms.plain_modulus().bit_count() << " bits" << endl;
    size_t coeff_modulus_bit_count = 0;
    cout << "[PARAM] coeff_modulus log(q)=";
    for (auto q_i: parms.coeff_modulus()) {
        if (q_i != parms.coeff_modulus()[0]) {
            cout << " + ";
        }
        if (q_i == parms.coeff_modulus()[parms.coeff_modulus().size() - 1]) {
            cout << "(" << q_i.bit_count() << ")";
        } else {
            coeff_modulus_bit_count += q_i.bit_count();
            cout << q_i.bit_count();
        }
    }
    cout << " = " << coeff_modulus_bit_count << " bits" << endl;
    cout << "[PARAM] coeff_modulus.size=" << parms.coeff_modulus().size() << endl;

    cout << "[PARAM] plain_modulus t=" << parms.plain_modulus().value() << endl;
    cout << "[PARAM] coeff_modulus q=";
    for (auto q_i: parms.coeff_modulus()) {
        if (q_i != parms.coeff_modulus()[0]) {
            cout << " * ";
        }
        if (q_i == parms.coeff_modulus()[parms.coeff_modulus().size() - 1]) {
            cout << "(" << q_i.value() << ")";
        } else {
            cout << q_i.value();
        }

    }
    cout << endl;

    KeyGenerator keygen(context);
    SecretKey secret_key = keygen.secret_key();
    PublicKey public_key;
    keygen.create_public_key(public_key);
    RelinKeys relin_keys;
    keygen.create_relin_keys(relin_keys);
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

    Ciphertext x_encrypted, zero_encrypted;
    encryptor.encrypt(x_plain, x_encrypted);
    encryptor.encrypt(zero_plain, zero_encrypted);
    auto end = chrono::high_resolution_clock::now();

    cout << "Noise budget in freshly encrypted x: " << decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;
    cout << "Noise budget in freshly encrypted x: " << decryptor.invariant_noise_budget(zero_encrypted) << " bits"
         << endl;

    cout << "=======================================" << endl;
    cout << "[TIME] Encode+Encrypt\t" << chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;

    // Compute total size in bytes, see https://github.com/microsoft/SEAL/issues/88
    cout << "Ciphertext levels: " << x_encrypted.coeff_modulus_size() << endl;
    unsigned long long size = 2 * x_encrypted.size() * parms.coeff_modulus().size() * parms.poly_modulus_degree() * 8;
    float expansion_factor = float(size) / N; // Each plaintext value takes up 1 byte (L_infty range check of 8 bytes)
    cout << "[SPACE] Ciphertext size\t" << size
         << " B"
         << endl;
    cout << "[SPACE] Expansion factor\t" << expansion_factor
         << endl;


    cout << endl;
}
