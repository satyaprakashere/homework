#!/usr/bin/env python3

x = 1
while 3.5 == 3.5:
    if x == 5:
        break
#   print(x)
    x +=1
d = 3.5
#print(x is True)
print(id(1))
print(id(1))
print(id(d))

a = [1,2,3] # 1000 cycles, 1kb
c = a # 1, # 0
b = [1,2,3]
#
#print(a==b)
print(a is b)
#
#
#address value
#a,b,c   [1,2,3], 8