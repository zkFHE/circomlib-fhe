pragma circom 2.1.0;


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
    Given an array arr of 2^k elements and an array index_bin of k elements,
    ArrayAccess returns the element of arr at the position given by the bit
    decomposition contained in index_bin, i.e, arr[bin2int(index_bin)].

    The elements of arr are arrays of dimension n.
*/
template ArrayAccess(k, n) {
    signal input arr[1<<k][n];
    signal input index_bin[k];
    signal output out[n];

    signal index_ext[k][2];
    for (var i=0; i<k; i++) {
        index_ext[i][0] <== 1 - index_bin[i];
        index_ext[i][1] <== index_bin[i];
    }

    var sum[n];
    for (var i=0; i<n; i++) {
        sum[i] = 0;
    }

    signal prod[1<<k][k];
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
