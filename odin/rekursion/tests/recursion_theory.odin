package tests

import "core:testing"

@(test)
recursion_theory :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/recursion_theory.scm", {"lib/recursion.scm"})
}
