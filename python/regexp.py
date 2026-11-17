#!/usr/bin/env python3

def isMatch(s: str, p: str) -> bool:
	i = 0
	prev = ''
	if p[0] == '*':
		return False
	for c in s:
		if i == len(p):
			return False
		if p[i] == '.' or p[i]==c:
			p = p[:i] + c + p[i+1:]

			i = i+1
			continue
		elif p[i] == '*':
			if p[i-1] == c or p[i-1] == '.':
				p = p[:i-1] + c + p[i:]
				continue
			else:
				i=i+1
		if p[i] == c or p[i] == '.':
			i=i+1
		elif i+1 < len(p) and p[i+1] == '*':
			i=i+2
		else:
			return False
		
	while i<len(p)-1 and p[i] == '*':
		i = i+2
	if(i < len(p)):
		return False
	return True

print(isMatch("mississippi", 'mis*is*ip*.'))
print(isMatch("ab", '.*c'))
print(isMatch("aab", 'c*a*b'))
