package tests

import "core:testing"

@(test)
test_goto_macro :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_goto.scm")
}
