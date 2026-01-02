(println "Hello, World!")

(function (fib n)
  (if (lessThan n 2) n)
  (add (call fib (subtract n 1))
       (call fib (subtract n 2))))

(function (fibH n a b)
    (if   (equal n 0) a)
    (recur (subtract n 1) b (add a b)))

(function (fib n)
    (call fibH n 0 1))

(val x 10)
; (var y 20) XXX
(Array 1 2 3 4)
(arrayOf 1 2 3 4)

[1 2 3 4]
(List 1 2 3 4 5)
(listOf 1 2 3 4 5)
(Vec 1 2 3 4 5)
(Set 1 2 3 4 5)
(Map "key1" "value1" "key2" "value2")
(Tuple 1 "Hello" 8.9)
