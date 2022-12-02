#!/bin/bash

date > out/benchMedium.out
for i in {0..10}
do
	build/benchMedium | tee -a out/benchMedium.out
	echo "=================" | tee -a out/benchMedium.out
done
