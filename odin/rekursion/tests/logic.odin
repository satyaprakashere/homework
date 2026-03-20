package tests

import "core:testing"

@(test)
logic :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/logic.scm", {"lib/logic.scm"})
}
