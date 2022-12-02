extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;

use crate::gadgets::*;
use crate::utils::*;

pub struct TinyProof(R1CSProof);

impl TinyProof {
    pub fn gadget<CS: ConstraintSystem>(cs: &mut CS, params: &FHEParams, in_l: &PubCtxt, in_r: &PubCtxt, out: &PubCtxt) -> Result<(), R1CSError> {
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

        let _rng = rand::thread_rng();

        assert_eq!(in_l.len(), 2);
        let _l = in_l[0].len();
        let _n = in_l[0][0].len();

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

        let _l = in_l[0].len();
        let _n = in_l[0][0].len();

        TinyProof::gadget(&mut verifier, params, in_l, in_r, out)?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}

pub fn setup<'a>() -> (Vec<Vec<Vec<Scalar>>>, Vec<Vec<Vec<Scalar>>>, Vec<Vec<Vec<Scalar>>>, PedersenGens, BulletproofGens, FHEParams) {
    let n: usize = 32; //128; // 8192;
    let qs = vec![8796092792833u64, 8796092858369u64];
    let t = 1073692673u64;
    let params = FHEParams::new(n, &qs, t, 0, 0, None);

    let in1 = new_ctxt(&params, 2);
    let in2 = new_ctxt(&params, 2);
    let out = new_ctxt(&params, 3);
    let pc_gens = PedersenGens::default();
    let bp_gens = BulletproofGens::new(1<<17, 1);

    (in1, in2, out, pc_gens, bp_gens, params)
}

pub fn prove(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, c1: &Vec<Vec<Vec<Scalar>>>, c2: &Vec<Vec<Vec<Scalar>>>, outputs: &Vec<Vec<Vec<Scalar>>>) -> TinyProof {
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

pub fn verify(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, proof: &TinyProof, in_l: &Vec<Vec<Vec<Scalar>>>, in_r: &Vec<Vec<Vec<Scalar>>>, out: &Vec<Vec<Vec<Scalar>>>) -> bool {
    let mut verifier_transcript = Transcript::new(b"TinyProofTest");

    return proof.verify(params, &pc_gens, &bp_gens, &mut verifier_transcript, &in_l, &in_r, &out).is_ok();
}

pub fn main_tiny() {
    let (in_l, in_r, out, pc_gens, bp_gens, params) = setup();

    let proof = prove(&params, &pc_gens, &bp_gens, &in_l, &in_r, &out);

    let verified = verify(&params, &pc_gens, &bp_gens, &proof, &in_l, &in_r, &out);
    println!("{verified}");
    assert!(verified);
}
