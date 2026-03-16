package tests

import "core:testing"

@(test)
test_fibonacci :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/fibonacci.scm")
}
