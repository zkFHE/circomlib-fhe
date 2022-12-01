use curve25519_dalek::scalar::Scalar;

use crate::gadgets::Ctxt;

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
                    for j in 0..n {
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
            for j in 0..params.n {
                ctxt[k][i].push(Scalar::zero());
            }
        }
    }
    ctxt
}

pub fn new_ptxt(params: &FHEParams) -> Vec<Scalar> {
    let mut ptxt: Vec<Scalar> = Vec::with_capacity(params.n);
    for j in 0..params.n {
        ptxt.push(Scalar::zero());
    }
    ptxt
}