pragma circom 2.1.0;

include "circomlib/circuits/comparators.circom";


/*
    Given an array arr of N elements and an index,
    ArrayAccess returns the element of arr at the position given by index,
    i.e, arr[index].

    Based on https://github.com/iden3/circomlib/blob/circom2.1/circuits/program_constructions/array_access.circom
*/
template ArrayAccess1D(N) {
    signal input arr[N];
    signal input index;
    signal output out;

    var sum = 0;

    signal {binary} isequal[N];
    signal prod[N];
    for (var p=0; p<N; p++) {
        isequal[p] <== IsEqual()([p, index]);
        prod[p] <== isequal[p] * arr[p];
        sum += prod[p];
    }

    out <== sum;
}

template AddArr(n) {
    signal input arr1[n], arr2[n];
    signal output out[n];

    for (var i=0; i<n; i++) {
        out[i] <== arr1[i] + arr2[i];
    }
}

template MulArrByCt(n) {
    signal input ct;
    signal input arr[n];
    signal output out[n];

    for (var i=0; i<n; i++) {
        out[i] <== ct * arr[i];
    }
}

/*
    Given an array arr of N elements and an index,
    ArrayAccess returns the element of arr at the position given by index,
    i.e, arr[index].

    The elements of arr are arrays of dimension n.

    Based on https://github.com/iden3/circomlib/blob/circom2.1/circuits/program_constructions/array_access.circom
*/
template ArrayAccess2D(N, n) {
    signal input arr[N][n];
    signal input index;
    signal output out[n];

    var sum[n];
    for (var i=0; i<n; i++) {
        sum[i] = 0;
    }

    signal {binary} isequal[N];
    signal prod[N][n];
    for (var p=0; p<N; p++) {
        isequal[p] <== IsEqual()([p, index]);
        prod[p] <== MulArrByCt(n)(isequal[p], arr[p]);
        sum = AddArr(n)(sum, prod[p]);
    }

    out <== sum;
}

/*
    Given an array arr of 2^k elements and an array index_bin of k elements,
    ArrayAccess returns the element of arr at the position given by the bit
    decomposition contained in index_bin, i.e, arr[bin2int(index_bin)].

    The elements of arr are arrays of dimension n.
*/
template ArrayAccess2DBin(k, n) {
    signal input arr[1<<k][n];
    signal input {binary} index_bin[k];
    signal output out[n];

    var index = 0;
    var power = 1;
    for (var i=0; i<k; i++) {
        index += power * index_bin[i];
        power *= 2;
    }

    out <== ArrayAccess2D(1<<k, n)(arr, index);
}

/*
    Given an array arr of 2^k elements and an array index_bin of k elements,
    ArrayAccess returns the element of arr at the position given by the bit
    decomposition contained in index_bin, i.e, arr[bin2int(index_bin)].

    The elements of arr are arrays of dimension n.
*/
template ArrayAccess2DBin2(k, n) {
    signal input arr[1<<k][n];
    signal input {binary} index_bin[k];
    signal output out[n];

    signal {binary} index_ext[k][2];
    for (var i=0; i<k; i++) {
        index_ext[i][0] <== 1 - index_bin[i];
        index_ext[i][1] <== index_bin[i];
    }

    var sum[n];
    for (var i=0; i<n; i++) {
        sum[i] = 0;
    }

    signal {binary} prod[1<<k][k];
    signal prod_end[1<<k][n];

    for (var p=0; p<(1<<k); p++) {

        prod[p][0] <== index_ext[0][p & 1];
        for (var i=1; i<k; i++) {
            prod[p][i] <== prod[p][i-1] * index_ext[i][(p>>i) & 1];
        }

        prod_end[p] <== MulArrByCt(n)(prod[p][k-1], arr[p]);
        sum = AddArr(n)(sum, prod_end[p]);
    }

    out <== sum;
}

template AddBSK(dg, N) {
    signal input bsk1[2*dg][2][N], bsk2[2*dg][2][N];
    signal output out[2*dg][2][N];

    for (var i=0; i<2*dg; i++) {
        for (var j=0; j<2; j++) {
            for (var k=0; k<N; k++) {
                out[i][j][k] <== bsk1[i][j][k] + bsk2[i][j][k];
            }
        }
    }
}

template MulBSKByCt(dg, N) {
    signal input ct;
    signal input bsk[2*dg][2][N];
    signal output out[2*dg][2][N];

    for (var i=0; i<2*dg; i++) {
        for (var j=0; j<2; j++) {
            for (var k=0; k<N; k++) {
                out[i][j][k] <== ct * bsk[i][j][k];
            }
        }
    }
}

/*
    Given an array bsk of n elements and an index,
    ArrayAccess returns the element of arr at the position given by index,
    i.e, bsk[index].

    The elements of bsk are arrays of dimension 2dg x 2 x N.

    Based on https://github.com/iden3/circomlib/blob/circom2.1/circuits/program_constructions/array_access.circom
*/
template ArrayAccessBSK(n, dg, N) {
    signal input bsk[n][2*dg][2][N];
    signal input index;
    signal output out[2*dg][2][N];

    var sum[2*dg][2][N];
    for (var i=0; i<2*dg; i++) {
        for (var j=0; j<2; j++) {
            for (var k=0; k<N; k++) {
                sum[i][j][k] = 0;
            }
        }
    }

    signal {binary} isequal[n];
    signal prod[n][2*dg][2][N];
    for (var p=0; p<n; p++) {
        isequal[p] <== IsEqual()([p, index]);
        prod[p] <== MulBSKByCt(dg, N)(isequal[p], bsk[p]);
        sum = AddBSK(dg, N)(sum, prod[p]);
    }

    out <== sum;
}

/*
    Given an array bsk of 2^k elements and an array index_bin of k elements,
    ArrayAccess returns the element of arr at the position given by the bit
    decomposition contained in index_bin, i.e, bsk[bin2int(index_bin)].

    The elements of bsk are arrays of dimension 2dg x 2 x N.
*/
template ArrayAccessBSKBin(k, dg, N) {
    signal input bsk[1<<k][2*dg][2][N];
    signal input {binary} index_bin[k];
    signal output key[2*dg][2][N];

    var index = 0;
    var power = 1;
    for (var i=0; i<k; i++) {
        index += power * index_bin[i];
        power *= 2;
    }

    key <== ArrayAccessBSK(1<<k, dg, N)(bsk, index);
}
