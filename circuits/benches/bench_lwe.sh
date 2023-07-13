#!/bin/bash

>&2 echo "[BENCH] Generating circuits for " $(ls main_benchLwe*.circom)
>&2 echo "[BENCH] Writing results to out/bench_lwe.out"
mkdir -p out/
python3 print_header.py > out/bench_lwe.out
ls main_benchLwe*.circom | parallel --progress python3 bench.py {} >> out/bench_lwe.out

>&2 echo "[BENCH] Outputs written to out/*.{r1cs,wasm}"
>&2 echo "[BENCH] Benchmarks written to out/bench_lwe.out"
cat out/bench_lwe.out