package tests

import "core:testing"

@(test)
macro :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/macro.scm")
}
