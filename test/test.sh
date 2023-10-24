#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    echo "E.g.: $0 lwe"
    exit 1
fi


mkdir -p out

circom $1_test.circom -l .. --c -o out

cd out/$1_test_cpp
 
make
 
echo "{}" > input.json

./$1_test input.json witness.wtns

cd ../..

rm -rf out/$1_test_cpp