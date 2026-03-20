package tests

import "core:testing"

@(test)
goto_macro :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/goto.scm")
}
