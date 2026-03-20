package tests

import "core:testing"

@(test)
minimal_lisp :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/let.scm", []string{"lang/scheme.scm"})
}
