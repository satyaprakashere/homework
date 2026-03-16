package tests

import "core:testing"

@(test)
test_tco :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/tco.scm")
}
