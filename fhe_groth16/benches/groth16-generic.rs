use std::env;
use std::process::ExitCode;

// For benchmark, run:
//     RAYON_NUM_THREADS=N cargo bench --no-default-features --features "std parallel" -- --nocapture
// where N is the number of threads you want to use (N = 1 for single-thread).
use ark_bls12_381::{Bls12_381, Fr as BlsFr};
use ark_crypto_primitives::SNARK;
use ark_ff::{PrimeField, UniformRand};
use ark_groth16::Groth16;
use ark_relations::{
    lc,
    r1cs::{ConstraintSynthesizer, ConstraintSystemRef, SynthesisError},
};
use ark_std::ops::Mul;

const NUM_PROVE_REPETITIONS: usize = 10;
const NUM_VERIFY_REPETITIONS: usize = 10;

#[derive(Copy)]
struct DummyCircuit<F: PrimeField> {
    pub a: Option<F>,
    pub b: Option<F>,
    pub num_variables: usize,
    pub num_constraints: usize,
}

impl<F: PrimeField> Clone for DummyCircuit<F> {
    fn clone(&self) -> Self {
        DummyCircuit {
            a: self.a.clone(),
            b: self.b.clone(),
            num_variables: self.num_variables.clone(),
            num_constraints: self.num_constraints.clone(),
        }
    }
}

impl<F: PrimeField> ConstraintSynthesizer<F> for DummyCircuit<F> {
    fn generate_constraints(self, cs: ConstraintSystemRef<F>) -> Result<(), SynthesisError> {
        let a = cs.new_witness_variable(|| self.a.ok_or(SynthesisError::AssignmentMissing))?;
        let b = cs.new_witness_variable(|| self.b.ok_or(SynthesisError::AssignmentMissing))?;
        let c = cs.new_input_variable(|| {
            let a = self.a.ok_or(SynthesisError::AssignmentMissing)?;
            let b = self.b.ok_or(SynthesisError::AssignmentMissing)?;

            Ok(a * b)
        })?;

        for _ in 0..(self.num_variables - 3) {
            let _ = cs.new_witness_variable(|| self.a.ok_or(SynthesisError::AssignmentMissing))?;
        }

        for _ in 0..self.num_constraints - 1 {
            cs.enforce_constraint(lc!() + a, lc!() + b, lc!() + c)?;
        }

        cs.enforce_constraint(lc!(), lc!(), lc!())?;

        Ok(())
    }
}

macro_rules! groth16_setup_bench {
    ($bench_name:ident, $bench_field:ty, $bench_pairing_engine:ty, $num_variables:expr, $num_constraints:expr) => {
        let rng = &mut ark_std::test_rng();
        let c = DummyCircuit::<$bench_field> {
            a: Some(<$bench_field>::rand(rng)),
            b: Some(<$bench_field>::rand(rng)),
            num_variables: $num_variables,
            num_constraints: $num_constraints,
        };

        let start = ark_std::time::Instant::now();
        for _ in 0..NUM_PROVE_REPETITIONS {
            let (_pk, _) = Groth16::<$bench_pairing_engine>::circuit_specific_setup(c, rng).unwrap();
        }

        println!(
            "setup time for {}: {} us",
            stringify!($bench_pairing_engine),
            start.elapsed().as_micros() / NUM_PROVE_REPETITIONS as u128
        );
    };
}

macro_rules! groth16_prove_bench {
    ($bench_name:ident, $bench_field:ty, $bench_pairing_engine:ty, $num_variables:expr, $num_constraints:expr) => {
        let rng = &mut ark_std::test_rng();
        let c = DummyCircuit::<$bench_field> {
            a: Some(<$bench_field>::rand(rng)),
            b: Some(<$bench_field>::rand(rng)),
            num_variables: $num_variables,
            num_constraints: $num_constraints,
        };

        let (pk, _) = Groth16::<$bench_pairing_engine>::circuit_specific_setup(c, rng).unwrap();

        let start = ark_std::time::Instant::now();

        for _ in 0..NUM_PROVE_REPETITIONS {
            let _ = Groth16::<$bench_pairing_engine>::prove(&pk, c.clone(), rng).unwrap();
        }

        println!(
            "proving time for {}: {} us",
            stringify!($bench_pairing_engine),
            start.elapsed().as_micros() / NUM_PROVE_REPETITIONS as u128
        );
    };
}

macro_rules! groth16_verify_bench {
    ($bench_name:ident, $bench_field:ty, $bench_pairing_engine:ty, $num_variables:expr, $num_constraints:expr) => {
        let rng = &mut ark_std::test_rng();
        let c = DummyCircuit::<$bench_field> {
            a: Some(<$bench_field>::rand(rng)),
            b: Some(<$bench_field>::rand(rng)),
            num_variables: $num_variables,
            num_constraints: $num_constraints,
        };

        let (pk, vk) = Groth16::<$bench_pairing_engine>::circuit_specific_setup(c, rng).unwrap();
        let proof = Groth16::<$bench_pairing_engine>::prove(&pk, c.clone(), rng).unwrap();

        let v = c.a.unwrap().mul(c.b.unwrap());

        let start = ark_std::time::Instant::now();

        for _ in 0..NUM_VERIFY_REPETITIONS {
            let _ = Groth16::<$bench_pairing_engine>::verify(&vk, &vec![v], &proof).unwrap();
        }

        println!(
            "verifying time for {}: {} us",
            stringify!($bench_pairing_engine),
            start.elapsed().as_micros() / NUM_VERIFY_REPETITIONS as u128
        );
    };
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    println!("==============");
    println!("{:?}", args);
    if args.len() < 2 {
        println!("Usage: main {{rlwe|ec}} [OPTIONS]");
        return ExitCode::FAILURE;
    }
    let name = &args[1];
    let (num_vars, num_constraints) = match &name[..] {
        "rlwe" => (3328, 87424), // (212992, 5595136),
        "ec" => (768, 150912), //(768, 9658368),
        x => {
            println!("Unknown setting `{x}'");
            return ExitCode::FAILURE;
        }
    };

    groth16_prove_bench!(bls, BlsFr, Bls12_381,num_vars, num_constraints);
    groth16_setup_bench!(bls, BlsFr, Bls12_381, num_vars, num_constraints);
    groth16_verify_bench!(bls, BlsFr, Bls12_381, num_vars, num_constraints);
    ExitCode::SUCCESS
}
