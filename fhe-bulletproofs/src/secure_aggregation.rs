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

pub struct SecAggProof(R1CSProof);

impl SecAggProof {
    fn gadget<CS: ConstraintSystem>(
        cs: &mut CS,
        params: &FHEParams,
        w: &Ptxt,
        sk_i: &Poly,
        a_in: &RNSPoly,
        err_in: &RNSPoly,
        a_cons: &RNSPoly,
        err_cons: &RNSPoly,
        out_in: &PubCtxt,
        out_cons: &PubCtxt,
    ) -> Result<(), R1CSError> {
        let l = err_in.len();
        let q = &params.q;

        // Range check on input weights
        in_range(cs, w, Scalar::from(1u64 << 8))?;

        // Range check on error
        let noise_bound = Scalar::from(1u128 << 127);
        for i in 0..l {
            in_range(cs, &err_in[i], noise_bound)?;
            in_range(cs, &err_cons[i], noise_bound)?;
        }

        // Range check on blinding factors
        for i in 0..l {
            in_range(cs, &a_in[i], params.q[i])?;
            in_range(cs, &a_cons[i], params.q[i])?;
        }

        // out_in = (a_in * sk_i + t * err_in + w, -a_in)
        let mut out_in_circ: Ctxt = Vec::with_capacity(2);
        out_in_circ.push(Vec::with_capacity(l));
        out_in_circ.push(Vec::with_capacity(l));
        for i in 0..l {
            let tmp_in_0 = mul_poly_(cs, &a_in[i], sk_i, params.q[i])?;
            let tmp = add_poly_(cs, &tmp_in_0, &err_in[i], q[i])?;
            out_in_circ[0].push(add_poly_(cs, &tmp, &w, q[i])?); // Since t < min{q_i}, no need for modular reduction

            out_in_circ[1].push(neg_poly(cs, &a_in[i], params.q[i])?);
        }

        // out_cons = (a_cons * sk_i + t * err_cons + w, -a_cons)
        let mut out_cons_circ: Ctxt = Vec::with_capacity(2);
        out_cons_circ.push(Vec::with_capacity(l));
        out_cons_circ.push(Vec::with_capacity(l));
        for i in 0..l {
            let tmp_cons_0 = mul_poly_(cs, &a_cons[i], sk_i, params.q[i])?;
            let tmp = add_poly_(cs, &tmp_cons_0, &err_cons[i], q[i])?;
            out_cons_circ[0].push(add_poly_(cs, &tmp, &w, q[i])?); // Since t < min{q_i}, no need for modular reduction

            out_cons_circ[1].push(neg_poly(cs, &a_cons[i], params.q[i])?);
        }

        let n = out_cons[0][0].len();
        for k in 0..2 {
            for i in 0..l {
                for j in 0..n {
                    cs.constrain(LinearCombination::from(out_in[k][i][j]) - LinearCombination::from(out_in_circ[k][i][j].variable));

                    cs.constrain(LinearCombination::from(out_cons[k][i][j]) - LinearCombination::from(out_cons_circ[k][i][j].variable));
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
        in_out: &InputsOutputs,
    ) -> Result<(SecAggProof, Commitments), R1CSError> {
        transcript.append_message(b"dom-sep", b"SecAggProof");

        let mut prover = Prover::new(&pc_gens, transcript);

        let mut rng = rand::thread_rng();

        let (w_vars, w_coms) = commit1(&mut prover, &mut rng, &in_out.w);
        let (sk_vars, sk_coms) = commit1(&mut prover, &mut rng, &in_out.sk_i);
        let (a_in_vars, a_in_coms) = commit2(&mut prover, &mut rng, &in_out.a_in);
        let (err_in_vars, err_in_coms) = commit2(&mut prover, &mut rng, &in_out.err_in);
        let (a_cons_vars, a_cons_coms) = commit2(&mut prover, &mut rng, &in_out.a_cons);
        let (err_cons_vars, err_cons_coms) = commit2(&mut prover, &mut rng, &in_out.err_cons);


        SecAggProof::gadget(&mut prover, params,
                            &w_vars, &sk_vars, &a_in_vars, &err_in_vars, &a_cons_vars, &err_cons_vars, &in_out.out_in, &in_out.out_cons,
        )?;

        let proof = prover.prove(&bp_gens)?;

        let coms = Commitments {
            w: w_coms,
            sk_i: sk_coms,
            a_in: a_in_coms,
            err_in: err_in_coms,
            a_cons: a_cons_coms,
            err_cons: err_cons_coms,
        };

        Ok((SecAggProof(proof), coms))
    }

    pub fn verify<'a, 'b>(
        &self,
        params: &FHEParams,
        pc_gens: &'b PedersenGens,
        bp_gens: &'b BulletproofGens,
        transcript: &'a mut Transcript,
        coms: &Commitments,
        in_out: &InputsOutputs,
    ) -> Result<(), R1CSError> {
        transcript.append_message(b"dom-sep", b"SecAggProof");

        let mut verifier = Verifier::new(transcript);

        let (w_vars) = commit1_v(&mut verifier, &coms.w);
        let (sk_vars) = commit1_v(&mut verifier, &coms.sk_i);
        let (a_in_vars) = commit2_v(&mut verifier, &coms.a_in);
        let (err_in_vars) = commit2_v(&mut verifier, &coms.err_in);
        let (a_cons_vars) = commit2_v(&mut verifier, &coms.a_cons);
        let (err_cons_vars) = commit2_v(&mut verifier, &coms.err_cons);

        SecAggProof::gadget(&mut verifier, params,
                            &w_vars, &sk_vars, &a_in_vars, &err_in_vars, &a_cons_vars, &err_cons_vars, &in_out.out_in, &in_out.out_cons,
        )?;

        verifier.verify(&self.0, &pc_gens, &bp_gens)
    }
}

pub struct InputsOutputs {
    w: Vec<Scalar>,
    sk_i: Vec<Scalar>,
    a_in: Vec<Vec<Scalar>>,
    err_in: Vec<Vec<Scalar>>,
    a_cons: Vec<Vec<Scalar>>,
    err_cons: Vec<Vec<Scalar>>,
    out_in: PubCtxt,
    out_cons: PubCtxt,
}

pub struct Commitments {
    w: Vec<CompressedRistretto>,
    sk_i: Vec<CompressedRistretto>,
    a_in: Vec<Vec<CompressedRistretto>>,
    err_in: Vec<Vec<CompressedRistretto>>,
    a_cons: Vec<Vec<CompressedRistretto>>,
    err_cons: Vec<Vec<CompressedRistretto>>,
}


pub fn setup<'a>() -> (InputsOutputs, PedersenGens, BulletproofGens, FHEParams) {
    let n: usize =  16; //128; // 8192;
    let qs = vec![18014398507892737u64, 18014398508138497u64, 18014398508400641u64];
    let t = 4079617u64;
    let params = FHEParams::new(n, &qs, t, 0, 0, None);

    let w = new_ptxt(&params);
    let sk_i = new_ptxt(&params);

    let a = new_ctxt(&params, 2);
    let a_in = a[0].clone();
    let a_cons = a[1].clone();

    let err = new_ctxt(&params, 2);
    let err_in = err[0].clone();
    let err_cons = err[1].clone();

    let out_in = new_ctxt(&params, 2);
    let out_cons = new_ctxt(&params, 2);

    let pc_gens = PedersenGens::default();
    // let bp_gens = BulletproofGens::new(1 << 17, 1);
    let bp_gens = BulletproofGens::new(1 << 18, 1);


    let in_out = InputsOutputs {
        w,
        sk_i,
        a_in,
        err_in,
        a_cons,
        err_cons,
        out_in,
        out_cons,
    };
    (in_out, pc_gens, bp_gens, params)
}

pub fn prove(params: &FHEParams, pc_gens: &PedersenGens, bp_gens: &BulletproofGens,
             in_out: &InputsOutputs) -> (SecAggProof, Commitments) {
    let mut prover_transcript = Transcript::new(b"SecAggProofTest");
    SecAggProof::prove(
        &params,
        &pc_gens,
        &bp_gens,
        &mut prover_transcript,
        &in_out,
    ).expect("error during proving")
}

pub fn verify(
    params: &FHEParams,
    pc_gens: &PedersenGens,
    bp_gens: &BulletproofGens,
    proof: &SecAggProof,
    coms: &Commitments,
    in_out: &InputsOutputs,
) -> bool {
    let mut verifier_transcript = Transcript::new(b"SecAggProofTest");

    proof.verify(&params, &pc_gens, &bp_gens, &mut verifier_transcript,
                 &coms, &in_out).is_ok()
}

pub fn main_secure_aggregation() {
    let (in_out, pc_gens, bp_gens, params) = setup();

    let (proof, coms) = prove(&params, &pc_gens, &bp_gens, &in_out);

    let verified = verify(&params, &pc_gens, &bp_gens, &proof, &coms, &in_out);
    println!("{verified}");
    assert!(verified);
}
