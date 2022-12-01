use curve25519_dalek::scalar::Scalar;

pub struct FHEParams {
    pub(crate) n: usize,
    pub(crate) q: Vec<Scalar>,
    pub(crate) t: Scalar,
    pub(crate) p: Scalar,
    pub(crate) noise: Vec<Vec<Vec<Vec<Scalar>>>>,
    pub(crate) ntt_table: Vec<Vec<Scalar>>,
}

impl FHEParams {
    pub(crate) fn new(n: usize, q: &Vec<u64>, t: u64, noise_len: usize, root: Option<u64>) -> Self {
        FHEParams {
            n: n,
            q: q.iter().map(|x| Scalar::from(*x)).collect(),
            t: Scalar::from(t),
            p: Scalar::from_bits([0xff; 32]),
            noise: vec![], // TODO
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