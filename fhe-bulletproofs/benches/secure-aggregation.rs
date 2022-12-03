extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;

use fhe_bulletproofs::secure_aggregation::*;

const NUM_REPETITIONS: usize = 10;

fn bench_prove() {
    let (in_out, pc_gens, bp_gens, params) = setup();

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        let (_proof, _coms) = prove(&params, &pc_gens, &bp_gens, &in_out);
    }

    println!(
        "Proving time for secure_aggregation: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}

fn bench_verify() {
    let (in_out, pc_gens, bp_gens, params) = setup();

    let (proof, coms) = prove(&params, &pc_gens, &bp_gens, &in_out);

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        let _verified = verify(&params, &pc_gens, &bp_gens, &proof, &coms, &in_out);
    }

    println!(
        "verifying time for secure_aggregation: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}


fn main() {
    bench_prove();
    bench_verify();
}
