package tests

import "core:testing"

@(test)
test_boolean :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/boolean.scm")
}
