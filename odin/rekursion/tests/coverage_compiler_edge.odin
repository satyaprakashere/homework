package tests

import "core:testing"

@(test)
coverage_compiler_edge :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/coverage_compiler_edge.scm")
}
