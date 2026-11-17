// platform "browser"

//procedure users() Get {
//
//}
//
//procedure set(orders) Post {
//
//}

post procedure set orders {

}

function square x = x * x

function square x {
  x ** 2
}

square = x in x ** 2

cube = x in {
  pow(x, 3)
}

function cube x {
  pow(x, 3)
}

pi = 3.14

type User t record {
  name string
  age uint8
  info t
}

type User t = string * uint8 * t

// type Utype = User | Teacher | Worker

type utype union {
  User
  Array
  Map
}

type Color enum {
  Red, Blue, Green
}

if x = 10 then y

ch = go square(5)

res <- ch
