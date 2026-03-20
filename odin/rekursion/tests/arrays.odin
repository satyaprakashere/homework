package tests

import "core:testing"

@(test)
arrays :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/arrays.scm")
}
