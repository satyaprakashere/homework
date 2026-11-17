# fizzbuzz.roc
# Run with: roc fizzbuzz.roc
# Run tests with: roc test fizzbuzz.roc
#
# Classic FizzBuzz — a great showcase of Roc's match expression.
# Prints numbers 1–20, replacing:
#   multiples of 3 with "Fizz"
#   multiples of 5 with "Buzz"
#   multiples of both with "FizzBuzz"

fizzbuzz = |n| {
    match (n % 3 == 0, n % 5 == 0) {
        (True, True)   => "FizzBuzz"
        (True, False)  => "Fizz"
        (False, True)  => "Buzz"
        (False, False) => n.to_str()
    }
}

expect fizzbuzz(1)  == "1"
expect fizzbuzz(3)  == "Fizz"
expect fizzbuzz(5)  == "Buzz"
expect fizzbuzz(15) == "FizzBuzz"
expect fizzbuzz(7)  == "7"

main! = |_args| {
    var $i = 1
    while $i <= 20 {
        echo!("${fizzbuzz($i)}\n")
        $i = $i + 1
    }
    Ok({})
}
