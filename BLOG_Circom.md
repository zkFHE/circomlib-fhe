# High-Assurance Circom

## Why circom?
- Lots of tools for zk, lots of front-ends/DSL
  - Circom is backend-agnostic (save for R1CS), and not blockchain-specific
- Easy to prototype
- Nice balance on the abstraction: high-level DSL and language feature so you don't hand-code R1CS matrices, but low-level enough to benefit from expert tweaking
- Built-in optimizer

## Existing tools to help circom development
### Circom builtins: assert, log
- What they do
- How we used them (not provided by Circom!)
  - Compile-time checks
  - Checks at witness-generation time
  - Overflows: using functions to check for field-overflow
    - TODO CHECK: how to make sure we're using the right curve for this check

### Circom: tags
- TODO

### Circomspect
- What it does
- Too noisy for our use case: TODO try and have a fix that only returns a single signal for constant comparison
  - our analysis: not really useful for big and complex circuits, too high noise-to-signal-ratio

## Testing
- No good built-in solution: circomlib uses unittests in js (but not documented)
- Antonio's framework for testing: hard-code expected values, and compute witnesses directly using functions without constraining
- How to test soundness: very hard in practice
  - "low-level" issues: 
    - Unconstrained inputs / unsafe assignments
    - Overflowing the field modulus
  - "high-level" issues: everything else, can only be ensured using fuzzing/auditing/static analysis

## Wishlist
- A lot of memory allocated to generate circuits: please use fewer than 152 bytes for binary values 
- Soundness testing: static analysis, fuzzing
