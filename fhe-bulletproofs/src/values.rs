use bulletproofs::r1cs::Variable;
use curve25519_dalek::scalar::Scalar;

#[derive(Copy, Clone, Debug)]
pub struct AllocatedScalar {
    pub variable: Variable,
    pub assignment: Option<Scalar>,
}
