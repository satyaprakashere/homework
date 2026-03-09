package tests

import "core:testing"

@(test)
test_let :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/let.scm")
}
