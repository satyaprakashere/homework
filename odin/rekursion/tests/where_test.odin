package tests

import "core:testing"

@(test)
where_macro :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/where.scm")
}
