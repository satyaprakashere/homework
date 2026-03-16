package tests

import "core:testing"

@(test)
test_coverage_primitives :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/coverage_primitives.scm")
}
