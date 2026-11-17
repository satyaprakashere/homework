//go:build ignore
package main

import ("fmt"; "math")

func main() {
    fmt.Println(divide(-2147483648, -1))
}

func divide(dividend int, divisor int) int {
    curr := dividend
    res := 0
    
    neg := 1
    if (dividend < 0) != (divisor < 0) {
        neg = -1
        if curr < 0 {
            curr = 0 - curr
        } else {
            divisor = 0 - divisor
        }
    }
    
    if (dividend < 0) && (divisor < 0) {
        curr = 0 - curr
        divisor = 0 - divisor
    }
    
    switch divisor {
    case 1: res, curr = curr, 0; if neg == -1 {res = 0-res}
    case 2: res, curr = curr>>1, 0; if neg == -1 {res = 0-res}
    case 4: res, curr = curr>>2, 0; if neg == -1 {res = 0-res}
    }
    
    
    for curr >= divisor {
        curr -= divisor
        res += neg
    }
    
    if res > math.MaxInt32 {
        res = math.MaxInt32
    }
    
    if res < math.MinInt32 {
        res = math.MinInt32
    }
    
    return res
}