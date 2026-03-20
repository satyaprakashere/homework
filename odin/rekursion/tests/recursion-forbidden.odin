package tests

import "core:testing"

@(test)
recursion_forbidden :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/recursion-forbidden.scm")
}
