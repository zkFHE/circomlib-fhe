#!/bin/bash

set -e

mkdir -p out

circom lwe_test.circom -l .. --c -o out

cd out/lwe_test_cpp
 
make
 
echo "{}" > input.json

./lwe_test input.json witness.wtns

cd ../..

rm -rf out/lwe_test_cpp