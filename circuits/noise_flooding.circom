pragma circom 2.1.0;

include "add.circom";

template NoiseFlooding(secparam, deg, l, n, q1, q2, q3, q4, q5, q6) {
    var q[6] = [q1, q2, q3, q4, q5, q6];
	signal input in[deg][l][n]; 
	signal input noise[secparam][deg][l][n];
	signal input b[secparam];
	
	signal output out[deg][l][n];
	
	
	// Select noise depending on bits b
	var lincomb[deg][l][n][secparam+1]; // secparam-index last for easier aggregation later on
	for (var s = 0; s < secparam; s++) {
		// Check that b[s] is binary
		b[s] * (b[s] - 1)  === 0;
		

		for (var i = 0; i < deg; i++) {
			for (var j = 0; j < l; j++) {
				for (var k = 0; k < n; k++) {
					lincomb[i][j][k][s] = b[s] * noise[s][i][j][k];
				}
			}
		}
	}
	
	// Sum all noisy components
	for (var i = 0; i < deg; i++) {
		for (var j = 0; j < l; j++) {
			for (var k = 0; k < n; k++) {
				lincomb[i][j][k][secparam] = in[i][j][k]; // Add input in last position before summing
				out[i][j][k] <== parallel AddModQ(secparam+1, q[j])(lincomb[i][j][k]);
			}
		}
	}
}
