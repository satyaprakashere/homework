# Imperative solution
def towerOfhanoi(f, to, aux, n):
    if n == 1 :
        to.append(f.pop())
        print(f, to, aux, n)
        return (f, to, aux)

    (f, aux, to) = towerOfhanoi(f, aux, to, n-1)
    to.append(f.pop())
    print(f, to, aux, n)
    (aux, to, f) = towerOfhanoi(aux, to, f, n-1)
    return (f, to, aux)


print(towerOfhanoi([5, 4, 3, 2, 1], [],  [], 5))
