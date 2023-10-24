# Benchmarks

Collection of benchmarks for circuits.

## Structure:

- `bench*.circom`: templates that instantiate the circuits to benchmark with specific parameters.
- `main_bench*.circom`: templates that include the `main` component. These are the ones that can be compiled to generate the constraints.
- `print_header.py`: script that prints the header for the benchmarking script.
- `bench.py`: benchmarking script. Receives as an argument the `main_bench*.circom` file to benchmark.
- `bench_all.sh`: runs `bench.py` for all files `main_bench*.circom`.
- `bench_lwe.sh`: runs `bench.py` for all files `main_benchLwe*.circom`.
- `bench_rlwe.sh`: runs `bench.py` for all files `main_benchRlwe*.circom`.