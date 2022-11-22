#!/bin/bash

echo "[BENCH] Generating circuits for " $(ls main_*.circom)
echo "[BENCH] Writing results to out/bench.out"
mkdir -p out/
python3 print_header.py > out/bench.out
ls main_*.circom | parallel --progress python3 bench.py {} >> out/bench.out

echo "[BENCH] Outputs written to out/*.{r1cs,wasm}"
echo "[BENCH] Benchmarks written to out/bench.out"