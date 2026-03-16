package tests

import "core:testing"

@(test)
test_recursion :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_recursion.scm")
}
