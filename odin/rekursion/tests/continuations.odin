package tests

import "core:testing"

@(test)
continuations :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/continuations.scm")
}
