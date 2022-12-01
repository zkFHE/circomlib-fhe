pragma circom 2.1.0;

include "benchMedium.circom";

component main {public [in, noise]} = BenchMediumNTT(3, 2, 1073692673, 35184371613697, 70368743489537, 70368743587841, 0, 0, 0);
