pragma circom 2.1.0;

include "benchMedium_Ring.circom";

component main {public [in, noise]} = BenchMediumNTTRing(1073692673);
