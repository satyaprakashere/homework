package tests

import "core:testing"

@(test)
fixed :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/fixed.scm", {"lib/fixed.scm", "lang/scheme.scm"})
}
