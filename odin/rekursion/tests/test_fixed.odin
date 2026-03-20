package tests

import "core:testing"

@(test)
test_fixed :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_fixed.scm", {"lib/fixed.scm", "lib/scheme.scm"})
}
