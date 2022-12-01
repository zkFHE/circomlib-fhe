extern crate bulletproofs;
extern crate curve25519_dalek;
extern crate merlin;
extern crate rand;

use bulletproofs::{BulletproofGens, PedersenGens};
use bulletproofs::r1cs::*;
use curve25519_dalek::ristretto::CompressedRistretto;
use curve25519_dalek::scalar::Scalar;
use merlin::Transcript;
use rand::thread_rng;

use crate::range_proof::{lt_constant, mod_gate, mod_scalar, range_proof};
use crate::utils::FHEParams;
use crate::values::{AllocatedQuantity, AllocatedScalar};

pub(crate) type Poly = Vec<AllocatedScalar>;
pub(crate) type RNSPoly = Vec<Poly>;
pub(crate) type Ptxt = Poly;
pub(crate) type PtxtNTT = RNSPoly;
pub(crate) type Ctxt = Vec<RNSPoly>;

pub(crate) type PubPoly = Vec<Scalar>;
pub(crate) type PubRNSPoly = Vec<PubPoly>;
pub(crate) type PubCtxt = Vec<Vec<Vec<Scalar>>>;


pub fn sum_mod<CS: ConstraintSystem>(cs: &mut CS,
                                     vars: &Vec<AllocatedScalar>,
                                     constants: &Vec<Scalar>,
                                     q: Scalar) -> Result<AllocatedScalar, R1CSError> {
    // TODO: implement mod-deferral optimization here as well
    let n = vars.len();
    let mut lincomb = LinearCombination::default();
    for ii in 0..n {
        lincomb = lincomb + LinearCombination::from(vars[ii].variable) * constants[ii];
    }
    // TODO: add mod-q gate
    let mut out_assignment = if vars[0].assignment.is_some() {
        let mut res = Scalar::zero();
        for ii in 0..n {
            res += mod_scalar(vars[ii].assignment.unwrap() * constants[ii], q);
            res = mod_scalar(res, q);
        }
        Some(res)
    } else {
        None
    };

    let out_var = cs.allocate(out_assignment)?;
    cs.constrain(lincomb - out_var);
    Ok(AllocatedScalar { variable: out_var, assignment: out_assignment })
}

pub fn to_ntt<CS: ConstraintSystem>(cs: &mut CS, ptxt: &Ptxt, l: usize, table: &Vec<Vec<Scalar>>, q: &Vec<Scalar>) -> Result<PtxtNTT, R1CSError> {
    let n = ptxt.len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            out[i].push(sum_mod(cs, ptxt, &table[j], q[i])?);
        }
    }
    Ok(out)
}

pub fn valid_ptxt<CS: ConstraintSystem>(cs: &mut CS, ptxt: &Ptxt) -> Result<(), R1CSError> {
    let t_int: u64 = 5;
    let t: Scalar = Scalar::from(t_int);

    let n = ptxt.len();

    for j in 0..n {
        lt_constant(cs, LinearCombination::from(ptxt[j].variable), ptxt[j].assignment, t)?;
    }
    Ok(())
}

pub fn add_poly<CS: ConstraintSystem>(cs: &mut CS, in_l: &RNSPoly, in_r: &RNSPoly) -> Result<RNSPoly, R1CSError> {
    let q_int: u64 = 17;
    let q: Scalar = Scalar::from(q_int);

    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let out_assignment = match (in_l[i][j].assignment, in_r[i][j].assignment) {
                (Some(l), Some(r)) => Some(l + r),
                (_, _) => None
            };

            let reduced = mod_gate(cs, LinearCombination::from(in_l[i][j].variable) + LinearCombination::from(in_r[i][j].variable), out_assignment, q)?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_poly<CS: ConstraintSystem>(cs: &mut CS, in_l: &RNSPoly, in_r: &RNSPoly, q: &Vec<Scalar>) -> Result<RNSPoly, R1CSError> {
    assert_eq!(in_l.len(), in_r.len());
    assert_eq!(in_l[0].len(), in_r[0].len());

    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let (_, _, out_var) = cs.multiply(LinearCombination::from(in_l[i][j].variable), LinearCombination::from(in_r[i][j].variable));

            let out_assignment = match (in_l[i][j].assignment, in_r[i][j].assignment) {
                (Some(l), Some(r)) => Some(l * r),
                (_, _) => None
            };

            let reduced = mod_gate(cs, LinearCombination::from(out_var), out_assignment, q[i])?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_pubctxt_ptxt<CS: ConstraintSystem>(cs: &mut CS, params: &FHEParams, in_l: &PubCtxt, in_r: &PtxtNTT) -> Result<Ctxt, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_l[0].len(), in_r.len());
    assert_eq!(in_l[0][0].len(), in_r[0].len());

    let out = vec![
        mul_poly_pub_priv(cs, &in_l[0], &in_r, &params.q)?,
        mul_poly_pub_priv(cs, &in_l[1], &in_r, &params.q)?,
    ];

    assert_eq!(out.len(), in_l.len());
    assert_eq!(out[0].len(), in_l[0].len());
    assert_eq!(out[0][0].len(), in_l[0][0].len());
    Ok(out)
}

pub fn mul_ctxt_ptxt<CS: ConstraintSystem>(params: &FHEParams, cs: &mut CS, in_l: &Ctxt, in_r: &PtxtNTT) -> Result<Ctxt, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_l[0].len(), in_r.len());
    assert_eq!(in_l[0][0].len(), in_r[0].len());

    let out = vec![
        mul_poly(cs, &in_l[0], &in_r, &params.q)?,
        mul_poly(cs, &in_l[1], &in_r, &params.q)?,
    ];

    Ok(out)
}

