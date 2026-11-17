package examples

import scala.annotation.tailrec

def fibNaive(n: Int): Long =
  if n <= 0 then 0
  else if n == 1 then 1
  else fibNaive(n - 1) + fibNaive(n - 2)


def fibTailRec(n: Int): BigInt =
  @tailrec
  def loop(count: Int, prev: BigInt, current: BigInt): BigInt =
    if count <= 0 then prev
    else loop(count - 1, current, prev + current)

  loop(n, 0, 1)

val fibStream: LazyList[BigInt] =
  def loop(a: BigInt, b: BigInt): LazyList[BigInt] =
    a #:: loop(b, a + b)
  loop(0, 1)

@main
def runFibonacci(): Unit =
  println("=== Fibonacci Examples ===")

  println("\n1. Naive recursion:")
  for i <- 0 to 10 do
    print(s"${fibNaive(i)} ")
  println()

  println("\n2. Tail recursion (fibTailRec(50)):")
  println(s"F(50) = ${fibTailRec(50)}")

  println("\n3. First 15 Fibonacci numbers using LazyList:")
  println(fibStream.take(15).toList.mkString(", "))