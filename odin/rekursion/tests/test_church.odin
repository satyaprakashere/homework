package tests

import "core:testing"

@(test)
test_church :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/test_church.scm", {"lib/church.scm"})
}
