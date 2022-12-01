extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;
extern crate test;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;
use rand::thread_rng;

use crate::gadgets::*;
use crate::gadgets::Ctxt;
use crate::utils::*;
use crate::values::{AllocatedQuantity, AllocatedScalar};

struct TinyProof(R1CSProof);

impl TinyProof {
    fn gadget<CS: ConstraintSystem>(cs: &mut CS, params: &FHEParams, in_l: &PubCtxt, in_r: &PubCtxt, out: &PubCtxt) -> Result<(), R1CSError> {
        let out_circuit = mul_ctxt_ctxt_pub(cs, params, in_l, in_r)?;
        for k in 0..out.len() {
            for i in 0..out[k].len() {
                for j in 0..out[k][i].len() {
                    cs.constrain(LinearCombination::from(out[k][i][j]) - LinearCombination::from(out_circuit[k][i][j].variable))
                }
            }
        }
        Ok(())
    }

    pub fn prove<'a, 'b>(
        params: &FHEParams,
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

        /*
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
         */

        TinyProof::gadget(&mut prover, params, in_l, in_r, out)?;

        let proof = prover.prove(&bp_gens)?;

        Ok((TinyProof(proof), in_l_coms, in_r_coms, out_coms))
    }

    pub fn verify<'a, 'b>(
        &self,
        params: &FHEParams,
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        in_l: &Vec<Vec<Vec<Scalar>>>,
        in_r: &Vec<Vec<Vec<Scalar>>>,
        out: &Vec<Vec<Vec<Scalar>>>,
        // in_l_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
        // in_r_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
        // out_coms: &Vec<Vec<Vec<CompressedRistretto>>>,
    ) -> Result<(), R1CSError> {
        // Apply a domain separator with the shuffle parameters to the transcript
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut verifier = Verifier::new(transcript);

        let l = in_l[0].len();
        let n = in_l[0][0].len();

        /*
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
         */

        //TinyProof::gadget(&mut verifier, in_l_vars, in_r_vars, out_vars)?;
        TinyProof::gadget(&mut verifier, params, in_l, in_r, out)?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}

fn setup<'a>() -> (Vec<Vec<Vec<Scalar>>>, Vec<Vec<Vec<Scalar>>>, Vec<Vec<Vec<Scalar>>>, PedersenGens, BulletproofGens, FHEParams) {
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

    let pc_gens = PedersenGens::default();
    let bp_gens = BulletproofGens::new(2048, 1);
    let t = Scalar::from(1u64 << 21);
    let p = Scalar::from_bits([0xff; 32]); // TODO

    let qs = vec![(1u64 << 45), (1u64 << 45), (1u64 << 45)];
    let t = (1u64 << 21);

    (c1, c2, outputs, pc_gens, bp_gens, FHEParams::new(&qs, 0u64, None))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[bench]
    fn bench_prove(b: &mut Bencher) {
        let (c1, c2, outputs, pc_gens, bp_gens, params) = setup();

        b.iter(|| {
            prove(&params, &pc_gens, &bp_gens, &c1, &c2, &outputs)
        });
    }
}

fn prove(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, c1: &Vec<Vec<Vec<Scalar>>>, c2: &Vec<Vec<Vec<Scalar>>>, outputs: &Vec<Vec<Vec<Scalar>>>) -> (TinyProof, Vec<Vec<Vec<CompressedRistretto>>>, Vec<Vec<Vec<CompressedRistretto>>>, Vec<Vec<Vec<CompressedRistretto>>>) {
    let mut prover_transcript = Transcript::new(b"TinyProofTest");
    TinyProof::prove(
        &params,
        &pc_gens,
        &bp_gens,
        &mut prover_transcript,
        &c1,
        &c2,
        &outputs,
    ).expect("error during proving")
}

fn verify(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, proof: TinyProof, in_l: &Vec<Vec<Vec<Scalar>>>, in_r: &Vec<Vec<Vec<Scalar>>>, out: &Vec<Vec<Vec<Scalar>>>) -> bool {
    let mut verifier_transcript = Transcript::new(b"TinyProofTest");

    return proof.verify(params, &pc_gens, &bp_gens, &mut verifier_transcript, &in_l, &in_r, &out).is_ok();
}

pub(crate) fn main_tiny() {
    let (in_l, in_r, out, pc_gens, bp_gens, params) = setup();

    let (proof, in_l_coms, in_r_coms, out_coms) = prove(&params, &pc_gens, &bp_gens, &in_l, &in_r, &out);

    let verified = verify(&params, &pc_gens, &bp_gens, proof, &in_l, &in_r, &out);
    println!("{verified}");
    assert!(verified);
}
