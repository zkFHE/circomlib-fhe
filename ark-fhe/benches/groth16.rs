use ark_bn254::Bn254;
use ark_circom::*;
use ark_groth16::prepare_verifying_key;
use criterion::{BenchmarkId, black_box, Criterion, criterion_group, criterion_main};
use num_bigint::ToBigInt;
use rand::thread_rng;

use ark_fhe::groth16;

pub fn criterion_benchmark(c: &mut Criterion) {
    let circuit_name = "main_add_poly.1024";
    let wasm = format!("../circuits/out/{circuit_name}_js/{circuit_name}.wasm");
    let r1cs = format!("../circuits/out/{circuit_name}.r1cs");
    let n: u32 = circuit_name.split(".").last().unwrap().parse().unwrap();
    let inputs = vec!["in1", "in2"];

    let cfg = CircomConfig::<Bn254>::new(wasm, r1cs).unwrap();
    // Insert our public inputs as key value pairs
    let mut builder = CircomBuilder::new(cfg);
    for input in inputs {
        for i in 0..n {
            builder.push_input(input, i.to_bigint().unwrap());
        }
    }


    // Create an empty instance for setting it up
    let circom = builder.setup();

    /* c.bench_with_input(
         BenchmarkId::new("groth16::prove::add_poly", 16), &circuit_name,
         |b, circuit_name| {
             let wasm = format!("../circuits/out/{circuit_name}_js/{circuit_name}.wasm");
             let r1cs = format!("../circuits/out/{circuit_name}.r1cs");
             let n: u32 = circuit_name.split(".").last().unwrap().parse().unwrap();
             let inputs = vec!["in1", "in2"];
             let cfg = CircomConfig::<Bn254>::new(wasm, r1cs).unwrap();
             // Insert our public inputs as key value pairs
             let mut builder = CircomBuilder::new(cfg);
             for input in inputs {
                 for i in 0..n {
                     builder.push_input(input, i.to_bigint().unwrap());
                 }
             }


             // // Create an empty instance for setting it up
             // let circom = builder.setup();

             // Get the populated instance of the circuit with the witness
             let circom = builder.build().unwrap();


             b.iter( || {
                 let rng = thread_rng();
                 groth16::setup(circom.clone(), rng)
             })
         }
     );*/
    c.bench_function("groth16::setup::add_poly",
                     |b| {
                         b.iter(|| {
                             let rng = thread_rng();
                             groth16::setup(circom.clone(), rng)
                         })
                     },
    );

    // Get the populated instance of the circuit with the witness
    let circom = builder.build().unwrap();


    let rng = thread_rng();
    let params = groth16::setup(circom.clone(), rng).unwrap();

    c.bench_function("groth16::prove::add_poly",
                     |b| {
                         b.iter(|| {
                             let rng = thread_rng();
                             groth16::prove(circom.clone(), &params, rng)
                         })
                     },
    );
    let rng = thread_rng();
    let proof = groth16::prove(circom.clone(), &params, rng).unwrap();

    let pvk = prepare_verifying_key(&params.vk);
    let inputs = circom.get_public_inputs().unwrap();

    c.bench_function("groth16::prove::add_poly",
                     |b| {
                         b.iter(|| {
                             let rng = thread_rng();
                             groth16::verify(&pvk, &proof, &inputs)
                         })
                     },
    );
    let verified = groth16::verify(&pvk, &proof, &inputs).unwrap();
    assert!(verified);
}


criterion_group!{
    name = benches;
    config = Criterion::default().sample_size(10);
    targets = criterion_benchmark
}
criterion_main!(benches);