#!/bin/bash

date > out/benchSmall.out
for i in {0..10}
do
	build/benchSmall | tee -a out/benchSmall.out
	echo "=================" | tee -a out/benchSmall.out
done
