//go:build ignore
package main

import (
  "fmt"
  "math/rand"
  "time"
)

func main() {
  a, b, c := 1234, 234, 3210

  m1 := Mat(a, b); fillMat(m1, 1000)
  m2 := Mat(b, c); fillMat(m2, 1000)

//fmt.Println(m1)
//fmt.Println(m2)

  res:= Mat(a, c)
  start := time.Now()         // record start time
  m3 := mult(&m1, &m2, &res)
  elapsed := time.Since(start) // calculate elapsed time

  fmt.Printf("Multiplication using pointer array took %s\n", elapsed)
  fmt.Println("res : ", len(*m3))

  res = clear(res)
  start = time.Now()         // record start time
  m4 := multUsingSlice(m1, m2, res)
  elapsed = time.Since(start) // calculate elapsed time

  fmt.Printf("Multiplication using array slice took %s\n", elapsed)
  fmt.Println("res : ", len(m4))
}

func multUsingSlice(x [][]int, y [][]int, res [][]int) [][]int {
  a := len(x)
  if a < 1 || len(x[0]) < 1 {
    return res
  }
  
  b := len(x[0])
  c := len(y[0])
  
  for i := range(a) {
    for j := range(b) {
      for k := range(c) {
        res[i][k] += x[i][j] * y[j][k]
      }
    }
  }
  return res
}

func Mat(m int, n int) [][]int {
  arr := make([][]int, m)
  for i := range(m) {
    arr[i] = make([]int, n)
  }
  return arr
}

func fillMat(mat [][]int, max int) [][]int {
  for i := range(len(mat)) {
    for j := range(len(mat[i])) {
      mat[i][j] = rand.Intn(max)
    }
  }
  return mat
}

func clear(mat [][]int) [][]int {
  for i := range(len(mat)) {
    for j := range(len(mat[i])) {
      mat[i][j] = 0
    }
  }
  return mat
}

func mult(x *[][]int, y *[][]int, res *[][]int) *[][]int {
  a := len(*x)
  if a < 1 || len((*x)[0]) < 1 {
    return res
  }
  b := len((*x)[0])
  c := len((*y)[0])

  for i := range(a) {
    for j := range(c) {
      temp := 0
      for k := range(b) {
        temp += (*x)[i][k] * (*y)[k][j]
      }
      (*res)[i][j] = temp
    }
  }
  return res
}

