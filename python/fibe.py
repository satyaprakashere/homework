def fibonacci(k):
	a,b=(0,1)
	for i in range(k.bit_length()-1,-1,-1):
		d=a**2
		c=2*a*b-d
		d+=b**2
		(a,b)=(d,c+d) if k>>i&1 else (c,d)
	return a

print(fibonacci(10))