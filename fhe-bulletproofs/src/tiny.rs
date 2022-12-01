extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::digest::generic_array::typenum::private::IsLessPrivate;
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;
use rand::thread_rng;

use crate::range_proof::mod_gate;
use crate::values::{AllocatedQuantity, AllocatedScalar};

// Shuffle gadget (documented in markdown file)

/// A proof-of-shuffle.
struct ShuffleProof(R1CSProof);

struct TinyProof(R1CSProof);

type Poly = Vec<AllocatedScalar>;
type RNSPoly = Vec<Poly>;
type Ctxt = Vec<RNSPoly>;

pub fn add_poly<CS: ConstraintSystem>(cs: &mut CS, in_l: &Vec<Vec<AllocatedScalar>>, in_r: &Vec<Vec<AllocatedScalar>>) -> Result<Vec<Vec<AllocatedScalar>>, R1CSError> {
    let q_int: u64 = 17;
    let q: Scalar = Scalar::from(q_int);

    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let out_assignment = match (in_l[i][j].assignment, in_r[i][j].assignment) {
                (Some(l), Some(r)) => Some(l + r),
                (_, _) => None
            };

            let reduced = mod_gate(cs, LinearCombination::from(in_l[i][j].variable) + LinearCombination::from(in_r[i][j].variable), out_assignment, q)?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_poly<CS: ConstraintSystem>(cs: &mut CS, in_l: &Vec<Vec<AllocatedScalar>>, in_r: &Vec<Vec<AllocatedScalar>>) -> Result<Vec<Vec<AllocatedScalar>>, R1CSError> {
    let q_int: u64 = 17;
    let q: Scalar = Scalar::from(q_int);

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

            let reduced = mod_gate(cs, LinearCombination::from(out_var), out_assignment, q)?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_ctxt_ctxt<CS: ConstraintSystem>(cs: &mut CS, in_l: Vec<Vec<Vec<AllocatedScalar>>>, in_r: Vec<Vec<Vec<AllocatedScalar>>>) -> Result<Vec<Vec<Vec<AllocatedScalar>>>, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_r.len(), 2);
    let l = in_l[0].len();
    let n = in_l[0][0].len();

    let tmp1 = mul_poly(cs, &in_l[0], &in_r[1])?;
    let tmp2 = mul_poly(cs, &in_l[1], &in_r[0])?;

    let out = vec![
        mul_poly(cs, &in_l[0], &in_r[0])?,
        add_poly(cs, &tmp1, &tmp2)?,
        mul_poly(cs, &in_l[1], &in_r[1])?,
    ];

    Ok(out)
}

impl TinyProof {
    fn gadget<CS: ConstraintSystem>(cs: &mut CS, in_l: Vec<Vec<Vec<AllocatedScalar>>>, in_r: Vec<Vec<Vec<AllocatedScalar>>>, out: Vec<Vec<Vec<AllocatedScalar>>>) -> Result<(), R1CSError> {
        let out_circuit = mul_ctxt_ctxt(cs, in_l, in_r)?;
        for k in 0..out.len() {
            for i in 0..out[k].len() {
                for j in 0..out[k][i].len() {
                    cs.constrain(LinearCombination::from(out[k][i][j].variable) - LinearCombination::from(out_circuit[k][i][j].variable))
                }
            }
        }
        Ok(())
    }

