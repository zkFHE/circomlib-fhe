#!/bin/bash

echo "Generating circuits for " $(ls main_*.circom)
echo "Writing results to out/bench.out"
python print_header.py > out/bench.out
ls main_*.circom | parallel --progress python bench.py {} >> out/bench.out