#!/usr/bin/env python3

def myAtoi(s: str) -> int:
	sign = 1
	res = 0
	s = s.lstrip(' ')
	for c in s:
		if c == '-':
			sign = -1
		elif (ord(c) - ord('0')) < 0 or (ord(c) - ord('0') > 9):
			break
		else :
			res = res*10 + (ord(c) - ord('0'))
	res = res*sign
	if res < -(2**31):
		res = -(2**31)
	elif res > (2**31-1):
		res = (2**31-1)
	return res

print(myAtoi("  4334823423423423"))
print(2**31)

print()