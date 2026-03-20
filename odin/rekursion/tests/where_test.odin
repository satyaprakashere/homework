package tests

import "core:testing"

@(test)
test_where_macro :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_where.scm")
}
