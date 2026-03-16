package tests

import "core:testing"

@(test)
test_ycombinator :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/ycombinator.scm")
}
