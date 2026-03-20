package tests

import "core:testing"

@(test)
test_logic :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_logic.scm", {"lib/logic.scm"})
}
