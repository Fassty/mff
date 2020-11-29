#!/bin/bash
for file in ./vstup*; do
	rm out
	(python ../../generator_cycles.py < "$file") > out
	RES=$(cat out | glpsol -m | grep "#OUTPUT:")
	echo "$RES"
done
