package tests

import "core:testing"

@(test)
scheme :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/scheme-r5rs.scm", []string{"lang/scheme.scm"})
}
