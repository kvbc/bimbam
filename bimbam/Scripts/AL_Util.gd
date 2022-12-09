#
# Utility library
#

extends Node

func gcd (a:int, b:int):
	return b if a == 0 else gcd(b % a, a)

#
#
# Public
#
#

func GCDArray (arr):
	if arr.empty():
		return 0
	var r = arr[0]
	for i in range(1, arr.size()):
		r = gcd(arr[i], r)
	return r

func RandomArrayElement (arr):
	return arr[randi() % arr.size()]

func AngleDistance (a, b):
	return abs(fposmod(a - b + 180, 360) - 180)
