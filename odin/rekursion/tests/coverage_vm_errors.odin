package tests

import "core:testing"

@(test)
test_coverage_vm_errors :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/coverage_vm_errors.scm")
}