pub fn add_ctxt_ptxt<CS: ConstraintSystem>(cs: &mut CS, in_l: &Ctxt, in_r: &PtxtNTT, q: &Vec<Scalar>) -> Result<Ctxt, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_l[0].len(), in_r.len());
    assert_eq!(in_l[0][0].len(), in_r[0].len());

    let out = vec![
        add_poly(cs, &in_l[0], &in_r)?,
        in_l[1].clone(),
    ];

    Ok(out)
}


pub fn mul_ctxt_ctxt<CS: ConstraintSystem>(params: &FHEParams, cs: &mut CS, in_l: Vec<Vec<Vec<AllocatedScalar>>>, in_r: Vec<Vec<Vec<AllocatedScalar>>>) -> Result<Vec<Vec<Vec<AllocatedScalar>>>, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_l.len(), in_r.len());
    assert_eq!(in_l[0].len(), in_r[0].len());
    assert_eq!(in_l[0][0].len(), in_r[0][0].len());
    let l = in_l[0].len();
    let n = in_l[0][0].len();

    let tmp1 = mul_poly(cs, &in_l[0], &in_r[1], &params.q)?;
    let tmp2 = mul_poly(cs, &in_l[1], &in_r[0], &params.q)?;

    let out = vec![
        mul_poly(cs, &in_l[0], &in_r[0], &params.q)?,
        add_poly(cs, &tmp1, &tmp2)?,
        mul_poly(cs, &in_l[1], &in_r[1], &params.q)?,
    ];

    Ok(out)
}

pub fn mul_poly_pub<CS: ConstraintSystem>(cs: &mut CS, in_l: &PubRNSPoly, in_r: &PubRNSPoly, q: &Vec<Scalar>) -> Result<RNSPoly, R1CSError> {
    assert_eq!(in_l.len(), in_r.len());
    assert_eq!(in_l[0].len(), in_r[0].len());
    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let out_assignment = Some(in_l[i][j] * in_r[i][j]);
            let out_var = cs.allocate(out_assignment)?;
            let reduced = mod_gate(cs, LinearCombination::from(out_var), out_assignment, q[i])?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_poly_pub_priv<CS: ConstraintSystem>(cs: &mut CS, in_l: &PubRNSPoly, in_r: &RNSPoly, q: &Vec<Scalar>) -> Result<RNSPoly, R1CSError> {
    assert_eq!(in_l.len(), in_r.len());
    assert_eq!(in_l[0].len(), in_r[0].len());
    let l = in_l.len();
    let n = in_l[0].len();

    let mut out: Vec<Vec<AllocatedScalar>> = Vec::with_capacity(l);
    for i in 0..l {
        // out.push(Vec::with_capacity(n));
        // sum_mod(cs, in_r[i].as_ref(), in_l[i].as_ref(), q[i])?;

        out.push(Vec::with_capacity(n));
        for j in 0..n {
            let out_assignment = in_r[i][j].assignment.and_then(|r| Some(in_l[i][j] * r));
            let out_var = cs.allocate(out_assignment)?;
            let reduced = mod_gate(cs, LinearCombination::from(out_var), out_assignment, q[i])?;
            out[i].push(reduced);
        }
    }
    Ok(out)
}

pub fn mul_ctxt_ctxt_pub<CS: ConstraintSystem>(cs: &mut CS,
                                               params: &FHEParams,
                                               in_l: &PubCtxt,
                                               in_r: &PubCtxt,
) -> Result<Ctxt, R1CSError> {
    assert_eq!(in_l.len(), 2);
    assert_eq!(in_r.len(), 2);
    let l = in_l[0].len();
    let n = in_l[0][0].len();
    let q = &params.q;

    let tmp1 = mul_poly_pub(cs, &in_l[0], &in_r[1], &q)?;
    let tmp2 = mul_poly_pub(cs, &in_l[1], &in_r[0], &q)?;

    let out = vec![
        mul_poly_pub(cs, &in_l[0], &in_r[0], &q)?,
        add_poly(cs, &tmp1, &tmp2)?,
        mul_poly_pub(cs, &in_l[1], &in_r[1], &q)?,
    ];

    Ok(out)
}


pub fn noise_flooding<CS: ConstraintSystem>(cs: &mut CS, ctxt: &Ctxt, b: &Vec<AllocatedScalar>, noise: &Vec<Vec<Vec<Vec<Scalar>>>>, q: &Vec<Scalar>) -> Result<Ctxt, R1CSError> {
    assert_eq!(ctxt.len(), 2);
    assert_eq!(ctxt.len(), noise.len());
    assert_eq!(ctxt[0].len(), noise[0].len());
    assert_eq!(ctxt[0][0].len(), noise[0][0].len());
    assert_eq!(b.len(), noise[0][0][0].len());


    let deg = ctxt.len();
    let l = ctxt[0].len();
    let n = ctxt[0][0].len();
    let noise_len = b.len();

    // Check b[i] is binary
    for i in 0..noise_len {
        let (_, _, o) = cs.multiply(LinearCombination::from(b[i].variable), LinearCombination::from(Scalar::one()) - LinearCombination::from(b[i].variable));
        cs.constrain(LinearCombination::from(o));
    }

    // Add noise
    let mut out: Ctxt = Vec::with_capacity(deg);
    for k in 0..deg {
        out.push(Vec::with_capacity(l));
        for i in 0..l {
            out[k].push(Vec::with_capacity(n));
            for j in 0..n {
                out[k][i].push(sum_mod(cs, b, &noise[k][i][j], q[i])?)
            }
        }
    }


    Ok(out)
}