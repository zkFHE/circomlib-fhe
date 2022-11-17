use ark_bn254::Bn254;
use ark_circom::*;
use ark_groth16::{
    create_random_proof as prove, generate_random_parameters, prepare_verifying_key, verify_proof,
};
use clap::{Arg, ArgAction::Append, Command, value_parser};
use num_bigint::{ToBigInt};
use rand::thread_rng;

fn main() {
    let args = Command::new("ark-circom-fhe")
        .version("0.1.0")
        .author("Christian Knabenhans")
        .about("Prove FHE computations in zero-knowledge")
        .arg(
            Arg::new("circuit_name")
                .value_parser(value_parser!(String))
                .required(true)
                .help("circuit name"),
        )
        .arg(
            Arg::new("inputs")
                .value_parser(value_parser!(String))
                .required(true)
                // .takes_value(true)
                .action(Append)
                .help("names of input values to the circuit")
        )
        .get_matches();
    let circuit_name = args
        .get_one::<String>("circuit_name")
        .expect("`circuit_name`is required");

    let wasm = format!("../circuits/out/{circuit_name}_js/{circuit_name}.wasm");
    let r1cs = format!("../circuits/out/{circuit_name}.r1cs");
    let n: u32 = circuit_name.split(".").last().unwrap().parse().unwrap();
    let inputs = vec!["in1", "in2"];

    println!("Loading circuit");
    println!("WASM: {wasm}");
    println!("R1CS: {r1cs}");

    // Load the WASM and R1CS for witness and proof generation
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

    // Run a trusted setup
    println!("Setup");
    let mut rng = thread_rng();
    let params = generate_random_parameters::<Bn254, _, _>(circom, &mut rng).unwrap();

    // Get the populated instance of the circuit with the witness
    let circom = builder.build().unwrap();

    let inputs = circom.get_public_inputs().unwrap();

    // Generate the proof
    // let proof = prove(circom, &params, &mut rng)?;
    let proof = prove(circom, &params, &mut rng).unwrap();

    // Check that the proof is valid
    let pvk = prepare_verifying_key(&params.vk);
    let verified = verify_proof(&pvk, &proof, &inputs).unwrap();

    println!("{verified}");
    assert!(verified);
}
