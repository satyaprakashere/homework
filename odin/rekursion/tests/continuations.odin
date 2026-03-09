package tests

import "core:testing"

@(test)
test_continuations :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/continuations.scm")
}
