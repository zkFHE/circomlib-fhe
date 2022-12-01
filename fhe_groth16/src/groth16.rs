use ark_circom::*;
use ark_ec::PairingEngine;
use ark_groth16::*;
use rand::Rng;

pub fn setup<E: PairingEngine, R: Rng>(circuit: CircomCircuit<E>, rng: &mut R) -> ark_relations::r1cs::Result<ProvingKey<E>>
{
    return generate_random_parameters::<E, _, _>(circuit, rng);
}

pub fn prove<E: PairingEngine, R: Rng>(circuit: CircomCircuit<E>, pk: &ProvingKey<E>, rng: &mut R) -> ark_relations::r1cs::Result<Proof<E>> {
    return create_random_proof(circuit, &pk, rng);
}

pub fn verify<E: PairingEngine>(pvk: &PreparedVerifyingKey<E>, proof: &Proof<E>, inputs: &[E::Fr]) -> ark_relations::r1cs::Result<bool> {
    return verify_proof(&pvk, &proof, &inputs);
}
