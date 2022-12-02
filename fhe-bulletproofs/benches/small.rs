extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::scalar::Scalar;
use fhe_bulletproofs::small::*;
use merlin::Transcript;

const NUM_REPETITIONS: usize = 10;

fn bench_prove() {
    let (in1, in2, in3, b, out, pc_gens, bp_gens, params) = setup();

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        let (_proof, _in2_coms, _in3_coms, _b_coms) = prove(&params, &pc_gens, &bp_gens, &in1, &in2, &in3, &b, &out);
    }

    println!(
        "Proving time for small: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}

fn bench_verify() {
    let (in1, in2, in3, b, out, pc_gens, bp_gens, params) = setup();

    let (proof, in2_coms, in3_coms, b_coms) = prove(&params, &pc_gens, &bp_gens, &in1, &in2, &in3, &b, &out);

    let start = ark_std::time::Instant::now();

    for _ in 0..NUM_REPETITIONS {
        verify(&params, &pc_gens, &bp_gens, &proof, &in1, &in2_coms, &in3_coms, &b_coms, &out);
    }

    println!(
        "verifying time for small: {} us",
        start.elapsed().as_micros() / NUM_REPETITIONS as u128
    );
}


fn main() {
    bench_prove();
    bench_verify();
}