    pub fn prove<'a, 'b>(
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        in_l: &Vec<Vec<Vec<Scalar>>>,
        in_r: &Vec<Vec<Vec<Scalar>>>,
        out: &Vec<Vec<Vec<Scalar>>>,
    ) -> Result<(TinyProof, Vec<Vec<Vec<CompressedRistretto>>>, Vec<Vec<Vec<CompressedRistretto>>>, Vec<Vec<Vec<CompressedRistretto>>>), R1CSError> {
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut prover = Prover::new(&pc_gens, transcript);

        // Construct blinding factors using an RNG.
        // Note: a non-example implementation would want to operate on existing commitments.
        let mut rng = rand::thread_rng();


        assert_eq!(in_l.len(), 2);
        let l = in_l[0].len();
        let n = in_l[0][0].len();

        let mut in_l_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut in_r_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut out_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut in_l_coms: Vec<Vec<Vec<CompressedRistretto>>> = Vec::with_capacity(2);
        let mut in_r_coms: Vec<Vec<Vec<CompressedRistretto>>> = Vec::with_capacity(2);
        let mut out_coms: Vec<Vec<Vec<CompressedRistretto>>> = Vec::with_capacity(2);
        for k in 0..2 {
            in_l_vars.push(Vec::with_capacity(l));
            in_r_vars.push(Vec::with_capacity(l));
            out_vars.push(Vec::with_capacity(l));
            in_l_coms.push(Vec::with_capacity(l));
            in_r_coms.push(Vec::with_capacity(l));
            out_coms.push(Vec::with_capacity(l));
            for i in 0..l {
                in_l_vars[k].push(Vec::with_capacity(n));
                in_r_vars[k].push(Vec::with_capacity(n));
                out_vars[k].push(Vec::with_capacity(n));
                in_l_coms[k].push(Vec::with_capacity(n));
                in_r_coms[k].push(Vec::with_capacity(n));
                out_coms[k].push(Vec::with_capacity(n));
                for j in 0..n {
                    let (com, var) = prover.commit(in_l[k][i][j].clone(), Scalar::random(&mut rng));
                    in_l_vars[k][i].push(AllocatedScalar { variable: var, assignment: Some(in_l[k][i][j]) });
                    in_l_coms[k][i].push(com);

                    let (com, var) = prover.commit(in_r[k][i][j].clone(), Scalar::random(&mut rng));
                    in_r_vars[k][i].push(AllocatedScalar { variable: var, assignment: Some(in_r[k][i][j]) });
                    in_r_coms[k][i].push(com);

                    let (com, var) = prover.commit(out[k][i][j].clone(), Scalar::random(&mut rng));
                    out_vars[k][i].push(AllocatedScalar { variable: var, assignment: Some(out[k][i][j]) });
                    out_coms[k][i].push(com);
                }
            }
        }

        TinyProof::gadget(&mut prover, in_l_vars, in_r_vars, out_vars)?;

        let proof = prover.prove(&bp_gens)?;

        Ok((TinyProof(proof), in_l_coms, in_r_coms, out_coms))
    }

    pub fn verify<'a, 'b>(
        &self,
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        in_l_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
        in_r_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
        out_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
    ) -> Result<(), R1CSError> {
        // Apply a domain separator with the shuffle parameters to the transcript
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut verifier = Verifier::new(transcript);

        let l = in_l_coms[0].len();
        let n = in_l_coms[0][0].len();

        let mut in_l_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut in_r_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        let mut out_vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(2);
        for k in 0..2 {
            in_l_vars.push(Vec::with_capacity(l));
            in_r_vars.push(Vec::with_capacity(l));
            out_vars.push(Vec::with_capacity(l));
            for i in 0..l {
                in_l_vars[k].push(Vec::with_capacity(n));
                in_r_vars[k].push(Vec::with_capacity(n));
                out_vars[k].push(Vec::with_capacity(n));
                for j in 0..n {
                    let in_l_var = verifier.commit(in_l_coms[k][i][j]);
                    in_l_vars[k][i].push(AllocatedScalar { variable: in_l_var, assignment: None });

                    let in_r_var = verifier.commit(in_r_coms[k][i][j]);
                    in_r_vars[k][i].push(AllocatedScalar { variable: in_r_var, assignment: None });

                    let out_var = verifier.commit(out_coms[k][i][j]);
                    out_vars[k][i].push(AllocatedScalar { variable: out_var, assignment: None });
                }
            }
        }

        TinyProof::gadget(&mut verifier, in_l_vars, in_r_vars, out_vars)?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}

pub(crate) fn main_tiny() {
    let pc_gens = PedersenGens::default();
    let bp_gens = BulletproofGens::new(2048, 1);

// Putting the prover code in its own scope means we can't
// accidentally reuse prover data in the test.
    let (proof, in_l_coms, in_r_coms, out_coms) = {
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
            Scalar::from(0u64),
        ]]];

        let mut prover_transcript = Transcript::new(b"TinyProofTest");
        TinyProof::prove(
            &pc_gens,
            &bp_gens,
            &mut prover_transcript,
            &c1,
            &c2,
            &outputs,
        ).expect("error during proving")
    };

    let mut verifier_transcript = Transcript::new(b"TinyProofTest");

    let verified = proof.verify(&pc_gens, &bp_gens, &mut verifier_transcript, &in_l_coms, &in_r_coms, &out_coms).is_ok();
    println!("{verified}");
    assert!(verified);
}
