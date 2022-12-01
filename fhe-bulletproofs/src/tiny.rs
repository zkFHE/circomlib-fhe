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
    ) -> Result<TinyProof, R1CSError> {
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut prover = Prover::new(&pc_gens, transcript);

        let mut rng = rand::thread_rng();

        assert_eq!(in_l.len(), 2);
        let l = in_l[0].len();
        let n = in_l[0][0].len();

        TinyProof::gadget(&mut prover, params, in_l, in_r, out)?;

        let proof = prover.prove(&bp_gens)?;

        Ok(TinyProof(proof))
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
    ) -> Result<(), R1CSError> {
        // Apply a domain separator with the shuffle parameters to the transcript
        transcript.append_message(b"dom-sep", b"TinyProof");
        //transcript.append_message(b"k", Scalar::from(k as u64).as_bytes());

        let mut verifier = Verifier::new(transcript);

        let l = in_l[0].len();
        let n = in_l[0][0].len();

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

    let n: usize = 8192;
    let qs = vec![(1u64 << 45), (1u64 << 45), (1u64 << 45)];
    let t = (1u64 << 21);

    (c1, c2, outputs, pc_gens, bp_gens, FHEParams::new(n, &qs, t, 0, 0, None))
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

fn prove(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, c1: &Vec<Vec<Vec<Scalar>>>, c2: &Vec<Vec<Vec<Scalar>>>, outputs: &Vec<Vec<Vec<Scalar>>>) -> TinyProof {
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

    let proof = prove(&params, &pc_gens, &bp_gens, &in_l, &in_r, &out);

    let verified = verify(&params, &pc_gens, &bp_gens, proof, &in_l, &in_r, &out);
    println!("{verified}");
    assert!(verified);
}
