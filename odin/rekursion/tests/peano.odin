package tests

import "core:testing"

@(test)
peano :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/peano.scm", {"lib/peano.scm"})
}
