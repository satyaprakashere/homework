package tests

import "core:testing"

@(test)
tco :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/tco.scm")
}
