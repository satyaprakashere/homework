package tests

import "core:testing"

@(test)
test_peano :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_peano.scm", {"lib/peano.scm"})
}
