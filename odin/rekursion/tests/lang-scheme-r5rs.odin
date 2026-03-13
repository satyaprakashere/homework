package tests

import "core:testing"

@(test)
test_scheme_r5rs :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/r5rs.scm", []string{"lib/scheme.scm"})
}
