package tests

import "core:testing"

@(test)
church :: proc(t: ^testing.T) {
	run_scm_tests(t, "tests/cases/church.scm", {"lib/church.scm"})
}
