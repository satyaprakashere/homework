//module BitInteger;
//
//record BigInteger {
//  u32 size;
//  u64[size] arr;
//}

/**
* Adds two unsigned 64 bit integers and provides the low 64 bits with carry information in overflow label.
*
* @param first First unsigned 64 bit number being added.
* @param second Second unsigned 64 bit number being added.
* @returns whole:(sum) If addition fits in 64 bits, answer is stored in sum.
* @returns overflow:(remainder) If addition does not fit in 64 bits, low 64 bits of answer are stored in remainder.
*/
func add(u64 first, u64 second) -> whole:(u64 sum) or overflow:(u64 remainder)


/**
* Adds two unsigned 64 bit integers and provides the low 64 bits ignoring carry information.
*
* @param first First unsigned 64 bit number being added.
* @param second Second unsigned 64 bit number being added.
* @returns Sum of provided numbers ignoring carry.
*/
func unsafeAdd(u64 first, u64 second) -> u64


/**
* Multiplies two unsigned 64 bit integers and provides the low 64 bits.
*
* @param first First unsigned 64 bit number being multiplied.
* @param second Second unsigned 64 bit number being multiplied.
* @returns Low 64 bits of multiplication of two unsigned 64 bit integers.
*/
func mulL(u64 first, u64 second) -> u64


/**
* Multiplies two unsigned 64 bit integers and provides the high 64 bits.
*
* @param first First unsigned 64 bit number being multiplied.
* @param second Second unsigned 64 bit number being multiplied.
* @returns High 64 bits of multiplication of two unsigned 64 bit integers.
*/
func mulH(u64 first, u64 second) -> u64


proc karatsuba(u32 size, u64[size] num1, u64[size] num2) {
    if size == 0 return Array.empty

    if size == 1 return Array.create(multH(num1(0), num2(0)), multL(num1(0), num2(0))

    if size == 2 return


    let sh = size-(size/2)
    let xl = num1.slice(0, size/2);
    let xr = num1.slize(size/2, sh);

    let yl = num2.slice(0, size/2);
    let yr = num2.slize(size/2, sh);


    let r1 = karatsuba(size/2, xl, yl)
    let r2 = karatsuba(sh, xr, yr)
    let r3  = karatsuba(add(xl+xr), add(yl, yr)))

    return r1*(1<<(2*sh) + (r3 - r1 - r2)*(1<<sh) + r2
}


long int multiply(string X, string Y)
{
    // Find the maximum of lengths of x and Y and make length
    // of smaller string same as that of larger string
    int n = makeEqualLength(X, Y);

    // Base cases
    if (n == 0) return 0;
    if (n == 1) return multiplyiSingleBit(X, Y);

    int fh = n/2;   // First half of string, floor(n/2)
    int sh = (n-fh); // Second half of string, ceil(n/2)

    // Find the first half and second half of first string.
    // Refer http://goo.gl/lLmgn for substr method
    string Xl = X.substr(0, fh);
    string Xr = X.substr(fh, sh);

    // Find the first half and second half of second string
    string Yl = Y.substr(0, fh);
    string Yr = Y.substr(fh, sh);

    // Recursively calculate the three products of inputs of size n/2
    long int P1 = multiply(Xl, Yl);
    long int P2 = multiply(Xr, Yr);
    long int P3 = multiply(addBitStrings(Xl, Xr), addBitStrings(Yl, Yr));

    // Combine the three products to get the final result.
    return P1*(1<<(2*sh)) + (P3 - P1 - P2)*(1<<sh) + P2;
}
