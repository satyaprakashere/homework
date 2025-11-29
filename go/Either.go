//go:build ignore
package main

type Error struct {}

type Either struct {
    left interface{}
    right Error
}

func leftEither(value interface{}) Either {
    return Either{value, nil}
}

func rightEither(error Error) Either {
    return Either{nil, error}
}

func (e Either) isError() bool {
    return e.left == nil || e.right != nil
}

func (e Either) orElse(value interface{}) Either {
    if e.left == nil {
        return Either{left: value, right: nil}
    }

    return e
}

func (e Either) fmap(f func(v interface{}) Either) Either {
    if e.isError() {
        return e;
    }

    return f(e.left)
}

func (e Either) get() (interface{}, error) {
    if e.left == nil && e.right == nil {
        return nil, nil // return some generic error : Error.New("Invalid Either instance);
    }
    return e.left, e.right
}

func main() {

}
