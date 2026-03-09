package tests

import "core:testing"

@(test)
test_aliasing :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/aliasing.scm")
}
