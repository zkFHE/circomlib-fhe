use ark_circom::*;
use ark_ec::PairingEngine;
use ark_groth16::*;
use rand::rngs::ThreadRng;

pub fn setup<E : PairingEngine>(circuit: CircomCircuit<E>, mut rng: ThreadRng) -> ark_relations::r1cs::Result<ProvingKey<E>> {
    return generate_random_parameters::<E, _, _>(circuit, &mut rng);
}

pub fn prove<E : PairingEngine>(circuit: CircomCircuit<E>, pk: &ProvingKey<E>, mut rng:  ThreadRng) -> ark_relations::r1cs::Result<Proof<E>> {
    return create_random_proof(circuit, &pk, &mut rng);
}

pub fn verify<E : PairingEngine>(pvk: &PreparedVerifyingKey<E>, proof: &Proof<E>, inputs: &[E::Fr]) -> ark_relations::r1cs::Result<bool> {
    return verify_proof(&pvk, &proof, &inputs);
}
