#include "seal/seal.h"
#include <iostream>
#include <cassert>

using namespace std;
using namespace seal;


#define N 8192
#define LOG_T 30
#define REPEATS 10


int main() {
    EncryptionParameters parms(scheme_type::bgv);
    size_t poly_modulus_degree = N;
    parms.set_poly_modulus_degree(poly_modulus_degree);

    if (N == 8192 || N == 16384) {
        parms.set_coeff_modulus(CoeffModulus::Create(poly_modulus_degree, {43, 43, 60}));
    }
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
        coeff_modulus_bit_count += q_i.bit_count();
        if (q_i != parms.coeff_modulus()[0]) {
            cout << " + ";
        }
        cout << q_i.bit_count();
    }
    cout << " = " << coeff_modulus_bit_count << " bits" << endl;
    cout << "[PARAM] coeff_modulus.size=" << parms.coeff_modulus().size() << endl;

    cout << "[PARAM] plain_modulus t=" << parms.plain_modulus().value() << endl;
    cout << "[PARAM] coeff_modulus q=";
    for (auto q_i: parms.coeff_modulus()) {
        if (q_i != parms.coeff_modulus()[0]) {
            cout << " * ";
        }
        cout << q_i.value();
    }
    cout << endl;

    auto start = chrono::high_resolution_clock::now();
    KeyGenerator keygen(context);
    SecretKey secret_key = keygen.secret_key();
    PublicKey public_key;
    keygen.create_public_key(public_key);
    auto end = chrono::high_resolution_clock::now();
    auto time = chrono::duration_cast<chrono::microseconds>(end - start).count();
    cout << "[TIME][CLIENT] One-time setup\t" << time << " us" << endl;
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

    start = chrono::high_resolution_clock::now();
    Plaintext x_plain, y_plain;
    batch_encoder.encode(pod_matrix, x_plain);
    batch_encoder.encode(pod_matrix, y_plain);

    Ciphertext x_encrypted, y_encrypted;
    encryptor.encrypt(x_plain, x_encrypted);
    encryptor.encrypt(y_plain, y_encrypted);
    end = chrono::high_resolution_clock::now();

    cout << "[NOISE] Noise budget in freshly encrypted x: " << decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;
    cout << "[NOISE] Fresh encryption noise: "
         << coeff_modulus_bit_count - decryptor.invariant_noise_budget(x_encrypted) << " bits"
         << endl;

    cout << "[TIME][CLIENT] Encode+Encrypt\t" << chrono::duration_cast<chrono::microseconds>(end - start).count()
         << " us"
         << endl;

    // Perform computation
    start = chrono::high_resolution_clock::now();
    evaluator.multiply_inplace(x_encrypted, y_encrypted);
    end = chrono::high_resolution_clock::now();
    time = chrono::duration_cast<chrono::microseconds>(end - start).count();

    cout << "[TIME][SERVER] Eval\t" << time << " us" << endl;

    cout << "[NOISE] Noise budget in output: " << decryptor.invariant_noise_budget(x_encrypted) << " bits" << endl;
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
    unsigned long long size = x_encrypted.size() * parms.coeff_modulus().size() * parms.poly_modulus_degree() * 8;
    cout << "[SPACE] Ciphertext size\t" << size << " B" << endl;
    cout << endl;
}

