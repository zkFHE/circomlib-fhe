use bulletproofs::r1cs::{Prover, Verifier};
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;
use rand::rngs::ThreadRng;

use crate::values::AllocatedScalar;

pub struct FHEParams {
    pub(crate) n: usize,
    pub(crate) q: Vec<Scalar>,
    pub(crate) t: Scalar,
    pub(crate) p: Scalar,
    pub(crate) noise: Vec<Vec<Vec<Vec<Scalar>>>>,
    pub(crate) noise_transposed: Vec<Vec<Vec<Vec<Scalar>>>>,
    pub(crate) noise_len: usize,
    pub(crate) ntt_table: Vec<Vec<Scalar>>,
}

impl FHEParams {
    pub(crate) fn new(n: usize, q: &Vec<u64>, t: u64, noise_len: usize, noise_deg: usize, root: Option<u64>) -> Self {
        FHEParams {
            n: n,
            q: q.iter().map(|x| Scalar::from(*x)).collect(),
            t: Scalar::from(t),
            p: Scalar::from_bits([0xff; 32]),
            noise: {
                let mut noise: Vec<Vec<Vec<Vec<Scalar>>>> = Vec::with_capacity(noise_len);
                let l = q.len();
                for ni in 0..noise_len {
                    noise.push(Vec::with_capacity(noise_deg));
                    for k in 0..noise_deg {
                        noise[ni].push(Vec::with_capacity(l));
                        for i in 0..l {
                            noise[ni][k].push(Vec::with_capacity(n));
                            for j in 0..n {
                                noise[ni][k][i].push(Scalar::from((ni ^ l ^ k ^ j) as u64 % q[i]));
                            }
                        }
                    }
                }
                noise
            },
            noise_transposed: {
                let mut noise: Vec<Vec<Vec<Vec<Scalar>>>> = Vec::with_capacity(noise_deg);
                let l = q.len();
                for k in 0..noise_deg {
                    noise.push(Vec::with_capacity(l));
                    for i in 0..l {
                        noise[k].push(Vec::with_capacity(n));
                        for j in 0..n {
                            noise[k][i].push(Vec::with_capacity(noise_len));
                            for ni in 0..noise_len {
                                noise[k][i][j].push(Scalar::from((ni ^ l ^ k ^ j) as u64 % q[i]));
                            }
                        }
                    }
                }
                noise
            },
            noise_len: noise_len,
            ntt_table: if root.is_some() {
                let mut table: Vec<Vec<Scalar>> = Vec::with_capacity(n);
                let mut curr_root = 1u64;
                for i in 0..n {
                    table.push(Vec::with_capacity(n));
                    for _j in 0..n {
                        table[i].push(Scalar::from(curr_root));
                        curr_root = (curr_root * root.unwrap()) % q[0];
                    }
                }
                table
            } else {
                vec![]
            },
        }
    }
}

pub fn new_ctxt(params: &FHEParams, deg: usize) -> Vec<Vec<Vec<Scalar>>> {
    let mut ctxt: Vec<Vec<Vec<Scalar>>> = Vec::with_capacity(deg);
    for k in 0..deg {
        ctxt.push(Vec::with_capacity(params.q.len()));
        for i in 0..params.q.len() {
            ctxt[k].push(Vec::with_capacity(params.n));
            for _j in 0..params.n {
                ctxt[k][i].push(Scalar::zero());
            }
        }
    }
    ctxt
}

pub fn new_ptxt(params: &FHEParams) -> Vec<Scalar> {
    let mut ptxt: Vec<Scalar> = Vec::with_capacity(params.n);
    for _j in 0..params.n {
        ptxt.push(Scalar::zero());
    }
    ptxt
}

pub fn commit1(prover: &mut Prover<&mut Transcript>, rng: &mut ThreadRng, values: &Vec<Scalar>) -> (Vec<AllocatedScalar>, Vec<CompressedRistretto>) {
    let mut vars: Vec<AllocatedScalar> = Vec::with_capacity(values.len());
    let mut coms: Vec<CompressedRistretto> = Vec::with_capacity(values.len());

    for j in 0..values.len() {
        let (com, var) = prover.commit(values[j].clone(), Scalar::random(rng));
        vars.push(AllocatedScalar { variable: var, assignment: Some(values[j]) });
        coms.push(com);
    }
    (vars, coms)
}

pub fn commit2(prover: &mut Prover<&mut Transcript>, rng: &mut ThreadRng, values: &Vec<Vec<Scalar>>) -> (Vec<Vec<AllocatedScalar>>, Vec<Vec<CompressedRistretto>>) {
    let mut vars: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(values.len());
    let mut coms: Vec<Vec<CompressedRistretto>> = Vec::with_capacity(values.len());

    for j in 0..values.len() {
        let (var, com) = commit1(prover, rng, &values[j]);
        vars.push(var);
        coms.push(com);
    }
    (vars, coms)
}

pub fn commit3(prover: &mut Prover<&mut Transcript>, rng: &mut ThreadRng, values: &Vec<Vec<Vec<Scalar>>>) -> (Vec<Vec<Vec<AllocatedScalar>>>, Vec<Vec<Vec<CompressedRistretto>>>) {
    let mut vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(values.len());
    let mut coms: Vec<Vec<Vec<CompressedRistretto>>> = Vec::with_capacity(values.len());

    for j in 0..values.len() {
        let (var, com) = commit2(prover, rng, &values[j]);
        vars.push(var);
        coms.push(com);
    }
    (vars, coms)
}

pub fn commit1_v(verifier: &mut Verifier<&mut Transcript>, values: &Vec<CompressedRistretto>) -> Vec<AllocatedScalar> {
    let mut vars: Vec<AllocatedScalar> = Vec::with_capacity(values.len());
    for j in 0..values.len() {
        let var = verifier.commit(values[j]);
        vars.push(AllocatedScalar { variable: var, assignment: None });
    }
    vars
}

pub fn commit2_v(verifier: &mut Verifier<&mut Transcript>, values: &Vec<Vec<CompressedRistretto>>) -> Vec<Vec<AllocatedScalar>> {
    let mut vars: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(values.len());
    for j in 0..values.len() {
        vars.push(commit1_v(verifier, &values[j]));
    }
    vars
}

pub fn commit3_v(verifier: &mut Verifier<&mut Transcript>, values: &Vec<Vec<Vec<CompressedRistretto>>>) -> Vec<Vec<Vec<AllocatedScalar>>> {
    let mut vars: Vec<Vec<Vec<AllocatedScalar>>> = Vec::with_capacity(values.len());
    for j in 0..values.len() {
        vars.push(commit2_v(verifier, &values[j]));
    }
    vars
}