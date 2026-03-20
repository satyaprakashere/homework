package tests

import "core:testing"

@(test)
recursion :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/recursion.scm")
}
