extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;
use rand::thread_rng;

use crate::range_proof::mod_gate;
use crate::values::{AllocatedQuantity, AllocatedScalar};

mod range_proof;
mod values;
mod signed_integer;

// Shuffle gadget (documented in markdown file)

/// A proof-of-shuffle.
struct ShuffleProof(R1CSProof);

struct TinyProof(R1CSProof);

type Poly = Vec<AllocatedScalar>;
type RNSPoly = Vec<Poly>;
type Ctxt = Vec<RNSPoly>;

pub fn mul_poly<CS: ConstraintSystem>(cs: &mut CS, in_l: Vec<Vec<AllocatedScalar>>, in_r: Vec<Vec<AllocatedScalar>>) -> Result<Vec<Vec<AllocatedScalar>>, R1CSError> {
    let Q_INT: u64 = 17;
    let Q: Scalar = Scalar::from(Q_INT);

    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let (_, _, out_var) = cs.multiply(LinearCombination::from(in_l[i][j].variable), LinearCombination::from(in_r[i][j].variable));

            let out_assignment = match (in_l[i][j].assignment, in_r[i][j].assignment) {
                (Some(l), Some(r)) => Some(l * r),
                (_, _) => None
            };
            out[i].push(AllocatedScalar { variable: out_var, assignment: out_assignment });

            mod_gate(cs, LinearCombination::from(out_var), out_assignment, Q)?;
        }
    }
    Ok(out)
}

impl TinyProof {
    // x is ctxt, size= 2 * l * n
    // y, z are ptxts, size= n
    fn gadget<CS: ConstraintSystem>(cs: &mut CS, in_l: Vec<Vec<Vec<AllocatedScalar>>>, in_r: Vec<Vec<Vec<AllocatedScalar>>>) -> Result<Vec<Vec<Vec<AllocatedScalar>>>, R1CSError> {
        assert_eq!(in_l.len(), 2);
        // assert_eq!(y.len(), o.len());
        let l = in_l[0].len();
        let n = in_l[0][0].len();


        let out = vec![
            mul_poly(cs, in_l[0].clone(), in_r[0].clone())?,
            mul_poly(cs, in_l[1].clone(), in_r[1].clone())?,
        ];

        Ok(out)
    }


    /// Attempt to construct a proof that `output` is a permutation of `input`.
    ///
    /// Returns a tuple `(proof, input_commitments || output_commitments)`.
    pub fn prove<'a, 'b>(
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        input_l: &Vec<Vec<Vec<Scalar>>>,
        input_r: &Vec<Vec<Vec<Scalar>>>,
        output: &Vec<Vec<Vec<Scalar>>>,
    ) -> Result<(TinyProof, Vec<Vec<Vec<CompressedRistretto>>>, Vec<CompressedRistretto>), R1CSError> {
        // Apply a domain separator with the shuffle parameters to the transcript
        //let k = input_l.len();
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut prover = Prover::new(&pc_gens, transcript);

        // Construct blinding factors using an RNG.
        // Note: a non-example implementation would want to operate on existing commitments.
        let mut blinding_rng = rand::thread_rng();

        let x = input_l;
        let y = input_r;
        assert_eq!(x.len(), 2);
        //assert_eq!(y.len(), o.len());
        let l = x[0].len();
        let n = x[0][0].len();
        let mut rng = rand::thread_rng();

        let mut input_l_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut commitments: Vec<Vec<Vec<CompressedRistretto>>> = Vec::with_capacity(2);
        for k in 0..2 {
            input_l_vars.push(Vec::with_capacity(l));
            commitments.push(Vec::with_capacity(l));
            for i in 0..l {
                input_l_vars[k].push(Vec::with_capacity(n));
                commitments[k].push(Vec::with_capacity(n));
                for j in 0..n {
                    let (com, var) = prover.commit(input_l[k][i][j].clone(), Scalar::random(&mut rng));
                    input_l_vars[k][i].push(AllocatedScalar { variable: var, assignment: Some(input_l[k][i][j]) });
                    commitments[k][i].push(com);
                }
            }
        }

        /*
                let (input_commitments, input_vars): (Vec<_>, Vec<_>) = input_l.into_iter()
                    .map(|v| {
                        prover.commit(*v, Scalar::random(&mut blinding_rng))
                    })
                    .unzip();

                let (output_commitments, output_vars): (Vec<_>, Vec<_>) = output.into_iter()
                    .map(|v| {
                        prover.commit(*v, Scalar::random(&mut blinding_rng))
                    })
                    .unzip();
        */
        TinyProof::gadget(&mut prover, input_l_vars.clone(), input_l_vars)?;

        let proof = prover.prove(&bp_gens)?;

        /* Ok((TinyProof(proof), input_commitments, output_commitments))*/
        Ok((TinyProof(proof), commitments, vec![]))
    }

