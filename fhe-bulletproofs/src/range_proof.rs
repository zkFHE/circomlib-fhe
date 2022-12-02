use std::ops::{Div, Rem};

use bulletproofs::r1cs::{ConstraintSystem, LinearCombination, R1CSError};
use curve25519_dalek::scalar::Scalar;
use num_bigint::BigUint;

use crate::values::AllocatedScalar;

pub fn scalar_2_u64(x: Scalar) -> u64 {
    let bytes = x.to_bytes();
    let mut bytes_cut: [u8; 8] = [0, 0, 0, 0, 0, 0, 0, 0];
    for i in 0..8 {
        bytes_cut[i] = bytes[i];
    }
    u64::from_le_bytes(bytes_cut)
}

pub fn scalar2biguint(a: Scalar) -> BigUint {
    BigUint::from_bytes_le(a.as_bytes())
}

pub fn biguint2scalar(a: BigUint) -> Scalar {
    let mut bs: [u8; 32] = [0; 32];
    let bs_unpadded = a.to_bytes_le();
    for i in 0..bs_unpadded.len() {
        bs[i] = bs_unpadded[i];
    }
    Scalar::from_bits(bs)
}

/// Perform integer division
pub fn div_scalar(a: Scalar, b: Scalar) -> Scalar {
    let a_int = scalar2biguint(a);
    let b_int = scalar2biguint(b);
    let c_int = a_int.div(b_int);
    biguint2scalar(c_int)
}

pub fn mod_scalar(a: Scalar, b: Scalar) -> Scalar {
    let a_int = scalar2biguint(a);
    let b_int = scalar2biguint(b);
    let c_int = a_int.rem(b_int);
    biguint2scalar(c_int)
}

/// Enforces that v % ct = remainder
pub fn mod_gate<CS: ConstraintSystem>(
    cs: &mut CS,
    v: LinearCombination,
    v_assignment: Option<Scalar>,
    ct: Scalar,
) -> Result<AllocatedScalar, R1CSError> {
    let p = Scalar::from_bits([0xff; 32]);
    let quotient_assignment = v_assignment.map(|x| div_scalar(x, ct));
    let quotient = cs.allocate(quotient_assignment)?;

    let remainder_assignment = v_assignment.map(|x| mod_scalar(x.into(), ct));
    let remainder = cs.allocate(remainder_assignment)?;

    lt_constant(cs, LinearCombination::from(quotient), quotient_assignment, Scalar::from(div_scalar(p, ct)))?;
    lt_constant(cs, LinearCombination::from(remainder), remainder_assignment, ct)?;

    cs.constrain(ct * quotient + remainder - v); // v = ct * quotient + remainder
    Ok(AllocatedScalar { variable: remainder, assignment: remainder_assignment })
}

pub fn log2_scalar(x: Scalar) -> usize {
    BigUint::from_bytes_le(x.as_bytes()).bits() as usize
}

/// Enforces that the quantity of v is in the range [0, ct)
pub fn lt_constant<CS: ConstraintSystem>(
    cs: &mut CS,
    v: LinearCombination,
    v_assignment: Option<Scalar>,
    ct: Scalar,
) -> Result<(), R1CSError> {
    let bit_size: usize = log2_scalar(ct) as usize;
    let lincomb = LinearCombination::from(ct) - v - Scalar::one();
    let assignment = v_assignment.map(|x| ct - x - Scalar::one());

    range_proof(cs, lincomb, assignment, bit_size + 1)
}

pub fn range_proof<CS: ConstraintSystem>(
    cs: &mut CS,
    mut v: LinearCombination,
    v_assignment: Option<Scalar>,
    bits_size: usize) -> Result<(), R1CSError> {
    let mut exp_2 = Scalar::one();
    for i in 0..bits_size {
        // Create low-level variables and add them to constraints
        let (a, b, o) = cs.allocate_multiplier(v_assignment.map(|q| {
            //let bit: u64 = (scalar_2_u64(q) >> i) & 1;
            let bit: u64 = scalar2biguint(q).bit(i as u64) as u64;
            ((1 - bit).into(), bit.into())
        }))?;

        // Enforce a * b = 0, so one of (a,b) is zero
        cs.constrain(o.into());

        // Enforce that a = 1 - b, so they both are 1 or 0.
        cs.constrain(a + (b - 1u64));

        // Add `-b_i*2^i` to the linear combination
        // in order to form the following constraint by the end of the loop:
        // v = Sum(b_i * 2^i, i = 0..n-1)
        v = v - b * exp_2;

        exp_2 = exp_2 + exp_2;
    }

    // Enforce that v = Sum(b_i * 2^i, i = 0..n-1)
    cs.constrain(v);

    Ok(())
}
