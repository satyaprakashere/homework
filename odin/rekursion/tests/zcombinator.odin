package tests

import "core:testing"

@(test)
test_zcombinator :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/zcombinator.scm")
}
