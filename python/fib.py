#!/usr/bin/env python3

def fibtail(n, a = 0, b = 1):
	for _ in range(n):
		a, b = b, (a+b) % 0xFFFFFFFF
	return a


print(fibtail(9876543))