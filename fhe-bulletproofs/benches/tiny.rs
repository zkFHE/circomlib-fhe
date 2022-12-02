extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;

use fhe_bulletproofs::tiny::*;

const NUM_REPETITIONS: usize = 10;

fn bench_prove() {
    let (c1, c2, outputs, pc_gens, bp_gens, params) = setup();

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        prove(&params, &pc_gens, &bp_gens, &c1, &c2, &outputs);
    }

    println!(
        "Proving time for tiny: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}

fn bench_verify() {
    let (c1, c2, outputs, pc_gens, bp_gens, params) = setup();

    let proof = prove(&params, &pc_gens, &bp_gens, &c1, &c2, &outputs);

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        verify(&params, &pc_gens, &bp_gens, &proof, &c1, &c2, &outputs);
    }

    println!(
        "verifying time for tiny: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}


fn main() {
    bench_prove();
    bench_verify();
}
