package tests

import "core:testing"

@(test)
test_recursion_forbidden :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/recursion-forbidden.scm")
}
