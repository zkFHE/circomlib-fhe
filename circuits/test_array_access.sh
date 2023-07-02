#!/bin/bash

set -e

circom array_access_test.circom --c -o out

cd out/array_access_test_cpp
 
make
 
echo "{}" > input.json

./array_access_test input.json witness.wtns

cd ../..

rm -rf out/array_access_test_cpp