use ark_bn254::Bn254;
use ark_circom::*;
use ark_groth16::prepare_verifying_key;
use criterion::{BatchSize, Criterion, criterion_group, criterion_main};
use num_bigint::ToBigInt;
use rand::thread_rng;

use ark_fhe::groth16;

pub fn criterion_benchmark(c: &mut Criterion) {
    let circuit_name = "main_bench1.512";
    let wasm = format!("../circuits/out/{circuit_name}_js/{circuit_name}.wasm");
    let r1cs = format!("../circuits/out/{circuit_name}.r1cs");
    let n: u32 = circuit_name.split(".").last().unwrap().parse().unwrap();
    let inputs = vec!["in", "w1", "w2"];

    let cfg = CircomConfig::<Bn254>::new(wasm, r1cs).unwrap();
    let mut builder = CircomBuilder::new(cfg);
    for input in inputs {
        if input == "in" {
            for _ in 0..n {
                builder.push_input(input, 0.to_bigint().unwrap());
                builder.push_input(input, 0.to_bigint().unwrap());
            }
        } else {
            for _ in 0..n {
                builder.push_input(input, 0.to_bigint().unwrap());
            }
        }
    }

    let circom_empty = builder.setup();
    let circom_filled = builder.build().unwrap();

    let mut rng = thread_rng();
    let params = groth16::setup(circom_empty.clone(), &mut rng).unwrap();

    let pvk = prepare_verifying_key(&params.vk);
    let inputs = circom_filled.get_public_inputs().unwrap();

    let proof = groth16::prove(circom_filled.clone(), &params, &mut rng).unwrap();
    let verified = groth16::verify(&pvk, &proof, &inputs).unwrap();
    assert!(verified);

    c.bench_function(&*format!("groth16::setup::{circuit_name}"),
                     move |b| {
                         b.iter_batched(|| circom_empty.clone(),
                                        |circuit| {
                                            groth16::setup(circuit, &mut rng)
                                        }, BatchSize::LargeInput)
                     },
    );

    let mut rng = thread_rng();
    c.bench_function(&*format!("groth16::prove::{circuit_name}"),
                     move |b| {
                         b.iter_batched(|| circom_filled.clone(),
                                        |circuit| {
                                            groth16::prove(circuit, &params, &mut rng)
                                        }, BatchSize::LargeInput)
                     },
    );

    c.bench_function(&*format!("groth16::verify::{circuit_name}"),
                     |b| {
                         b.iter(|| {
                             groth16::verify(&pvk, &proof, &inputs)
                         })
                     },
    );
}


criterion_group! {
    name = benches;
    config = Criterion::default().sample_size(10);
    targets = criterion_benchmark
}
criterion_main!(benches);
