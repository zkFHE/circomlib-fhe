#!/bin/bash

set -e

circom lwe_test.circom --c -o out

cd out/lwe_test_cpp
 
make
 
echo "{}" > input.json

./lwe_test input.json witness.wtns

cd ../..

rm -rf out/lwe_test_cpp