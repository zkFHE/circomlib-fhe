pragma circom 2.1.0;

include "benchSmall_Ring.circom";

component main {public [in, noise]} = BenchSmallNTTRing(1073643521);
