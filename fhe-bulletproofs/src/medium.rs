extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;

use crate::gadgets::*;
use crate::utils::*;
use crate::values::AllocatedScalar;

pub struct MediumProof(R1CSProof);

impl MediumProof {
    fn gadget<CS: ConstraintSystem>(
        cs: &mut CS,
        params: &FHEParams,
        in_1: &PubCtxt,
        in_2: &Ptxt,
        b: &Vec<AllocatedScalar>,
        out: &PubCtxt,
    ) -> Result<(), R1CSError> {
        valid_ptxt(params, cs, in_2)?;

        let l = in_1[0].len();
        let q = &params.q;
        let ntt_table = &params.ntt_table;
        let noise = &params.noise_transposed;

        let in_2_ntt = to_ntt(cs, in_2, l, ntt_table, q)?;

        let diff = sub_pubctxt_ptxt(cs, in_1, &in_2_ntt, q)?;
        let mul = square_ctxt(params, cs, diff)?;
        let res = mod_switch(cs, &mul)?;

        let out_circuit = noise_flooding(cs, &res, b, noise, q)?;

        let deg = out_circuit.len();
        let l = out_circuit[0].len();
        let n = out_circuit[0][0].len();
        for k in 0..deg {
            for i in 0..l {
                for j in 0..n {
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
        in_1: &Vec<Vec<Vec<Scalar>>>,
        in_2: &Vec<Scalar>,
        b: &Vec<Scalar>,
        out: &Vec<Vec<Vec<Scalar>>>,
    ) -> Result<(MediumProof, Vec<CompressedRistretto>, Vec<CompressedRistretto>), R1CSError> {
        transcript.append_message(b"dom-sep", b"MediumProof");

        let mut prover = Prover::new(&pc_gens, transcript);

        let mut rng = rand::thread_rng();


        assert_eq!(in_1.len(), 2);
        let _l = in_1[0].len();
        let n = in_1[0][0].len();

        let mut in_2_vars: Ptxt = Vec::with_capacity(n);
        let mut in_2_coms: Vec<CompressedRistretto> = Vec::with_capacity(n);
        for j in 0..n {
            let (com, var) = prover.commit(in_2[j].clone(), Scalar::random(&mut rng));
            in_2_vars.push(AllocatedScalar { variable: var, assignment: Some(in_2[j]) });
            in_2_coms.push(com);
        }

        let mut b_vars: Vec<AllocatedScalar> = Vec::with_capacity(params.noise.len());
        let mut b_coms: Vec<CompressedRistretto> = Vec::with_capacity(params.noise.len());

        for k in 0..params.noise.len() {
            let (com, var) = prover.commit(b[k].clone(), Scalar::random(&mut rng));
            b_vars.push(AllocatedScalar { variable: var, assignment: Some(b[k]) });
            b_coms.push(com);
        }

        MediumProof::gadget(&mut prover, params, in_1, &in_2_vars, &b_vars, out)?;

        let proof = prover.prove(&bp_gens)?;

        Ok((MediumProof(proof), in_2_coms, b_coms))
    }

    pub fn verify<'a, 'b>(
        &self,
        params: &FHEParams,
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        in_1: &Vec<Vec<Vec<Scalar>>>,
        in_2_coms: &Vec<CompressedRistretto>,
        b_coms: &Vec<CompressedRistretto>,
        out: &Vec<Vec<Vec<Scalar>>>,
    ) -> Result<(), R1CSError> {
        transcript.append_message(b"dom-sep", b"MediumProof");

        let mut verifier = Verifier::new(transcript);

        let n = in_2_coms.len();

        let mut in_2_vars: Ptxt = Vec::with_capacity(n);
        for j in 0..n {
            let var = verifier.commit(in_2_coms[j]);
            in_2_vars.push(AllocatedScalar { variable: var, assignment: None });
        }

        let mut b_vars: Ptxt = Vec::with_capacity(params.noise_len);
        for j in 0..params.noise_len {
            let var = verifier.commit(b_coms[j]);
            b_vars.push(AllocatedScalar { variable: var, assignment: None });
        }

        MediumProof::gadget(&mut verifier, params, in_1, &in_2_vars, &b_vars, out)?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}

pub fn setup<'a>() -> (Vec<Vec<Vec<Scalar>>>, Vec<Scalar>, Vec<Scalar>, Vec<Vec<Vec<Scalar>>>, PedersenGens, BulletproofGens, FHEParams) {
    let n: usize = 32; //128; // 8192;
    let qs = vec![35184371613697u64, 70368743489537u64, 70368743587841u64];
    let t = 1073692673u64;
    let params = FHEParams::new(n, &qs, t, 2, 3, Some(33));

    let in1 = new_ctxt(&params, 2);
    let in2 = new_ptxt(&params);
    //let mut b_ints = vec![1u64; params.noise_len / 2];
    let mut b_ints = vec![0u64; params.noise_len / 2];
    b_ints.append(&mut vec![0u64; params.noise_len / 2]);
    let b: Vec<Scalar> = b_ints.iter().map(|x| Scalar::from(*x)).collect();
    let outputs = new_ctxt(&params, 3);

    let pc_gens = PedersenGens::default();
    let bp_gens = BulletproofGens::new(1 << 17, 1);

    (in1, in2, b, outputs, pc_gens, bp_gens, params)
}

pub fn prove(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens, in1: &Vec<Vec<Vec<Scalar>>>, in2: &Vec<Scalar>, b: &Vec<Scalar>, out: &Vec<Vec<Vec<Scalar>>>) -> (MediumProof, Vec<CompressedRistretto>, Vec<CompressedRistretto>) {
    let mut prover_transcript = Transcript::new(b"MediumProofTest");
    MediumProof::prove(
        &params,
        &pc_gens,
        &bp_gens,
        &mut prover_transcript,
        &in1,
        &in2,
        b,
        out,
    ).expect("error during proving")
}

pub fn verify(
    params: &FHEParams,
    pc_gens: &PedersenGens,
    bp_gens: &BulletproofGens,
    proof: &MediumProof,
    in1: &Vec<Vec<Vec<Scalar>>>,
    in2_coms: &Vec<CompressedRistretto>,
    b_coms: &Vec<CompressedRistretto>,
    out: &Vec<Vec<Vec<Scalar>>>,
) -> bool {
    let mut verifier_transcript = Transcript::new(b"MediumProofTest");

    proof.verify(&params, &pc_gens, &bp_gens, &mut verifier_transcript, &in1, &in2_coms, &b_coms, &out).is_ok()
}

pub fn main_medium() {
    let (in1, in2, b, out, pc_gens, bp_gens, params) = setup();

    let (proof, in2_coms, b_coms) = prove(&params, &pc_gens, &bp_gens, &in1, &in2, &b, &out,);

    let verified = verify(&params, &pc_gens, &bp_gens, &proof, &in1, &in2_coms, &b_coms, &out);
    println!("{verified}");
    assert!(verified);
}
