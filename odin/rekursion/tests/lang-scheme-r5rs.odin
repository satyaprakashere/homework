package tests

import "core:testing"

@(test)
test_scheme_r5rs :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/r5rs_compliance.scm")
}
