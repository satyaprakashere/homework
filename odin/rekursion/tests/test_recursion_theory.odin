package tests

import "core:testing"

@(test)
test_recursion_theory :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_recursion_theory.scm", {"lib/recursion.scm"})
}
