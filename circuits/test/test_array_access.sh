#!/bin/bash

set -e

mkdir -p out

circom array_access_test.circom -l .. --c -o out

cd out/array_access_test_cpp
 
make
 
echo "{}" > input.json

./array_access_test input.json witness.wtns

cd ../..

rm -rf out/array_access_test_cpp