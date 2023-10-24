#!/bin/bash

>&2 echo "[BENCH] Generating circuits for " $(ls main_benchRlwe*.circom)
>&2 echo "[BENCH] Writing results to out/bench_rlwe.out"
mkdir -p out/
python3 print_header.py > out/bench_rlwe.out
ls main_benchRlwe*.circom | parallel --progress python3 bench.py {} >> out/bench_rlwe.out

>&2 echo "[BENCH] Outputs written to out/*.{r1cs,wasm}"
>&2 echo "[BENCH] Benchmarks written to out/bench_rlwe.out"
cat out/bench_rlwe.out