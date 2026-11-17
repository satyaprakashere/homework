package main

import "core:fmt"

Inner :: struct {
    value: f32,
}

Outer :: struct {
	using inner: Inner,
}

Data :: struct {
	arr: #soa[10]Outer,
}

main :: proc() {
	data := Data{}

    for &outer in data.arr[:] {
        fmt.println(outer.value)
        // NOTE: this version works fine
        // fmt.println(outer.inner.value)
    }
}