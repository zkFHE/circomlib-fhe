use curve25519_dalek::scalar::Scalar;

pub struct FHEParams {
    pub(crate) q: Vec<Scalar>,
    pub(crate) t: Scalar,
    pub(crate) p: Scalar,
    pub(crate) ntt_table: Vec<Vec<Vec<Vec<Scalar>>>>,
}

impl FHEParams {
    pub(crate) fn new(q: &Vec<u64>, t: u64, root: Option<u64>) -> Self {
        FHEParams {
            q: q.iter().map(|x| Scalar::from(*x)).collect(),
            t: Scalar::from(t),
            p: Scalar::from_bits([0xff; 32]),
            ntt_table: if root.is_some() {
                // TODO
                vec![]
            } else {
                vec![]
            },
        }
    }
}