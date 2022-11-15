# Circom circuits for FHE

## Usage
Instantiate the `*.template` files by invoking `make`, with an optional argument `N` (default is 1024): 
```bash
make N=2048
```

To benchmark all main components, run `bench_all.sh` (which simply invokes `circom` for each file). 