    pub fn verify<'a, 'b>(
        &self,
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        input_commitments: &Vec<Vec<Vec<CompressedRistretto>>>,
        //output_commitments: &Vec<CompressedRistretto>,
    ) -> Result<(), R1CSError> {
        // Apply a domain separator with the shuffle parameters to the transcript
        let k = input_commitments.len();
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut verifier = Verifier::new(transcript);


        let l = input_commitments[0].len();
        let n = input_commitments[0][0].len();
        let mut rng = rand::thread_rng();

        let mut input_l_vars = Vec::with_capacity(2);
        // let mut commitments = Vec::with_capacity(2);
        for k in 0..2 {
            input_l_vars.push(Vec::with_capacity(l));
            // commitments.push(Vec::with_capacity(l));
            for i in 0..l {
                input_l_vars[k].push(Vec::with_capacity(n));
                // commitments[k].push(Vec::with_capacity(n));
                for j in 0..n {
                    let var = verifier.commit(input_commitments[k][i][j]);
                    input_l_vars[k][i].push(AllocatedScalar { variable: var, assignment: None });
                    //commitments[k][i][j] = com;
                }
            }
        }
        /*
        let input_vars: Vec<_> = input_commitments.iter().map(|commitment| {
            verifier.commit(*commitment)
        }).collect();

        let output_vars: Vec<_> = output_commitments.iter().map(|commitment| {
            verifier.commit(*commitment)
        }).collect();
         */

        TinyProof::gadget(&mut verifier, input_l_vars.clone(), input_l_vars)?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}
/*
impl ShuffleProof {
    fn gadget<CS: RandomizableConstraintSystem>(cs: &mut CS, x: Vec<Variable>, y: Vec<Variable>) -> Result<(), R1CSError> {
        assert_eq!(x.len(), y.len());
        let k = x.len();

        if k == 1 {
            cs.constrain(y[0] - x[0]);
            return Ok(());
        }

        cs.specify_randomized_constraints(move |cs| {
            let z = cs.challenge_scalar(b"shuffle challenge");

            // Make last x multiplier for i = k-1 and k-2
            let (_, _, last_mulx_out) = cs.multiply(x[k - 1] - z, x[k - 2] - z);

            // Make multipliers for x from i == [0, k-3]
            let first_mulx_out = (0..k - 2).rev().fold(last_mulx_out, |prev_out, i| {
                let (_, _, o) = cs.multiply(prev_out.into(), x[i] - z);
                o
            });

            // Make last y multiplier for i = k-1 and k-2
            let (_, _, last_muly_out) = cs.multiply(y[k - 1] - z, y[k - 2] - z);

            // Make multipliers for y from i == [0, k-3]
            let first_muly_out = (0..k - 2).rev().fold(last_muly_out, |prev_out, i| {
                let (_, _, o) = cs.multiply(prev_out.into(), y[i] - z);
                o
            });

            // Constrain last x mul output and last y mul output to be equal
            cs.constrain(first_mulx_out - first_muly_out);

            Ok(())
        })
    }
}
*/
fn main() {

// Construct generators. 1024 Bulletproofs generators is enough for 512-size shuffles.
    let pc_gens = PedersenGens::default();
    let bp_gens = BulletproofGens::new(1024, 1);

// Putting the prover code in its own scope means we can't
// accidentally reuse prover data in the test.
    let (proof, in_commitments, out_commitments) = {
        let c1 = vec![vec![vec![
            Scalar::from(0u64),
        ]], vec![vec![
            Scalar::from(0u64),
        ]]];
        let c2 = vec![vec![vec![
            Scalar::from(0u64),
        ]], vec![vec![
            Scalar::from(0u64),
        ]]];
        let outputs = vec![vec![vec![
            Scalar::from(0u64),
        ]], vec![vec![
            Scalar::from(1u64),
        ]]];

        let mut prover_transcript = Transcript::new(b"TinyProofTest");
        TinyProof::prove(
            &pc_gens,
            &bp_gens,
            &mut prover_transcript,
            &c1,
            &c2,
            &outputs,
        )
            .expect("error during proving")
    };

    let mut verifier_transcript = Transcript::new(b"TinyProofTest");

    let verified = proof
        .verify(&pc_gens, &bp_gens, &mut verifier_transcript, &in_commitments)
        .is_ok();
    println!("{verified}");
    assert!(
        verified
    );
}
